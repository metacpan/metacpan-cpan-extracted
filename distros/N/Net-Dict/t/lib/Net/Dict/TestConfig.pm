package Net::Dict::TestConfig;

use parent 'Exporter';

our @EXPORT_OK = qw($TEST_HOST $TEST_PORT);

our $TEST_HOST = 'dict.org';
our $TEST_PORT = 2628;

1;
