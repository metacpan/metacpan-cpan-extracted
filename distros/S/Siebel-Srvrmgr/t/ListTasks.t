use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_tasks.txt' ]
    }
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_tasks.txt' ]
    }
  );

Test::Class->runtests( $fixed_test, $delimited_test );

