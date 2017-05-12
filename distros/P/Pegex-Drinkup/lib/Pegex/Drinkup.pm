use strict; use warnings;
package Pegex::Drinkup;
our $VERSION = '0.0.2';

use Pegex::Base;

use Pegex::Parser;
use Pegex::Drinkup::Grammar;
use Pegex::Drinkup::Data;

sub parse {
    my ($self, $input) = @_;
    my $parser = Pegex::Parser->new(
        grammar => Pegex::Drinkup::Grammar->new(),
        receiver => Pegex::Drinkup::Data->new(),
        # debug => 1,
    );
    return $parser->parse($input);
}

1;
