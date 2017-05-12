use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    use overload q{""} => sub { shift->stringify }, fallback => 1;

    has class_att => (isa => 'Str', is => 'rw');
    sub stringify { 'from class' }
}
{
    package TestClass::Baby;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    extends 'TestClass';

    #use overload q{""} => sub { shift->stringify }, fallback => 1;

    has baby_class_att => (isa => 'Str', is => 'rw');
    #sub stringify { 'from class' }
}

use Test::More 0.92;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

check_sugar_removed_ok('TestClass');
check_sugar_removed_ok('TestClass::Baby');

my $T = make_and_check('TestClass');

my $t = make_and_check(
    'TestClass::Baby',
    undef,
    [ qw{ class_att baby_class_att } ],
);

check_overloads($T, '""', 'from class');
check_overloads($t, '""', 'from class');

done_testing;

