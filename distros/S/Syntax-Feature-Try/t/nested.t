use Test::Spec;
require Test::NoWarnings;
use Test::Exception;

use syntax 'try';

describe "nested try/catch" => sub {
    it "is working" => sub {
        my @log;
        lives_ok {
            try {
                push @log, "outer-try";
                try {
                    push @log, "inner-try";
                    die bless {}, "AAA";
                }
                catch(AAA $e) {
                    push @log, "inner-catch";
                    die $e;
                }
                finally {
                    push @log, "inner-finally";
                }
                push @log, "innter-done-will-be-skipped";
            }
            catch (AAA $e) {
                push @log, "outer-catch";
            }
            finally {
                push @log, "outer-finally";
            }
            push @log, "outer-done";
        };

        is_deeply(\@log, [qw/
                outer-try
                inner-try
                inner-catch
                inner-finally
                outer-catch
                outer-finally
                outer-done
            /]);
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
