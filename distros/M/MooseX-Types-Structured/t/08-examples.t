use strict;
use warnings;
use Test::More;
use Test::Needs 'MooseX::Types::DateTime';
plan tests => 10;

{
    ## Normalize a HashRef
    package Test::MooseX::Meta::TypeConstraint::Structured::Examples::Normalize;

    use Moose;
    use DateTime;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::DateTime qw(DateTime);
    use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef);
    use MooseX::Types -declare => [qw(
        Name Age Person FullName

    )];

    ## So that our test works, we'll set Now to 2008.
    sub Now {
        return 'DateTime'->new(year=>2008);
    }

    subtype FullName,
     as Dict[last=>Str, first=>Str];

    subtype Person,
     as Dict[name=>Str, age=>Int];

    coerce Person,
     from Dict[first=>Str, last=>Str, years=>Int],
     via { +{
        name => "$_->{first} $_->{last}",
        age=>$_->{years},
     }},
     from Dict[fullname=>FullName, dob=>DateTime],
     via { +{
        name => "$_->{fullname}{first} $_->{fullname}{last}",
        age => ($_->{dob} - Now)->years,
     }};

    has person => (is=>'rw', isa=>Person, coerce=>1);
}

NORMALIZE: {
    ok my $normalize = Test::MooseX::Meta::TypeConstraint::Structured::Examples::Normalize->new();
    isa_ok $normalize, 'Test::MooseX::Meta::TypeConstraint::Structured::Examples::Normalize';

    ok $normalize->person({name=>'John', age=>25})
     => 'Set value';

    is_deeply $normalize->person, {name=>'John', age=>25}
     => 'Value is correct';

    ok $normalize->person({first=>'John', last=>'Napiorkowski', years=>35})
     => 'Set value';

    is_deeply $normalize->person, {name=>'John Napiorkowski', age=>35}
     => 'Value is correct';

    ok $normalize->person({years=>36, last=>'Napiorkowski', first=>'John'})
     => 'Set value';

    is_deeply $normalize->person, {name=>'John Napiorkowski', age=>36}
     => 'Value is correct';

    ok $normalize->person({fullname=>{first=>'Vanessa', last=>'Li'}, dob=>DateTime->new(year=>1974)})
     => 'Set value';

    is_deeply $normalize->person, {name=>'Vanessa Li', age=>34}
     => 'Value is correct';
}
