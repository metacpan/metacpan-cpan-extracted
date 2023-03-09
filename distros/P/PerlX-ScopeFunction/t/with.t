use v5.36;
use Test2::V0;

use PerlX::ScopeFunction;

sub range ($n) {
    (1..$n)
}

subtest "__rewrite_with", sub {
    note "__rewrite_with() is called by Keyword::Simple and the keyword \"with\" is trimed from the input";

    my $code = "( EXPR ) { CODE }\n foo();";
    PerlX::ScopeFunction::__rewrite_with( \$code );

    is $code, "(sub { local \$_ = \$_[-1]; CODE })->( EXPR );\n foo();";
};


subtest "basic", sub {
    with( range(5) ) {
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

    with( 1..5 ) {
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

subtest "scalar context", sub {
    with ( scalar localtime ) {
        is scalar(@_), 1;
        is $_, $_[0];
    }
};

subtest "nested parens/brackets", sub {
    with ( (1,2,(3,4)),[5] ) {
        is \@_, array {
            item 1;
            item 2;
            item 3;
            item 4;
            item array {
                item 5;
                end;
            };
            end;
        }
    }
};

subtest "whitespaces", sub {
    ok lives {
        with ( 1 ) {
            ok 1;
        };
    };

    ok lives {
        with (1) { ok 1 };
    };

    ok lives {
        with(1){ok 1};
    };

    ok lives {
        with(1)
          {ok 1};
    };

    ok lives {
        with
          (1)
          {ok 1};
    };
};


done_testing;
