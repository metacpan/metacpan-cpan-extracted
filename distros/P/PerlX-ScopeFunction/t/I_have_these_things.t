use Test2::V0;

use PerlX::ScopeFunction with => { -as => "I_have_these_things" };

subtest "I_have_these_things", sub {
    I_have_these_things( 1..5 ) {
        is $_, 5;
        is \@_, array {
            item 1;
            item 2;
            item 3;
            item 4;
            item 5;
            end;
        };
    }
};

done_testing;
