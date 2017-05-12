use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_comp_types.txt' ]
    }
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_comp_types.txt' ]
    }
  );

Test::Class->runtests( $fixed_test, $delimited_test );

