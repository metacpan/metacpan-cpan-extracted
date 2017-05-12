use strict;
use warnings;

{
    package TestRole;

    use Moose::Role;
    use MooseX::MarkAsMethods autoclean => 1;

    use overload q{""} => sub { shift->stringify }, fallback => 1;
    sub stringify { 'from role' }

    has role_att => (isa => 'Str', is => 'rw');
}
{
    package TestClass;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    with 'TestRole';

    #sub stringify { 'gotcha!' }
    has class_att => (isa => 'Str', is => 'rw');
}

use Test::More 0.92; #tests => XX;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

check_sugar_removed_ok('TestClass');
check_sugar_removed_ok('TestRole');

my $t = make_and_check(
    'TestClass',
    [ 'TestRole' ],
    [ qw{ role_att class_att } ],
);

check_overloads($t, '""' => 'from role');

done_testing;

