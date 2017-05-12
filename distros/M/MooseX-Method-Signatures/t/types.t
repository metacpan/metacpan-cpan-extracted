use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;

{
    package MyTypes;
    use MooseX::Types::Moose qw/Str/;
    use MooseX::Types -declare => [qw/CustomType/];

    BEGIN {
        subtype CustomType,
            as Str,
            where { length($_) == 2 };
    }
}

{
    package TestClass;
    use MooseX::Method::Signatures;
    BEGIN { MyTypes->import('CustomType') };
    use MooseX::Types::Moose qw/ArrayRef/;
    use namespace::clean 0.19;

    method foo (CustomType $bar) { }

    method bar (ArrayRef[CustomType] $baz) { }
}

my $o = bless {} => 'TestClass';

is(exception { $o->foo('42') }, undef);
ok(exception { $o->foo('bar') });

is(exception { $o->bar(['42', '23']) }, undef);
ok(exception { $o->bar(['foo', 'bar']) });
