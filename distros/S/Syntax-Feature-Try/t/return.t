use 5.014;
use Test::Spec;
require Test::NoWarnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ test_syntax_error compile_ok /;

use Exception::Class 'Error1';
use syntax 'try';


my @RET_TYPES = qw/ array list empty_list scalar undef wantarray none /;

sub mock_return {
    my $mode = shift;
    if ($mode eq 'array')       { my @a = qw/ aa bb cc dd /; return @a; }
    if ($mode eq 'list')        { return (444,666,777); }
    if ($mode eq 'empty_list')  { return (); }
    if ($mode eq 'scalar')      { return 53.3; }
    if ($mode eq 'undef')       { return undef; }
    if ($mode eq 'wantarray') {  return wantarray ? 'want-array' : 'want-scalar'; }
    return;
}

describe "return" => sub {

    describe "from mock function" => sub {
        it "is ok" => sub {
            is_deeply([ mock_return('array') ], [qw/ aa bb cc dd /]);
            is_deeply(scalar mock_return('array'), 4);

            is_deeply([ mock_return('list') ], [qw/ 444 666 777 /]);
            is_deeply(scalar(mock_return('list')), 777);

            is_deeply([ mock_return('empty_list') ], []);
            is_deeply(scalar(mock_return('empty_list')), undef);

            is_deeply([ mock_return('scalar') ], [53.3]);
            is_deeply(scalar mock_return('scalar'), 53.3);

            is_deeply([ mock_return('undef') ], [undef]);
            is_deeply(scalar mock_return('undef'), undef);

            is_deeply([ mock_return('wantarray') ], ['want-array']);
            is_deeply(scalar mock_return('wantarray'), 'want-scalar');

            is_deeply([ mock_return('none') ], []);
            is_deeply(scalar mock_return('none'), undef);
        };
    };

    describe "from try block" => sub {
        it "works ok" => sub {
            our @done = ();

            sub test_return_try {
                my ($x) = @_;

                push @done, 'before';
                try {
                    push @done, 'try-1';
                    return 66;

                    push @done, 'try-2';
                }
                catch (Error1 $e) {
                    push @done, 'catch';
                    return 77;
                }
                finally {
                    push @done, 'finally';
                }
                return 88;
            }

            is_deeply(test_return_try(), 66);

            is_deeply(\@done, [qw/ before try-1 finally /]);
        };

        it "works in all contexts" => sub {
            sub test_try_context {
                my $mode = shift;
                try {
                    return mock_return($mode);
                }
                finally { }
                die "This-is-never-called";
            }

            for (@RET_TYPES) {
                is_deeply(scalar test_try_context($_), scalar mock_return($_));
                is_deeply([test_try_context($_)], [mock_return($_)]);
                test_try_context($_); # void context
            }
        };
    };

    describe "from catch block" => sub {
        it "works inside catch block" => sub {
            our @done = ();

            sub test_return_catch {
                my ($x) = @_;

                push @done, 'before';
                try {
                    push @done, 'try-1';
                    Error1->throw;

                    push @done, 'try-2';
                    return 66;
                }
                catch (Error1 $e) {
                    push @done, 'catch';
                    return 77;
                }
                finally {
                    push @done, 'finally';
                }
                return 88;
            }

            is_deeply(test_return_catch(), 77);

            is_deeply(\@done, [qw/ before try-1 catch finally /]);
        };

        it "works in all contexts" => sub {
            sub test_catch_context {
                my $mode = shift;
                try { Error1->throw }
                catch (Error1 $err) {
                    return mock_return($mode);
                }
                die "This-is-never-called";
            }

            for (@RET_TYPES) {
                is_deeply(scalar test_catch_context($_), scalar mock_return($_));
                is_deeply([test_catch_context($_)], [mock_return($_)]);
                test_catch_context($_); # void context
            }
        };
    };

    describe "from finally block" => sub {
        it "works ok" => sub {
            our @done = ();

            sub test_return_finally {
                my ($x) = @_;

                push @done, 'before';
                try {
                    push @done, 'try-1';
                    Error1->throw;
                    return 66;
                }
                catch (Error1 $e) {
                    push @done, 'catch';
                }
                finally {
                    push @done, 'finally';
                    return 99;
                }
                return 88;
            }

            is_deeply(test_return_finally(), 99);

            is_deeply(\@done, [qw/ before try-1 catch finally /]);
        };

        it "overrides prevoiusly returned values" => sub {
            sub test_override_return {
                my $mode = shift;
                try {
                    Error1->throw if $mode eq 'err';
                    return 44;
                }
                catch (Error1 $e) {
                    return 55;
                }
                finally {
                    return 66;
                }
                return 99;
            }

            is(test_override_return('err'), 66);
            is(test_override_return('ok'), 66);
        };

        it "works in all contexts" => sub {
            sub test_finally_context {
                my $mode = shift;
                try { Error1->throw }
                catch (Error1 $err) {
                }
                finally {
                    return mock_return($mode);
                }
                die "This-is-never-called";
            }

            for (@RET_TYPES) {
                is_deeply(scalar test_finally_context($_), scalar mock_return($_));
                is_deeply([test_finally_context($_)], [mock_return($_)]);
                test_finally_context($_); # void context
            }
        };
    };

    it "works for nested blocks structures" => sub {
        sub test_nested_blocks {
            my $mode = shift;
            try {
                for (1..3) {
                    try {
                        Error1->throw if $mode eq 'ERROR';
                        return mock_return($mode) if $mode;
                    }
                    finally {
                    }
                }
            }
            catch (Error1 $e) {
                return 67;
            }
            return 5;
        }

        for (@RET_TYPES) {
            is_deeply(scalar test_nested_blocks($_), scalar mock_return($_));
            is_deeply([test_nested_blocks($_)], [mock_return($_)]);
            test_nested_blocks($_); # void context
        }

        is_deeply(scalar test_nested_blocks('ERROR'), 67);
        is_deeply([test_nested_blocks('ERROR')], [qw/ 67 /]);
        test_nested_blocks('ERROR'); # void context
    };

    it "can be used outside try/finally blocks" => sub {
        compile_ok q[
            use syntax 'try';

            my $a = sub { return 11 };
            sub t1 { return 111 }
            t1();

            try { }
            finally { }

            my $b = sub { return 22 };
            sub t2 { return 222 }
            t2();
        ];
    };

    it "can be used inside subroutines defined in try/catch/finally blocks" => sub {
        my @result = compile_ok q[
            use syntax 'try';

            my @res;
            try {
                my $t1 = sub {
                    return 6;
                    return 7;
                };
                push @res, $t1->();

                die bless {}, "Mock::Err";
            }
            catch (Mock::Err $e) {
                my $t2 = sub {
                    return 8;
                    return 9;
                };
                push @res, $t2->();
            }
            return @res;
        ];

        is_deeply(\@result, [6,8]);
    };

    it "can be used outside try/catch/finally blocks" => sub {
        compile_ok q[
            use syntax 'try';

            sub test_return {
                my $x = shift;

                return 55 if $x;

                try {
                }
                catch (Mock::Err $e) {
                }

                return 99;
            }
        ];
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
