use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

author 'Robert Rothenberg <rrwo@cpan.org>';
name 'Pod-Readme';
all_from 'lib/Pod/Readme.pm';
license 'perl';

perl_version '5.10.1';

tests_recursive('t');

resources(
    homepage   => 'https://metacpan.org/pod/Pod::Readme',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/bigpresh/Pod-Readme.git',
    bugtracker => 'https://github.com/bigpresh/Pod-Readme/issues',
);

configure_requires();

build_requires(
    'Exporter'        => 0,
    'File::Compare'   => 0,
    'File::Temp'      => 0,    # included in Path::Tiny anyway
    'IO::String'      => 0,
    'Test::Deep'      => 0,
    'Test::Exception' => 0,

    # 'Test::Kit'       => '2.10', # Buggy with Test::Builder 1.301001_056
    'Test::More' => 0,
    'lib'        => 0,
);

requires(
    'Carp'                      => 0,
    'Class::Method::Modifiers'  => '2.00',
    'CPAN::Changes'             => '0.30',
    'CPAN::Meta'                => 0,
    'Exporter'                  => 0,
    'ExtUtils::MakeMaker'       => 6.56,
    'File::Copy'                => 0,
    'File::Slurp'               => 0,
    'Getopt::Long::Descriptive' => 0,
    'Hash::Util'                => 0,
    'IO'                        => 0,
    'List::Util'                => 1.33,
    'Module::CoreList'          => 0,
    'Module::Load'              => 0,
    'Moo'                       => 1.004005,
    'Moo::Role'                 => 0,
    'MooX::HandlesVia'          => 0,
    'namespace::autoclean'      => 0,
    'Path::Tiny'                => 0.018,
    'Pod::Simple'               => 0,
    'Role::Tiny'                => 0,
    'Scalar::Util'              => 0,
    'Try::Tiny'                 => 0,
    'Type::Tiny'                => 0,
    'Types::Standard'           => 0,
    'version'                   => 0.77,
);

recommends(
    'Pod::Simple::LaTeX' => 0,
    'Pod::Man'           => 0,
    'Pod::Markdown'      => 0,
    'Type::Tiny::XS'     => 0,
);

install_script(qw{ bin/pod2readme });

author_requires(
    'Module::Install::AuthorRequires' => 0.02,
    'Module::Install::AuthorTests'    => 0,
    'Test::CPAN::Meta'                => 0,
    'Test::CheckManifest'             => 0.9,
    'Test::CleanNamespaces'           => 0,
    'Test::Command'                   => 0,
    'Test::ConsistentVersion'         => 0,
    'Test::MinimumVersion'            => 0,
    'Test::Perl::Critic'              => 0,
    'Test::Pod'                       => '1.00',
    'Test::Pod::Coverage'             => 0,
    'Test::Portability::Files'        => 0,
);

recursive_author_tests('xt');

install_as_cpan;
auto_install;
WriteAll;
