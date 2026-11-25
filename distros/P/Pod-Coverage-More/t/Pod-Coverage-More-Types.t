#!perl

use 5.036;
use warnings FATAL => q{all};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use Pod::Coverage::More::Types qw{type_of_value type_of_usage type_named};

# The name of a constraint, or a dash when there is none, so a failure shows both sides as text.
sub name_of {
    my ($type) = @_;
    return defined $type ? $type->display_name : q{-};
}

subtest type_of_value => sub {
    is( name_of( type_of_value( { type => 'number', value => 5 } ) ),                                   'Int',                                                     "a whole number is an Int" );
    is( name_of( type_of_value( { type => 'number', value => -5 } ) ),                                  'Int',                                                     "so is a negative one" );
    is( name_of( type_of_value( { type => 'number', value => 2.5 } ) ),                                 'Num',                                                     "a fraction is a Num" );
    is( name_of( type_of_value( { type => 'number' } ) ),                                               'Num',                                                     "a number of unknown value is a Num" );
    is( name_of( type_of_value( { type => 'number', integer => 1 } ) ),                                 'Int',                                                     "a number that is whole by its op is an Int" );
    is( name_of( type_of_value( { type => 'number', integer => 1, maybe_undef => 1 } ) ),               'Maybe[Int]',                                              "a whole number that can be undef is a Maybe[Int]" );
    is( name_of( type_of_value( { type => 'object', classes => [qw{Math::BigInt Math::BigFloat}] } ) ), 'InstanceOf["Math::BigInt"]|InstanceOf["Math::BigFloat"]', "an object of one of several classes" );
    is( name_of( type_of_value( { type => 'string', value => 'x' } ) ),                                 'Str',                                                     "a string is a Str" );
    is( name_of( type_of_value( { type => 'boolean' } ) ),                                              'Bool',                                                    "a comparison is a Bool" );
    is( name_of( type_of_value( { type => 'empty' } ) ),                                                'Undef',                                                   "an empty return is undef to a caller that wants one value" );
    is( name_of( type_of_value( { type => 'hashref' } ) ),                                              'HashRef',                                                 "a hash reference" );
    is( name_of( type_of_value( { type => 'object', class => 'Foo' } ) ),                               'InstanceOf["Foo"]',                                       "an object of a known class" );
    is( name_of( type_of_value( { type => 'object', class => undef } ) ),                               'Object',                                                  "an object of a class known only at run time" );
    is( name_of( type_of_value( { type => 'variable', name => '$x' } ) ),                               q{-},                                                      "a variable says nothing by itself" );
    is( name_of( type_of_value( { type => 'call' } ) ),                                                 q{-},                                                      "nor does a call" );
};

subtest type_of_usage => sub {
    is( name_of( type_of_usage( {} ) ),                                 q{-},                      "no use says nothing" );
    is( name_of( type_of_usage( { hashref => 1 } ) ),                   'HashRef',                 "dereferenced as a hash" );
    is( name_of( type_of_usage( { numeric => 1 } ) ),                   'Num',                     "used as a number" );
    is( name_of( type_of_usage( { numeric => 1, string => 1 } ) ),      'Str',                     "used as a number and as a string is a string" );
    is( name_of( type_of_usage( { hashref => 1, arrayref => 1 } ) ),    'HashRef|ArrayRef',        "two kinds of reference are alternatives" );
    is( name_of( type_of_usage( { methods => [qw{a b}] } ) ),           'HasMethods["a","b"]',     "methods called on it" );
    is( name_of( type_of_usage( { hashref => 1, methods => ['a'] } ) ), 'HashRef&HasMethods["a"]', "a hash reference that methods are called on" );
};

subtest type_named => sub {
    is( name_of( type_named('HASHREF') ),                           'HashRef',       "a POD type word, in upper case" );
    is( name_of( type_named('integer') ),                           'Int',           "or in lower case" );
    is( name_of( type_named('MIXED') ),                             'Any',           "MIXED takes anything" );
    is( name_of( type_named('ARRAY') ),                             'ArrayRef',      "a container word names a reference to one" );
    is( name_of( type_named('ArrayRef[Int]') ),                     'ArrayRef[Int]', "a Types::Standard expression" );
    is( name_of( type_named('NoSuchType') ),                        q{-},            "a name that no library has" );
    is( name_of( type_named(undef) ),                               q{-},            "no name" );
    is( name_of( type_named('fail2ban reads C<%> as a variable') ), q{-},            "prose with a % in it names no type, and warns of nothing" );
};

done_testing;
