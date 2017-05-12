
use strict;
use warnings;

{
    package TestClass;

    use Moose;
    use MooseX::MarkAsMethods autoclean => 1;

    use overload q{""} => sub { shift->stringify }, fallback => 1;

    has class_att => (isa => 'Str', is => 'rw', lazy_build => 1);
    sub _build_class_att { 'class_att value' }

    sub stringify { 'val: ' . shift->class_att }
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

check_overloads($t, '""' => 'val: class_att value');

done_testing;

__END__
