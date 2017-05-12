use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::ListCompTypes;

my $filename = 'list_comp_types.txt';

my $fixed = Test::Siebel::Srvrmgr::Daemon::Action::ListCompTypes->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output fixed), $filename ]
    }
);

my $delimited = Test::Siebel::Srvrmgr::Daemon::Action::ListCompTypes->new(
    {
        col_sep        => '|',
        structure_type => 'delimited',
        output_file    => [ qw(t output delimited), $filename ]
    }
);

Test::Class->runtests( $fixed, $delimited );
