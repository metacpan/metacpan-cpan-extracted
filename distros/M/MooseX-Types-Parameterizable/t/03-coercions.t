
use strict;
use warnings;

use Test::More;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str HashRef ArrayRef);
use MooseX::Types -declare=>[qw(
    InfoHash OlderThanAge DefinedOlderThanAge
)];

ok subtype( InfoHash,
    as HashRef[Int],
    where {
        defined $_->{older_than};
    }), 'Created InfoHash Set (reduce need to depend on Dict type';

ok InfoHash->check({older_than=>25}), 'Good InfoHash';
ok !InfoHash->check({older_than=>'aaa'}), 'Bad InfoHash';
ok !InfoHash->check({at_least=>25}), 'Bad InfoHash';

ok subtype( OlderThanAge,
    as Parameterizable[Int, InfoHash],
    where {
        my ($value, $dict) = @_;
        return $value > $dict->{older_than} ? 1:0;
    }), 'Created the OlderThanAge subtype';

ok OlderThanAge([{older_than=>25}])->check(39), '39 is older than 25';
ok OlderThanAge([older_than=>1])->check(9), '9 is older than 1';
ok !OlderThanAge([older_than=>1])->check('aaa'), '"aaa" not an int';
ok !OlderThanAge([older_than=>10])->check(9), '9 is not older than 10';
    
coerce OlderThanAge,
    from HashRef,
    via { 
        my ($hashref, $constraining_value) = @_;
        return scalar(keys(%$hashref));
    },
    from ArrayRef,
    via { 
        my ($arrayref, $constraining_value) = @_;
        my $age;
        $age += $_ for @$arrayref;
        return $age;
    };

is OlderThanAge->name, 'main::OlderThanAge',
  'Got corect name for OlderThanAge';
is OlderThanAge([older_than=>5])->coerce([1..10]), 55,
  'Coerce works';
is OlderThanAge([older_than=>5])->coerce({a=>1,b=>2,c=>3,d=>4}), 4,
  'Coerce works';      
like OlderThanAge([older_than=>2])->name, qr/main::OlderThanAge\[/,
  'Got correct name for OlderThanAge([older_than=>2])';
is OlderThanAge([older_than=>2])->coerce({a=>5,b=>6,c=>7,d=>8}), 4,
  'Coerce works';

SKIP: {
    skip 'Type Coercions on defined types not supported yet', 1;

    subtype DefinedOlderThanAge, as OlderThanAge([older_than=>1]);
    
    coerce DefinedOlderThanAge,
        from ArrayRef,
        via {
            my ($arrayref, $constraining_value) = @_;
            my $age;
            $age += $_ for @$arrayref;
            return $age;
        };
    
    is DefinedOlderThanAge->coerce([1,2,3]), 6, 'Got expected Value';
}

done_testing;
