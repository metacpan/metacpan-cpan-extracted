use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

our $terminated = 0;

my @log;

my $app = sub {
    my $env = shift;
    $env->{'psgix.harakiri'} = 1 unless $env->{'psgix.harakiri'};
    $env->{'psgix.logger'} = sub { $terminated = 1 };
    my $r = Plack::Request->new($env);
    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ 'abcdef' ]
    ];
};
$app = builder {
    enable SizeLimit => (
        max_process_size_in_kb => 1,
        log_when_limits_exceeded => 1,
        callback => sub { push @log, [@_] },
    );
    $app;
};

my $test = Plack::Test->create($app);
my $res = $test->request(GET "/");

is $res->content, 'abcdef';
is $terminated, 1;

ok scalar(@log), 'callback';

done_testing;
