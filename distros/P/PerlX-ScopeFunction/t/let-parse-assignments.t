use Test2::V0;
use PerlX::ScopeFunction qw(let);

subtest "__comb_PerlVariable", sub {
    my @testCases = (
        [q< $foo >, ['$foo']],
        [q<( $foo )>, ['$foo']],
        [q<( $foo , $bar )>, ['$foo', '$bar']],
    );
    for (@testCases) {
        my ($code, $answer) = @$_;

        subtest "$code", sub {
            subtest "with whitespaces", sub {
                my @o = PerlX::ScopeFunction::__comb_PerlVariable($code);
                is \@o, $answer;
            };

            $code =~ s/\s//g;
            subtest "without whitespaces", sub {
                my @o = PerlX::ScopeFunction::__comb_PerlVariable($code);
                is \@o, $answer;
            };
        };
    }
};

subtest "__parse_LetAssignmentSequence", sub {
    subtest "one scalar variable", sub {
        my $code = q<$foo = 1>;
        my @o = PerlX::ScopeFunction::__parse_LetAssignmentSequence($code);
        is \@o, array {
            item hash {
                field 'expr', D();
                field 'lhs', q<$foo>;
                field 'variables', array { item '$foo'; end };
                end;
            };
            end;
        };
    };

    subtest "multiple statements,each with one scalar variable", sub {
        my $code = q<$foo = 1; $bar = 1>;
        my @o = PerlX::ScopeFunction::__parse_LetAssignmentSequence($code);
        is \@o, array {
            item hash {
                field 'expr', D();
                field 'lhs', '$foo';
                field 'variables', array { item '$foo'; end };
                end;
            };
            item hash {
                field 'expr', D();
                field 'lhs', '$bar';
                field 'variables', array { item '$bar'; end };
                end;
            };
            end;
        };
    };

    subtest "one statement with one scalar variables in parenthesis", sub {
        my $code = q<($foo) = foo(1)>;
        my @o = PerlX::ScopeFunction::__parse_LetAssignmentSequence($code);
        is \@o, array {
            item hash {
                field 'expr', D();
                field 'lhs', '($foo)';
                field 'variables', array {
                    item '$foo';
                    end;
                };
                end;
            };
            end;
        };
    };

    subtest "one statement with multiple scalar variables", sub {
        my $code = q<($foo, $bar) = (1, 2)>;
        my @o = PerlX::ScopeFunction::__parse_LetAssignmentSequence($code);
        is \@o, array {
            item hash {
                field 'expr', D();
                field 'lhs', '($foo, $bar)';
                field 'variables', array {
                    item '$foo';
                    item '$bar';
                    end;
                };
                end;
            };
            end;
        };
    };
};


done_testing;
