use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::ListParams;

my $filename = 'list_params_for_srproc.txt';

my $fixed = Test::Siebel::Srvrmgr::Daemon::Action::ListParams->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output fixed), $filename ]
    }
);

my $delimited = Test::Siebel::Srvrmgr::Daemon::Action::ListParams->new(
    {
        col_sep        => '|',
        structure_type => 'delimited',
        output_file    => [ qw(t output delimited), $filename ]
    }
);

Test::Class->runtests( $fixed, $delimited );
