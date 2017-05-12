use strict;
use warnings;

use Test::More;

sub toggle;
use Params::Lazy toggle => q(^^);

my $toggle_state = '';
sub toggle {
    my ($begin, $end) = @_;
    
    if ( !$toggle_state ) {
        $toggle_state = 1 if force $begin;
    }
    else {
        if ( force $end ) {
            $toggle_state = '';
            return "1E0";
        }
        else {
            $toggle_state++;
        }
    }

    return $toggle_state;
}

my $out;
for (qw(no1 no2 --a first second third --b no3)) {
    $out .= "<$_>" if toggle /^--a$/, /^--b$/;
}

is(
    $out,
    join("", map "<$_>", qw(--a first second third --b)),
    "Can create a toggle using delayed arguments"
);

done_testing;
