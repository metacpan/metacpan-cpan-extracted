use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Feersum;
use Plack::Runner;
use Plack::Handler::Feersum::SS;

my $listen = IO::Socket::INET->new(
    Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
    ReuseAddr => 1, Proto => 'tcp',
) or plan skip_all => "cannot bind 127.0.0.1: $!";
local $ENV{SERVER_STARTER_PORT} = '127.0.0.1:' . $listen->sockport . '=' . $listen->fileno;

my $ngn = Feersum->endjinn;
my %numeric = (
    read_timeout => 5, header_timeout => 6, write_timeout => 7, linger_timeout => 2,
    max_connection_reqs => 10, max_connections => 100, max_accept_per_loop => 8,
    max_read_buf => 65536, max_body_len => 1024, max_uri_len => 512,
    wbuf_low_water => 4096, max_h2_concurrent_streams => 10, max_h2_conn_body => 2048,
    read_priority => 1, write_priority => -1, accept_priority => 2,
);
delete $numeric{$_} for grep { !$ngn->can($_) } keys %numeric;
# a Feersum built without HTTP/2 ignores the h2 limits and reads them back as 0
delete @numeric{qw/max_h2_concurrent_streams max_h2_conn_body/}
    unless $ngn->can('has_h2') && $ngn->has_h2;
my $can_drop = Plack::Handler::Feersum::SS->can('_drop_privs');

my @args = (
    (map { (my $o = $_) =~ tr/_/-/; "--$o=$numeric{$_}" } sort keys %numeric),
    qw/--keepalive=0 --reverse-proxy=1 --proxy-protocol=1 --psgix-io=1
       --pre-fork=2 --graceful-timeout=3 --max-requests-per-worker=100 --bogus=1/,
    ($can_drop ? '--user=' . getpwuid($<) : ()),
);
my $runner = Plack::Runner->new;
$runner->parse_options(@args);

my %ready;
my $h = Plack::Handler::Feersum::SS->new(@{ $runner->{options} },
    server_ready => sub { %ready = %{ $_[0] } });
my @warns;
my $ok = do {
    local $SIG{__WARN__} = sub { push @warns, "@_" };
    eval { $h->_prepare; 1 };
};
ok $ok, 'plackup --key=value options accepted' or diag $@;

my $f = $h->{endjinn};
isa_ok $f, 'Feersum', 'endjinn';
is $f->$_(), $numeric{$_}, "$_ applied" for sort keys %numeric;
ok !exists $h->{$_}, "$_ consumed" for qw/keepalive reverse_proxy proxy_protocol psgix_io/;

is $h->{pre_fork}, 2, 'pre_fork left for run()';
is $h->{graceful_timeout}, 3, 'graceful_timeout left for run()';
is $h->{max_requests_per_worker}, 100, 'max_requests_per_worker left for run()';
SKIP: {
    skip 'Feersum::Runner cannot drop privileges', 1 unless $can_drop;
    is $h->{user}, scalar getpwuid($<), 'user left for run() to drop privileges';
}

is_deeply [ map { /Unknown option '(\w+)'/ ? $1 : () } @warns ], ['bogus'],
    'only the misspelled option warns';
is $ready{host}, '127.0.0.1', 'server_ready host';
is $ready{port}, $listen->sockport, 'server_ready port';
ok !$ready{proto}, 'server_ready proto is plain http';

done_testing;
