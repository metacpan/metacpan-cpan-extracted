#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 38;
use PAUSE::Permissions;

my $pp;
my $mp;
my $string;

#-----------------------------------------------------------------------
# construct PAUSE::Permissions
#-----------------------------------------------------------------------

$pp = PAUSE::Permissions->new(path => 't/06perms-mini.txt');

ok(defined($pp), "instantiate PAUSE::Permissions");

#-----------------------------------------------------------------------
# non-existent module
#-----------------------------------------------------------------------
ok(!defined($pp->module_permissions('Does::Not::Exist')),
    "module_permissions() should return undef for non-existent module");

#-----------------------------------------------------------------------
# constant,P5P,c
# constant,SAPER,m
# constant,perl,c
#-----------------------------------------------------------------------
expect_for_module('constant',
                  owner                 => 'SAPER',
                  comaint               => [qw(P5P PERL)],
                  registered_maintainer => 'SAPER',
                  first_come            => undef,
                  all                   => [qw(P5P PERL SAPER)],
                 );

#-----------------------------------------------------------------------
# constant::Atom,JOHNWRDN,f
# constant::Atom,NEILB,c
#-----------------------------------------------------------------------
expect_for_module('constant::Atom',
                  owner                 => 'JOHNWRDN',
                  registered_maintainer => undef,
                  comaint               => [qw(NEILB)],
                  first_come            => 'JOHNWRDN',
                  all                   => [qw(JOHNWRDN NEILB)],
                 );

#-----------------------------------------------------------------------
# Math::Complex,JHI,c
# Math::Complex,RAM,m
# Math::Complex,ZEFRAM,f
# Math::Complex,perl,c
#-----------------------------------------------------------------------
expect_for_module('Math::Complex',
                  owner                 => 'RAM',
                  registered_maintainer => 'RAM',
                  comaint               => [qw(JHI PERL ZEFRAM)],
                  first_come            => 'ZEFRAM',
                  all                   => [qw(JHI PERL RAM ZEFRAM)],
                 );

#-----------------------------------------------------------------------
# Case-insensitive test
# Math::Complex,JHI,c
# Math::Complex,RAM,m
# Math::Complex,ZEFRAM,f
# Math::Complex,perl,c
#-----------------------------------------------------------------------
expect_for_module('math::complex',
                  owner                 => 'RAM',
                  registered_maintainer => 'RAM',
                  comaint               => [qw(JHI PERL ZEFRAM)],
                  first_come            => 'ZEFRAM',
                  all                   => [qw(JHI PERL RAM ZEFRAM)],
                 );

#-----------------------------------------------------------------------
# CPAN::Test::Reporter,SKUD,c
#-----------------------------------------------------------------------
expect_for_module('CPAN::Test::Reporter',
                  owner                 => undef,
                  registered_maintainer => undef,
                  comaint               => [qw(SKUD)],
                  first_come            => undef,
                  all                   => [qw(SKUD)],
                 );

#-----------------------------------------------------------------------
# Test::Cucumber,JOHND,f
# Test::Cucumber,SARGIE,m
#-----------------------------------------------------------------------
expect_for_module('Test::Cucumber',
                  owner                 => 'SARGIE',
                  registered_maintainer => 'SARGIE',
                  comaint               => [qw(JOHND)],
                  first_come            => 'JOHND',
                  all                   => [qw(JOHND SARGIE)],
                 );

#=======================================================================
# expect_for_module
#=======================================================================
sub expect_for_module
{
    my $module_name = shift;
    my %options     = @_;
    my $mp;

    $mp = $pp->module_permissions($module_name);
    ok(defined($mp), "get permissions for '$module_name'");

    if (exists($options{owner})) {
        is($mp->owner, $options{owner}, "owner of '$module_name' is ".($options{owner} || 'undef'));
    }

    if (exists($options{registered_maintainer})) {
        is($mp->registered_maintainer, $options{registered_maintainer}, "registered maintainer of '$module_name' is ".($options{registered_maintainer} || 'undef'));
    }

    if (exists($options{comaint})) {
        my $expected = join(':', @{ $options{comaint} });
        is(join(':', $mp->co_maintainers),
           $expected, "co-maints for '$module_name' is $expected");
    }

    if (exists($options{first_come})) {
        is($mp->first_come, $options{first_come}, "first-come for '$module_name' should be ".($options{first_come} || 'undef'));
    }

    if (exists($options{all})) {
        my $expected = join(':', @{ $options{all} });
        is(join(':', $mp->all_maintainers), $expected, "all maintainers for '$module_name' should be $expected");
    }

}

