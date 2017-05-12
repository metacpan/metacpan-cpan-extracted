use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::ListServers::Server;

my $fixed =
  Test::Siebel::Srvrmgr::ListParser::Output::ListServers::Server->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_servers.txt' ]
    }
  );

my $delimited =
  Test::Siebel::Srvrmgr::ListParser::Output::ListServers::Server->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_servers.txt' ]
    }
  );

Test::Class->runtests( $fixed, $delimited );
