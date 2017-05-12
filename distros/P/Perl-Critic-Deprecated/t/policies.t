#!perl

#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/t/policies.t $
#     $Date: 2010-06-22 15:16:01 -0700 (Tue, 22 Jun 2010) $
#   $Author: clonezone $
# $Revision: 3849 $

use 5.006;

use strict;
use warnings;

our $VERSION = '1.108';

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

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
