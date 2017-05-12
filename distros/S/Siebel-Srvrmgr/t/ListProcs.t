use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListProcs;

my $delimited_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular::ListProcs->new(
    {
        structure_type => 'delimited',
        col_sep        => '|',
        output_file    => [ 't', 'output', 'delimited', 'list_procs.txt' ]
    }
  );

Test::Class->runtests($delimited_test);

