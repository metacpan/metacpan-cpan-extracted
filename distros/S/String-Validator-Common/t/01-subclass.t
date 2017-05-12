#!perl -T
use Test::More;    #tests ;# => 4;

use 5.008;

BEGIN {
    use_ok('String::Validator::Common') || print "Bail out!\n";
}
my $Validator = String::Validator::Common->new();
is( $Validator->isa('String::Validator::Common'),
    1, 'New validator isa String::Validator::Common' );
diag(
    "Testing String::Validator::Common $String::Validator::Common::VERSION, Perl $], $^X"
);

SKIP: {
    skip "Your Perl is too old for this test", 1 unless $] >= 5.014;

    package String::Validator::Common::TestClass ;

       our $VERSION = 0.16;

        sub new {
            my $class = shift;
            my $self  = {@_};
            use base ('String::Validator::Common');
            bless $self, $class;
            return $self;
        }
        sub opus { return 'penguin' }

    package notestclass;
    use Test::More; 
    my $newclass = String::Validator::Common::TestClass->new();
    ok( $newclass, "newclass evaluates as true" );
    is( $newclass->opus(), 'penguin' , "opus method returns penguin" );
    is( $newclass->isa('String::Validator::Common::TestClass'),
        1, 'new object isa String::Validator::Common::TestClass' );
    is( $String::Validator::Common::TestClass::VERSION, 
        0.16, 
        'Check version of new class is 0.16');
}

done_testing;
