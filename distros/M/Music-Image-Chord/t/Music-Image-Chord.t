# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Music-Image-Chord.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Music::Image::Chord') };

#########################

my $image = Music::Image::Chord->new();

$image->bar_thickness(3);
$image->grid(x=>0,y=>25,w=>10,h=>15);
$image->crop_width(5);
$image->debug(1);
$image->font('/Library/Fonts/ArialHB.ttf'); # Only needed for title
$image->file('chord.png');
#  $image->bounds(width=>120,height=>120);
$image->bounds(70,120);
$image->draw
        (
        'name'   => 'D', # Standard-6 D chord
        'fret'   => 1,
        'barres' => [],
        #'chord'  => 'Xx0232',
        );
is($image->bar_thickness(),3);
is($image->crop_width(),5);
is($image->debug(),1);
