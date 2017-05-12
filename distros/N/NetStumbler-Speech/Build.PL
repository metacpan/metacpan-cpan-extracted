use Module::Build;
my $build = Module::Build->new
(

module_name => 'NetStumbler::Speech',
license => 'perl',
create_makefile_pl => 'passthrough',
dist_author => 'Salvatore E. ScottoDiLuzio <lt>washu@olypmus.net<gt>',
dist_abstract => 'Module to manipulate MS TTS Com object'
);
$build->create_build_script;