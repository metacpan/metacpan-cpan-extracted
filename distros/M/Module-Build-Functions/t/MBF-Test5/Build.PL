use inc::Module::Build::Functions::DSL;

module_name         MBF::Test
license             perl
perl_version        5.005
dist_author         'Curtis Jewell <csjewell@cpan.org>'
dist_author         'Curtis Jewell <perl@csjewell.fastmail.us>'
dist_version_from   lib/MBF/Test.pm
requires 		    File::Slurp
test_requires       Test::More
build_requires      Test::Compile
add_to_cleanup      MBF-Test-*
create_makefile_pl  passthrough
install_share
install_share		module MBF share_mod1
install_share		module MBF::Test share_mod2
create_license      1
