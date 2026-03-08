#!perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    eval { require Test::Pod::Spelling::CommonMistakes }
      or plan skip_all => "Test::Pod::Spelling::CommonMistakes required for this test";
}

use Test::Pod::Spelling::CommonMistakes qw(all_pod_files_ok);

all_pod_files_ok();
