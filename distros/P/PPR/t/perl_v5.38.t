use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

use PPR;
sub feature;

feature 'Or-assign in sub signatures'
     => q{{ sub foo ($x ||= 0) {...} }};

feature 'Or-assign in anon sub signatures'
     => q{{ sub ($x ||= 0) {...} }};

feature 'Doh-assign in sub signatures'
     => q{{ sub foo ($x //= 0) {...} }};

feature 'Doh-assign in anon sub signatures'
     => q{{ sub ($x //= 0) {...} }};


feature 'Optimistic eval in regexes'
     => q{{ qr/ \A (*{ ... }) \z/ }};


feature 'Class declarations'
     => q{{ class Foo; }};

feature 'Class declarations with version number'
     => q{{ class Foo v1.2.3; }};

feature 'Class declaration with attribute'
     => q{{ class Foo :isa(Bar); }};

feature 'Class declaration with attribute with minimal version'
     => q{{ class Foo :isa(Bar 1.2345); }};

feature 'Class blocks'
     => q{{ class Foo {} }};

feature 'Class block with attribute'
     => q{{ class Foo :isa(Bar) {} }};

feature 'Class block with version numbers'
     => q{{ class Foo 1.23456 {} }};


feature 'Field declarations'
     => q{{ field $f; }};

feature 'Field attribute'
     => q{{ field $f :param; }};

feature 'Field attribute with rename'
     => q{{ field $f :param(foo); }};

feature 'Field default initializer'
     => q{{ field $f = 0; }};

feature 'Field default doh initializer'
     => q{{ field $f //= 0; }};

feature 'Field default or initializer'
     => q{{ field $f ||= 0; }};

feature 'Field with all-of-the-above'
     => q{{ field $f :param(foo) = 0; }};

feature 'Array fields'
     => q{{ field @f; }};

feature 'Array field with initializer'
     => q{{ field @f = 1..10; }};

feature 'Hash field'
     => q{{ field %f }};

feature 'Hash field with initializer'
     => q{{ field %f = (a=>1, z=>26); }};


feature 'Methods'
     => q{{ method foo {...}  method bar {...} }};

feature 'Method with signature'
     => q{{ method foo ($x) {...}; }};

feature 'Anonymous method'
     => q{{ method {...}; }};

feature 'Anonymous method with signature'
     => q{{ method ($x //= 1) {...}; }};


feature 'ADJUST blocks'
     => q{{ ADJUST { $x = 1 } ADJUST { $y = 1 } }};


feature 'Class with fields, methods, and ADJUST blocks'
     => q{{
            class Basic;
            class Derived :isa(Basic) {}
            class WithMethods {
                field $greetings;
                field $info : param = 'default';
                field @data         = get_data();
                field %dict         = ();

                ADJUST {
                    $greetings = "Hello";
                }

                ADJUST {
                    shift @data;
                }

                method greet($name = "someone") {
                    say "$greetings, $name";
                }
            }
         }};


done_testing();


sub feature {
    state $STATEMENT = qr{ \A (?&PerlBlock) \s* \Z  $PPR::GRAMMAR }xms;

    my ($desc, $syntax) = @_;
    ok $syntax =~ $STATEMENT => $desc;
}
