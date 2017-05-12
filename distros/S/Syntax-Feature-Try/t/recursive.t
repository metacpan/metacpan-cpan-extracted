use Test::Spec;
require Test::NoWarnings;
use Exception::Class 'TestError';

use syntax 'try';

our @log;

describe "recursive calling try block" => sub {
    it "works ok" => sub {
        sub test_recursive_try {
            my $n = shift;

            try {
                push @log, "try-$n-before";
                test_recursive_try($n-1) if $n;
                push @log, "try-$n-after";
            }
            finally {
                push @log, "finally-$n";
            }
        }

        @log = ();
        test_recursive_try(2);

        is_deeply(\@log, [qw/
            try-2-before
            try-1-before
            try-0-before
            try-0-after
            finally-0
            try-1-after
            finally-1
            try-2-after
            finally-2
        /]);
    };
};

describe "recursive calling catch block" => sub {
    it "works ok" => sub {
        sub test_recursive_catch {
            my $n = shift;

            try {
                push @log, "try-$n";
                TestError->throw("e$n");
            }
            catch(TestError $err) {
                push @log, "catch-$n-before=".$err->message;
                test_recursive_catch($n-1) if $n;
                push @log, "catch-$n-after=".$err->message;
            }
        }

        @log = ();
        test_recursive_catch(2);

        is_deeply(\@log, [qw/
            try-2
            catch-2-before=e2
            try-1
            catch-1-before=e1
            try-0
            catch-0-before=e0
            catch-0-after=e0
            catch-1-after=e1
            catch-2-after=e2
        /]);
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
