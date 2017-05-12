use Test::Spec;
require Test::NoWarnings;
use Test::Exception;
use Exception::Class qw/
    MyTestErr
    MyTestErr::A
    MyTestErr::B
/;

use syntax 'try';

describe "finally" => sub {
    it "is called if try block ends successfully" => sub {
        my $mock = mock();
        $mock->expects('cleanup_code');

        lives_ok {
            try { }
            finally { $mock->cleanup_code; }
        };
    };

    it "is called if exception is not thrown" => sub {
        my $mock = mock();
        $mock->expects('err_handler');
        $mock->expects('cleanup_code');

        lives_ok {
            try { MyTestErr->throw; }
            catch (MyTestErr $e) { $mock->err_handler; }
            finally { $mock->cleanup_code; }
        };
    };

    it "is called even if exception is not caught" => sub {
        my $mock = mock();
        $mock->expects('cleanup_code');

        throws_ok {
            try { MyTestErr->throw; }
            finally { $mock->cleanup_code; }
        } 'MyTestErr';
    };

    it "is called even if different exception is thrown from catch block" => sub {
        my $mock = mock();
        $mock->expects('cleanup_code');

        throws_ok {
            try { die 123 }
            catch ($e) { MyTestErr->throw }
            finally { $mock->cleanup_code; }
        } 'MyTestErr';
    };

    it "it propagate throwed exception" => sub {
        my $mock = mock();
        $mock->expects('try_called');

        throws_ok {
            try { $mock->try_called }
            finally { MyTestErr->throw }
        } 'MyTestErr';
    };

    it "it override throwed exception from catch block" => sub {
        my $mock = mock();
        $mock->expects('catch_called');

        throws_ok {
            try { die 123; }
            catch ($e) {
                $mock->catch_called;
                MyTestErr::A->throw;
            }
            finally { die MyTestErr::B->throw }
        } 'MyTestErr::B';
    };

    it "is called in right order" => sub {
        my @order;

        lives_ok {
            push @order, 'before';
            try {
                push @order, 'try-out-1';
                try {
                    push @order, 'try-in-1';
                    MyTestErr::A->throw;
                    push @order, 'try-in-2';
                }
                catch (MyTestErr::A $e) {
                    push @order, 'catch-in-1';
                    MyTestErr::B->throw;
                    push @order, 'catch-in-2';
                }
                finally {
                    push @order, 'finally-in';
                }
                push @order, 'try-in-2';
            }
            catch (MyTestErr::B $e) {
                push @order, 'catch-out';
            }
            finally {
                push @order, 'finally-out';
            }
            push @order, 'after';
        };

        is_deeply(\@order, [qw/
            before
            try-out-1
            try-in-1
            catch-in-1
            finally-in
            catch-out
            finally-out
            after
        /]);
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
