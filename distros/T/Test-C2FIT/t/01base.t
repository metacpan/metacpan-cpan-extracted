use Test::More tests => 35;
# use Test::More qw(no_plan);

## check loading

use_ok('Test::C2FIT');
use_ok('Test::C2FIT::Parse');
use_ok('Test::C2FIT::Fixture');
use_ok('Test::C2FIT::PrimitiveFixture');
use_ok('Test::C2FIT::ActionFixture');
use_ok('Test::C2FIT::TimedActionFixture');
use_ok('Test::C2FIT::ColumnFixture');
use_ok('Test::C2FIT::RowFixture');
use_ok('Test::C2FIT::TypeAdapter');
use_ok('Test::C2FIT::GenericAdapter');
use_ok('Test::C2FIT::GenericArrayAdapter');
use_ok('Test::C2FIT::ScientificDouble');
use_ok('Test::C2FIT::ScientificDoubleTypeAdapter');
use_ok('Test::C2FIT::FileRunner');
use_ok('Test::C2FIT::WikiRunner');

## check main (public) methods

can_ok('Test::C2FIT',qw(file_runner wiki_runner fit_shell));
can_ok('Test::C2FIT::Parse',qw(new from at last leaf asString leader body tag parts end more trailer print));
can_ok('Test::C2FIT::Fixture',
    qw(doTables doTable doRows doRow doCells doCell right wrong ignore error info exception camel check),
    qw(suggestFieldType suggestMethodResultType suggestMethodParamType));
can_ok('Test::C2FIT::PrimitiveFixture','checkValue');
can_ok('Test::C2FIT::ColumnFixture',qw(reset execute));
# can_ok('Test::C2FIT::RowFixture','query');
can_ok('Test::C2FIT::TypeAdapter',qw(get set invoke parse equals toString));
can_ok('Test::C2FIT::GenericAdapter',qw(get set invoke parse equals toString));
can_ok('Test::C2FIT::GenericArrayAdapter',qw(get set invoke parse equals toString));
can_ok('Test::C2FIT::ActionFixture',qw(do_start do_enter do_press do_check));
can_ok('Test::C2FIT::TimedActionFixture',qw(do_start do_enter do_press do_check));
can_ok('Test::C2FIT::ScientificDouble',qw(equals toString));
can_ok('Test::C2FIT::ScientificDoubleTypeAdapter',qw(get set invoke parse equals toString));
can_ok('Test::C2FIT::FileRunner','run');
can_ok('Test::C2FIT::WikiRunner','run');

## check fit (java-) to perl namespace conversion
is(Test::C2FIT::Fixture->_java2PerlFixtureName('abc'),'abc','simple');
is(Test::C2FIT::Fixture->_java2PerlFixtureName('abc.def'),'abc::def','one level');
is(Test::C2FIT::Fixture->_java2PerlFixtureName('abc.def.ghi'),'abc::def::ghi','two levels level');

is(Test::C2FIT::Fixture->_java2PerlFixtureName('fit.Abc'),'Test::C2FIT::Abc','a fit class');
is(Test::C2FIT::Fixture->_java2PerlFixtureName('fat.Abc'),'Test::C2FIT::fat::Abc','a fat class');
is(Test::C2FIT::Fixture->_java2PerlFixtureName('eg.Abc'), 'Test::C2FIT::eg::Abc','a eg class');


