# Build.PL for Perl::Critic::logicLAB

use strict;
use warnings;
use Module::Build;

our $VERSION = '0.08';

my $build = Module::Build->new(
    dist_author   => 'Jonas B. Nielsen (jonasbn), <jonasbn@cpan.org>',
    module_name   => 'Perl::Critic::logicLAB',
    license       => 'artistic',
    create_makefile_pl => 'traditional',
    create_readme => 1,
    requires      => {
        'Perl::Critic::Policy::logicLAB::ProhibitUseLib'            => '0',
        'Perl::Critic::Policy::logicLAB::RequireVersionFormat'      => '0',
        'Perl::Critic::Policy::logicLAB::ProhibitShellDispatch'     => '0',
        'Perl::Critic::Policy::logicLAB::RequireSheBang'            => '0',
        'Perl::Critic::Policy::logicLAB::RequirePackageNamePattern' => '0',
        'Perl::Critic::Policy::logicLAB::RequireParamsValidate'     => '0',
        'Perl::Critic::Policy::logicLAB::ModuleBlacklist'           => '0',
        'perl'                                                      => '5.6.0',
    },
    meta_merge => {
        resources => {
            homepage => 'http://logiclab.jira.com/wiki/display/PCLL/Home',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic-logicLAB',
            repository => 'https://github.com/jonasbn/pcll',
            ProjectChangelog =>
                'http://logiclab.jira.com/browse/PCLL#selectedTab=com.atlassian.jira.plugin.system.project%3Achangelog-panel',
            ProjectSite => 'http://logicLAB.jira.com/browse/PCLL',
            ProjectWiki => 'http://logiclab.jira.com/wiki/display/PCLL/Home',
        }
    },
);

$build->create_build_script();
