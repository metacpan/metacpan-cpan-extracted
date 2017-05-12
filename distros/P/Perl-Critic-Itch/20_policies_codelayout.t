#!perl

use 5.006;
use strict;
use warnings;
use utf8;
use Test::More tests => 5;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
'$hash{ola}=10;';
EOF
END_PERL

$policy = 'CodeLayout::ProhibitHashBarewords';
is( pcritique($policy, \$code), 1, $policy.' - valid ASCII');
#----------------------------------------------------------------

