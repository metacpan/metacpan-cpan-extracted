package Pegex::CPAN::Packages;
our $VERSION = '0.05';

use Pegex::Base;

use Pegex::Parser;
use Pegex::CPAN::Packages::Grammar;
use Pegex::CPAN::Packages::Data;

sub parse {
    my ($self, $input) = @_;

    return Pegex::Parser->new(
        grammar => Pegex::CPAN::Packages::Grammar->new,
        receiver => Pegex::CPAN::Packages::Data->new,
        # debug => 1,
    )->parse($input);
}

1;
