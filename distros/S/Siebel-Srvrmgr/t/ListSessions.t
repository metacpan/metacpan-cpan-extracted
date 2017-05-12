use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_sessions.txt' ]
    }
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_sessions.txt' ]
    }
  );

Test::Class->runtests( $fixed_test, $delimited_test );

