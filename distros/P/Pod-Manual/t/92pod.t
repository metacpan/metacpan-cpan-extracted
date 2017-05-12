use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

$ENV{ TEST_AUTHOR } =~ /Pod::Manual/ and eval q{
    use Test::Pod;
    goto RUN_TESTS;
};

plan skip_all => $@
       ? 'Test::Pod not installed; skipping pod testing'
       :   q{Set TEST_AUTHOR to 'Pod::Manual' in your environment }
         . q{ to enable these tests};

RUN_TESTS: 

all_pod_files_ok();
