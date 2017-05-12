use Test::Spec;
require Test::NoWarnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use test_tools qw/ test_syntax_error /;

describe "parser" => sub {

    describe "try" => sub {
        it "throws error if it is not followed by block of code" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try
                    catch (My::Class1 $aa) {}
                    my $6=y;
                ], qr/^syntax error: expected block after 'try' at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if code-reference after try is used instead of block" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    sub foo { }
                    try &foo
                    catch ($aa) { }
                ], qr/^syntax error: expected block after 'try' at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if try block is not followed by catch/finally block" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    my $i;
                    try { $i++ }
                    $i += 10;
                ], qr/^syntax error: expected catch\/finally after try block at \(eval \d+\) line 6[.]?$/;
        };

        it "throws error if it is not called in statement-context" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    my $x = try {}
                            catch ($e) {}
                    ;
                ], qr/^syntax error at \(eval \d+\) line/;
        };
    };

    describe "catch" => sub {
        it "throws error if it is not called after try block" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    my $e;
                    catch ($e) { }
                ], qr/^syntax error: try\/catch\/finally sequence at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if class-name has invalid syntax" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    catch (Test::Foo:x $abc) { }
                ], qr/^syntax error: invalid catch syntax at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if variable is not simple scalar" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    catch (My::Class::A @aa) { }
                ], qr/^syntax error: invalid catch syntax at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if variable name is missing" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    catch (Moo::AA $goo) { }
                    catch ($) { }
                ], qr/^syntax error: invalid catch syntax at \(eval \d+\) line 6[.]?$/;
        };

        it "throws error if variable is not followed by ')'" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    catch ($abc->test) { }
                ], qr/^syntax error: invalid catch syntax at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if block after catch definition is missing" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    catch ($err)
                    my $a=0;
                ], qr/^syntax error: expected block after 'catch\(\)' at \(eval \d+\) line 6[.]?$/;
        };
    };

    describe "finally" => sub {
        it "throws error if it is not followed by block of code" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    finally 123
                ], qr/^syntax error: expected block after 'finally' at \(eval \d+\) line 5[.]?$/;
        };

        it "throws error if it is called without try block" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    finally {  }
                ], qr/^syntax error: finally without try block at \(eval \d+\) line 4[.]?$/;
        };

        it "throws error if statement contains multiple 'finally' blocks" => sub {
            test_syntax_error q[
                    use syntax 'try';

                    try { }
                    finally {  }
                    finally {  }
                ], qr/^syntax error: finally without try block at \(eval \d+\) line 6[.]?$/;
        };
    };

};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
