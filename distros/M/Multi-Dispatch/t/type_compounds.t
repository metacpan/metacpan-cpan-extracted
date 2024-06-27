use 5.022;
use warnings;
use strict;

use Test::More;

BEGIN {
    if (! eval {require Types::Standard}) {
        plan skip_all => 'Test required Types::Standard module';
        exit;
    }
    else {
        Types::Standard->import(':all');
    }
}

use Multi::Dispatch;


BEGIN { package MyClass;    sub bar {} }
BEGIN { package MyDerClass; our @ISA = 'MyClass'; sub bar {} }


note 'Subtypes are preferred to subclasses';

multi foo( $desc,  Ref     $x :where(MyDerClass)  )  { is 'R/D', $desc => 'R/D'; }
multi foo( $desc,  MyClass $x :where(Ref['HASH']) )  { is 'B/H', $desc => 'B/H'; }

foo( 'B/H',  bless {}, 'MyDerClass' );


note 'Subtypes are not preferred to subclasses that are expressed as types';

multi bar( $desc,  Ref     $x :where(InstanceOf['MyDerClass'])  )  { is 'R/D', $desc => 'R/D'; }
multi bar( $desc,  InstanceOf['MyClass'] $x :where(Ref['HASH']) )  { is 'B/H', $desc => 'B/H'; }

bar( 'R/D',  bless {}, 'MyDerClass' );


note 'Ambiguous specifiers are treated as typenames, rather than classnames';

BEGIN { package Value; sub val {} }

multi baz( $desc, Value $v)  { is 'not an object', $desc => 'Dispatched as an unblessed value' }

           baz( 'not an object',           'Value' );
ok !eval { baz( 'not an object', bless {}, 'Value' ); }  => 'Did not dispatch Value object';


note 'Ambiguous specifiers can be disambiguated with ::';

multi qux( $desc, Value:: $v)  { is 'an object', $desc => 'Dispatched as a Value object' }

           qux( 'an object', bless {}, 'Value' );
ok !eval { qux( 'an object',           'Value' ); }  => 'Did not dispatch as a literal value';

done_testing();

