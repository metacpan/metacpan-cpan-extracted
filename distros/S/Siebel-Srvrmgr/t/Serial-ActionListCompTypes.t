use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompTypes;
use File::Spec;

Test::Class->runtests(
    Test::Siebel::Srvrmgr::Daemon::Action::Serializable::ListCompTypes->new(
        data_file => File::Spec->catfile(qw(t output fixed list_comp_types.txt))
    )
);
