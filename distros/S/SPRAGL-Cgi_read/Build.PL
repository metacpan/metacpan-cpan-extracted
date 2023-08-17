# Build.PL for SPRAGL::Cgi_read.
use Module::Build;
use strict;
use 5.030000;

Module::Build->new(
    module_name         => 'SPRAGL::Cgi_read' ,
    license             => 'apache' ,
    dist_author         => 'Bjoern Hee <github@spredehagl.com>' ,
    dist_abstract       => 'Barebones CGI.' ,
    dist_version_from   => 'lib/SPRAGL/Cgi_read.pm' ,
    create_makefile_pl  => 0 ,
    create_readme       => 0 ,
    requires            => {
        'Encode'        => 0 ,
        'List::Util'    => 0 ,
        'Scalar::Util'  => 0 ,
        } ,
    meta_merge => {
        resources => {
            repository => 'https://github.com/spragl/Cgi_read' ,
            bugtracker => 'https://github.com/spragl/Cgi_read/issues' ,
            } ,
        } ,
    )->create_build_script;
