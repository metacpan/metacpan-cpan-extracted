use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_servers.txt' ]
    }
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_servers.txt' ]
    }
  );

Test::Class->runtests( $fixed_test, $delimited_test );

