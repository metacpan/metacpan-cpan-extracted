use 5.014;

use FindBin qw($Bin);
use Mojo::UserAgent::Mockable;
use Test::Most;
use Test::JSON;

use Time::HiRes qw/tv_interval gettimeofday/;

my $TEST_FILE_DIR = qq{$Bin/files};
my $vanilla_ua    = Mojo::UserAgent->new();

my $url    = Mojo::URL->new(q{http://www.vam.ac.uk/api/json/museumobject/O1});
my $result = Mojo::UserAgent->new->get($url)->res->json;

plan skip_all => 'Museum API not responding properly' unless ref $result eq 'ARRAY' && $result->[0]{'pk'};

my $mock = Mojo::UserAgent::Mockable->new( mode => 'passthrough' );
my $result_from_mock;
lives_ok {
    $mock->get(
        $url,
        sub {
            my ( $ua, $tx ) = @_;
            is_deeply $tx->res->json, $result, q{Result matches (non blocking)};
            Mojo::IOLoop->stop_gracefully;
        }
    );
}
'non blocking get() did not die';
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

done_testing;
