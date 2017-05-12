use lib 't';
use Test::Siebel::Srvrmgr::ListParser;
use constant LATEST => '8.1.1.11_23030.txt';

my $fixed_test =
  Test::Siebel::Srvrmgr::ListParser->new(
    { output_file => [ 't', 'output', 'fixed', LATEST ] } );

my $delimited_test = Test::Siebel::Srvrmgr::ListParser->new(
    {
        col_sep     => '|',
        output_file => [ 't', 'output', 'delimited', LATEST ]
    }
);

Test::Class->runtests( $fixed_test, $delimited_test );

