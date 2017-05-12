#!perl
##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/t/00_compile.t $
#     $Date: 2008-05-18 17:16:51 -0700 (Sun, 18 May 2008) $
#   $Author: clonezone $
# $Revision: 2370 $
##############################################################################

use strict;
use warnings;

use Perl::Critic::Config;
use Perl::Critic::Utils qw{ &policy_long_name &hashify };
use Perl::Critic::TestUtils qw(bundled_policy_names);

use Test::More tests => 1;

Perl::Critic::TestUtils::block_perlcriticrc();

my @policies = bundled_policy_names();
my $had_failure = 0;

{
    my $config = Perl::Critic::Config->new(-theme => 'more');
    my @found_policies = sort map { policy_long_name(ref $_) } $config->policies();

    is_deeply(\@found_policies, \@policies, 'successfully loaded policies matches MANIFEST')
        or $had_failure = 1;
}

if ($had_failure) {
    BAIL_OUT('No point continueing if there was a compilation problem.');
}

# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
