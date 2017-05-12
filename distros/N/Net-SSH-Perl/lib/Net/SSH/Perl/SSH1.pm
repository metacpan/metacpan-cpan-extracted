# $Id: SSH1.pm,v 1.24 2009/01/26 01:05:00 turnstep Exp $

package Net::SSH::Perl::SSH1;
use strict;
use warnings;

use Net::SSH::Perl::Packet;
use Net::SSH::Perl::Buffer;
use Net::SSH::Perl::Config;
use Net::SSH::Perl::Constants qw( :protocol :msg :hosts );
use Net::SSH::Perl::Cipher;
use Net::SSH::Perl::Auth;
use Net::SSH::Perl::Comp;
use Net::SSH::Perl::Key::RSA1;
use Net::SSH::Perl::Util qw( :hosts _compute_session_id _rsa_public_encrypt );

use Net::SSH::Perl;
use base qw( Net::SSH::Perl );

use Math::GMP;
use Carp qw( croak );
use File::Spec::Functions qw( catfile );
use File::HomeDir ();

use vars qw( $VERSION $CONFIG $HOSTNAME );
$VERSION = $Net::SSH::Perl::VERSION;

sub version_string {
    my $class = shift;
    sprintf "Net::SSH::Perl Version %s, protocol version %s.%s.",
        $class->VERSION, PROTOCOL_MAJOR_1, PROTOCOL_MINOR_1;
}

sub _proto_init {
    my $ssh = shift;
    my $home = File::HomeDir->my_home;
    my $config = $ssh->{config};

    unless ($config->get('user_known_hosts')) {
        defined $home or croak "Cannot determine home directory, please set the environment variable HOME";
        $config->set('user_known_hosts', catfile($home, '.ssh', 'known_hosts'));
    }
    unless ($config->get('global_known_hosts')) {
        my $glob_known_hosts = $^O eq 'MSWin32'
          ? catfile( $ENV{WINDIR}, 'ssh_known_hosts' )
          : '/etc/ssh_known_hosts';
        $config->set('global_known_hosts', $glob_known_hosts );
    }
    unless (my $if = $config->get('identity_files')) {
        defined $home or croak "Cannot determine home directory, please set the environment variable HOME";
        $config->set('identity_files', [ catfile($home, '.ssh', 'identity') ]);
    }

    for my $a (qw( password rhosts rhosts_rsa rsa ch_res )) {
        $config->set("auth_$a", 1)
            unless defined $config->get("auth_$a");
    }
}

sub _disconnect {
    my $ssh = shift;
    my $packet = $ssh->packet_start(SSH_MSG_DISCONNECT);
    $packet->put_str("@_") if @_;
    $packet->send;
    $ssh->{session} = {};
    for my $key (qw( _cmd_stdout _cmd_stderr _cmd_exit )) {
        $ssh->{$key} = "";
    }
}

sub register_handler {
    my($ssh, $type, $sub, @extra) = @_;
    ## XXX hack
    if ($type eq 'stdout') {
        $type = SSH_SMSG_STDOUT_DATA;
    } elsif ($type eq 'stderr') {
        $type = SSH_SMSG_STDERR_DATA;
    }
    $ssh->{client_handlers}{$type} = { code => $sub, extra => \@extra };
}
sub handler_for { $_[0]->{client_handlers}{$_[1]} }

sub _login {
    my $ssh = shift;
    my $user = $ssh->{config}->get('user');
    croak "No user defined" unless $user;

    $ssh->debug("Waiting for server public key.");
    my $packet = Net::SSH::Perl::Packet->read_expect($ssh, SSH_SMSG_PUBLIC_KEY);

    my $check_bytes = $packet->bytes(0, 8, "");

    my %keys;
    for my $which (qw( public host )) {
        $keys{$which} = Net::SSH::Perl::Key::RSA1->new;
        $keys{$which}{rsa}{bits} = $packet->get_int32;
        $keys{$which}{rsa}{e}    = $packet->get_mp_int;
        $keys{$which}{rsa}{n}    = $packet->get_mp_int;
    }

    my $protocol_flags = $packet->get_int32;
    my $supported_ciphers = $packet->get_int32;
    my $supported_auth = $packet->get_int32;

    $ssh->debug("Received server public key ($keys{public}{rsa}{bits} " .
        "bits) and host key ($keys{host}{rsa}{bits} bits).");

    my $session_id =
      _compute_session_id($check_bytes, $keys{host}, $keys{public});
    $ssh->{session}{id} = $session_id;

    $ssh->check_host_key($keys{host});

    my $session_key = join '', map chr rand(255), 1..32;
    my $skey = Math::GMP->new(0);
    for my $i (0..31) {
        $skey *= 2**8;
        $skey += $i < 16 ?
            vec($session_key, $i, 8) ^ vec($session_id, $i, 8) :
            vec($session_key, $i, 8);
    }

    if ($keys{public}{rsa}{n} < $keys{host}{rsa}{n}) {
        $skey = _rsa_public_encrypt($skey, $keys{public});
        $skey = _rsa_public_encrypt($skey, $keys{host});
    }
    else {
        $skey = _rsa_public_encrypt($skey, $keys{host});
        $skey = _rsa_public_encrypt($skey, $keys{public});
    }

    my($cipher, $cipher_name);
    if ($cipher_name = $ssh->{config}->get('cipher')) {
        $cipher = Net::SSH::Perl::Cipher::id($cipher_name);
    }
    else {
        my $cid;
        if (($cid = Net::SSH::Perl::Cipher::id('IDEA')) &&
            Net::SSH::Perl::Cipher::supported($cid, $supported_ciphers)) {
            $cipher_name = 'IDEA';
            $cipher = $cid;
        }
        elsif (($cid = Net::SSH::Perl::Cipher::id('DES3')) &&
            Net::SSH::Perl::Cipher::supported($cid, $supported_ciphers)) {
            $cipher_name = 'DES3';
            $cipher = $cid;
        }
    }

    unless (Net::SSH::Perl::Cipher::supported($cipher, $supported_ciphers)) {
        croak "Selected cipher type $cipher_name not supported by server.";
    }
    $ssh->debug(sprintf "Encryption type: %s", $cipher_name);

    $packet = $ssh->packet_start(SSH_CMSG_SESSION_KEY);
    $packet->put_int8($cipher);
    $packet->put_chars($check_bytes);
    $packet->put_mp_int($skey);
    $packet->put_int32(0);    ## No protocol flags.
    $packet->send;
    $ssh->debug("Sent encrypted session key.");

    $ssh->set_cipher($cipher_name, $session_key);
    $ssh->{session}{key} = $session_key;

    Net::SSH::Perl::Packet->read_expect($ssh, SSH_SMSG_SUCCESS);
    $ssh->debug("Received encryption confirmation.");

    $packet = $ssh->packet_start(SSH_CMSG_USER);
    $packet->put_str($user);
    $packet->send;

    $packet = Net::SSH::Perl::Packet->read($ssh);
    return 1 if $packet->type == SSH_SMSG_SUCCESS;

    if ($packet->type != SSH_SMSG_FAILURE) {
        $ssh->fatal_disconnect(sprintf
          "Protocol error: got %d in response to SSH_CMSG_USER", $packet->type);
    }

    my $auth_order = Net::SSH::Perl::Auth::auth_order();
    for my $auth_id (@$auth_order) {
        next unless Net::SSH::Perl::Auth::supported($auth_id, $supported_auth);
        my $auth = Net::SSH::Perl::Auth->new(Net::SSH::Perl::Auth::name($auth_id), $ssh);
        my $valid = $auth->authenticate;
        return 1 if $valid;
    }
}

sub compression {
    my $ssh = shift;
    if (@_) {
        my $level = shift;
        $ssh->debug("Enabling compression at level $level.");
        $ssh->{session}{compression} = Net::SSH::Perl::Comp->new('Zlib', $level);
    }
    $ssh->{session}{compression};
}

sub _setup_connection {
    my $ssh = shift;

    $ssh->_connect unless $ssh->sock;
    $ssh->_login or
        $ssh->fatal_disconnect("Permission denied");

    if ($ssh->{config}->get('compression')) {
        eval { require Compress::Zlib; };
        if ($@) {
            $ssh->debug("Compression is disabled because Compress::Zlib can't be loaded.");
        }
        else {
            my $level = $ssh->{config}->get('compression_level') || 6;
            $ssh->debug("Requesting compression at level $level.");
            my $packet = $ssh->packet_start(SSH_CMSG_REQUEST_COMPRESSION);
            $packet->put_int32($level);
            $packet->send;

            $packet = Net::SSH::Perl::Packet->read($ssh);
            if ($packet->type == SSH_SMSG_SUCCESS) {
                $ssh->compression($level);
            }
            else {
                $ssh->debug("Warning: Remote host refused compression.");
            }
        }
    }

    if ($ssh->{config}->get('use_pty')) {
        $ssh->debug("Requesting pty.");
        my($packet);
        $packet = $ssh->packet_start(SSH_CMSG_REQUEST_PTY);
        my($term) = $ENV{TERM} =~ /(\S+)/;
        $packet->put_str($term);
        my $foundsize = 0;
        if (eval "require Term::ReadKey") {
            my @sz = Term::ReadKey::GetTerminalSize($ssh->sock);
            if (defined $sz[0]) {
                $foundsize = 1;
                $packet->put_int32($sz[0]); # width
                $packet->put_int32($sz[1]); # height
                $packet->put_int32($sz[2]); # xpix
                $packet->put_int32($sz[3]); # ypix
            }
        }
        if (!$foundsize) {
            $packet->put_int32(0) for 1..4;
        }
        $packet->put_int8(0);
        $packet->send;

        $packet = Net::SSH::Perl::Packet->read($ssh);
        unless ($packet->type == SSH_SMSG_SUCCESS) {
            $ssh->debug("Warning: couldn't allocate a pseudo tty.");
        }
    }
}

sub cmd {
    my $ssh = shift;
    my $cmd = shift;
    my $stdin = shift;

    $ssh->_setup_connection;

    my($packet);

    $ssh->debug("Sending command: $cmd");
    $packet = $ssh->packet_start(SSH_CMSG_EXEC_CMD);
    $packet->put_str($cmd);
    $packet->send;

    if (defined $stdin) {
        my $chunk_size = 32000;
        while ($stdin) {
            my $chunk = substr($stdin, 0, $chunk_size, '');
            $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
            $packet->put_str($chunk);
            $packet->send;
        }

        $packet = $ssh->packet_start(SSH_CMSG_EOF);
        $packet->send;
    }

    unless ($ssh->handler_for(SSH_SMSG_STDOUT_DATA)) {
        $ssh->register_handler(SSH_SMSG_STDOUT_DATA,
            sub { $ssh->{_cmd_stdout} .= $_[1]->get_str });
    }
    unless ($ssh->handler_for(SSH_SMSG_STDERR_DATA)) {
        $ssh->register_handler(SSH_SMSG_STDERR_DATA,
            sub { $ssh->{_cmd_stderr} .= $_[1]->get_str });
    }
    unless ($ssh->handler_for(SSH_SMSG_EXITSTATUS)) {
        $ssh->register_handler(SSH_SMSG_EXITSTATUS,
            sub { $ssh->{_cmd_exit} = $_[1]->get_int32 });
    }

    $ssh->debug("Entering interactive session.");
    $ssh->_start_interactive(defined $stdin ? 1 : 0);
    my($stdout, $stderr, $exit) =
        map $ssh->{"_cmd_$_"}, qw( stdout stderr exit );

    $ssh->_disconnect;
    ($stdout, $stderr, $exit);
}

sub shell {
    my $ssh = shift;

    $ssh->{config}->set('use_pty', 1)
        unless defined $ssh->{config}->get('use_pty');
    $ssh->_setup_connection;

    $ssh->debug("Requesting shell.");
    my $packet = $ssh->packet_start(SSH_CMSG_EXEC_SHELL);
    $packet->send;

    $ssh->register_handler(SSH_SMSG_STDOUT_DATA,
        sub { syswrite STDOUT, $_[1]->get_str });
    $ssh->register_handler(SSH_SMSG_STDERR_DATA,
        sub { syswrite STDERR, $_[1]->get_str });
    $ssh->register_handler(SSH_SMSG_EXITSTATUS, sub {});

    $ssh->debug("Entering interactive session.");
    $ssh->_start_interactive(0);

    $ssh->_disconnect;
}

sub open2 {
    my $ssh = shift;
    my($cmd) = @_;

    require Net::SSH::Perl::Handle::SSH1;

    unless ($cmd) {
        $ssh->{config}->set('use_pty', 1)
            unless defined $ssh->{config}->get('use_pty');
    }
    $ssh->_setup_connection;

    if ($cmd) {
        $ssh->debug("Sending command: $cmd");
        my $packet = $ssh->packet_start(SSH_CMSG_EXEC_CMD);
        $packet->put_str($cmd);
        $packet->send;
    }
    else {
        $ssh->debug("Requesting shell.");
        my $packet = $ssh->packet_start(SSH_CMSG_EXEC_SHELL);
        $packet->send;
    }

    my $read = Symbol::gensym;
    my $write = Symbol::gensym;
    tie *$read, 'Net::SSH::Perl::Handle::SSH1', 'r', $ssh;
    tie *$write, 'Net::SSH::Perl::Handle::SSH1', 'w', $ssh;

    $ssh->debug("Entering interactive session.");
    return ($read, $write);
}

sub break_client_loop { $_[0]->{_cl_quit_pending} = 1 }
sub _quit_pending { $_[0]->{_cl_quit_pending} }

sub _start_interactive {
    my $ssh = shift;
    my($sent_stdin) = @_;

    my $s = IO::Select->new;
    $s->add($ssh->{session}{sock});
    $s->add(\*STDIN) unless $sent_stdin;

    CLOOP:
    $ssh->{_cl_quit_pending} = 0;
    while (!$ssh->_quit_pending) {
        my @ready = $s->can_read;
        for my $a (@ready) {
            if ($a == $ssh->{session}{sock}) {
                my $buf;
                my $len = sysread $a, $buf, 8192;
                $ssh->break_client_loop unless $len;
                ($buf) = $buf =~ /(.*)/s;  ## Untaint data. Anything allowed.
                $ssh->incoming_data->append($buf);
            }
            elsif ($a == \*STDIN) {
                my $buf;
                sysread STDIN, $buf, 8192;
                ($buf) = $buf =~ /(.*)/s;  ## Untaint data. Anything allowed.
                my $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
                $packet->put_str($buf);
                $packet->send;
            }
        }

        while (my $packet = Net::SSH::Perl::Packet->read_poll($ssh)) {
            if (my $r = $ssh->handler_for($packet->type)) {
                $r->{code}->($ssh, $packet, @{ $r->{extra} });
            }
            else {
                $ssh->debug(sprintf
                    "Warning: ignoring packet of type %d", $packet->type);
            }

            if ($packet->type == SSH_SMSG_EXITSTATUS) {
                my $packet = $ssh->packet_start(SSH_CMSG_EXIT_CONFIRMATION);
                $packet->send;
                $ssh->break_client_loop;
            }
        }

        last if $ssh->_quit_pending;
    }
}

sub send_data {
    my $ssh = shift;
    my($data) = @_;
    my $packet = $ssh->packet_start(SSH_CMSG_STDIN_DATA);
    $packet->put_str($data);
    $packet->send;
}

sub set_cipher {
    my $ssh = shift;
    my $ciph = shift;
    $ssh->{session}{receive} = Net::SSH::Perl::Cipher->new($ciph, @_);
    $ssh->{session}{send} = Net::SSH::Perl::Cipher->new($ciph, @_);
}

sub send_cipher { $_[0]->{session}{send} }
sub receive_cipher { $_[0]->{session}{receive} }
sub session_key { $_[0]->{session}{key} }

1;
__END__

=head1 NAME

Net::SSH::Perl::SSH1 - SSH1 implementation

=head1 SYNOPSIS

    use Net::SSH::Perl;
    my $ssh = Net::SSH::Perl->new($host, protocol => 1);

=head1 DESCRIPTION

I<Net::SSH::Perl::SSH1> implements the SSH1 protocol. It is a
subclass of I<Net::SSH::Perl>, and implements the interface
described in the documentation for that module. In fact, your
usage of this module should be completely transparent; simply
specify the proper I<protocol> value (C<1>) when creating your
I<Net::SSH::Perl> object, and the SSH1 implementation will be
loaded automatically.

NOTE: Of course, this is still subject to protocol negotiation
with the server; if the server doesn't support SSH1, there's
not much the client can do, and you'll get a fatal error if
you use the above I<protocol> specification (C<1>).

=head1 USAGE

I<Net::SSH::Perl::SSH1> shares the interface described by
I<Net::SSH::Perl>. In addition, you can call the following
"advanced" methods on a I<Net::SSH::Perl::SSH1> object, that
I<do not> apply to a regular I<Net::SSH::Perl> object.

=head2 $ssh->set_cipher($cipher_name)

Sets the cipher for the SSH session I<$ssh> to I<$cipher_name>
(which must be a valid cipher name), and turns on encryption
for that session.

=head2 $ssh->send_cipher

Returns the "send" cipher object. This is the object that encrypts
outgoing data.

If it's not defined, encryption is not turned on for the session.

=head2 $ssh->receive_cipher

Returns the "receive" cipher object. This is the object that
decrypts incoming data.

If it's not defined, encryption is not turned on for the session.

NOTE: the send and receive ciphers and two I<different> objects,
each with its own internal state (initialization vector, in
particular). Thus they cannot be interchanged.

=head2 $ssh->compression([ $level ])

Without arguments, returns the current compression level for the
session. If given an argument I<$level>, sets the compression level
and turns on compression for the session.

Note that this should I<not> be used to turn compression off. In fact,
I don't think there's a way to turn compression off. But in other
words, don't try giving this method a value of 0 and expect that to
turn off compression. It won't.

If the return value of this method is undefined or 0, compression
is turned off.

=head2 $ssh->session_key

Returns the session key, which is simply 32 bytes of random
data and is used as the encryption/decryption key.

=head2 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
