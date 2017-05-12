use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompDef;
use File::Spec;
my $fixed_test =
  Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompDef->new( data_file => File::Spec->catfile( ( 't', 'output', 'fixed', 'list_comp_def.txt' ) ) );
Test::Class->runtests($fixed_test);
