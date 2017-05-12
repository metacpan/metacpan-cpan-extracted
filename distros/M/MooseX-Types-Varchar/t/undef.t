use strict;
use warnings;
use Test::More tests => 1 + 1;
use Test::Exception;
use Test::NoWarnings;
{
    package MyClass;
    use Moose;
    use MooseX::Types::Varchar qw/ Varchar /;

    has 'attr1' => (is => 'ro', required => 0, isa => Varchar[20]);
    no Moose;
}

dies_ok {
        my $obj = MyClass->new( attr1 => undef );
} 'undef is not valid';
