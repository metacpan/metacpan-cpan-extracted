# perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POOF-DataType.t'

#########################
use Test::More;
BEGIN
{
    plan tests => 20;
};
use_ok(qw(POOF::DataType));

#########################

# testing the integer type
my $integer = POOF::DataType->new({'type' => 'integer'});

ok((defined $integer && ref($integer) eq 'POOF::DataType'
    ? 1
    : 0), 'Checking that we got a valid object instance of type integer'); 

ok(($integer->value == 0
    ? 1
    : 0 ), 'Checking that the default value is [O] as it should');

ok(($integer->default(55)
    ? 1
    : 0 ), 'Changing default value to [55]');

ok(($integer->value == 55
    ? 1
    : 0 ), 'Making sure the default value is in fact [55]'); 

ok(($integer->value(100)
    ? 1
    : 0 ), 'Setting the value to [100]');

ok(($integer->value == 100
    ? 1
    : 0 ), 'Checking that the value is [100]');

ok(($integer->value('something bad')
    ? 1
    : 0 ), 'Setting the value to [some illegal] value'); 

ok(($integer->value == 100
    ? 1
    : 0 ), 'Checking that the value is still [100]' );

ok(($integer->pErrors == 1
    ? 1
    : 0 ), 'Checking that an error was registered correctly');

eval { $integer->_getValue('value') };
ok((
    $@
        ? 1
        : 0 ), 'Making sure that private methods are private');


# testing the float type
my $float = POOF::DataType->new({'type' => 'float'});

ok((defined $float && ref($float) eq 'POOF::DataType'
    ? 1
    : 0), 'Checking that we got a valid object instance of type float'); 

ok(($float->value == 0
    ? 1 
    : 0 ), 'Checking that the default value is [0] and value = [' . $float->value . ']');


# testing the boolean
my $boolean = POOF::DataType->new({'type' => 'boolean'});

ok((defined $boolean  && ref($boolean ) eq 'POOF::DataType'
    ? 1
    : 0), 'Checking that we got a valid object instance of type boolean');

ok(($boolean->value == 0
    ? 1
    : 0 ), 'Checking that the default value is 0 and value = [' . $float->value . ']');  

ok(($boolean->default(1)
    ? 1
    : 0 ), 'Changing default value to [1]'); 

ok(($boolean->value == 1
    ? 1
    : 0 ), 'Making sure the default value is in fact [1]');   

ok(($boolean->value(2)
    ? 1
    : 0 ), 'Setting the value to some illegal value [2]'); 

ok(($boolean->value == 1
    ? 1
    : 0 ), 'Checking that the value is still [1]' );

ok(($boolean->pErrors == 1
    ? 1
    : 0 ), 'Checking that an error was registered correctly [' . $boolean->pErrors . ']');





