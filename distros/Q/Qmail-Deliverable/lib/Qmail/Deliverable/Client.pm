package Qmail::Deliverable::Client;

use strict;
use 5.006;
use Carp qw(carp);
use base 'Exporter';
use IO::Socket::INET;
use Qmail::Deliverable::Status qw(:status);

our @EXPORT_OK   = ( qw(qmail_local deliverable), @Qmail::Deliverable::Status::STATUS, );
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    status => \@Qmail::Deliverable::Status::STATUS,
);

our $SERVER = "127.0.0.1:8998";
our $ERROR;

# rfc2822's "atext"
my $atext = "[A-Za-z0-9!#\$%&\'*+\/=?^_\`{|}~-]";
my $valid = qr/^(?!.*\@.*\@)($atext+(?:[\@.]$atext+)*)\.?\z/;

sub _uri_escape {
    my ($value) = @_;
    $value =~ s/([^A-Za-z0-9\-\._~])/sprintf("%%%02X", ord($1))/eg;
    return $value;
}

sub _http_request {
    my ( $server, $command, $arg ) = @_;
    my ( $host, $port ) = $server =~ /^([A-Za-z0-9_.-]+):([0-9]+)\z/
        or return ( undef, undef, "invalid server address" );

    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 5,
    ) or return ( undef, undef, $! );

    my $request = join "",
        "GET /qd1/$command?" . _uri_escape($arg) . " HTTP/1.0\r\n",
        "Host: $host:$port\r\n",
        "Connection: close\r\n",
        "\r\n";

    print {$sock} $request or return ( undef, undef, $! );

    my $response = do { local $/; <$sock> };
    close $sock;
    return ( undef, undef, "empty response" ) if not defined $response;

    my ( $headers, $body ) = split /\r?\n\r?\n/, $response, 2;
    return ( undef, undef, "malformed response" ) if not defined $body;

    my ($status_line) = split /\r?\n/, $headers, 2;
    my ($code)        = $status_line =~ /^HTTP\/\d+\.\d+\s+([0-9]+)\b/
        or return ( undef, undef, "malformed response" );

    return ( $code, $body, $status_line );
}

sub _remote {
    my ( $command, $arg ) = @_;

    my $server =
        ref($SERVER) eq 'CODE'
        ? $SERVER->()
        : $SERVER;

    if ( not defined $server ) {
        $ERROR = "No SERVER defined; connection not attempted";
        return "\0";
    }

    my ( $code, $body, $sl ) = _http_request( $server, $command, $arg );
    if ( not defined $code ) {
        carp $ERROR = "Server $server unreachable or broken! ($sl)";
        return "\0";
    }
    return undef if $code == 204;    # rpc undef
    if ( $code == 200 ) {
        return $body;
    }

    carp $ERROR = "Server $server unreachable or broken! ($sl)";
    return "\0";
}

sub qmail_local {
    my ($in)      = @_;
    my ($address) = lc($in) =~ /$valid/
        or do { carp "Invalid address: $in"; return; };

    # This we can do locally. Let's not waste HTTP requests :)
    return $address if $address !~ /\@/;

    my $rv = _remote 'qmail_local', $address;
    return "" if defined $rv and $rv eq "\0";
    return $rv;
}

sub deliverable {
    my ($in)      = @_;
    my ($address) = lc($in) =~ /$valid/
        or do { carp "Invalid address: $in"; return; };

    my $rv = _remote 'deliverable', $address;
    return QD_CLIENT_FAILURE if not defined $rv;    # shouldn't happen
    return QD_CLIENT_FAILURE if not length $rv;     # shouldn't happen
    return QD_CLIENT_FAILURE if $rv eq "\0";

    return $rv;
}

1;

__END__

=head1 NAME

Qmail::Deliverable::Client - Client for qmail-deliverabled

=head1 SYNOPSIS

    use Qmail::Deliverable::Client qw(deliverable);

    $Qmail::Deliverable::Client::SERVER = "127.0.0.1:8998";

    if (deliverable "foo@example.com") { ... }

=head1 DESCRIPTION

Qmail::Deliverable comes with a daemon program called qmail-deliverabled. This
module is a front end to it.

=head2 Error reporting

The error message for communication failure is reported via a warning, but also
available via $Qmail::Deliverable::Client::ERROR.

=head2 Configuration

=over 4

=item $Qmail::Deliverable::Client::SERVER

IP adress and port of the qmail-deliverabled server, joined by a colon.
Defaults to C<127.0.0.1:8998>, just like the daemon.

This variable can also be assigned a code reference, in which case it is called
in scalar context for each remote call, using the returned value.

If the value is undef, then a connection failure is faked, but without the
warning.

=back

=head2 Functions

All documented functions are exportable, and a tag :all is available for
convenience.

Unless documented differently, these functions follow the interfaces described
in L<Qmail::Deliverable>.

=over 4

=item qmail_local $address

As Qmail::Deliverable::qmail_local. Warns and returns "" on communication
failure.

=item deliverable $address

=item deliverable $local

As Qmail::Deliverable::deliverable. Warns and returns
C<QD_CLIENT_FAILURE> (0x2f) on communication failure.

=back

=head2 Status codes

Status-code constants are re-exported under the C<:status> tag from
L<Qmail::Deliverable::Status>. Loading them does not pull in any of
C<Qmail::Deliverable>'s privileged code:

    use Qmail::Deliverable::Client qw(deliverable :status);

    my $rv = deliverable $address;
    warn "daemon down" if $rv == QD_CLIENT_FAILURE;

=head1 PERFORMANCE

The server on which I benchmarked this, the client+daemon combination (on
localhost) reached 300 deliverability checks per second for assigned/virtual
users. Real users are slower: around 150 checks per second.

=head1 LICENSE

This software does not come with warranty or guarantee of any kind. Use it at
your own risk.

This software may be redistributed under the terms of the GPL, LGPL, modified
BSD, or Artistic license, or any of the other OSI approved licenses listed at
http://www.opensource.org/licenses/alphabetical. Distribution is allowed under
all of these these licenses, or any smaller subset of multiple or just one of
these licenses.

When using a packaged version, please refer to the package metadata to see
under which license terms it was distributed. Alternatively, a distributor may
choose to replace the LICENSE section of the documentation and/or include a
LICENSE file to reflect the license(s) they chose to redistribute under.

=head1 AUTHORS

=over 4

=item *

Juerd Waalboer <#####@juerd.nl> (original author)

=item *

Matt Simerson <msimerson@cpan.org> (current maintainer)

=back

=head1 CONTRIBUTORS

=over 4

=item *

Martin Sluka

=back
