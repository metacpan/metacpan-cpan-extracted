
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

use Test::More 0.92;
use Test::Moose;

require 't/funcs.pm' unless eval { require funcs };

check_sugar_removed_ok('TestClass');

my $t = make_and_check(
    'TestClass',
    undef,
    [ 'class_att' ],
);

check_overloads($t, '""' => 'from class');

done_testing;

