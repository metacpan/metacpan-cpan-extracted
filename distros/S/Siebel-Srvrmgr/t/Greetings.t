use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::Enterprise;

my $test = Test::Siebel::Srvrmgr::ListParser::Output::Enterprise->new(
    { output_file => [qw(t output greetings.txt)] } );

Test::Class->runtests($test);
