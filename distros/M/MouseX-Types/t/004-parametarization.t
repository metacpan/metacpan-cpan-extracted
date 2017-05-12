use strict;
use warnings;
use Test::More tests => 16;

use MouseX::Types::Mouse qw(ArrayRef HashRef Maybe Str);

my $t = ArrayRef[Str];

ok ref $t, "ArrayRef[Str]";
ok $t->is_a_type_of(ArrayRef);
ok $t->check([qw(Foo)]);
ok!$t->check([ [] ]);

$t = HashRef[Str];
ok ref $t, "HashRef[Str]";
ok $t->is_a_type_of(HashRef);
ok $t->check({foo => "bar"});
ok!$t->check({foo => {} });

$t = Maybe[Str];
ok ref $t, "Maybe[Str]";
ok $t->is_a_type_of(Maybe);
ok $t->check("foo");
ok $t->check(undef);
ok!$t->check({});

eval {
    $t = Str[Str];
};
ok $@;

eval {
    $t = ArrayRef([Str, Str]);
};

ok $@;

eval q{
    package Class;
    use Mouse;
    use MouseX::Types::Mouse qw(ArrayRef Str);

    has foo => (
        is => 'rw',
        isa => ArrayRef[Str],

        required => 1,
    );
};

is $@, '';

