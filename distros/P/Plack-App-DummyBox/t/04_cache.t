use strict;
use warnings;
use Test::More 0.88;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Headers;

use Plack::App::DummyBox;

note('cache option');
{
    my $box = Plack::App::DummyBox->new(
        cache => My::Cache->new,
    );
    is ref($box->cache), 'My::Cache', 'cache getter';
    is $box->cache->get(1), undef, 'no cache get';
    $box->cache->set(1, 5);
    is $box->cache->get(1), 5, 'cache get';
    $box->cache(undef);
    is $box->cache, undef, 'cache setter';
}

note('app with cache');
{
    my $app = Plack::App::DummyBox->new(
        cache => My::Cache->new,
    );

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/?w=250&h=50');

        is $res->code, 200, 'response status 200';

        SKIP: {
            skip 'gif is not supported', 1 unless $Imager::formats{gif};

            like $res->content, qr/^GIF.+/, 'gif image';
        }

        my $cache_key = $app->cache_key;
        like $cache_key, qr/^250:50:.+/, 'cache key';

        is $res->content, $app->cache->get($cache_key)->[1][0], 'cached content';

        my $c = 0;
        my $key = '';
        my %hash;
        for my $i ( @{$app->cache->get($cache_key)->[0]} ) {
            if ($c++ % 2 == 0) {
                $key = $i;
            }
            else {
                $hash{$key} = $i;
            }
        }
        my $cached_headers = HTTP::Headers->new(%hash);

        is ref($res->headers), ref($cached_headers), 'cached header object';
        is $cached_headers->as_string, $res->headers->as_string, 'cached headers';

        # req again
        {
            my $res_cached = $cb->(GET '/?w=250&h=50');

            is $res_cached->code, 200, 'response status 200 again';

            SKIP: {
                skip 'gif is not supported', 1 unless $Imager::formats{gif};

                like $res_cached->content, qr/^GIF.+/, 'gif image again';
            }

            is(
                $res_cached->content,
                $app->cache->get($cache_key)->[1][0],
                'cached content again'
            );
        }
    };
}

done_testing;


package My::Cache;
sub new { bless {}, shift }
sub get { $_[0]->{ $_[1] } }
sub set { $_[0]->{ $_[1] } = $_[2] }
