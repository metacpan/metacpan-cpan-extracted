use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListComps;
use File::Spec;
my $fixed_test =
  Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListComps->new( data_file => File::Spec->catfile( ( 't', 'output', 'fixed', 'list_comp.txt' ) ) );
Test::Class->runtests($fixed_test);
