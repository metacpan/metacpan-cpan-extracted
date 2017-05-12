use strict;
use warnings;

use Test::More;

do {
    package TestPackage;
    use syntax 'method';
    method multiply ($n, $m) { $n * $m }
    method build { method { 23 } }
};

is(TestPackage->multiply(3, 4), 12, 'keyword works');

my $built = TestPackage->build;
is($built->(), 23, 'anonymous method works');

do {
    package TestRename;
    use syntax method => { -as => 'met' };
    met foo { $self }
};

is(TestRename->foo, 'TestRename', 'renamed method keyword works');

do {
    package TestChangedInvocant;
    use syntax 'method';
    use syntax method => { -as => 'classmethod', -invocant => '$class' };
    classmethod foo { $class }
    method bar { $self }
};

is(TestChangedInvocant->foo, 'TestChangedInvocant', 'invocant change works');
is(TestChangedInvocant->bar, 'TestChangedInvocant', 'separate import works');

done_testing;
