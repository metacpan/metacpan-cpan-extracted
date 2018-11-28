use 5.014;

use File::Temp;
use FindBin qw($Bin);
use Mojo::UserAgent::Mockable;
use Test::Most;
use Test::JSON;

use Time::HiRes qw/tv_interval gettimeofday/;

my $TEST_FILE_DIR = qq{$Bin/files};
my $vanilla_ua = Mojo::UserAgent->new();

subtest 'Victoria and Albert Museum' => sub {
    my $url = Mojo::URL->new(q{https://www.vam.ac.uk/api/json/museumobject/O1});
    my $result = Mojo::UserAgent->new->get($url)->res->json;

    plan skip_all => 'Museum API not responding properly' unless ref $result eq 'ARRAY' && $result->[0]{'pk'};

    my $mock = Mojo::UserAgent::Mockable->new( mode => 'passthrough' );
    my $result_from_mock;
    lives_ok { $result_from_mock = $mock->get($url)->res->json; } 'get() did not die';
    is_deeply( $result_from_mock, $result, 'result matches that of stock Mojo UA' );
};

subtest 'Local App' => sub {
    my $dir = File::Temp->newdir;
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'passthrough' );

    package LocalApp {
        use Mojolicious::Lite;
        get '/thingy' => sub {
            my $c = shift;
            $c->render( json => { foo => 'bar', baz => 'Lehmann', things => [qw/noise noise noise/] } );
        };
    };
    my $app    = LocalApp::app;
    my $result = $app->ua->get(q{/thingy})->res->json;

    $mock->server->app($app);

    my $result_from_mock;

    lives_ok { $result_from_mock = $mock->get(q{/thingy})->res->json; } 'get() did not die';
    is_deeply( $result_from_mock, $result, 'result matches that of stock Mojo UA' );

};

done_testing;
