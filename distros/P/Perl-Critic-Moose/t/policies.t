use strict;
use warnings;

use Test::Perl::Critic::Policy qw< all_policies_ok >;

my %args = @ARGV ? ( -policies => [@ARGV] ) : ();
all_policies_ok(%args);
