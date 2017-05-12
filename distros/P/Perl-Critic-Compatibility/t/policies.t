#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/t/policies.t $
#     $Date: 2008-04-13 13:21:52 -0500 (Sun, 13 Apr 2008) $
#   $Author: clonezone $
# $Revision: 2221 $

use 5.006;

use strict;
use warnings;

use version; our $VERSION = qv('v1.1');

use English qw< -no_match_vars >;
use Carp qw< confess >;

use Test::More;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique subtests_in_tree);
Perl::Critic::TestUtils::block_perlcriticrc();

my $subtests = subtests_in_tree( 't' );

# Check for cmdline limit on policies.  Example:
#   perl -Ilib t/20_policies.t BuiltinFunctions::ProhibitLvalueSubstr
if (@ARGV) {
    my @policies = keys %{$subtests};
    # This is inefficient, but who cares...
    for my $p (@policies) {
        if (0 == grep {$_ eq $p} @ARGV) {
            delete $subtests->{$p};
        }
    }
}

# count how many tests there will be
my $nsubtests = 0;
for my $s (values %{$subtests}) {
    $nsubtests += @{$s}; # one [pf]critique() test per subtest
}
my $npolicies = scalar keys %{$subtests}; # one can() test per policy

plan tests => $nsubtests + $npolicies;

for my $policy ( sort keys %{$subtests} ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{$subtests->{$policy}} ) {
        local $TODO = $subtest->{TODO}; # Is NOT a todo if it's not set

        my $desc = join ' - ', $policy, "line $subtest->{lineno}", $subtest->{name};
        my $violations = $subtest->{filename}
          ? eval { fcritique($policy, \$subtest->{code}, $subtest->{filename}, $subtest->{parms}) }
          : eval { pcritique($policy, \$subtest->{code}, $subtest->{parms}) };
        my $err = $EVAL_ERROR;

        if ($subtest->{error}) {
            if ( 'Regexp' eq ref $subtest->{error} ) {
                like($err, $subtest->{error}, $desc);
            }
            else {
                ok($err, $desc);
            }
        }
        else {
            confess $err if $err;
            is($violations, $subtest->{failures}, $desc);
        }
    }
}

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
