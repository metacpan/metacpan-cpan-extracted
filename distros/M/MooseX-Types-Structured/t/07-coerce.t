use strict;
use warnings;
use Test::More tests=>16;

{
    package Test::MooseX::Meta::TypeConstraint::Structured::Coerce;

    use Moose;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef);
    use MooseX::Types -declare => [qw(
        myDict myTuple Fullname

    )];

    subtype myDict,
     as Dict[name=>Str, age=>Int];

    subtype Fullname,
     as Dict[first=>Str, last=>Str];

    coerce Fullname,
     from ArrayRef,
     via { +{first=>$_->[0], last=>$_->[1]} };

    subtype myTuple,
     as Tuple[Str, Int];

    ## Create some coercions.  Note the dob_epoch could be a more useful convert
    ## from a dob datetime object, I'm just lazy.

    coerce myDict,
     from Int,
     via { +{name=>'JohnDoe', age=>$_} },
     from Dict[aname=>HashRef, dob_in_years=>Int],
     via { +{
        name=> $_->{aname}->{first} .' '. $_->{aname}->{last},
        age=>$_->{dob_in_years},
        }
     },
     from Dict[bname=>HashRef, dob_in_years=>Int],
     via { +{
        name=> $_->{bname}->{first} .' '. $_->{bname}->{last},
        age=>$_->{dob_in_years},
        }
     },
     from Dict[fullname=>Fullname, dob_epoch=>Int],
     via { +{
        name=> $_->{fullname}->{first} .' '. $_->{fullname}->{last},
        age=>$_->{dob_epoch}}
     },
     from myTuple,
     via { +{name=>$_->[0], age=>$_->[1]} };

    has 'stuff' => (is=>'rw', isa=>myDict, coerce=>1);
}

## Create an object to test

ok my $person = Test::MooseX::Meta::TypeConstraint::Structured::Coerce->new();
isa_ok $person, 'Test::MooseX::Meta::TypeConstraint::Structured::Coerce';## Try out the coercions

ok $person->stuff({name=>"John",age=>25}), 'Set Stuff {name=>"John",age=>25}';
is_deeply $person->stuff, {name=>"John",age=>25}, 'Correct set';

ok $person->stuff(30), 'Set Stuff 30';
is_deeply $person->stuff, {name=>"JohnDoe",age=>30}, 'Correct set';

ok $person->stuff({aname=>{first=>"frank", last=>"herbert"},dob_in_years=>80}),
 '{{first=>"frank", last=>"herbert"},80}';

is_deeply $person->stuff, {name=>"frank herbert",age=>80}, 'Correct set';

ok $person->stuff({bname=>{first=>"frankbbb", last=>"herbert"},dob_in_years=>84}),
 '{{first=>"frankbbb", last=>"herbert"},84}';

is_deeply $person->stuff, {name=>"frankbbb herbert",age=>84}, 'Correct set';

ok $person->stuff(["mary",40]), 'Set Stuff ["mary",40]';
is_deeply $person->stuff, {name=>"mary",age=>40}, 'Correct set';

ok $person->stuff({fullname=>{first=>"frank", last=>"herbert1"},dob_epoch=>85}),
 '{{first=>"frank", last=>"herbert1"},85}';

is_deeply $person->stuff, {name=>"frank herbert1",age=>85}, 'Correct set';

SKIP: {
    skip 'deep coercions not yet supported', 2, 1;

    ok $person->stuff({fullname=>["frank", "herbert2"],dob_epoch=>86}),
     '{fullname=>["frank", "herbert2"],dob_epoch=>86}';

    is_deeply $person->stuff, {name=>"frank herbert2",age=>86}, 'Correct set';
}


