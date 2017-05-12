use strict;
use warnings;
use utf8;

use Test::Perl::Critic::Policy qw(all_policies_ok);
use File::Basename qw(dirname);

my $test_directory = dirname(__FILE__);
all_policies_ok('-test-directory' => $test_directory);
