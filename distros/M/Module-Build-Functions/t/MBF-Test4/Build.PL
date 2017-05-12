# use strict;
# $^W = 1; # Can't use "use warnings", see perl_version below.
use inc::Module::Build::Functions;

module_name         'MBF::Test';
license             'perl';
perl_version        '5.005';
dist_author         'Curtis Jewell <csjewell@cpan.org>';
dist_author         'Curtis Jewell <perl@csjewell.fastmail.us>';
dist_version_from   'lib/MBF/Test.pm';
requires 		    'File::Slurp' => 0.01;
test_requires       'Test::More';
build_requires      'Test::Compile';
add_to_cleanup      'MBF-Test-*';
create_makefile_pl  'passthrough';
create_license      1;

create_build_script;