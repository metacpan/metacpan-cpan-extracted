package P4::Server::Test::Server::Helper::Timeout;

use base qw( P4::Server );

use Class::Std;

{

# We're going to force a timeout by not actually spawning anything.
sub _spawn_p4d : PROTECTED {
    # This will work for the current implementation and is safe if it
    # accidentally gets killed somehow.
    return 0;
}

}

1;
