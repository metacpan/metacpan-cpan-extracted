use strict;
use warnings;
use RPi::UnicornHatHD;
use Imager;
use HTTP::Tiny;
use JSON::Tiny qw[decode_json];
use Time::HiRes qw[sleep];

# Scroll the front page of Reddit
my $display = RPi::UnicornHatHD->new();
$display->brightness(1);
my $font = Imager::Font->new(
                file => '/usr/share/fonts/truetype/piboto/Piboto-Regular.ttf',
                type => 'ft2',
                color => Imager::Color->new('#000033'),
                size  => 12
) or die Imager->errstr;
while (1) {
    my @titles;
    my $response
        = HTTP::Tiny->new->get('https://www.reddit.com/r/all/new.json');
    die "Failed!\n" unless $response->{success};
    my $json = decode_json $response->{content};
    push @titles, map {
        sprintf '[/r/%s] %s (/u/%s)',
            $_->{data}{subreddit}, $_->{data}{title}, $_->{data}{author}
    } @{$json->{data}{children}};
    for my $title (map { $_ . ' --- ' } @titles) {
        my $bounds = $font->bounding_box(string => $title);
        my $img = Imager->new(xsize => $bounds->display_width + 16 + 2,
                              ysize => 16);
        $img->box(filled => 1, color => '010101'); # fill the background color
        my ($left, $top, $right, $bottom)
            = $img->align_string(font   => $font,
                                 text   => $title,
                                 x      => 16,
                                 y      => 2,
                                 halign => 'left',
                                 valign => 'top',
                                 aa     => 1
            );
        for my $scroll_position (0 .. $right) {
            for my $x (0 .. 15) {
                for my $y (0 .. 15) {
                    my $color
                        = $img->getpixel(x => $x + $scroll_position, y => $y);
                    if ($color) {
                        my ($r, $g, $b, $a) = $color->rgba();
                        $display->set_pixel($y, $x, $r, $b, $g);
                    }
                }
            }
            $display->show;
            sleep .01;
        }
    }
    $display->off;
    sleep 60 * 5;    # Snooze for a few
}
