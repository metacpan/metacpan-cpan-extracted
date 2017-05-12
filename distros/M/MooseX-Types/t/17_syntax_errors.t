use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# remove this when CheckedUtilExports croaks instead of carps
$SIG{__WARN__} = sub { die @_ };

my $missing_comma_test = q{
    package TypeLib1;

    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Str';

    subtype Foo #,
        as Str,
        where { /foo/ },
        message { 'not a Foo' };

    1;
};

eval $missing_comma_test;
like $@, qr/forget a comma/, 'missing comma error';

my $string_as_type_test = q{
    package TypeLib2;

    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Str';

    subtype Foo => # should be ,
        as Str,
        where { /foo/ },
        message { 'not a Foo' };

    1;
};

eval $string_as_type_test;
like $@, qr/String found where Type expected/, 'string instead of Type error';

my $fully_qualified_type = q{
    package TypeLib3;

    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Str';

    subtype TypeLib3::Foo =>
        as Str,
        where { /foo/ },
        message { 'not a Foo' };

    1;
};

eval $fully_qualified_type;
is $@, '', "fully qualified type doesn't throw error";

my $class_type = q{
    package TypeLib4;

    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Str';

    class_type 'mtfnpy';

    coerce mtfnpy =>
        from Str,
        via { bless \$_, 'mtfnpy' };

    1;
};
eval $class_type;
is $@, '', "declared class_types don't throw error";

my $role_type = q{
    package TypeLib5;

    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Str';

    role_type 'ypnftm';

    coerce ypnftm =>
        from Str,
        via { bless \$_, 'ypnftm' };

    1;
};
eval $role_type;
is $@, '', "declared role_types don't throw error";

done_testing();
