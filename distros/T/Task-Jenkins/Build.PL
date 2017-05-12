# $Id$

use strict;
use warnings;
use Module::Build;
use 5.006; #perl version 5.6.0

my $build = Module::Build->new(
    dist_author => 'Jonas B. Nielsen (JONASBN)',
    dist_abstract =>
        'Collection of distributions for continuous integration using Jenkins',
    module_name          => 'Task::Jenkins',
    license              => 'artistic_2',
    recursive_test_files => 1,
    create_readme        => 1,
    create_makefile_pl   => 'traditional',
    configure_requires => { 'Module::Build' => 0.40 },
    requires             => {
        'TAP::Formatter::JUnit'        => '0',
        'Devel::Cover'                 => '0',
        'App::Prove'                   => '0',
        'perl'                         => '5.6.0',
        'Devel::Cover::Report::Clover' =>  '0',
    },
    meta_merge => {
        resources => {
            homepage => 'http://logiclab.jira.com/wiki/display/TJENKINS/Home',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Jenkins',
            repository => 'https://github.com/jonasbn/tjenkins.git',
            ProjectChangelog =>
                'http://logiclab.jira.com/browse/TJENKINS#selectedTab=com.atlassian.jira.plugin.system.project%3Achangelog-panel',
            ProjectSite => 'http://logicLAB.jira.com/browse/TJENKINS',
            ProjectWiki => 'http://logiclab.jira.com/wiki/display/TJENKINS/Home',
        }
    },
);

$build->create_build_script();
