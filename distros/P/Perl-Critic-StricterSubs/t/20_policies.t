#!perl

use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Warnings;

use English qw(-no_match_vars);

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique subtests_in_tree);
Perl::Critic::TestUtils::block_perlcriticrc();

my $subtests = subtests_in_tree( 't' );

# Check for cmdline limit on policies.  Example:
#   perl -Ilib t/20_policies.t BuiltinFunctions::ProhibitLvalueSubstr
if (@ARGV) {
    my @policies = keys %{$subtests};
    my @regexps = map { qr{ \Q$_\E }smx } @ARGV;
    # This is inefficient, but who cares...
    for my $p (@policies) {
        if (0 == grep { $p =~ $_ } @regexps) {
            delete $subtests->{$p};
        }
    }
}

# count how many tests there will be
my $nsubtests = 0;
for my $s (values %$subtests) {
    $nsubtests += @$s; # one [pf]critique() test per subtest
}
my $npolicies = scalar keys %$subtests; # one can() test per policy

plan tests => $nsubtests + $npolicies + 1;

for my $policy ( sort keys %$subtests ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{$subtests->{$policy}} ) {
        local $TODO = $subtest->{TODO}; # Is NOT a TODO if it's not set

        my $desc = join( ' - ', $policy, "line $subtest->{lineno}", $subtest->{name} );
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
            die $err if $err;
            is($violations, $subtest->{failures}, $desc);
        }
    }
}

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab ft=perl:

