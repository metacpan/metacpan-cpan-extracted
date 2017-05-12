use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Tabular;

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser::Output::Tabular->new(
    {
        structure_type => 'fixed',
        output_file    => [ 't', 'output', 'fixed', 'list_comp.txt' ]
    }
  );

Test::Class->runtests($fixed_test);
