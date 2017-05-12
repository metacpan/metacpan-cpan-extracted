# -*- perl -*-
#
#  Net::Server::Proto::SSLEAY - Net::Server Protocol module
#
#  $Id$
#
#  Copyright (C) 2010-2012
#
#    Paul Seamons
#    paul@seamons.com
#    http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
################################################################

package Net::Server::Proto::SSLEAY;

use strict;
use warnings;
use IO::Socket::INET;
use Fcntl ();
use Errno ();
use Socket ();

BEGIN {
    eval { require Net::SSLeay; 1 }
        or warn "Module Net::SSLeay is required for SSLeay.";
    for my $sub (qw(load_error_strings SSLeay_add_ssl_algorithms ENGINE_load_builtin_engines ENGINE_register_all_complete randomize)) {
        Net::SSLeay->can($sub)->();
    }
    eval { [Fcntl::F_GETFL(), Fcntl::F_SETFL(), Fcntl::O_NONBLOCK()] } || die "Could not access Fcntl constant while loading ".__PACKAGE__.": $@";
}

our @ISA = qw(IO::Socket::INET);
our $AUTOLOAD;

my @ssl_args = qw(
    SSL_use_cert
    SSL_verify_mode
    SSL_key_file
    SSL_cert_file
    SSL_ca_path
    SSL_ca_file
    SSL_cipher_list
    SSL_passwd_cb
    SSL_max_getline_length
    SSL_error_callback
);

sub NS_proto { 'SSLEAY' }
sub NS_port   { my $sock = shift; ${*$sock}{'NS_port'}   = shift if @_; return ${*$sock}{'NS_port'}   }
sub NS_host   { my $sock = shift; ${*$sock}{'NS_host'}   = shift if @_; return ${*$sock}{'NS_host'}   }
sub NS_ipv    { my $sock = shift; ${*$sock}{'NS_ipv'}    = shift if @_; return ${*$sock}{'NS_ipv'}    }
sub NS_listen { my $sock = shift; ${*$sock}{'NS_listen'} = shift if @_; return ${*$sock}{'NS_listen'} }

sub object {
    my ($class, $info, $server) = @_;

    my $ssl = $server->{'server'}->{'ssl_args'} ||= do {
        my %temp = map {$_ => undef} @ssl_args;
        $server->configure({map {$_ => \$temp{$_}} @ssl_args});
        \%temp;
    };

    # we cannot do this at compile time because we have not yet read the configuration then
    @ISA = qw(IO::Socket::INET6) if $ISA[0] eq 'IO::Socket::INET' && Net::Server::Proto->requires_ipv6($server);

    my @sock = $class->SUPER::new();
    foreach my $sock (@sock) {
        $sock->NS_host($info->{'host'});
        $sock->NS_port($info->{'port'});
        $sock->NS_ipv( $info->{'ipv'} );
        $sock->NS_listen(defined($info->{'listen'}) ? $info->{'listen'}
                        : defined($server->{'server'}->{'listen'}) ? $server->{'server'}->{'listen'}
                        : Socket::SOMAXCONN());
        ${*$sock}{'NS_orig_port'} = $info->{'orig_port'} if defined $info->{'orig_port'};

        for my $key (@ssl_args) {
            my $val = defined($info->{$key}) ? $info->{$key}
                    : defined($ssl->{$key})  ? $ssl->{$key}
                    : $server->can($key) ? $server->$key($info->{'host'}, $info->{'port'}, 'SSLEAY')
                    : undef;
            next if ! defined $val;
            $sock->$key($val) if defined $val;
        }
    }
    return wantarray ? @sock : $sock[0];
}

sub log_connect {
    my ($sock, $server) = @_;
    $server->log(2, "Binding to ".$sock->NS_proto." port ".$sock->NS_port." on host ".$sock->NS_host." with IPv".$sock->NS_ipv);
}

sub connect { # connect the first time
    my ($sock, $server) = @_;
    my $host = $sock->NS_host;
    my $port = $sock->NS_port;
    my $ipv  = $sock->NS_ipv;
    my $lstn = $sock->NS_listen;

    $sock->SUPER::configure({
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => $lstn,
        ReuseAddr => 1,
        Reuse     => 1,
        (($host ne '*') ? (LocalAddr => $host) : ()), # * is all
        ($sock->isa("IO::Socket::INET6") ? (Domain => ($ipv eq '6') ? Socket6::AF_INET6() : ($ipv eq '4') ? Socket::AF_INET() : Socket::AF_UNSPEC()) : ()),
    }) || $server->fatal("Can't connect to SSLEAY port $port on $host [$!]");

    if ($port eq '0' and $port = $sock->sockport) {
        $server->log(2, "  Bound to auto-assigned port $port");
        ${*$sock}{'NS_orig_port'} = $sock->NS_port;
        $sock->NS_port($port);
    } elsif ($port =~ /\D/ and $port = $sock->sockport) {
        $server->log(2, "  Bound to service port ".$sock->NS_port()."($port)");
        ${*$sock}{'NS_orig_port'} = $sock->NS_port;
        $sock->NS_port($port);
    }

    $sock->bind_SSL($server);
}

sub reconnect { # connect on a sig -HUP
    my ($sock, $fd, $server, $port) = @_;
    $server->log(3,"Reassociating file descriptor $fd with ".$sock->NS_proto." on [".$sock->NS_host."]:".$sock->NS_port.", using IPv".$sock->NS_ipv);
    my $resp = $sock->fdopen( $fd, 'w' ) or $server->fatal("Error opening to file descriptor ($fd) [$!]");

    if ($sock->isa("IO::Socket::INET6")) {
        my $ipv = $sock->NS_ipv;
        ${*$sock}{'io_socket_domain'} = ($ipv eq '6') ? Socket6::AF_INET6() : ($ipv eq '4') ? Socket::AF_INET() : Socket::AF_UNSPEC();
    }

    $sock->bind_SSL($server);

    if ($port ne $sock->NS_port) {
        $server->log(2, "  Re-bound to previously assigned port $port");
        ${*$sock}{'NS_orig_port'} = $sock->NS_port;
        $sock->NS_port($port);
    }

    return $resp;
}

sub bind_SSL {
    my ($sock, $server) = @_;
    my $ctx = Net::SSLeay::CTX_new();  $sock->SSLeay_check_fatal("SSLeay bind_SSL CTX_new");

    Net::SSLeay::CTX_set_options($ctx, Net::SSLeay::OP_ALL());  $sock->SSLeay_check_fatal("SSLeay bind_SSL CTX_set_options");

    # 0x1:  SSL_MODE_ENABLE_PARTIAL_WRITE
    # 0x10: SSL_MODE_RELEASE_BUFFERS (ignored before OpenSSL v1.0.0)
    Net::SSLeay::CTX_set_mode($ctx, 0x11);  $sock->SSLeay_check_fatal("SSLeay bind_SSL CTX_set_mode");

    # Load certificate. This will prompt for a password if necessary.
    my $file_key  = $sock->SSL_key_file  || die "SSLeay missing SSL_key_file on ".$sock->hup_string.".\n";
    my $file_cert = $sock->SSL_cert_file || die "SSLeay missing SSL_cert_file on ".$sock->hup_string>".\n";
    Net::SSLeay::CTX_use_RSAPrivateKey_file($ctx, $file_key,  Net::SSLeay::FILETYPE_PEM());  $sock->SSLeay_check_fatal("SSLeay bind_SSL CTX_use_RSAPrivateKey_file");
    Net::SSLeay::CTX_use_certificate_file(  $ctx, $file_cert, Net::SSLeay::FILETYPE_PEM());  $sock->SSLeay_check_fatal("SSLeay bind_SSL CTX_use_certificate_file");
    $sock->SSLeay_context($ctx);
}

sub close {
    my $sock = shift;
    if ($sock->SSLeay_is_client) {
        Net::SSLeay::free($sock->SSLeay);
    } else {
        Net::SSLeay::CTX_free($sock->SSLeay_context);
    }
    $sock->SSLeay_check_fatal("SSLeay close free");
    return $sock->SUPER::close(@_);
}

sub accept {
    my ($sock, $class) = (@_);
    my ($client, $peername);
    if (wantarray) {
        ($client, $peername) = $sock->SUPER::accept($class);
    } else {
        $client = $sock->SUPER::accept($class);
    }
    if (defined $client) {
        $client->NS_proto($sock->NS_proto);
        $client->NS_ipv(  $sock->NS_ipv);
        $client->NS_host( $sock->NS_host);
        $client->NS_port( $sock->NS_port);
        $client->SSLeay_context($sock->SSLeay_context);
        $client->SSLeay_is_client(1);
    }

    return wantarray ? ($client, $peername) : $client;
}

sub post_accept {
    my $client = shift;
    $client->SSLeay;
}

sub SSLeay {
    my $client = shift;

    if (! exists ${*$client}{'SSLeay'}) {
        die "SSLeay refusing to accept on non-client socket" if !$client->SSLeay_is_client;

        $client->autoflush(1);

        my $f = fcntl($client, Fcntl::F_GETFL(), 0)                || die "SSLeay - fcntl get: $!\n";
        fcntl($client, Fcntl::F_SETFL(), $f | Fcntl::O_NONBLOCK()) || die "SSLeay - fcntl set: $!\n";

        my $ssl = Net::SSLeay::new($client->SSLeay_context);  $client->SSLeay_check_fatal("SSLeay new");
        Net::SSLeay::set_fd($ssl, $client->fileno);           $client->SSLeay_check_fatal("SSLeay set_fd");
        Net::SSLeay::accept($ssl);                            $client->SSLeay_check_fatal("SSLeay accept");
        ${*$client}{'SSLeay'} = $ssl;
    }

    return if ! defined wantarray;
    return ${*$client}{'SSLeay'};
}

sub SSLeay_check_fatal {
    my ($client, $msg) = @_;
    if (my $err = $client->SSLeay_check_error($msg, 1)) {
        my ($file, $pkg, $line) = caller;
        die "$msg at $file line $line\n  ".join('  ', @$err);
    }
}

sub SSLeay_check_error {
    my ($client, $msg, $fatal) = @_;
    my @err;
    while (my $n = Net::SSLeay::ERR_get_error()) {
        push @err, "$n. ". Net::SSLeay::ERR_error_string($n) ."\n";
    }
    if (@err) {
        my $cb = $client->SSL_error_callback;
        $cb->($client, $msg, \@err, ($fatal ? 'is_fatal' : ())) if $cb;
        return \@err;
    }
    return;
}


###----------------------------------------------------------------###

sub read_until {
    my ($client, $bytes, $end_qr, $non_greedy) = @_;

    my $ssl = $client->SSLeay;
    my $content = ${*$client}{'SSLeay_buffer'};
    $content = '' if ! defined $content;
    my $ok = 0;

    # the rough outline for this loop came from http://devpit.org/wiki/OpenSSL_with_nonblocking_sockets_%28in_Perl%29
    OUTER: while (1) {
        if (!length($content)) {
        }
        elsif (defined($bytes) && length($content) >= $bytes) {
            ${*$client}{'SSLeay_buffer'} = substr($content, $bytes, length($content), '');
            $ok = 2;
            last;
        }
        elsif (defined($end_qr) && $content =~ m/$end_qr/g) {
            my $n = pos($content);
            ${*$client}{'SSLeay_buffer'} = substr($content, $n, length($content), '');
            $ok = 1;
            last;
        }

        # this select appears to only cause read issues - in some cases the underlying select of Net::SSLeay enters into a spinloop
        #vec(my $vec = '', $client->fileno, 1) = 1;
        #select($vec, undef, undef, undef);

        my $n_empty = 0;
        while (1) {
            # 16384 is the maximum amount read() can return
            my $n = 16384;
            $n -= ($bytes - length($content)) if $non_greedy && ($bytes - length($content)) < $n;
            my $buf = Net::SSLeay::read($ssl, 16384); # read the most we can - continue reading until the buffer won't read any more
            if ($client->SSLeay_check_error('SSLeay read_until read')) {
                last OUTER;
            }
            die "SSLeay read_until: $!\n" if ! defined($buf) && !$!{EAGAIN} && !$!{EINTR} && !$!{ENOBUFS};
            last if ! defined($buf);
            if (!length($buf)) {
                last OUTER if !length($buf) && $n_empty++;
            }
            else {
                $content .= $buf;
                if ($non_greedy && length($content) == $bytes) {
                    $ok = 3;
                    last;
                }
            }
        }
    }
    return wantarray ? ($ok, $content) : $content;
}

sub read {
    my ($client, $buf, $size, $offset) = @_;
    my ($ok, $read) = $client->read_until($size, undef, 1);
    substr($_[1], $offset || 0, defined($buf) ? length($buf) : 0, $read);
    return length $read;
}

sub sysread  {
    my ($client, $buf, $length, $offset) = @_;
    $length = length $buf unless defined $length;
    $offset = 0 unless defined $offset;
    my $ssl = $client->SSLeay;
    my $data = Net::SSLeay::read($ssl, $length);

    return if $!{EAGAIN} || $!{EINTR};

    die "SSLeay print: $!\n" unless defined $data;

    $length = length($data);
    $$buf = '' if !defined $buf;

    if ($offset > length($$buf)) {
        $$buf .= "\0" x ($offset - length($buf));
    }

    substr($$buf, $offset, length($$buf), $data);
    return $length;
}

sub error { my $client = shift; return ${*$client}{'_error'} }

sub syswrite {
    my ($client, $buf, $length, $offset) = @_;
    delete ${*$client}{'_error'};

    $length = length $buf unless defined $length;
    $offset = 0 unless defined $offset;
    my $ssl    = $client->SSLeay;

    my $write = Net::SSLeay::write_partial($ssl, $offset, $length, $buf);

    return if $!{EAGAIN} || $!{EINTR};
    if ($write < 0) {
        ${*$client}{'_error'} = "SSLeay print: $!\n";
        return;
    }

    return $write;
}

sub getline {
    my $client = shift;
    my ($ok, $line) = $client->read_until($client->SSL_max_getline_length, $/);
    return $line;
}

sub getlines {
    my $client = shift;
    my @lines;
    while (1) {
        my ($ok, $line) = $client->read_until($client->SSL_max_getline_length, $/);
        push @lines, $line;
        last if $ok != 1;
    }
    return @lines;
}

sub print {
    my $client = shift;
    delete ${*$client}{'_error'};
    my $buf    = @_ == 1 ? $_[0] : join('', @_);
    my $ssl    = $client->SSLeay;
    while (length $buf) {
        vec(my $vec = '', $client->fileno, 1) = 1;
        select(undef, $vec, undef, undef);

        my $write = Net::SSLeay::write($ssl, $buf);
        return 0 if $client->SSLeay_check_error('SSLeay write');
        if ($write == -1 && !$!{EAGAIN} && !$!{EINTR} && !$!{ENOBUFS}) {
            ${*$client}{'_error'} = "SSLeay print: $!\n";
            return;
        }
        substr($buf, 0, $write, "") if $write > 0;
    }
    return 1;
}

sub printf {
    my $client = shift;
    $client->print(sprintf(shift, @_));
}

sub say {
    my $client = shift;
    $client->print(@_, "\n");
}

sub write {
    my $client = shift;
    my $buf    = shift;
    $buf = substr($buf, $_[1] || 0, $_[0]) if @_;
    $client->print($buf);
}

sub seek {
    my $client = shift;
    my ($pos, $whence) = @_;
    if ($whence) {
        $! = "Seek from $whence of non-zero is not supported.";
        return 0;
    }
    my $n = $client->read(my $buf, $pos);
    if ($n != $pos) {
        $| = "Couldn't seek to $pos ($n)\n";
        return 0;
    }
    return 1;
}

sub poll_cb { # implemented for psgi compatibility - TODO - should poll appropriately for Multipex
    my ($self, $cb) = @_;
    return $cb->($self);
}

###----------------------------------------------------------------###

sub hup_string {
    my $sock = shift;
    return join "|", $sock->NS_host, $sock->NS_port, $sock->NS_proto, "ipv".$sock->NS_ipv, (defined(${*$sock}{'NS_orig_port'}) ? ${*$sock}{'NS_orig_port'} : ());
}

sub show {
    my $sock = shift;
    my $t = "Ref = \"".ref($sock). "\" (".$sock->hup_string.")\n";
    foreach my $prop (qw(SSLeay_context SSLeay_is_client)) {
        $t .= "  $prop = \"" .$sock->$prop()."\"\n";
    }
    return $t;
}

sub AUTOLOAD {
    my $sock = shift;
    my $prop = $AUTOLOAD =~ /::([^:]+)$/ ? $1 : die "Missing property in AUTOLOAD.";
    die "Unknown method or property [$prop]"
        if $prop !~ /^(SSLeay_context|SSLeay_is_client|SSL_\w+)$/;

    no strict 'refs';
    *{__PACKAGE__."::${prop}"} = sub {
        my $sock = shift;
        if (@_) {
            ${*$sock}{$prop} = shift;
            return delete ${*$sock}{$prop} if ! defined ${*$sock}{$prop};
        } else {
            return ${*$sock}{$prop};
        }
    };
    return $sock->$prop(@_);
}

sub tie_stdout { 1 }

1;

__END__

=head1 NAME

Net::Server::Proto::SSLEAY - Custom Net::Server SSL protocol handler based on Net::SSLeay.

=head1 SYNOPSIS

See L<Net::Server::Proto>.

    use base qw(Net::Server::HTTP);
    main->run(
        proto => 'ssleay',
        SSL_key_file  => "/path/to/my/file.key",
        SSL_cert_file => "/path/to/my/file.crt",
    );


    # OR

    sub SSL_key_file  { "/path/to/my/file.key" }
    sub SSL_cert_file { "/path/to/my/file.crt" }
    main->run(proto => 'ssleay');


    # OR

    main->run(
        port => [443, 8443, "80/tcp"],  # bind to two ssleay ports and one tcp
        proto => "ssleay",    # use ssleay as the default
        ipv  => "*",          # bind both IPv4 and IPv6 interfaces
        SSL_key_file  => "/path/to/my/file.key",
        SSL_cert_file => "/path/to/my/file.crt",
    );


    # OR

    main->run(port => [{
        port  => "443",
        proto => "ssleay",
        # ipv => 4, # default - only do IPv4
        SSL_key_file  => "/path/to/my/file.key",
        SSL_cert_file => "/path/to/my/file.crt",
    }, {
        port  => "8443",
        proto => "ssleay",
        ipv   => "*", # IPv4 and IPv6
        SSL_key_file  => "/path/to/my/file2.key", # separate key
        SSL_cert_file => "/path/to/my/file2.crt", # separate cert
    }]);


=head1 DESCRIPTION

This module has reliably been used in situations receiving millions of
hits on a single box per day.  If anybody has any successes or ideas
for improvment under SSLEAY, please email <paul@seamons.com>.

Protocol module for Net::Server.  This module implements a secure
socket layer over tcp (also known as SSL).  See L<Net::Server::Proto>.

If you need more customization of the SSL layer, you may want to
investigate using SSL rather than SSLEAY as it uses the venerable(ish)
IO::Socket::SSL.

=head1 PARAMETERS

Currently there is support for the following:

=over 4

=item C<SSL_cert_file>

Full path to the certificate file to be used for this server.  Should
be in PEM format.

=item C<SSL_key_file>

Full path to the key file to be used for this server.  Should be in
PEM format.

=item C<SSL_max_getline_length>

Used during getline to only read until this many bytes are found.
Default is undef which means unlimited.

=item C<SSL_error_callback>

Should be a code ref that will be called whenever error conditions are
encountered.  It passes a source message and an arrayref of the
errors.

=back

=head1 METHODS

This module implements most of the common file handle operations.
There are some additions though:

=over 4

=item C<read_until>

Takes bytes and match qr.  If bytes is defined - it will read until
that many bytes are found.  If match qr is defined, it will read until
the buffer matches that qr.  If both are undefined, it will read until
there is nothing left to read.

=item C<error>

If an error occurred while writing, this method will return that error.

=back

=head1 BUGS

There are probably many.

=head1 LICENCE

Distributed under the same terms as Net::Server

=head1 THANKS

Thanks to Bilbo at
http://devpit.org/wiki/OpenSSL_with_nonblocking_sockets_%28in_Perl%29
for documenting a more reliable way of accepting and reading SSL
connections.

=cut
