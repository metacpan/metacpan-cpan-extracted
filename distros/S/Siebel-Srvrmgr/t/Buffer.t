use lib 't';
use Test::Siebel::Srvrmgr::ListParser::Buffer;

my $filename = 'load_preferences.txt';

my $fixed = Test::Siebel::Srvrmgr::ListParser::Buffer->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output), $filename ]
    }
);

Test::Class->runtests($fixed);
