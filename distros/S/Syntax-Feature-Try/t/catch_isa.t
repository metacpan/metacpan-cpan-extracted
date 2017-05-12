use Test::Spec;
require Test::NoWarnings;

use syntax 'try';

# mock classes inheritance for tests
{
    package MyMock::Animal;
    sub new { bless {}, shift };

    package MyMock::Bird;
    use base 'MyMock::Animal';

    package MyMock::Raptor;
    use base 'MyMock::Bird';

    package MyMock::Eagle;
    use base 'MyMock::Raptor';
}

sub test_catch_bird {
    my ($err, $expected_result) = @_;

    my $result;
    try { die $err }
    catch (MyMock::Bird $e) { $result=1 }
    catch ($others) { $result=0 }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is($result, $expected_result);
}

describe "catch (MyMock::Bird ...) {}" => sub {
    it "handles exception of given class" => sub {
        test_catch_bird( MyMock::Bird->new(), 1 );
    };

    it "handles also exceptions based on given class" => sub {
        test_catch_bird( MyMock::Raptor->new(), 1 );
        test_catch_bird( MyMock::Eagle->new(), 1 );
    };

    it "ignores it's super-class(es)" => sub {
        test_catch_bird( MyMock::Animal->new(), 0 );
    };

    it "ignores other exceptions classes" => sub {
        test_catch_bird( bless({}, "MyMock::ABC"), 0 );
        test_catch_bird( bless({}, "MyMock::Bird::Two"), 0 );
    };

    it "skips also any non-object exceptions" => sub {
        test_catch_bird( {}, 0 );
        test_catch_bird( "mock-error", 0 );
        test_catch_bird( "MyMock::Bird", 0 );
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
