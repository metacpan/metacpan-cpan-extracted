BEGIN {
    use strict;
    use warnings;

    use Test::More;  
    eval "use MooseX::Types::Structured qw(Tuple Dict slurpy)"; if($@) {
        plan skip_all => "MooseX::Types:Structured Required for advanced Tests";
    } else {
        eval "use Set::Scalar"; if($@) {
            plan skip_all => "Set::Scalar Required for advanced Tests";
        } else {
            plan tests => 37;
        }
    }
} 

use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str);
use Moose::Util::TypeConstraints;

use MooseX::Types -declare=>[qw(
    Set UniqueInt UniqueInSet Range RangedInt PositiveRangedInt1
    PositiveRangedInt2 PositiveInt PositiveRange NameAge NameBetween18and35Age
)];

ok class_type("Set::Scalar"), 'Created Set::Scalar class_type';
ok subtype( Set, as "Set::Scalar"), 'Created Set subtype';

ok subtype( UniqueInt,
    as Parameterizable[Int, Set],
    where {
        my ($int, $set) = @_;
        return !$set->has($int);
    }), 'Created UniqueInt Parameterizable Type';

ok( (my $set_obj = Set::Scalar->new(1,2,3,4,5)), 'Create Set Object');

ok !UniqueInt([$set_obj])->check(1), "Not OK, since one isn't unique in $set_obj";
ok !UniqueInt([$set_obj])->check('AAA'), "Not OK, since AAA is not an Int";    
ok UniqueInt([$set_obj])->check(100), "OK, since 100 isn't in the set";

ok( (my $unique = UniqueInt[$set_obj]), 'Created Anonymous typeconstraint');
ok $unique->check(10), "OK, 10 is unique";
ok !$unique->check(2), "Not OK, '2' is already in the set";

ok( subtype(UniqueInSet, as UniqueInt[$set_obj]), 'Created Subtype');
ok UniqueInSet->check(99), '99 is unique';
ok !UniqueInSet->check(3), 'Not OK, 3 is already in the set';

CHECKHARDEXCEPTION: {
    eval { UniqueInt->check(1000) };
    like $@,
      qr/Validation failed for 'main::Set' with value undef/,
      'Got Expected Error';
      
    eval { UniqueInt->validate(1000) };
    like $@,
      qr/Validation failed for 'main::Set' with value undef/,
      'Got Expected Error';          
}

subtype Range,
    as Dict[max=>Int, min=>Int],
    where {
        my ($range) = @_;
        return $range->{max} > $range->{min};
    };

subtype RangedInt,
    as Parameterizable[Int, Range],
    where {
        my ($value, $range) = @_;
        return ($value >= $range->{min} &&
         $value <= $range->{max});
    };
    
ok RangedInt([{min=>10,max=>100}])->check(50), '50 in the range';
ok !RangedInt([{min=>50, max=>75}])->check(99),'99 exceeds max';
ok !RangedInt([{min=>50, max=>75}])->check('aa'), '"aa" not even an Int';

CHECKRANGEDINT: {    
    eval {
        RangedInt([{min=>99, max=>10}])->check(10); ## Not OK, not a valid Range!    
    };
    
    like $@,
      qr/Validation failed for 'main::Range'/,
      'Got Expected Error';
}

ok RangedInt([min=>10,max=>100])->check(50), '50 in the range';
ok !RangedInt([min=>50, max=>75])->check(99),'99 exceeds max';
ok !RangedInt([min=>50, max=>75])->check('aa'), '"aa" not even an Int';

CHECKRANGEDINT2: {    
    eval {
        RangedInt([min=>99, max=>10])->check(10); ## Not OK, not a valid Range!    
    };
    
    like $@,
      qr/Validation failed for 'main::Range'/,
      'Got Expected Error';
}

subtype PositiveRangedInt1,
    as RangedInt,
    where {
        shift >= 0;    
    };

ok PositiveRangedInt1([min=>10,max=>100])->check(50), '50 in the range';
ok !PositiveRangedInt1([min=>50, max=>75])->check(99),'99 exceeds max';
ok !PositiveRangedInt1([min=>50, max=>75])->check('aa'), '"aa" not even an Int';

CHECKRANGEDINT2: {    
    eval {
        PositiveRangedInt1([min=>99, max=>10])->check(10); ## Not OK, not a valid Range!    
    };
    
    like $@,
      qr/Validation failed for 'main::Range'/,
      'Got Expected Error';
}

ok !PositiveRangedInt1([min=>-100,max=>100])->check(-10), '-10 is not positive';

subtype PositiveInt,
    as Int,
    where {
        my ($value, $range) = @_;
        return $value >= 0;
    };

## subtype Range to re-parameterize Range with subtypes
subtype PositiveRange,
    as Range[max=>PositiveInt, min=>PositiveInt];

## create subtype via reparameterizing
subtype PositiveRangedInt2,
    as RangedInt[PositiveRange];

ok PositiveRangedInt2([min=>10,max=>100])->check(50), '50 in the range';
ok !PositiveRangedInt2([min=>50, max=>75])->check(99),'99 exceeds max';
ok !PositiveRangedInt2([min=>50, max=>75])->check('aa'), '"aa" not even an Int';

CHECKRANGEDINT2: {    
    eval {
        PositiveRangedInt2([min=>-100,max=>100])->check(-10); ## Not OK, not a valid Range!    
    };
    
    like $@,
      qr/Validation failed for 'main::PositiveRange'/,
      'Got Expected Error';
}

subtype NameAge,
    as Tuple[Str, Int];

ok NameAge->check(['John',28]), 'Good NameAge';
ok !NameAge->check(['John','Napiorkowski']), 'Bad NameAge';

subtype NameBetween18and35Age,
    as NameAge[
        Str,
        PositiveRangedInt2[min=>18,max=>35],
    ];
    
ok NameBetween18and35Age->check(['John',28]), 'Good NameBetween18and35Age';
ok !NameBetween18and35Age->check(['John','Napiorkowski']), 'Bad NameBetween18and35Age';
ok !NameBetween18and35Age->check(['John',99]), 'Bad NameBetween18and35Age';

