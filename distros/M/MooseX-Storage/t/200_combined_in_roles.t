use strict;
use warnings;
use Test::More tests => 1;
use Test::Fatal;

{
    package ClassOne;
    use Moose::Role;
    use MooseX::Storage;
}
{
    package ClassTwo;
    use Moose::Role;
    use MooseX::Storage;
}

is( exception {
    package CombineClasses;
    use Moose;
    with qw/ClassOne ClassTwo/;
}, undef, 'Can include two roles which both use MooseX::Storage');
