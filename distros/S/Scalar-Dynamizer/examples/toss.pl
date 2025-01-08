use strict;
use warnings;

use Scalar::Dynamizer qw(dynamize);

# Dynamized scalar to simulate a coin toss
my $coin_toss = dynamize {
    return rand() < 0.5 ? 'heads' : 'tails';
};

print "Welcome to the Coin Toss Game!\n";
print "Guess Heads or Tails (type 'exit' to quit):\n";

while (1) {
    print "\nYour guess: ";
    chomp( my $guess = <STDIN> );
    last if lc($guess) eq 'exit';

    # Validate input
    if ( lc($guess) ne 'heads' && lc($guess) ne 'tails' ) {
        print "Invalid input. Please guess 'Heads' or 'Tails'.\n";
        next;
    }

    # Use string interpolation to get the VALUE of the tied scalar. Perl doesn't
    # know the context here, so if you just say:
    #     my $result = $coin_toss
    # Then you'll get a copy of a reference to the object instead of its value!
    my $result = "$coin_toss";

    # Compare user's guess with the result
    if ( lc($guess) eq $result ) {
        print "You guessed it right! The coin shows: "
          . ucfirst($result) . "\n";
    }
    else {
        print "Oops, better luck next time! The coin shows: "
          . ucfirst($result) . "\n";
    }
}

print "Thanks for playing! Goodbye!\n";
