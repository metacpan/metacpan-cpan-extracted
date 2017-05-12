use strict;
use warnings;

use Test::More;

{
    package Test::MooseX::Types::Parameterizable::Synopsis;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(Str Int ArrayRef);
    use MooseX::Types -declare=>[qw(Varchar)];

    subtype Varchar,
      as Parameterizable[Str,Int],
      where {
        my($string, $int) = @_;
        $int >= length($string) ? 1:0;
      },
      message { "'$_[0]' is too long (max length $_[1])" };

    coerce Varchar,
      from ArrayRef,
      via { 
        my ($arrayref, $int) = @_;
        join('', @$arrayref);
      };

    my $varchar_five = Varchar[5];

    Test::More::ok $varchar_five->check('four');
    Test::More::ok ! $varchar_five->check('verylongstrong');

    my $varchar_ten = Varchar[10];

    Test::More::ok $varchar_ten->check( 'X' x 9 );
    Test::More::ok ! $varchar_ten->check( 'X' x 12 );

    has varchar_five => (isa=>Varchar[5], is=>'ro', coerce=>1);
    has varchar_ten => (isa=>Varchar[10], is=>'ro');
  
    my $object1 = __PACKAGE__->new(
        varchar_five => '1234',
        varchar_ten => '123456789',
    );

    eval {
        my $object2 = __PACKAGE__->new(
            varchar_five => '12345678',
            varchar_ten => '123456789',
        );
    };

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr{'12345678' is too long \(max length 5\)}, 'Correct custom error';

    my $object3 = __PACKAGE__->new(
        varchar_five => [qw/aa bb/],
        varchar_ten => '123456789',
    );

    Test::More::is $object3->varchar_five, 'aabb',
      'coercion as expected';
}

{
    package Test::MooseX::Types::Parameterizable::Description;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(HashRef Int);
    use MooseX::Types -declare=>[qw(Range RangedInt)];

    ## Minor change from docs to avoid additional test dependencies
    subtype Range,
        as HashRef[Int],
        where {
            my ($range) = @_;
            return $range->{max} > $range->{min};
        },
        message { "Not a Valid range [ $_->{max} not > $_->{min} ] " };

    subtype RangedInt,
        as Parameterizable[Int, Range],
        where {
            my ($value, $range) = @_;
            return ($value >= $range->{min} &&
             $value <= $range->{max});
        };
        
    Test::More::ok RangedInt([{min=>10,max=>100}])->check(50);
    Test::More::ok !RangedInt([{min=>50, max=>75}])->check(99);

    eval {
        Test::More::ok !RangedInt([{min=>99, max=>10}])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';

    Test::More::ok RangedInt([min=>10,max=>100])->check(50);
    Test::More::ok ! RangedInt([min=>50, max=>75])->check(99);

    eval {
        RangedInt([min=>99, max=>10])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';


}

{
    package Test::MooseX::Types::Parameterizable::Subtypes;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(HashRef Int);
    use MooseX::Types -declare=>[qw(Range RangedInt PositiveRangedInt 
        PositiveInt PositiveRange PositiveRangedInt2 )];

    ## Minor change from docs to avoid additional test dependencies
    subtype Range,
        as HashRef[Int],
        where {
            my ($range) = @_;
            return $range->{max} > $range->{min};
        },
        message { "Not a Valid range [ $_->{max} not > $_->{min} ] " };

    subtype RangedInt,
        as Parameterizable[Int, Range],
        where {
            my ($value, $range) = @_;
            return ($value >= $range->{min} &&
             $value <= $range->{max});
        };
        
    subtype PositiveRangedInt,
        as RangedInt,
        where {
            shift >= 0;              
        };

    Test::More::ok PositiveRangedInt([{min=>10,max=>100}])->check(50);
    Test::More::ok !PositiveRangedInt([{min=>50, max=>75}])->check(99);

    eval {
        Test::More::ok !PositiveRangedInt([{min=>99, max=>10}])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';

    Test::More::ok PositiveRangedInt([min=>10,max=>100])->check(50);
    Test::More::ok ! PositiveRangedInt([min=>50, max=>75])->check(99);

    eval {
        PositiveRangedInt([min=>99, max=>10])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(Not a Valid range), 'Correct custom error';

    Test::More::ok !PositiveRangedInt([{min=>-10, max=>75}])->check(-5);

    ## Subtype of Int for positive numbers
    subtype PositiveInt,
        as Int,
        where {
            my ($value, $range) = @_;
            return $value >= 0;
        };

    ## subtype Range to re-parameterize Range with subtypes.  Minor change from
    ## docs to reduce test dependencies

    subtype PositiveRange,
      as Range[PositiveInt],
      message { "[ $_->{max} not > $_->{min} ] is not a positive range " };
    
    ## create subtype via reparameterizing
    subtype PositiveRangedInt2,
        as RangedInt[PositiveRange];

    Test::More::ok PositiveRangedInt2([{min=>10,max=>100}])->check(50);
    Test::More::ok !PositiveRangedInt2([{min=>50, max=>75}])->check(99);

    eval {
        Test::More::ok !PositiveRangedInt2([{min=>99, max=>10}])->check(10); 
    }; 

    Test::More::ok $@, 'There was an error';
    Test::More::like $@, qr(not a positive range), 'Correct custom error';

    Test::More::ok !PositiveRangedInt2([{min=>10, max=>75}])->check(-5);

    ## See t/02-types-parameterizable-extended.t for remaining examples tests
}

{
    package Test::MooseX::Types::Parameterizable::Coercions;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(HashRef ArrayRef Object Str Int);
    use MooseX::Types -declare=>[qw(Varchar MySpecialVarchar )];


    subtype Varchar,
      as Parameterizable[Str, Int],
      where {
        my($string, $int) = @_;
        $int >= length($string) ? 1:0;
      },
      message { "'$_' is too long"  };


    coerce Varchar,
      from Object,
      via { "$_"; },  ## stringify the object
      from ArrayRef,
      via { join '',@$_ };  ## convert array to string

    subtype MySpecialVarchar,
      as Varchar;

    coerce MySpecialVarchar,
      from HashRef,
      via { join '', keys %$_ };


    Test::More::is Varchar([40])->coerce("abc"), 'abc';
    Test::More::is Varchar([40])->coerce([qw/d e f/]), 'def';

    Test::More::is MySpecialVarchar([40])->coerce("abc"), 'abc';
    Test::More::is_deeply( MySpecialVarchar([40])->coerce([qw/d e f/]), [qw/d e f/]);
    Test::More::is MySpecialVarchar([40])->coerce({a=>1, b=>2}), 'ab';
}

{
    package Test::MooseX::Types::Parameterizable::Recursion;

    use Moose;
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(  );
    use MooseX::Types -declare=>[qw(  )];

    ## To be done when I can think of a use case
}

done_testing;

