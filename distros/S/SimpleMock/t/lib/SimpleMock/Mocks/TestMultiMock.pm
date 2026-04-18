package SimpleMock::Mocks::TestMultiMock;
use strict;
use warnings;
use SimpleMock qw(register_mocks);

# Regression fixture: register_mocks called from inside an auto-loaded Mocks
# file with multiple models. Previously, any die inside validate_mocks whose
# message began with "Can't locate object method ..." was silently swallowed
# because _load_mocks_for matched /Can't locate/ too broadly.
register_mocks(
    PATH_TINY => {
        '/tmp/simplemock_multi_test' => { data => 'hello' },
    },
    LWP_UA => {
        'http://example.com/multi' => {
            GET => [ { response => { code => 200, content => 'ok' } } ],
        },
    },
    DBI => {
        QUERIES => [
            { sql => 'SELECT 1', results => [ { data => [[1]] } ] },
        ],
    },
);

1;
