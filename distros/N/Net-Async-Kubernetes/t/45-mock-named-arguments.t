use strict;
use warnings;
use Test::More;

use lib 't/lib';

use IO::Async::Loop;
use Net::Async::Kubernetes;
use MockTransport;

# karr k67: log, port_forward, exec, attach, cp_to_pod and cp_from_pod take
# the resource name either positionally - METHOD('Pod', 'web', %options) - or
# keyed - METHOD('Pod', name => 'web', %options). A first argument that is
# one of the options the method takes starts the keyed form; anything else
# that is no reference is the name. So the options a method refuses as
# unknown and the first arguments it reads as an option key are one list:
# each allowed option is read as a key (a following odd list then fails with
# Invalid arguments to METHOD()), a name that merely contains one is the
# name (the stray option after it is then refused as unknown), and a
# reference never is. All of it fails the Future before any request and
# without a warning. Mock mode only.

my $loop = IO::Async::Loop->new;

MockTransport::reset();
my $kube = Net::Async::Kubernetes->new(
    server      => { endpoint => 'https://mock.local' },
    credentials => { token => 'mock-token' },
    resource_map_from_cluster => 0,
);
MockTransport::install($kube);
$loop->add($kube);

my @CB = qw( subprotocol on_open on_frame on_close on_error );
my %ALLOWED = (
    log          => [qw( name namespace container follow tailLines sinceSeconds sinceTime
                         timestamps previous limitBytes on_line )],
    port_forward => [qw( name namespace ports ), @CB],
    exec         => [qw( name namespace command container stdin stdout stderr tty ), @CB],
    attach       => [qw( name namespace container stdin stdout stderr tty ), @CB],
    cp_to_pod    => [qw( name namespace container local remote chunk_size )],
    cp_from_pod  => [qw( name namespace container local remote )],
);

# The failure message of METHOD('Pod', @args), or what went wrong instead.
sub failure_of {
    my ($method, @args) = @_;
    my $f = eval { $kube->$method('Pod', @args) };
    return "died: $@" if $@;
    return 'no Future' unless $f;
    return 'not failed' unless $f->is_failed;
    return ($f->failure)[0];
}

for my $method (sort keys %ALLOWED) {
    subtest $method => sub {
        my @allowed = @{ $ALLOWED{$method} };
        my $invalid = "Invalid arguments to $method()";
        my $unknown = "Unknown argument 'x' to $method() (allowed: " . join(', ', @allowed) . ')';
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };

        for my $key (@allowed) {
            is(failure_of($method, $key, 'v', 'orphan'), $invalid,
                "'$key' first starts the keyed form");
            is(failure_of($method, "web-$key", 'x', 'orphan'), $unknown,
                "'web-$key' first is the name");
            is(failure_of($method, "$key-web", 'x', 'orphan'), $unknown,
                "'$key-web' first is the name");
        }
        is(failure_of($method, [], 'x', 'orphan'), $invalid, 'a reference first is never the name');
        is(failure_of($method, 'web', 'orphan'), $invalid, 'the name, then an odd list');
        is(failure_of($method, 'web', namespace => 'default', 'orphan'), $invalid,
            'the name, then options and a stray key');
        is(failure_of($method), "name required for $method", 'nothing at all: the keyed form, no name');

        is_deeply(\@warnings, [], 'no warning');
        is(scalar(() = MockTransport::request_log()), 0, 'nothing was sent');
    };
}

done_testing;
