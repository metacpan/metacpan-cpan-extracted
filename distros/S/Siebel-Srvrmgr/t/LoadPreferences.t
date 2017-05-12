use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Output::LoadPreferences;

my $test = Test::Siebel::Srvrmgr::ListParser::Output::LoadPreferences->new(
    { output_file => [qw(t output load_preferences.txt)] } );

Test::Class->runtests($test);
