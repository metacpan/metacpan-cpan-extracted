# Build.PL for Bundle-JONASBN

# $Id$

use strict;
use warnings;
use Module::Build::Bundle;

our $VERSION = '0.05';

my $build = Module::Build::Bundle->new(
    dist_author        => 'Jonas B. Nielsen (jonasbn), <jonasbn@cpan.org>',
    module_name        => 'Task::BeLike::JONASBN',
    license            => 'artistic',
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    configure_requires => {
        'Tie::IxHash' => '0',    #used in dist
    },
    requires => {
        'AppConfig'                   => '0',
        'App::Ack'                    => '0',
        'App::Prove'                  => '0',
        'Class::Accessor'             => '0',
        'CPAN::Mini'                  => '0',
        'CPAN::Reporter'              => '0',
        'Cwd'                         => '0',
        'DBD::Mock'                   => '0',
        'DBI'                         => '0',
        'Data::Dumper'                => '0',
        'Data::FormValidator'         => '0',
        'Date::Calc'                  => '0',
        'DateTime'                    => '0',
        'Devel::Cover'                => '1.00',
        'Error'                       => '0',
        'ExtUtils::Install'           => '1.47',
        'File::Copy'                  => '0',
        'File::Find::Rule'            => '0',
        'File::Path'                  => '0',
        'File::Slurp'                 => '0',
        'File::Which'                 => '0',
        'Hash::Merge'                 => '0',
        'JSON'                        => '0',
        'List::MoreUtils'             => '0',
        'local::lib'                  => '0',
        'Module::Build'               => '0.35',
        'Module::Info::File'          => '0',
        'Module::Load'                => '0',
        'Params::Validate'            => '0.85',
        'Perl::Critic'                => '0',
        'Perl::Critic::logicLAB'      => '0',
        'Perl::Critic::Bangs'         => '0',
        'Perl::Tidy'                  => '0',
        'Pod::Simple::Wiki'           => '0',
        'Spreadsheet::WriteExcel'     => '0',
        'TAP::Formatter::JUnit'       => '0',
        'Task::Jenkins'               => '0',
        'Tie::IxHash'                 => '0',
        'Template'                    => '0',
        'Test::Class'                 => '0',
        'Test::CPAN::Changes'         => '0',
        'Test::DatabaseRow'           => '0',
        'Test::Exception'             => '0',
        'Test::Fatal'                 => '0',
        'Test::Kwalitee'              => '0',
        'Test::MockObject::Extends'   => '0',
        'Test::More'                  => '0',
        'Test::Perl::Critic'          => '0',
        'Test::Pod'                   => '1.14',
        'Test::Pod::Coverage'         => '1.04',
        'Test::Prereq'                => '0',
        'Term::ReadLine::Perl'        => '0',
        'Try::Tiny'                   => '0',
        'WWW::Mechanize'              => '0',
        'WWW::Mechanize::Cached'      => '0',
        'XML::Simple'                 => '0',
        'YAML'                        => '0',
        'YAML::Shell'                 => '0',
        'perl'                        => '5.6.0',

    },
    meta_merge => {
        resources => {
            homepage => 'http://logiclab.jira.com/wiki/display/BJONASBN/Home',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-BeLike-JONASBN',
            repository => 'https://github.com/jonasbn/bjonasbn',
            ProjectChangelog =>
                'http://logiclab.jira.com/browse/BJONASBN#selectedTab=com.atlassian.jira.plugin.system.project%3Achangelog-panel',
            ProjectSite => 'http://logicLAB.jira.com/browse/BJONASBN',
            ProjectWiki =>
                'http://logiclab.jira.com/wiki/display/BJONASBN/Home',
        }
    },
);

$build->create_build_script();
