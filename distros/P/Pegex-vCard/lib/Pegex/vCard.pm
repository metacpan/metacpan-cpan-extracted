package Pegex::vCard;
our $VERSION = '0.05';

use Pegex::Base;

use Pegex::Parser;
use Pegex::vCard::Grammar;
use Pegex::vCard::Data;

sub parse {
    my ($self, $input) = @_;

    return Pegex::Parser->new(
        grammar => Pegex::vCard::Grammar->new,
        receiver => Pegex::vCard::Data->new,
        # debug => 1,
    )->parse($input);
}

1;
