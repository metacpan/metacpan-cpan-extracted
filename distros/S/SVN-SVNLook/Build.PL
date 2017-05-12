use Module::Build;
my $build = Module::Build->new
(

module_name => 'SVN::SVNLook',
license => 'perl',
create_makefile_pl => 'passthrough',
dist_author => 'Salvatore E. ScottoDiLuzio <lt>sal.scotto@gmail.com<gt>',
dist_abstract => 'Module to aid in creating subversion hooks'
);
$build->create_build_script;
