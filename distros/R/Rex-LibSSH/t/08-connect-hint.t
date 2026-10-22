use strict;
use warnings;
use lib 't/lib';
use Test::More;
use IO::Socket::INET;
use TestSSHD;

# karr k11: a failed connect under strict host key checking used to append the
# "add the host to known_hosts ... or opt out" hint to every error, so a host
# that is still rebooting ("Connection refused") sent the reader to turn host
# key checking off. The hint belongs to host key refusals only; Net::LibSSH
# names known_hosts in each of them.
#
# This proves: an unknown host key still gets the hint, a closed port does not.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

use Rex -feature => ['1.4'];
use Rex::Config;
use Rex::Interface::Connection;

Rex::Config->set_user( scalar getpwuid($<) );
Rex::Config->set_private_key( $srv->client_key );
Rex::Config->set_public_key( $srv->client_key . '.pub' );

# Every message Rex::Logger::info gets while $code runs.
sub logged {
    my ($code) = @_;
    my @lines;
    no warnings 'redefine';
    local *Rex::Logger::info = sub { push @lines, $_[0] };
    local $SIG{ALRM} = sub { die "TIMEOUT\n" };
    alarm 15;
    $code->();
    alarm 0;
    return join "\n", @lines;
}

sub connect_to {
    my ($port) = @_;
    my $conn = Rex::Interface::Connection->create('LibSSH');
    my $log  = logged( sub {
        $conn->connect(
            server      => $srv->host,
            port        => $port,
            user        => scalar getpwuid($<),
            private_key => $srv->client_key,
            public_key  => $srv->client_key . '.pub',
            auth_type   => 'key',
        );
    } );
    return ( $conn, $log );
}

# A port nothing listens on: bind one, note it, close it again.
my $closed = do {
    my $s = IO::Socket::INET->new( LocalAddr => $srv->host, LocalPort => 0, Listen => 1 )
        or die "no free port: $!";
    my $p = $s->sockport;
    close $s;
    $p;
};

{
    my ( $conn, $log ) = connect_to( $srv->port );
    is $conn->is_connected, 0, 'unknown host key: refused (default strict)';
    like $log, qr/not in known_hosts/, 'unknown host key: the error is in the log';
    like $log, qr/host key checking is on: add the host to known_hosts/,
        'unknown host key: the known_hosts hint follows';
}

{
    my ( $conn, $log ) = connect_to($closed);
    is $conn->is_connected, 0, 'closed port: not connected';
    like $log, qr/can't connect to/, 'closed port: the error is in the log';
    unlike $log, qr/host key checking is on/,
        'closed port: no host key hint for an error that is not about the host key';
}

done_testing;
