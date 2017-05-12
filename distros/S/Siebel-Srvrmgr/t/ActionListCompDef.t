use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::ListCompDef;

my $filename = 'list_comp_def.txt';

my $fixed = Test::Siebel::Srvrmgr::Daemon::Action::ListCompDef->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output fixed), $filename ]
    }
);

my $delimited = Test::Siebel::Srvrmgr::Daemon::Action::ListCompDef->new(
    {
        col_sep        => '|',
        structure_type => 'delimited',
        output_file    => [ qw(t output delimited), $filename ]
    }
);

Test::Class->runtests( $fixed, $delimited );
