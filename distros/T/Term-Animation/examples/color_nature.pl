#!/usr/bin/perl
#
# This is a very simple example using Term::Animation. 
# To see it in color, you will need your TERM environment
# variable set to something that supports color, and your
# terminal or terminal emulator configured to support color.
#
# Kirk Baucom <kbaucom@schizoid.com>
#
#

use strict;
use warnings;

# you don't have to include Curses, but it is handy so we
# can use halfdelay and getch below.
use Curses;

use Term::Animation 2.0;

# this creates a full screen animation object. you can also
# pass a curses window as an argument to new()
my $s = Term::Animation->new();

# if you are going to use color, you must enable it immediately
# after creating the animation object. you can turn color off
# again afterwards by calling disable_color()
$s->color(1);

my $phrase = "Press q to exit";


# a few simple ASCII art objects to move around
my $cloud1 = q#
   .--.
 .(    )
(_   )__)
  '-'
#;

my $cloud2 = q#
   .-.
 .(  _).
(_. (___)
#;

my $cloud3 = q#
    .-.
 .-(   ).
(        )
 (_(__.___)
#;

my @sun = (q{
  \  |  /
   .---.
- |     | -
   '---'
  /  |  \
},
q{

   .---.
  |     |
   '---'

});


my $tree = q#
     ,-
    (  }
  ,^    '),
 (         }
{           )
 '-.       /,
  {         }
   -.    ,-'
     |  }
     | |
     | |
  .-'   '-.
#;


# here we have a color mask for the tree above. each
# character in the mask represents the color for the
# corresponding character in the object. capital letters
# indicate bold. here, G and K represent bold green and
# bold black (dark gray). supplying a color where there
# is no character draw in the object has no effect.
# leaving out a color where there is a character will
# cause that character to be drawn with the default color.
# the default color (unless you override it) is non-bold white.
my $tree_fg_mask = q#
     GG
    G  G
  GG    GGG
 G         G
G           G
 GGG       GG
  G         G
   GG    GGG
     K  G
     K K
     K K
  KKK   KKK
#;

# now we take our ascii art from above and create animation
# objects out of them.
$s->new_entity(
	# the ASCII image for this entity
	shape		=> $cloud1,

	# this is the start position of the object,
	# row, column, depth. lower depth numbers
	# make objects closer to the 'camera'
	position	=> [ 2, 1, 10],

	# the vector we want the object to follow
	# x, y, z, frame. see the 'sun' object for frame
	# info. vectors can be floating point values
	callback_args	=> [1,0,0,0],

	# whether the object should wrap around when
	# it gets to the edge of the screen
	wrap		=> 1,

	# instead of supplying a color mask, we just
	# give a default_color, since the whole thing
	# is the same color
	default_color	=> 'WHITE',

	# this flag indicates that any whitespace before
	# the first non-whitespace in a line should be
	# transparent
	auto_trans	=> 1,
);

$s->new_entity(
	shape		=> $cloud2,
	position	=> [ 10, 5, 10],
	callback_args	=> [1,0,0,0],
	wrap		=> 1,
	default_color	=> 'WHITE',
	auto_trans	=> 1,
);

$s->new_entity(
	shape		=> $cloud3,
	position	=> [ 15, 1, 10],
	callback_args	=> [1,0,0,0],
	wrap		=> 1,
	default_color	=> 'WHITE',
	auto_trans	=> 1,
);

$s->new_entity(
	# here we pass in an array of animation frames
	shape		=> \@sun,
	position	=> [ 60, 2, 20],

	# the last element of the vector represents the
	# animation frame. for every update, the sun will
	# move ahead one animation frame (and loop back
	# to the first frame when it reaches the last frame)
	callback_args	=> [-1,0,0,1],

	wrap		=> 1,
	default_color	=> 'YELLOW',
);

$s->new_entity(
	shape		=> $tree,
	position	=> [ 25, 7, 5],

	# here we specify our color mask. you can still
	# supply a default_color even if you give a mask,
	# which will be used for any characters that you
	# left out of the mask
	color		=> $tree_fg_mask,

	auto_trans	=> 1,
);

$s->new_entity(
	shape		=> $tree,
	position	=> [ 5, 5, 5],
	color		=> $tree_fg_mask,
	auto_trans	=> 1,
);

$s->new_entity(
	shape		=> $tree,
	position	=> [ 35, 5, 5],
	color		=> $tree_fg_mask,
	auto_trans	=> 1,
);

# halfdelay is a Curses call to tell getch  how long it should
# wait for input before it times out (in tenths of a second).
# you can use halfdelay and getch to control the frame rate
# of your animation, if you don't expect to be getting much
# input from the user. 
halfdelay( 2 );

# here is the main animation loop.
for(1..500) {

  # run the callback routines for all the objects, and update
  # the screen
  $s->animate();

  # ask for user input, and wait a bit. exit our loop
  # if the user gives us a 'q'
  my $in = lc( getch() );
  if($in eq 'q') { last; }

}
