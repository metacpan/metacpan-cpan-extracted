use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    use overload q{""} => sub { shift->stringify }, fallback => 1;

    has class_att => (isa => 'Str', is => 'rw');
    sub stringify { 'from class' }

    {
        # CMOP/Moose will successfully find this as a method
        no strict 'refs';
        *{"gen3"} = sub { 'gen3 called' };
    }
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

check_methods($t, 'gen1');
check_methods($t, 'gen3');

# this should also be found as a method, no tinkering necessary
sub TestClass::gen1 { 'gen1 called' }

{
    # CMOP/Moose will not find this as a method.

    check_no_methods($t, 'gen2');

    no strict 'refs';
    *{"TestClass" . '::' . "gen2"} = sub { 'gen2 called' };

    check_no_methods($t, 'gen2');
    TestClass->meta->mark_as_method('gen2');
    check_methods($t, 'gen2');
}

done_testing;

