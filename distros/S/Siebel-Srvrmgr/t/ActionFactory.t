use lib 't';
use Test::Siebel::Srvrmgr::Daemon::ActionFactory;

my $filename = 'list_comp.txt';

my $fixed = Test::Siebel::Srvrmgr::Daemon::ActionFactory->new(
    {
        structure_type => 'fixed',
        output_file    => [ qw(t output fixed), $filename ]
    }
);

Test::Class->runtests( $fixed );
