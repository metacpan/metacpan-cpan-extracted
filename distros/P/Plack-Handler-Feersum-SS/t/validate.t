use strict;
use warnings;
use Test::More;
use Plack::Runner;
use Plack::Handler::Feersum::SS;

sub handler {
    my $runner = Plack::Runner->new;
    $runner->parse_options(@_);
    return Plack::Handler::Feersum::SS->new(@{ $runner->{options} });
}

my @reject = (
    [['--h2=1'],                  qr/h2 requires TLS/],
    [['--tls-cert-file=a.crt'],   qr/tls_cert_file requires tls_key_file/],
    [['--tls-key-file=a.key'],    qr/tls_key_file requires tls_cert_file/],
    [[qw/--tls-cert-file=nx.crt --tls-key-file=nx.key/], qr/cert_file 'nx\.crt': not found/],
    [['--after-fork=My::init'],   qr/after_fork must be a code reference/],
    [['--pre-fork=two'],          qr/pre_fork must be a positive integer/],
    [['--accept-priority=3'],     qr/accept_priority must be an integer between -2 and 2/],
    [['--max-accept-per-loop=0'], qr/max_accept_per_loop must be a positive integer/],
    [['--max-connections=-1'],    qr/max_connections must be a non-negative integer/],
);
for my $case (@reject) {
    my ($args, $re) = @$case;
    eval { handler(@$args)->_normalize_options };
    like $@, $re, "@$args rejected";
}

eval { Plack::Handler::Feersum::SS->new(sni => [{}])->_normalize_options };
like $@, qr/sni requires TLS/, 'sni without tls rejected';
eval { Plack::Handler::Feersum::SS->new(access_log => 'x')->_normalize_options };
like $@, qr/access_log must be a code reference/, 'non-code access_log rejected';

for my $opt (qw/daemonize hot_restart pid_file reuseport backlog/) {
    eval { Plack::Handler::Feersum::SS->new($opt => 1)->run(sub {}) };
    like $@, qr/^\Q$opt\E is not supported under Server::Starter/, "$opt rejected";
}

{
    my $h = Plack::Handler::Feersum::SS->new(
        options => { keepalive => 0, epoll_exclusive => 1 });
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, "@_" };
    $h->_normalize_options;
    is $h->{keepalive}, 0, 'options hash merged, false value kept';
    is_deeply [ map { /Unknown option '(\w+)'/ ? $1 : () } @warns ], ['epoll_exclusive'],
        'options hash keys are checked too';
}

done_testing;
