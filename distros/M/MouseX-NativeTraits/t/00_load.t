#!perl -w

use strict;
use Test::More;

require_ok 'Mouse::Meta::Attribute::Native';

require_ok 'MouseX::NativeTraits';
require_ok 'MouseX::NativeTraits::MethodProvider';

foreach my $type(qw(ArrayRef HashRef CodeRef Str Num Bool Counter)){
    my $trait = 'MouseX::NativeTraits::' . $type;

    require_ok $trait;
    require_ok $trait->method_provider_class;
}

ok( Mouse::Meta::Attribute::Native->VERSION );

diag "Testing MouseX::NativeTraits/$MouseX::NativeTraits::VERSION";
diag "Dependencies:";

require Mouse;
diag "    Mouse/$Mouse::VERSION";

done_testing;
