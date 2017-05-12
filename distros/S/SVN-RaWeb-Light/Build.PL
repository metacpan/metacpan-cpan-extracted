use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;
use SVN::RaWeb::Light::GenHelp;

_gen_help();

# This is done to be able to depend on SVN::Core.
$SVN::Core::VER_MAJOR = '1';
$SVN::Core::VER_MINOR = '6';
$SVN::Core::VER_MICRO = '6';

my $v = $SVN::Core::VER_MAJOR . $SVN::Core::VER_MINOR . $SVN::Core::VER_MICRO;

my $build = Test::Run::Builder->new(
    module_name => 'SVN::RaWeb::Light',
    dist_version_from => 'lib/SVN/RaWeb/Light.pm', # finds $VERSION
    requires =>
    {
        'CGI' => 0,
        'Class::Accessor' => 0,
        'IO::Scalar' => 0,
        'strict' => 0,
        'SVN::Core' => 0,
        'SVN::Ra' => 0,
        'perl' => '5.008',
        'vars' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'base' => 0,
        'strict' => 0,
        'Test::More' => 0,
        'warnings' => 0,
    },
    configure_requires =>
    {
        'File::Spec' => 0,
        'lib' => 0,
        'Module::Build' => '0.36',
    },
    license => 'mit',
    dist_author => 'Shlomi Fish',
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-svn-raweb-light",
            homepage => "http://web-cpan.shlomifish.org/modules/SVN-RaWeb-Light/",
        },
        keywords =>
        [
            "browser",
            "light",
            "subversion",
            "vcs",
            "web",
            "www",
        ],
    },
);

$build->create_build_script;

