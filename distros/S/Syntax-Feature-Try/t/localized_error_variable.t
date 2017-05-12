use Test::Spec;
require Test::NoWarnings;
use Exception::Class 'TestErr';

our @done;

use syntax 'try';

{
    package EvalInDesctructor;

    sub new {
        return bless { err => shift };
    }

    sub DESTROY {
        my $self = shift;
        eval {
            die $self->{err} if $self->{err};
        };
        push @done, 'DESTROY';
    }
}

describe "try/catch/finally handling" => sub {
    it "does not override outside error" => sub {
        local $@ = "orig-error";
        @done = ();

        try {
            TestErr->throw("aaa");
        }
        catch (TestErr $e) {
            push @done, 'catch';
        }

        is($@, "orig-error");
        is_deeply(\@done, [qw/
            catch
        /]);
    };

    it "is not affected by eval called from DESTROY" => sub {
        foreach my $mock_err ((undef, TestErr->new('xx'))) {
            local $@ = "orig-error";
            @done = ();

            try {
                my $obj = EvalInDesctructor->new($mock_err);
                TestErr->throw("aaa");
            }
            catch (TestErr $e) {
                my $obj = EvalInDesctructor->new($mock_err);
                push @done, 'catch';
            }
            finally {
                my $obj = EvalInDesctructor->new($mock_err);
                push @done, 'finally';
            }

            is($@, "orig-error");
            is_deeply(\@done, [qw/
                DESTROY
                catch
                DESTROY
                finally
                DESTROY
            /]);
        }
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
