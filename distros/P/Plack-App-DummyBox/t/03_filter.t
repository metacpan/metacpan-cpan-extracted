use strict;
use warnings;
use Test::More 0.88;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::DummyBox;

note('filter option');
{
    my $filtered_app = Plack::App::DummyBox->new(
        filter => sub {
            my ($self, $img) = @_;
            $img->box(
                xmin => 5, ymin => 5, xmax => 10, ymax => 10,
                filled => 1,
                color  => 'green'
            );
        },
    )->to_app;

    my $img = Imager->new;

    test_psgi $filtered_app, sub {
        my $cb = shift;

        my $res = $cb->(GET '/?w=99&h=99');

        is $res->code, 200, 'response status 200';
        is $res->content_type, 'image/gif', 'default content_type';

        SKIP: {
            skip 'gif is not supported', 2 unless $Imager::formats{gif};

            like $res->content, qr/^GIF.+/, 'gif image';

            $img->read(data => $res->content);
            is $img->colorcount, 4, 'color count';
        }
    };
}

done_testing;
