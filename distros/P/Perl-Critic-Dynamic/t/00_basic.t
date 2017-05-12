#!perl

##############################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/t/00_basic.t $
#    $Date: 2010-09-24 21:21:51 -0700 (Fri, 24 Sep 2010) $
#   $Author: thaljef $
# $Revision: 3942 $
##############################################################################

use strict;
use warnings;
use Test::More (tests => 8);

#-----------------------------------------------------------------------------

our $VERSION = '0.05';

#-----------------------------------------------------------------------------

my $package = 'Perl::Critic::Policy::Dynamic::ValidateAgainstSymbolTable';

#-----------------------------------------------------------------------------

use_ok( $package );
can_ok($package, 'new');
can_ok($package, 'violates');
can_ok($package, 'is_safe');

my $policy = $package->new();
isa_ok($policy, 'Perl::Critic::Policy');
isa_ok($policy, 'Perl::Critic::DynamicPolicy');
isa_ok($policy, $package);

isnt($policy->is_safe(), 1, 'Policy is not marked as safe');

