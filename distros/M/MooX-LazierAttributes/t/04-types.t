use Test::More;

BEGIN {
    eval {
	    require Moo;
        require Type::Tiny;
        1;
    } or do {
        plan skip_all => "Cannot require Moo or Type::Tiny";
    };
}

use t::odea::BasicTypes;
use lib '.';

my $basics = t::odea::BasicTypes->new;

ok($basics->thing('okay'));
is($basics->thing, 'okay');

eval { $basics->thing({ ohhh => 'noooo' }) };
my $error = $@;
my $expected_error = 'Reference {"ohhh" => "noooo"} did not pass type constraint "Str" (in $self->{"thing"})';
is($error->message, $expected_error, "caugt an error - ${expected_error}");

is_deeply($basics->sorry, { one => 'two' }, "we have a set hashref");
is_deeply($basics->okay, { one => 'two' }, "we have a set hashref");

ok($basics->sorry({ three => 'four' }, "set sorry"));
ok($basics->okay({ three => 'four' }, "set sorry"));

is_deeply($basics->sorry, { three => 'four' }, "sorry was set");
is_deeply($basics->okay, { three => 'four' }, "okay was set");

is_deeply($basics->another, { }, "lazy hash");

isa_ok($basics->object, 'Thing');

done_testing();
