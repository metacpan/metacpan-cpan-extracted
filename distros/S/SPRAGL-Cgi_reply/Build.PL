# Build.PL for SPRAGL::Cgi_reply.
use Module::Build;
use strict;
use 5.030000;

Module::Build->new(
    module_name         => 'SPRAGL::Cgi_reply' ,
    license             => 'apache' ,
    dist_author         => 'Bjoern Hee <github@spredehagl.com>' ,
    dist_abstract       => 'Simple HTTP replies.' ,
    dist_version_from   => 'lib/SPRAGL/Cgi_reply.pm' ,
    create_makefile_pl  => 0 ,
    create_readme       => 0 ,
    requires            => {
        'File::Basename'  => 0 ,
        'File::Spec'      => 0 ,
        'JSON'            => 0 ,
        } ,
    test_requires       => {
        'Capture::Tiny'   => 0 ,
        'Cwd'             => 0 ,
        'File::Basename'  => 0 ,
        'Try::Tiny'       => 0 ,
        } ,
    meta_merge => {
        resources => {
            repository => 'https://github.com/spragl/Cgi_reply' ,
            bugtracker => 'https://github.com/spragl/Cgi_reply/issues' ,
            } ,
        } ,
    )->create_build_script;
