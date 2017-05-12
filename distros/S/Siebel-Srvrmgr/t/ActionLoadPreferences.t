use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::LoadPreferences;

my $filename = 'load_preferences.txt';

my $fixed = Test::Siebel::Srvrmgr::Daemon::Action::LoadPreferences->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output), $filename ]
    }
);

Test::Class->runtests( $fixed );
