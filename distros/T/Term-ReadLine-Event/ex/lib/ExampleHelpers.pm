package ExampleHelpers;

use warnings;
use strict;

use IO::Handle;
use Term::ReadLine;

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw( update_time print_input initialize_completion );

STDOUT->autoflush(1);

my $CSI = "\x1b[";
print "${CSI}2J${CSI}3H";

# Helper to update an internal time register and print it as we go.
# This helps us know it's working asynchronously.

my $t = 0;

sub update_time {
    ++$t;
    print STDERR "\x1b7${CSI}1H$t s \x1b8";
}

# Helper to print input with the elapsed time it took to receive the
# input.  This also lets us know Term::ReadLine is working.  The time
# only updates if timers can fire while Term::ReadLine is waiting for
# input.

sub print_input {
    my ($input) = @_;
    print "Got input [$input] in $t second(s)\n";
}

# Set up completion for a Term::ReadLine object.
# Completion only works if Term::ReadLine can handle individual
# asynchronous keystrokes.

my @words = qw(
abase
abased
abasedly
abasedness
abasement
abaser
abash
abashed
abashedly
abashedness
abashless
abashlessly
);

sub initialize_completion {
    my ($term) = @_;

    $term->Attribs()->{completion_function} = sub {
        my ($word, $line, $pos) = @_;
        $word ||= "";
        grep /^$word/i, @words;
    };

    return $term;
}

1;
