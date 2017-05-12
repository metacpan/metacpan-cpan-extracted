use Test::Spec;
require Test::NoWarnings;
use Exception::Class 'MockErr';

use syntax 'try';

# TODO fix this and enable tests
xdescribe "subroutine aguments" => sub {
    they "are accessible inside try/catch/finally blocks" => sub {
        sub test_sub {
            is_deeply(\@_, [qw/ a b c d e /]);
            try {
                is_deeply(\@_, [qw/ a b c d e /]);
                is(pop, 'e');

                MockErr->throw('aa');
            }
            catch (MockErr $err) {
                is_deeply(\@_, [qw/ a b c d /]);
                is(shift, 'a');
            }
            finally {
                is_deeply(\@_, [qw/ b c d /]);
                $_->[1] = 'CC';
            }
            is_deeply(\@_, [qw/ b CC d /]);
        }

        test_sub(qw/ a b c d e /);
    }
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
