package Net::SSH::Perl;
use strict;
use warnings;

use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Config;
use Net::SSH::Perl::Constants qw( :protocol :compat :hosts );
use Net::SSH::Perl::Cipher;
use Net::SSH::Perl::Util qw( :hosts _read_yes_or_no _current_user_win32 );

use Errno;

use vars qw( $VERSION $CONFIG $HOSTNAME );
$CONFIG = {};

use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Socket;
use Fcntl;
use Symbol;
use Carp qw( croak );
use File::Spec::Functions qw( catfile );
use Sys::Hostname;
eval {
    $HOSTNAME = hostname();
};

$VERSION = '2.142';

sub VERSION { $VERSION }

sub new {
    my $class = shift;
    my $host = shift;
    croak "usage: ", __PACKAGE__, "->new(\$host)"
        unless defined $host;
    my $ssh = bless { host => $host }, $class;
    my %p = @_;
    $ssh->{_test} = delete $p{_test};
    $ssh->_init(%p);
    $ssh->_connect unless $ssh->{_test};
    $ssh;
}

sub protocol { $_[0]->{use_protocol} }

sub set_protocol {
    my $ssh = shift;
    my $proto = shift;
    $ssh->{use_protocol} = $proto;
    my $proto_class = join '::', __PACKAGE__,
        ($proto == PROTOCOL_SSH2 ? "SSH2" : "SSH1");
    (my $lib = $proto_class . ".pm") =~ s!::!/!g;
    require $lib;
    bless $ssh, $proto_class;
    $ssh->debug($proto_class->version_string);
    $ssh->_proto_init;
}

use vars qw( @COMPAT );
@COMPAT = (
  [  '^OpenSSH[-_]2\.[012]' => SSH_COMPAT_OLD_SESSIONID,   ],
  [  'MindTerm'             => 0,                          ],
  [  '^2\.1\.0 '            => SSH_COMPAT_BUG_SIGBLOB |
                               SSH_COMPAT_BUG_HMAC |
                               SSH_COMPAT_OLD_SESSIONID,   ],
  [  '^2\.0\.'              => SSH_COMPAT_BUG_SIGBLOB |
                               SSH_COMPAT_BUG_HMAC |
                               SSH_COMPAT_OLD_SESSIONID |
                               SSH_COMPAT_BUG_PUBKEYAUTH |
                               SSH_COMPAT_BUG_X11FWD,      ],
  [  '^2\.[23]\.0 '         => SSH_COMPAT_BUG_HMAC,        ],
  [  '^2\.[2-9]\.'          => 0,                          ],
  [  '^2\.4$'               => SSH_COMPAT_OLD_SESSIONID,   ],
  [  '^3\.0 SecureCRT'      => SSH_COMPAT_OLD_SESSIONID,   ],
  [  '^1\.7 SecureFX'       => SSH_COMPAT_OLD_SESSIONID,   ],
  [  '^2\.'                 => SSH_COMPAT_BUG_HMAC,        ],
);

sub _compat_init {
    my $ssh = shift;
    my($version) = @_;
    $ssh->{datafellows} = 0;
    for my $rec (@COMPAT) {
        my($re, $mask) = @$rec[0, 1];
        if ($version =~ /$re/) {
            $ssh->debug("Compat match: '$version' matches pattern '$re'.");
            $ssh->{datafellows} = $mask;
            return;
        }
    }
    $ssh->debug("No compat match: $version.");
}

sub version_string { }

sub client_version_string { $_[0]->{client_version_string} }
sub server_version_string { $_[0]->{server_version_string} }

sub _current_user {
    if ( $^O eq 'MSWin32' ) {
        return _current_user_win32();
    }

    my $user;
    eval { $user = scalar getpwuid $> };
    return $user;
}

sub _init {
    my $ssh = shift;

    my %arg = @_;
    my $user_config = delete $arg{user_config}
      || catfile($ENV{HOME} || $ENV{USERPROFILE}, '.ssh', 'config');
    my $sys_config  = delete $arg{sys_config}
      || $^O eq 'MSWin32'
        ? catfile($ENV{WINDIR}, 'ssh_config')
        : "/etc/ssh_config";

    my $directives = delete $arg{options} || [];

    if (my $proto = delete $arg{protocol}) {
        push @$directives, "Protocol $proto";
    }

    my $cfg = Net::SSH::Perl::Config->new($ssh->{host}, %arg);
    $ssh->{config} = $cfg;

    # Merge config-format directives given through "options"
    # (just like -o option to ssh command line). Do this before
    # reading config files so we override files.
    for my $d (@$directives) {
        $cfg->merge_directive($d);
    }

    for my $f (($user_config, $sys_config)) {
        $ssh->debug("Reading configuration data $f");
        $cfg->read_config($f);
    }

    if (my $real_host = $ssh->{config}->get('hostname')) {
        $ssh->{host} = $real_host;
    }

    my $user = _current_user();
    if ($user && $user eq "root" &&
      !defined $ssh->{config}->get('privileged')) {
        $ssh->{config}->set('privileged', 1);
    }

    unless ($ssh->{config}->get('protocol')) {
        $ssh->{config}->set('protocol',
            PROTOCOL_SSH1 | PROTOCOL_SSH2 | PROTOCOL_SSH1_PREFERRED);
    }

    unless (defined $ssh->{config}->get('password_prompt_login')) {
        $ssh->{config}->set('password_prompt_login', 1);
    }
    unless (defined $ssh->{config}->get('password_prompt_host')) {
        $ssh->{config}->set('password_prompt_host', 1);
    }
    unless (defined $ssh->{config}->get('number_of_password_prompts')) {
        $ssh->{config}->set('number_of_password_prompts', 3);
    }
}

sub _proto_init { }

sub register_handler { }

sub config { $_[0]->{config} }

sub configure {
    my $class = shift;
    $CONFIG = { @_ };
}

sub ssh {
    my($host, @cmd) = @_;
    my($user);
    ($host, $user) = $host =~ m!(.+)@(.+)! ?
       ($2, $1) : ($host, _current_user());
    my $ssh = __PACKAGE__->new($host, %$CONFIG);
    $ssh->login($user);
    my($out, $err, $exit) = $ssh->cmd(join ' ', @cmd);
    print $out;
    print STDERR $err if $err;
}

sub issh {
    my($host, @cmd) = @_;
    print join(' ', @cmd), "\n";
    print "Proceed: [y/N]:";
    my $x = scalar(<STDIN>);
    if ($x =~ /^y/i) {
        $CONFIG->{interactive} = 1;
        ssh($host, @cmd);
    }
}

sub _connect {
    my $ssh = shift;
    my $sock = $ssh->_create_socket;

    my $raddr = inet_aton($ssh->{host});
    croak "Net::SSH: Bad host name: $ssh->{host}"
        unless defined $raddr;
    my $rport = $ssh->{config}->get('port') || 'ssh';
    if ($rport =~ /\D/) {
        my @serv = getservbyname(my $serv = $rport, 'tcp');
        $rport = $serv[2] || 22;
    }
    $ssh->debug("Connecting to $ssh->{host}, port $rport.");
    connect($sock, sockaddr_in($rport, $raddr))
        or die "Can't connect to $ssh->{host}, port $rport: $!";

    select((select($sock), $|=1)[0]);

    $ssh->{session}{sock} = $sock;
    $ssh->_exchange_identification;

    if ($^O eq 'MSWin32') {
      my $nonblocking = 1;
      ioctl $sock, 0x8004667e, \\$nonblocking;
    }
    else {
      defined($sock->blocking(0))
          or die "Can't set socket non-blocking: $!";
    }

    $ssh->debug("Connection established.");
}

sub _create_socket {
    my $ssh = shift;
    my $sock = gensym;

    my ($p,$end,$delta) = (0,1,1); # normally we use whatever port we can get
          ($p,$end,$delta) = (1023,512,-1) if $ssh->{config}->get('privileged');

    # allow an explicit bind address
    my $addr = $ssh->{config}->get('bind_address');
    $addr = inet_aton($addr) if $addr;
    ($p,$end,$delta) = (10000,65535,1) if $addr and not $p;
    $addr ||= INADDR_ANY;

    for(; $p != $end; $p += $delta) {
        socket($sock, AF_INET, SOCK_STREAM, getprotobyname('tcp') || 0) ||
            croak "Net::SSH: Can't create socket: $!";
        setsockopt($sock, IPPROTO_TCP, TCP_NODELAY, 1);
        last if not $p or bind($sock, sockaddr_in($p,$addr));
        if ($! =~ /Address already in use/i) {
            close($sock) or warn qq{Could not close socket: $!\n};
            next;
        }
        croak "Net::SSH: Can't bind socket to port $p: $!";
    }
    if($p) {
        $ssh->debug("Allocated local port $p.");
        $ssh->{config}->set('localport', $p);
    }

    $sock;
}

sub _disconnect { }

sub fatal_disconnect {
    my $ssh = shift;
    $ssh->_disconnect(@_);
    croak @_;
}

sub _read_version_line {
    my $ssh = shift;
    my $sock = $ssh->{session}{sock};
    my $line;
    for(;;) {
        my $s = IO::Select->new($sock);
        my @ready = $s->can_read;
        my $buf;
        my $len = sysread($sock, $buf, 1);
        unless(defined($len)) {
            next if $!{EAGAIN} || $!{EWOULDBLOCK};
            croak "Read from socket failed: $!";
        }
        croak "Connection closed by remote host" if $len == 0;
        $line .= $buf;
        croak "Version line too long: $line"
         if substr($line, 0, 4) eq "SSH-" and length($line) > 255;
        croak "Pre-version line too long: $line" if length($line) > 4*1024;
        return $line if $buf eq "\n";
    }
}

sub _read_version {
    my $ssh = shift;
    my ($line, $line_out);
    do {
        $line = $line_out = $ssh->_read_version_line;
    } while (substr($line, 0, 4) ne "SSH-");
    chomp($line_out);
    $ssh->debug("Remote version string: $line_out");
    return $line;
}

sub sock { $_[0]->{session}{sock} }

sub _exchange_identification {
    my $ssh = shift;
    my $sock = $ssh->{session}{sock};
    my $remote_id = $ssh->_read_version;
    ($ssh->{server_version_string} = $remote_id) =~ s/\cM?\n$//;
    my($remote_major, $remote_minor, $remote_version) = $remote_id =~
        /^SSH-(\d+)\.(\d+)-([^\n\r]+)[\r]*\n$/;
    $ssh->debug("Remote protocol version $remote_major.$remote_minor, remote software version $remote_version");

    my $proto = $ssh->config->get('protocol');
    my($mismatch, $set_proto);
    if ($remote_major == 1) {
        if ($remote_minor == 99 && $proto & PROTOCOL_SSH2 &&
            !($proto & PROTOCOL_SSH1_PREFERRED)) {
            $set_proto = PROTOCOL_SSH2;
        }
        elsif (!($proto & PROTOCOL_SSH1)) {
            $mismatch = 1;
        }
        else {
            $set_proto = PROTOCOL_SSH1;
        }
    }
    elsif ($remote_major == 2) {
        if ($proto & PROTOCOL_SSH2) {
            $set_proto = PROTOCOL_SSH2;
        }
    }
    if ($mismatch) {
        croak sprintf "Protocol major versions differ: %d vs. %d",
            ($proto & PROTOCOL_SSH2) ? PROTOCOL_MAJOR_2 :
            PROTOCOL_MAJOR_1, $remote_major;
    }
    my $compat20 = $set_proto == PROTOCOL_SSH2;
    my $buf = sprintf "SSH-%d.%d-%s\n",
        $compat20 ? PROTOCOL_MAJOR_2 : PROTOCOL_MAJOR_1,
        $compat20 ? PROTOCOL_MINOR_2 : PROTOCOL_MINOR_1,
        $VERSION;
    $ssh->{client_version_string} = substr $buf, 0, -1;
    syswrite $sock, $buf;

    $ssh->set_protocol($set_proto);
    $ssh->_compat_init($remote_version);
}

sub debug {
    my $ssh = shift;
    if ($ssh->{config}->get('debug')) {
        printf STDERR "%s@_\n", $HOSTNAME ? "$HOSTNAME: " : '';
    }
}

sub login {
    my $ssh = shift;
    my($user, $pass) = @_;
    if (!defined $ssh->{config}->get('user')) {
        $ssh->{config}->set('user',
            defined $user ? $user : _current_user());
    }
    if (!defined $pass && exists $CONFIG->{ssh_password}) {
        $pass = $CONFIG->{ssh_password};
    }
    $ssh->{config}->set('pass', $pass);
}

sub _login { }

sub cmd { }
sub shell { }

sub incoming_data {
    my $ssh = shift;
    if (!exists $ssh->{session}{incoming_data}) {
        $ssh->{session}{incoming_data} = Net::SSH::Perl::Buffer->new( MP => $ssh->protocol == PROTOCOL_SSH2 ? 'SSH2' : 'SSH1' );
    }
    $ssh->{session}{incoming_data};
}

sub session_id {
    my $ssh = shift;
    $ssh->{session}{id} = shift if @_ and not defined $ssh->{session}{id};
    $ssh->{session}{id};
}

sub packet_start { Net::SSH::Perl::Packet->new($_[0], type => $_[1]) }

sub check_host_key {
    my $ssh = shift;
    my($key, $host, $u_hostfile, $s_hostfile) = @_;
    my $strict_host_key_checking =
        $ssh->{config}->get('strict_host_key_checking') || 'no';
    $host ||= $ssh->{host};
    $u_hostfile ||= $ssh->{config}->get('user_known_hosts');
    $s_hostfile ||= $ssh->{config}->get('global_known_hosts');
    my $port = $ssh->{config}->get('port');

    if (defined $port && $port =~ /\D/) {
        my @serv = getservbyname(my $serv = $port, 'tcp');
        $port = $serv[2];
    }

    my $hash_known_hosts = $ssh->{config}->get('hash_known_hosts');
    my $check_ip = $ssh->{config}->get('check_host_ip');
    $check_ip = 1 unless defined $check_ip;

    my $status = _check_host_in_hostfile($host, $port, $u_hostfile, $key);
    unless (defined $status && ($status == HOST_OK || $status == HOST_CHANGED)) {
        $status = _check_host_in_hostfile($host, $port, $s_hostfile, $key);
    }

    if ($status == HOST_OK) {
        $ssh->debug("Host '$host' is known and matches the host key.");
    }
    elsif ($status == HOST_NEW) {
        if ($strict_host_key_checking =~ /(ask|yes)/) {
            if (!$ssh->{config}->get('interactive')) {
                croak "Host key verification failed.";
            }
            my $prompt =
qq(The authenticity of host '$host' can't be established.
Key fingerprint is @{[ $key->fingerprint($ssh->config->get('fingerprint_hash')) ]}.
Are you sure you want to continue connecting (yes/no)?);
            unless (_read_yes_or_no($prompt, "yes")) {
                croak "Aborted by user!";
            }
        }
        _add_host_to_hostfile($host, $port, $u_hostfile, $key, $hash_known_hosts);
        $ssh->debug("Permanently added '$host' to the list of known hosts.");
    }
    else {
        croak "Host key for '$host' has changed!";
    }

    return unless $check_ip && $host =~ /[a-z][A-Z]+/;
    my $ip = inet_ntoa(inet_aton($host)) or return;

    $status = _check_host_in_hostfile($ip, $port, $u_hostfile, $key);
    unless (defined $status && ($status == HOST_OK || $status == HOST_CHANGED)) {
        $status = _check_host_in_hostfile($ip, $port, $s_hostfile, $key);
    }
    if ($status == HOST_NEW) {
        _add_host_to_hostfile($ip, $port, $u_hostfile, $key, $hash_known_hosts);
    }
    elsif ($status == HOST_CHANGED) {
        my $prompt =
qq(The host key for IP address '$ip' does not match that for '$host'.
Are you sure you want to continue connecting (yes/no)?);
        unless (_read_yes_or_no($prompt, "yes")) {
            croak "Aborted by user!";
        }
    }
}

1;
__END__

=head1 NAME

Net::SSH::Perl - Perl client Interface to SSH

=head1 SYNOPSIS

    use Net::SSH::Perl;
    my $ssh = Net::SSH::Perl->new($host);
    $ssh->login($user, $pass);
    my($stdout, $stderr, $exit) = $ssh->cmd($cmd);

=head1 DESCRIPTION

I<Net::SSH::Perl> is an all-Perl module implementing an SSH
(Secure Shell) client. It is compatible with both the SSH-1 and
SSH-2 protocols.

I<Net::SSH::Perl> enables you to simply and securely execute commands
on remote machines, and receive the STDOUT, STDERR, and exit status
of that remote command. It contains built-in support for various
methods of authenticating with the server (password authentication,
RSA challenge-response authentication, etc.). It completely implements
the I/O buffering, packet transport, and user authentication layers
of the SSH protocol, and makes use of external Perl libraries (in
the Crypt:: family of modules) to handle encryption of all data sent
across the insecure network. It can also read your existing SSH
configuration files (F</etc/ssh_config>, etc.), RSA identity files,
ECDSA identity files, Ed25519 identity files, known hosts files, etc.

One advantage to using I<Net::SSH::Perl> over wrapper-style
implementations of ssh clients is that it saves on process
overhead: you no longer need to fork and execute a separate process
in order to connect to an sshd. Depending on the amount of time
and memory needed to fork a process, this win can be quite
substantial; particularly if you're running in a persistent
Perl environment (I<mod_perl>, for example), where forking a new
process is a drain on process and memory resources.

It also simplifies the process of using password-based authentications;
when writing a wrapper around I<ssh> you probably need to use
I<Expect> to control the ssh client and give it your password.
I<Net::SSH::Perl> has built-in support for the authentication
protocols, so there's no longer any hassle of communicating with
any external processes.

The SSH2 protocol support (present in I<Net::SSH::Perl> as of version
1.00) is compatible with the SSH2 implementation in OpenSSH, and should
also be fully compatible with the "official" SSH implementation. If
you find an SSH2 implementation that is not compatible with
I<Net::SSH::Perl>, please let me know (email address down in
I<AUTHOR & COPYRIGHTS>); it turns out that some SSH2 implementations
have subtle differences from others. AES-CTR (C<aes256-ctr>,
C<aes192-ctr>, and C<aes128-ctr>) and Chacha20-Poly1305 ciphers are
currently supported for SSH2 encryption.  Deprecated ciphers
AES-CBC (C<aes256-cbc>, C<aes192-cbc>, and C<aes128-cbc>) 3DES
(C<3des-cbc>), Blowfish (C<blowfish-cbc>), and RC4 (C<arcfour>)
are available but not enabled by default.  One can enable them by
using the Ciphers options parameter. For example:

    options => [ "Ciphers +aes256-cbc" ]

Using the + notation will append a cipher to the default ciphers list.

Integrity checking is performed by the C<hmac-sha2-256>,
C<hmac-sha2-512>, C<hmac-sha2-256-etm@openssh.com>, or
C<hmac-sha2-512-etm@openssh.com> algorithms.  The deprecated C<hmac-sha1>
or C<hmac-md5> algorithms are available but not enabled by default.  Many
older SSH server installations still use hmac-sha1 as the main accepted
MAC algorithm.  To enable this, use the following options parameter:

    options => [ "MACs +hmac-sha1" ]

Compression, if requested, is limited to Zlib.

Supported server host key algorithms are C<ssh-ed25519>, C<rsa-sha2-512>,
C<rsa-sha2-256>, C<ecdsa-sha2-nistp521>, C<ecdsa-sha2-nistp384>,
C<ecdsa-sha2-nistp256>, and C<ssh-rsa>.  Deprecated C<ssh-dss> is
supported but not enabled by default.  It can be enabled with the options
parameter:

    options => [ "HostKeyAlgorithms +ssh-dss" ]

Supported SSH2 public key authentication algorithms are the same.

Supported Key Exchange (KEX) algorithms are C<diffie-hellman-group1-sha1>,
C<diffie-hellman-group14-sha1>, c<diffie-hellman-group14-sha256>,
C<diffie-hellman-group16-sha512>, C<diffie-hellman-group18-sha512>,
C<diffie-hellman-group-exchange-sha256>, C<diffie-hellman-group-exchange-sha1>,
and C<curve25519-sha256@libssh.org>/C<curve25519-sha256>.  The
C<diffie-hellman-group1-sha1> algorithm is disabled by default, but can
be activated via the options parameter:

    options => [ "KexAlgorithms +diffie-hellman-group1-sha1" ]

If you're looking for SFTP support, take a look at I<Net::SFTP>,
which provides a full-featured Perl implementation of SFTP, and
sits on top of I<Net::SSH::Perl>. SFTP requires the usage of the
SSH2 protocol.

=head1 BASIC USAGE

Usage of I<Net::SSH::Perl> is very simple.

=head2 Net::SSH::Perl->new($host, %params)

To set up a new connection, call the I<new> method, which
connects to I<$host> and returns a I<Net::SSH::Perl> object.

I<new> accepts the following named parameters in I<%params>:

=over 4

=item * protocol

The protocol you wish to use for the connection: should be either
C<2>, C<1>, C<'1,2'> or C<'2,1'>. The first two say, quite simply,
"only use this version of the protocol" (SSH-2 or SSH-1, respectively).
The latter two specify that either protocol can be used, but that
one protocol (the first in the comma-separated list) is preferred
over the other.

For this reason, it's "safer" to use the latter two protocol
specifications, because they ensure that either way, you'll be able
to connect; if your server doesn't support the first protocol listed,
the second will be used. (Presumably your server will support at
least one of the two protocols. :)

The default value is C<'1,2'>, for compatibility with OpenSSH; this
means that the client will use SSH-1 if the server supports SSH-1.
Of course, you can always override this using a user/global
configuration file, or through using this constructor argument.

=item * cipher

Specifies the name of the encryption cipher that you wish to
use for this connection. This must be one of the supported
ciphers; specifying an unsupported cipher will give you an error
when you enter algorithm negotiation (in either SSH-1 or SSH-2).

In SSH-1, the supported cipher names are I<IDEA>, I<DES>, I<DES3>,
and I<Blowfish>; in SSH-2, the supported ciphers are I<aes256-ctr>,
I<aes192-ctr>, I<aes128-ctr>, I<chacha20-poly1305@openssh.com>.
I<arcfour>, I<blowfish-cbc>, and I<3des-cbc> are deprecated and
are not enabled by default.
I<aes256-cbc>, I<aes192-cbc>, and I<aes128-cbc> are also supported
but not enabled by default as CBC is no longer considered secure.

The default SSH-1 cipher is I<IDEA>; the default SSH-2 ciphers are
I<aes256-ctr>, I<aes192-ctr>, I<aes128-ctr>, I<chacha20-poly1305@openssh.com>.

=item * ciphers

Like I<cipher>, this is a method of setting the cipher you wish to
use for a particular SSH connection; but this corresponds to the
I<Ciphers> configuration option, where I<cipher> corresponds to
I<Cipher>. This also applies only in SSH-2.

This should be a comma-separated list of SSH-2 cipher names; the list
of cipher names is listed above in I<cipher>.

This defaults to:
I<chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr>.

=item * port

The port of the I<sshd> daemon to which you wish to connect;
if not specified, this is assumed to be the default I<ssh>
port.

=item * debug

Set to a true value if you want debugging messages printed
out while the connection is being opened. These can be helpful
in trying to determine connection problems, etc. The messages
are similar (and in some cases exact) to those written out by
the I<ssh> client when you use the I<-v> option.

Defaults to false.

=item * interactive

Set to a true value if you're using I<Net::SSH::Perl> interactively.
This is used in determining whether or not to display password
prompts, for example. It's basically the inverse of the
I<BatchMode> parameter in ssh configuration.

Defaults to false.

=item * privileged

Set to a true value if you want to bind to a privileged port
locally. You'll need this if you plan to use Rhosts or
Rhosts-RSA authentication, because the remote server
requires the client to connect on a privileged port. Of course,
to bind to a privileged port you'll need to be root.

If you don't provide this parameter, and I<Net::SSH::Perl>
detects that you're running as root, this will automatically
be set to true. Otherwise it defaults to false.

=item * identity_files

A list of identity files to be used in pubkey authentication.
The value of this argument should be a reference to an array of
strings, each string identifying the location of an identity
file. Each identity file will be tested against the server until
the client finds one that authenticates successfully.

If you don't provide this, SSH1 authentication defaults to using
F<$ENV{HOME}/.ssh/identity>, and SSH2 authentication defaults to
the three files F<$ENV{HOME}/.ssh/id_ed25519>, F<$ENV{HOME}/.ssh/id_ecdsa>,
and F<$ENV{HOME}/.ssh/id_rsa>.

=item * strict_host_key_checking

This corresponds to the I<StrictHostKeyChecking> ssh configuration
option. Allowed values are I<no>, I<yes>, or I<ask>. I<no> disables
host key checking, e.g., if you connect to a virtual host that answers
to multiple IP addresses. I<yes> or I<ask> enable it, and when it
fails in I<interactive> mode, you are asked whether to continue. The
host is then added to the list of known hosts.

=item * compression

If set to a true value, compression is turned on for the session
(assuming that the server supports it).

Compression is off by default.

Note that compression requires that you have the I<Compress::Zlib>
module installed on your system. If the module can't be loaded
successfully, compression is disabled; you'll receive a warning
stating as much if you having debugging on (I<debug> set to 1),
and you try to turn on compression.

=item * compression_level

Specifies the compression level to use if compression is enabled
(note that you must provide both the I<compression> and
I<compression_level> arguments to set the level; providing only
this argument will not turn on encryption).

This setting is only applicable to SSH-1; the compression level for
SSH-2 Zlib compression is always set to 6.

The default value is 6.

=item * use_pty

Set this to 1 if you want to request a pseudo tty on the remote
machine. This is really only useful if you're setting up a shell
connection (see the I<shell> method, below); and in that case,
unless you've explicitly declined a pty (by setting I<use_pty>
to 0), this will be set automatically to 1. In other words,
you probably won't need to use this, often.

The default is 1 if you're starting up a shell, and 0 otherwise.

=item * terminal_mode_string

Specify the POSIX terminal mode string to send when use_pty is
set. By default the only mode set is the VEOF character to 0x04
(opcode 5, value 0x00000004). See RFC 4254 section 8 for complete
details on this value.

=item * no_append_veof

(SSH-2 only) Set this to 1 if you specified use_pty and do not want
Ctrl-D (0x04) appended twice to the end of your input string. On most
systems, these bytes cause the terminal driver to return "EOF" when
standard input is read. Without them, many programs that read from
standard input will hang after consuming all the data on STDIN.

No other modifications are made to input data. If your data contains
0x04 bytes, you may need to escape them.

Set this to 0 if you have raw terminal data to specify on standard
input, and you have terminated it correctly.

=item * options

Used to specify additional options to the configuration settings;
useful for specifying options for which there is no separate
constructor argument. This is analogous to the B<-o> command line
flag to the I<ssh> program.

If used, the value should be a reference to a list of option
directives in the format used in the config file. For example:

    my $ssh = Net::SSH::Perl->new("host", options => [
        "BatchMode yes", "RhostsAuthentication no" ]);

Available options are:

    BindAddress
    Host
    BatchMode
    ChallengeResponseAuthentication
    CheckHostIP
    Cipher
    Ciphers*
    Compression
    CompressionLevel
    DSAAuthentication
    FingerprintHash
    GlobalKnownHostsFile
    HashKnownHosts
    HostKeyAlgorithms*
    HostName
    IdentityFile
    KexAlgorithms*
    MACs*
    NumberOfPasswordPrompts
    PasswordAuthentication
    PasswordPromptHost
    PasswordPromptLogin
    Port
    Protocol
    RhostsAuthentication
    RhostsRSAAuthentication
    RSAAuthentication
    StrictHostKeyChecking
    UpdateHostKeys
    UsePrivilegedPort
    User
    UserKnownHostsFile

* Indicates the +/- wildcard notation may be used.

For example:

    MACs +hmac-sha1

will add hmac-sha1 to the default MACs list.

Or:

    Ciphers +aes*-cbc

will add aes128-cbc, aes192-cbc, and aes256-cbc to the default Ciphers

While:

    KexAlgorithms -*-sha512

will remove all algorithms that end in -sha512 from the default list.

=back

=head2 $ssh->login([ $user [, $password [, $suppress_shell ] ] ])

Sets the username and password to be used when authenticating
with the I<sshd> daemon. The username I<$user> is required for
all authentication protocols (to identify yourself to the
remote server), but if you don't supply it the username of the
user executing the program is used.

The password I<$password> is needed only for password
authentication (it's not used for passphrases on encrypted
RSA/DSA identity files, though perhaps it should be). And if you're
running in an interactive session and you've not provided a
password, you'll be prompted for one.

By default, Net::SSH::Perl will open a channel with a shell
on it. This is usually what you want. If you are tunneling
another protocol over SSH, however, you may want to
prevent this behavior.  Passing a true value in I<$suppress_shell>
will prevent the shell channel from being opened (SSH2 only).

=head2 ($out, $err, $exit) = $ssh->cmd($cmd, [ $stdin ])

Runs the command I<$cmd> on the remote server and returns
the I<stdout>, I<stderr>, and exit status of that
command.

If I<$stdin> is provided, it's supplied to the remote command
I<$cmd> on standard input.

NOTE: the SSH-1 protocol does not support running multiple commands
per connection, unless those commands are chained together so that
the remote shell can evaluate them. Because of this, a new socket
connection is created each time you call I<cmd>, and disposed of
afterwards. In other words, this code:

    my $ssh = Net::SSH::Perl->new("host1");
    $ssh->login("user1", "pass1");

    $ssh->cmd("foo");
    $ssh->cmd("bar");

will actually connect to the I<sshd> on the first invocation of
I<cmd>, then disconnect; then connect again on the second
invocation of I<cmd>, then disconnect again.

Note that this does I<not> apply to the SSH-2 protocol. SSH-2 fully
supports running more than one command over the same connection.

=head2 $ssh->shell

Opens up an interactive shell on the remote machine and connects
it to your STDIN. This is most effective when used with a
pseudo tty; otherwise you won't get a command line prompt,
and it won't look much like a shell. For this reason--unless
you've specifically declined one--a pty will be requested
from the remote machine, even if you haven't set the I<use_pty>
argument to I<new> (described above).

This is really only useful in an interactive program.

In addition, you'll probably want to set your terminal to raw
input before calling this method. This lets I<Net::SSH::Perl>
process each character and send it off to the remote machine,
as you type it.

To do so, use I<Term::ReadKey> in your program:

    use Term::ReadKey;
    ReadMode('raw');
    $ssh->shell;
    ReadMode('restore');

In fact, you may want to place the C<restore> line in an I<END>
block, in case your program exits prior to reaching that line.

If you need an example, take a look at F<eg/pssh>, which
uses almost this exact code to implement an ssh shell.

=head2 $ssh->register_handler($packet_type, $subref [, @args ])

Registers an anonymous subroutine handler I<$subref> to handle
packets of type I<$packet_type> during the client loop. The
subroutine will be called when packets of type I<$packet_type>
are received, and in addition to the standard arguments (see
below), will receive any additional arguments in I<@args>, if
specified.

The client loop is entered after the client has sent a command
to the remote server, and after any STDIN data has been sent;
it consists of reading packets from the server (STDOUT
packets, STDERR packets, etc.) until the server sends the exit
status of the command executed remotely. At this point the client
exits the client loop and disconnects from the server.

When you call the I<cmd> method, the client loop by default
simply sticks STDOUT packets into a scalar variable and returns
that value to the caller. It does the same for STDERR packets,
and for the process exit status. (See the docs for I<cmd>).

You can, however, override that default behavior, and instead
process the data itself as it is sent to the client. You do this
by calling the I<register_handler> method and setting up handlers
to be called at specific times.

The behavior of the I<register_handler> method differs between
the I<Net::SSH::Perl> SSH-1 and SSH-2 implementations. This is so
because of the differences between the protocols (all
client-server communications in SSH-2 go through the channel
mechanism, which means that input packets are processed
differently).

=over 4

=item * SSH-1 Protocol

In the SSH-1 protocol, you should call I<register_handler> with two
arguments: a packet type I<$packet_type> and a subroutine reference
I<$subref>. Your subroutine will receive as arguments the
I<Net::SSH::Perl::SSH1> object (with an open connection to the
ssh3), and a I<Net::SSH::Perl::Packet> object, which represents the
packet read from the server. It will also receive any additional
arguments I<@args> that you pass to I<register_handler>; this can
be used to give your callback functions access to some of your
otherwise private variables, if desired. I<$packet_type> should be
an integer constant; you can import the list of constants into your
namespace by explicitly loading the I<Net::SSH::Perl::Constants>
module:

    use Net::SSH::Perl::Constants qw( :msg );

This will load all of the I<MSG> constants into your namespace
so that you can use them when registering the handler. To do
that, use this method. For example:

    $ssh->register_handler(SSH_SMSG_STDOUT_DATA, sub {
        my($ssh, $packet) = @_;
        print "I received this: ", $packet->get_str;
    });

To learn about the methods that you can call on the packet object,
take a look at the I<Net::SSH::Perl::Packet> docs, as well as the
I<Net::SSH::Perl::Buffer> docs (the I<get_*> and I<put_*> methods).

Obviously, writing these handlers requires some knowledge of the
contents of each packet. For that, read through the SSH RFC, which
explains each packet type in detail. There's a I<get_*> method for
each datatype that you may need to read from a packet.

Take a look at F<eg/remoteinteract.pl> for an example of interacting
with a remote command through the use of I<register_handler>.

=item * SSH-2 Protocol

In the SSH-2 protocol, you call I<register_handler> with two
arguments: a string identifying the type of handler you wish to
create, and a subroutine reference. The "string" should be, at
this point, either C<stdout> or C<stderr>; any other string will
be silently ignored. C<stdout> denotes that you wish to handle
STDOUT data sent from the server, and C<stderr> that you wish
to handle STDERR data.

Your subroutine reference will be passed two arguments:
a I<Net::SSH::Perl::Channel> object that represents the open
channel on which the data was sent, and a I<Net::SSH::Perl::Buffer>
object containing data read from the server. In addition to these
two arguments, the callback will be passed any additional
arguments I<@args> that you passed to I<register_handler>; this
can be used to give your callback functions to otherwise private
variables, if desired.

This illustrates the two main differences between the SSH-1 and
SSH-2 implementations. The first difference is that, as mentioned
above, all communication between server and client is done through
channels, which are built on top of the main connection between
client and server. Multiple channels are multiplexed over the
same connection. The second difference is that, in SSH-1, you are
processing the actual packets as they come in; in SSH-2, the packets
have already been processed somewhat, and their contents stored in
buffers--you are processing those buffers.

The above example (the I<I received this> example) of using
I<register_handler> in SSH-1 would look like this in SSH-2:

    $ssh->register_handler("stdout", sub {
        my($channel, $buffer) = @_;
        print "I received this: ", $buffer->bytes;
    });

As you can see, it's quite similar to the form used in SSH-1,
but with a few important differences, due to the differences
mentioned above between SSH-1 and SSH-2.

=back

=head1 ADVANCED METHODS

Your basic SSH needs will hopefully be met by the methods listed
above. If they're not, however, you may want to use some of the
additional methods listed here. Some of these are aimed at
end-users, while others are probably more useful for actually
writing an authentication module, or a cipher, etc.

=head2 $ssh->config

Returns the I<Net::SSH::Perl::Config> object managing the
configuration data for this SSH object. This is constructed
from data passed in to the constructor I<new> (see above),
merged with data read from the user and system configuration
files. See the I<Net::SSH::Perl::Config> docs for details
on methods you can call on this object (you'll probably
be more interested in the I<get> and I<set> methods).

=head2 $ssh->sock

Returns the socket connection to sshd. If your client is not
connected, dies.

=head2 $ssh->debug($msg)

If debugging is turned on for this session (see the I<debug>
parameter to the I<new> method, above), writes I<$msg> to
C<STDERR>. Otherwise nothing is done.

=head2 $ssh->incoming_data

Incoming data buffer, an object of type I<Net::SSH::Perl::Buffer>.
Returns the buffer object.

The idea behind this is that we our socket is non-blocking, so we
buffer input and periodically check back to see if we've read a
full packet. If we have a full packet, we rip it out of the incoming
data buffer and process it, returning it to the caller who
presumably asked for it.

This data "belongs" to the underlying packet layer in
I<Net::SSH::Perl::Packet>. Unless you really know what you're
doing you probably don't want to disturb that data.

=head2 $ssh->session_id

Returns the session ID, which is generated from the server's
host and server keys, and from the check bytes that it sends
along with the keys. The server may require the session ID to
be passed along in other packets, as well (for example, when
responding to RSA challenges).

=head2 $packet = $ssh->packet_start($packet_type)

Starts building a new packet of type I<$packet_type>. This is
just a handy method for lazy people. Internally it calls
I<Net::SSH::Perl::Packet::new>, so take a look at those docs
for more details.

=head1 SUPPORT

For samples/tutorials, take a look at the scripts in F<eg/> in
the distribution directory.

Please report bugs at:
https://github.com/lkinley/Net-SSH-Perl/issues

=head1 AUTHOR

Development on V2 by Lance Kinley
lkinley@rythmos.com

Previous maintainers were:
David Robins, dbrobins@cpan.org
Dave Rolsky, autarch@urth.org.

Originally written by Benjamin Trott.

=head1 COPYRIGHT

Copyright (c) 2015-2017 Rythmos, Inc.
Copyright (c) 2001-2003 Benjamin Trott, Copyright (c) 2003-2008 David
Rolsky.  Copyright (c) David Robins.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
