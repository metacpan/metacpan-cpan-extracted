#!perl

use strict;
use warnings;
use diagnostics;
use List::Util 'shuffle';

# The size of the maze. Take the arguments from the command line or from the
# default.
my ( $HEIGHT, $WIDTH ) = @ARGV ? @ARGV : ( 20, 20 );

# Time::HiRes was officially released with Perl 5.8.0, though Module::Corelist
# reports that it was actually released as early as v5.7.3. If you don't have
# this module, your version of Perl is probably over a decade old
use Time::HiRes 'usleep';

# In Perl, $^O is the name of your operating system. On Windows (as of this
# writing), it always 'MSWin32'.
use constant IS_WIN32 => 'MSWin32' eq $^O;

# On Windows, we assume that the command to clear the screen is 'cls'. On all
# other systems, we assume it's 'clear'. You may need to adjust this.
use constant CLEAR => IS_WIN32 ? 'cls' : 'clear';

# We will only redraw the screen (and thus show the recursive maze generation)
# if and only if the system is capable of clearing the screen. The system()
# command returns 0 upon success. See perldoc -f system.
# The following line works because $x == $y returns a boolean value.
#use constant CAN_REDRAW => 0 == system(CLEAR);
use constant CAN_REDRAW => 0;

# Time in microseconds between screen redraws. See Time::HiRes and the usleep
# function
use constant DELAY => 10_000;

use constant OPPOSITE_OF => {
    north => 'south',
    south => 'north',
    west  => 'east',
    east  => 'west',
};

my @maze;
tunnel( 0, 0, \@maze );
my $num = 10_000;

system(CLEAR) if CAN_REDRAW;
print render_maze( \@maze );

exit;

sub tunnel {
    my ( $x, $y, $maze ) = @_;

    if (CAN_REDRAW) {
        my $render = render_maze($maze);
        system(CLEAR);
        print $render;
        usleep DELAY;
    }

    # Here we need to use a unary plus in front of OPPOSITE_OF so that
    # Perl understands that this is a constant and that we're not trying
    # to access the %OPPOSITE_OF variable.
    my @directions = shuffle keys %{ +OPPOSITE_OF };

    foreach my $direction (@directions) {
        my ( $new_x, $new_y ) = ( $x, $y );

        if    ( 'east'  eq $direction ) { $new_x += 1; }
        elsif ( 'west'  eq $direction ) { $new_x -= 1; }
        elsif ( 'south' eq $direction ) { $new_y += 1; }
        else                            { $new_y -= 1; }

        if ( have_not_visited( $new_x, $new_y, $maze ) ) {
            $maze->[$y][$x]{$direction} = 1;
            $maze->[$new_y][$new_x]{ OPPOSITE_OF->{$direction} } = 1;

            # This program will often recurse more than one hundred levels
            # deep and this is Perl's default recursion depth level prior to
            # issuing warnings. In this case, we're telling Perl that we know
            # that we'll exceed the recursion depth and to now warn us about
            # it
            no warnings 'recursion';
            tunnel( $new_x, $new_y, $maze );
        }
    }
}

sub have_not_visited {
    my ( $x, $y, $maze ) = @_;

    # the first two lines return false  if we're out of bounds
    return if $x < 0 or $y < 0;
    return if $x > $WIDTH - 1 or $y > $HEIGHT - 1;

    # this returns false if we've already visited this cell
    return if $maze->[$y][$x];

    # return true
    return 1;
}

sub render_maze {
    my $maze = shift;

    my $as_string = "_" x ( 1 + $WIDTH * 2 );
    $as_string .= "\n";

    for my $y ( 0 .. $HEIGHT - 1 ) {
        $as_string .= "|";
        for my $x ( 0 .. $WIDTH - 1 ) {
            my $cell = $maze->[$y][$x];
            $as_string .= $cell->{south} ? " " : "_";
            $as_string .= $cell->{east}  ? " " : "|";
        }
        $as_string .= "\n";
    }
    return $as_string;
}
