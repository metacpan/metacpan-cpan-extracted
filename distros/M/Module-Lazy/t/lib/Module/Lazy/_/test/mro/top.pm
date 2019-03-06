package Module::Lazy::_::test::mro::top;

use strict;
use warnings;
our $VERSION = 1;

use mro 'c3';
use Module::Lazy 'Module::Lazy::_::test::mro::left';
use Module::Lazy 'Module::Lazy::_::test::mro::right';
our @ISA = qw( Module::Lazy::_::test::mro::left Module::Lazy::_::test::mro::right );

sub frobnicate {
    my $self = shift;
    return $self->frob . $self->nicate;
};

1;
