use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef;

my $file = 'list_comp_def.txt';

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', $file ]
    }
  );

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', $file ]
    }
  );

Test::Class->runtests( $fixed_test, $delimited_test );
