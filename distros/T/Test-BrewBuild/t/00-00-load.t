#!perl -T
use 5.006;
use strict;
use warnings;

use version;
use Test::More;

if ($ENV{BBDEV_TESTING}){
    if (! $ENV{PERLVER}){
        BAIL_OUT("for BBDEV_TESTING, you need to set \$ENV{PERLVER}, eg: 5.26.0");
    }
}
BEGIN {
    use_ok( 'Test::BrewBuild' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Tester' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Dispatch' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::BrewCommands' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Plugin::DefaultExec' ) || print "Bail out!\n";
    use_ok( 'Test::BrewBuild::Plugin::UnitTestPluginInst' ) || print "Bail out!\n";
}

{
    my $mod = 'Test::BrewBuild';

    my @subs = qw(
        new
        perls_available
        perls_installed
        instance_remove
        instance_install
        test
        is_win
        _exec
        brew_info
        log
    );

    push @subs, 'plugins';

    for (@subs){
        can_ok($mod, $_);
    }
}
{
    my $mod = 'Test::BrewBuild::Plugin::DefaultExec';

    my @subs = qw(
        brewbuild_exec
    );

    for (@subs){
        can_ok($mod, $_);
    }
}
{
    my $mod = 'Test::BrewBuild::BrewCommands';

    my @subs = qw(
        new
        brew
        installed
        available
        install
        remove
        is_win
    );

    for (@subs){
        can_ok($mod, $_);
    }
}
if ($ENV{BBDEV_TESTING}){
    # config file copied?
    my $work_dir;

    if ($^O =~ /MSWin/){
        $work_dir = "$ENV{USERPROFILE}/brewbuild";
    }
    else {
        $work_dir = "$ENV{HOME}/brewbuild";
    }

    is (-f "$work_dir/brewbuild.conf-dist", 1, "dist conf file installed ok");
}
done_testing();
