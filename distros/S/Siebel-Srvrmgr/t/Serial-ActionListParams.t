use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListParams;
use File::Spec;

Test::Class->runtests(
    Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListParams->new(
        data_file =>
          File::Spec->catfile(qw(t output fixed list_params_for_srproc.txt))
    )
);
