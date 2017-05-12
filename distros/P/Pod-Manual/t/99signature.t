use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

$ENV{ TEST_AUTHOR } =~ /Pod::Manual/ and eval q{
    use Test::Signature;
    goto RUN_TESTS;
};

plan skip_all => $@
    ? 'Test::Signature not installed; skipping signature testing'
    :   q{Set TEST_AUTHOR to 'Pod::Manual' in your environment }
        . q{ to enable these tests};

RUN_TESTS:

plan tests => 1;

signature_ok();
