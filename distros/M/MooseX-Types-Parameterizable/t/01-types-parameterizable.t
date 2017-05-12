
use Test::More tests=>79; {
    
    use strict;
    use warnings;
    
    use MooseX::Types::Parameterizable qw(Parameterizable);
    use MooseX::Types::Moose qw(Int Any Maybe);
    use Moose::Util::TypeConstraints;
    
    use MooseX::Types -declare=>[qw(SubParameterizable IntLessThan EvenInt
        LessThan100GreatThen5andEvenIntNot44 IntNot54
        GreatThen5andEvenIntNot54or64)];
    
    ok Parameterizable->check(1),
      'Parameterizable is basically an "Any"';
      
    is Parameterizable->validate(1), undef,
      'No Error Message';
      
    is Parameterizable->parent, 'Any',
      'Parameterizable is an Any';
      
    is Parameterizable->name, 'MooseX::Types::Parameterizable::Parameterizable',
      'Parameterizable has expected name';
      
    like Parameterizable->get_message,
      qr/Validation failed for 'MooseX::Types::Parameterizable::Parameterizable' with value undef/,
      'Got Expected Message';
      
    ok Parameterizable->equals(Parameterizable),
      'Parameterizable equal Parameterizable';
      
    ok Parameterizable->is_a_type_of(Parameterizable),
      'Parameterizable is_a_type_of Parameterizable';
      
    ok Parameterizable->is_a_type_of('Any'),
      'Parameterizable is_a_type_of Any';
      
    ok Parameterizable->is_subtype_of('Any'),
      'Parameterizable is_subtype_of Parameterizable';

    is Parameterizable->parent_type_constraint, 'Any',
      'Correct parent type';

    is subtype( SubParameterizable, as Parameterizable ),
      'main::SubParameterizable',
      'Create a useless subtype';

    ok SubParameterizable->check(1),
      'SubParameterizable is basically an "Any"';
      
    is SubParameterizable->validate(1), undef,
      'validate returned no error message';

    is SubParameterizable->parent, 'MooseX::Types::Parameterizable::Parameterizable',
      'SubParameterizable is a Parameterizable';
      
    is SubParameterizable->name, 'main::SubParameterizable',
      'Parameterizable has expected name';
      
    like SubParameterizable->get_message,
      qr/Validation failed for 'main::SubParameterizable' with value undef/,
      'Got Expected Message';
      
    ok SubParameterizable->equals(SubParameterizable),
      'SubParameterizable equal SubParameterizable';
      
    ok !SubParameterizable->equals(Parameterizable),
      'SubParameterizable does not equal Parameterizable';
      
    ok SubParameterizable->is_a_type_of(Parameterizable),
      'SubParameterizable is_a_type_of Parameterizable';
      
    ok SubParameterizable->is_a_type_of(Any),
      'SubParameterizable is_a_type_of Any';
      
    ok SubParameterizable->is_subtype_of('Any'),
      'SubParameterizable is_subtype_of Parameterizable';
      
    ok !SubParameterizable->is_subtype_of(SubParameterizable),
      'SubParameterizable is not is_subtype_of SubParameterizable';
    
    ok subtype( EvenInt,
        as Int,
        where {
            my $val = shift @_;
            return $val % 2 ? 0:1;
        }),
      'Created a subtype of Int';

    ok !EvenInt->check('aaa'), '"aaa" not an Int';      
    ok !EvenInt->check(1), '1 is not even';
    ok EvenInt->check(2), 'but 2 is!';
      
    ok subtype( IntLessThan,
        as Parameterizable[EvenInt, Maybe[Int]],
        where {
            my $value = shift @_;
            my $constraining = shift @_ || 200;
            return ($value < $constraining && $value > 5);
        }),
      'Created IntLessThan subtype';
      
    ok !IntLessThan->check('aaa'),
      '"aaa" is not an integer';
      
    like IntLessThan->validate('aaa'),
      qr/Validation failed for 'main::EvenInt' with value .*aaa.*/,
      'Got expected error messge for "aaa"';
      
    ok !IntLessThan->check(1),
      '1 smaller than 5';

    ok !IntLessThan->check(2),
      '2 smaller than 5';
      
    ok !IntLessThan->check(15),
      '15 greater than 5 (but odd)';

    ok !IntLessThan->check(301),
      '301 is too big';
      
    ok !IntLessThan->check(400),
      '400 is too big';
      
    ok IntLessThan->check(10),
      '10 greater than 5 (and even)';
      
    like IntLessThan->validate(1),
      qr/Validation failed for 'main::EvenInt' with value 1/,
      'error message is correct';
      
    is IntLessThan->name, 'main::IntLessThan',
      'Got correct name for IntLessThan';
    
    is IntLessThan->parent, 'MooseX::Types::Parameterizable::Parameterizable[main::EvenInt, Maybe[Int]]',
      'IntLessThan is a Parameterizable';
      
    is IntLessThan->parent_type_constraint, EvenInt,
      'Parent is an Int';
      
    is IntLessThan->constraining_value_type_constraint, (Maybe[Int]),
      'constraining is an Int';
      
    ok IntLessThan->equals(IntLessThan),
      'IntLessThan equals IntLessThan';

    ok IntLessThan->is_subtype_of(Parameterizable),
      'IntLessThan is_subtype_of Parameterizable';      

    ok IntLessThan->is_subtype_of(Int),
      'IntLessThan is_subtype_of Int';

    ok IntLessThan->is_a_type_of(Parameterizable),
      'IntLessThan is_a_type_of Parameterizable';      

    ok IntLessThan->is_a_type_of(Int),
      'IntLessThan is_a_type_of Int';

    ok IntLessThan->is_a_type_of(IntLessThan),
      'IntLessThan is_a_type_of IntLessThan';
      
    ok( (my $lessThan100GreatThen5andEvenInt = IntLessThan[100]),
       'Parameterized!');
    
    ok !$lessThan100GreatThen5andEvenInt->check(150),
      '150 Not less than 100';
      
    ok !$lessThan100GreatThen5andEvenInt->check(151),
      '151 Not less than 100';
      
    ok !$lessThan100GreatThen5andEvenInt->check(2),
      'Not greater than 5';

    ok !$lessThan100GreatThen5andEvenInt->check(51),
      'Not even';

    ok !$lessThan100GreatThen5andEvenInt->check('aaa'),
      'Not Int';
      
    ok $lessThan100GreatThen5andEvenInt->check(42),
      'is Int, is even, greater than 5, less than 100';

    ok subtype( LessThan100GreatThen5andEvenIntNot44,
        as IntLessThan[100],
        where {
            my $value = shift @_;
            return $value != 44;
        }),
      'Created LessThan100GreatThen5andEvenIntNot44 subtype';

    ok !LessThan100GreatThen5andEvenIntNot44->check(150),
      '150 Not less than 100';
      
    ok !LessThan100GreatThen5andEvenIntNot44->check(300),
      '300 Not less than 100 (check to make sure we are not defaulting 200)';
      
    ok !LessThan100GreatThen5andEvenIntNot44->check(151),
      '151 Not less than 100';
      
    ok !LessThan100GreatThen5andEvenIntNot44->check(2),
      'Not greater than 5';

    ok !LessThan100GreatThen5andEvenIntNot44->check(51),
      'Not even';

    ok !LessThan100GreatThen5andEvenIntNot44->check('aaa'),
      'Not Int';
      
    ok LessThan100GreatThen5andEvenIntNot44->check(42),
      'is Int, is even, greater than 5, less than 100';

    ok !LessThan100GreatThen5andEvenIntNot44->check(44),
      'is Int, is even, greater than 5, less than 100 BUT 44!';
      
    ok subtype( IntNot54,
        as Maybe[Int],
        where {
            my $val = shift @_ || 200;
            return $val != 54
        }),
      'Created a subtype of Int';
      
    ok IntNot54->check(100), 'Not 54';
    ok !IntNot54->check(54), '54!!';
    
    ok( subtype( GreatThen5andEvenIntNot54or64,
        as IntLessThan[IntNot54],
        where {
            my $value = shift @_;
            return $value != 64;
        }),
      'Created GreatThen5andEvenIntNot54or64 subtype');
      
    is( (GreatThen5andEvenIntNot54or64->name),
       'main::GreatThen5andEvenIntNot54or64',
       'got expected name');
    
    ok GreatThen5andEvenIntNot54or64->check(150),
        '150 is even, less than 200, not 54 or 64 but > 5';

    ok !GreatThen5andEvenIntNot54or64->check(202),
        '202 is even, exceeds 200, not 54 or 64 but > 5';
        
    is( ((GreatThen5andEvenIntNot54or64[100])->name),
      'main::GreatThen5andEvenIntNot54or64[100]',
      'got expected name');
      
    ok !GreatThen5andEvenIntNot54or64([100])->check(150),
      '150 Not less than 100';
      
    ok !GreatThen5andEvenIntNot54or64([100])->check(300),
      '300 Not less than 100 (check to make sure we are not defaulting 200)';
      
    ok !GreatThen5andEvenIntNot54or64([100])->check(151),
      '151 Not less than 100';
      
    ok !GreatThen5andEvenIntNot54or64([100])->check(2),
      'Not greater than 5';

    ok !GreatThen5andEvenIntNot54or64([100])->check(51),
      'Not even';

    ok !GreatThen5andEvenIntNot54or64([100])->check('aaa'),
      'Not Int';
      
    ok GreatThen5andEvenIntNot54or64([100])->check(42),
      'is Int, is even, greater than 5, less than 100';
      
    ok !GreatThen5andEvenIntNot54or64([100])->check(64),
      'is Int, is even, greater than 5, less than 100 BUT 64!';
    
    CHECKPARAM: {
        eval { GreatThen5andEvenIntNot54or64([54])->check(32) };
        like $@,
          qr/Validation failed for 'main::IntNot54' with value 54/,
          'Got Expected Error';    
    }
}
