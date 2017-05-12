use Test::Spec;
require Test::NoWarnings;
use Test::Exception;
use Exception::Class (
    'Error::Mock::AAA',
    'Error::Mock::BBB'
);

use syntax 'try';

describe "Exception::Class errors" => sub {
    they "are compatible with try/catch syntax" => sub {
        my @log;
        throws_ok {
            try {
                Error::Mock::BBB->throw('mock-error-msg');
            }
            catch (Error::Mock::AAA $e) { fail("AAA not caught.") }
            catch (Error::Mock::BBB $e) {
                push @log, "$e";
                $e->rethrow;
            }
        } 'Error::Mock::BBB';

        is_deeply(\@log, ['mock-error-msg']);
    };
};

it "has no warnings" => sub {
    Test::NoWarnings::had_no_warnings();
};

runtests;
