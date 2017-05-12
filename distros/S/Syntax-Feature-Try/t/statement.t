use Test::Spec;
require Test::NoWarnings;
use Test::Exception;

use syntax 'try';

describe "statement" => sub {
    it "throws exception if there is not catch block to handle
            this kind of exception"
    => sub {
        throws_ok {
            try {
                my $err = bless {}, "Mock::Donkey";
                die $err;
            }
            catch (Mock::Cat $e) { fail("Mock::Cat not caught"); }
        } 'Mock::Donkey';
    };

    it "does not throw exception it try block does not die" => sub {
        my $mock = mock();
        $mock->expects('try_code')->exactly(1);

        lives_ok {
            try {
                $mock->try_code;
            }
            catch ($all_errors) { fail("There is no error") }
        };
    };

    it "calls first catch-block in sequence only" => sub {
        my $mock = mock();
        $mock->expects('handle_MockErr')->exactly(1);

        lives_ok {
            try { die bless {}, "Mock::Err"; }
            catch (Mock::Err $e) {
                $mock->handle_MockErr();
            }
            catch (Mock::Err $e) { fail("second catch block is never executed") }
            catch ($other) { fail("third catch block is never executed") }
        };
    };

    it "throws exception from catch block" => sub {
        throws_ok {
            try { die bless {}, "Mock::OrigErr"; }
            catch (Mock::OrigErr $e) {
                die bless {}, "Mock::NewErr";
            }
            catch (Mock::OrigErr $e) { fail("second Mock::OrigErr is never caught") }
            catch (Mock::NewErr $e) { fail("Mock::NewErr is never caught") }
            catch ($other) { fail("others block is never executed") }
        } 'Mock::NewErr';
    };

    it "can use upper local variables" => sub {

        lives_ok {
            my @out;
            my $a = 11;
            my $b = 22;
            try {
                push @out, "try-$a";
                try {
                    push @out, "try-$b";
                    die bless {}, "Mock::Err";
                }
                catch (Mock::Err $e) {
                    push @out, "catch-$b";
                }
            }
            finally {
                push @out, "finally-$a";
            }

            is_deeply(
                \@out,
                [qw/
                    try-11
                    try-22
                    catch-22
                    finally-11
                /]
            );
        };
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
