package P4::Server::Test::Server::Helper::KillChld;

use base qw( P4::Server );

use Class::Std;

{

# We're going to force a signal by killing ourselves.
sub _spawn_p4d : PROTECTED {
    kill( CHLD, $$ );

    # This will work for the current implementation and is safe if it
    # accidentally gets killed somehow.
    return 0;
}

}

1;
