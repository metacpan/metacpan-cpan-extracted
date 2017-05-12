# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name => "SVN::Pusher",
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'perl'        => '5.8.8',
        'SVN::Core'   => 0,
        'URI::Escape' => '0',
    },
    dist_version_from => "lib/SVN/Pusher.pm",
    license => "perl",
    create_makefile_pl => 'traditional',
    script_files => ["bin/svn-pusher"],
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-svn-pusher",
        },
    },
);

$builder->create_build_script;

