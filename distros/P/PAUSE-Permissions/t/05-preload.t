#!perl

use strict;
use warnings;

use Test::More 0.88;
use PAUSE::Permissions;

my $NO_MODULE_RENDER = '||module=undef||owner=undef||co-maints=||';
my %TESTS = (
    'constant'             => '||module=constant||owner=SAPER||co-maints=P5P,PERL||',
    'constant::Atom'       => '||module=constant::Atom||owner=JOHNWRDN||co-maints=NEILB||',
    'Math::Complex'        => '||module=Math::Complex||owner=RAM||co-maints=JHI,PERL,ZEFRAM||',
    'CPAN::Test::Reporter' => '||module=CPAN::Test::Reporter||owner=undef||co-maints=SKUD||',
    'Test::Cucumber'       => '||module=Test::Cucumber||owner=SARGIE||co-maints=JOHND||',
);

plan tests => 2 + int(keys %TESTS);

my $pp = PAUSE::Permissions->new(path => 't/06perms-mini.txt', preload => 1);

BAIL_OUT("failed to instantiate PAUSE::Permissions") unless defined($pp);

my $rendering;
foreach my $module_name (keys %TESTS) {
    check_module($module_name, $TESTS{$module_name});
}

is(render_module(undef), $NO_MODULE_RENDER);
check_module('No::Such::Module', $NO_MODULE_RENDER);

sub check_module
{
    my $module_name     = shift;
    my $expected_result = shift;
    my $module          = $pp->module_permissions($module_name);

    if (defined($module) && defined($rendering = render_module($module))) {
        is($rendering, $TESTS{$module_name}, "check results for $module_name");
    }
    else {
        is($NO_MODULE_RENDER, $expected_result, "check results for $module_name");
    }

}

sub render_module
{
    my $module = shift;

    return $NO_MODULE_RENDER unless defined($module);

    return sprintf('||module=%s||owner=%s||co-maints=%s||',
                   $module->name // 'undef',
                   $module->owner // 'undef',
                   join(',', $module->co_maintainers),
                  );
}
