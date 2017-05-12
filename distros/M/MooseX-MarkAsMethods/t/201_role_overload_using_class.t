use strict;
use warnings;

{
    package TestRole;

    use Moose::Role;
    use MooseX::MarkAsMethods autoclean => 1;

    use overload q{""} => sub { shift->stringify }, fallback => 1;
    #sub stringify { 'from role' }
    requires 'stringify';

    has role_att => (isa => 'Str', is => 'rw');
}
{
    package TestClass;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    with 'TestRole';

    sub stringify { 'from class' }
    has class_att => (isa => 'Str', is => 'rw');
}

use Test::More 0.92; #tests => XX;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

check_sugar_removed_ok('TestClass');

my $t = make_and_check(
    'TestClass',
    [ 'TestRole' ],
    [ qw{ role_att class_att } ],
);

check_overloads($t, '""' => 'from class');

done_testing;

