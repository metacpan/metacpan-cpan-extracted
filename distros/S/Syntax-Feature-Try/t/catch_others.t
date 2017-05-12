use Test::Spec;
require Test::NoWarnings;
use Test::Exception;

use syntax 'try';

sub test_catch_others {
    my ($err) = @_;

    my $caught;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    lives_ok {
        try { die $err }
        catch ($e) { $caught = 1 }
    };
    ok($caught);
}

describe 'catch ($e)' => sub {
    it "handles any kind of error" => sub {
        test_catch_others( bless({}, "SomeClass") );
        test_catch_others( [1,2,3] );
        test_catch_others( {4 => 5} );
        test_catch_others( 'my-err' );
        test_catch_others( 123 );
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
