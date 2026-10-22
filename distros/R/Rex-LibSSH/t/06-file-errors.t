use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

use Rex -feature => ['1.4'];
use Rex::Group::Entry::Server;
use Rex::Commands::Run;
use Rex::Interface::File;
use Rex::Config;

set connection => 'LibSSH';

Rex::Config->set_user( scalar getpwuid($<) );
Rex::Config->set_private_key( $srv->client_key );
Rex::Config->set_public_key( $srv->client_key . '.pub' );

Rex::connect(
    server      => $srv->host,
    port        => $srv->port,
    user        => scalar( getpwuid($<) ),
    private_key => $srv->client_key,
    public_key  => $srv->client_key . '.pub',
    auth_type   => 'key',
    knownhosts  => $srv->known_hosts,
);

my $dir = "/tmp/rex-libssh-fileerr-$$";
run "mkdir '$dir'";

# --- read of a missing file is a failure, not an empty file ---
{
    my $fh = Rex::Interface::File->create;
    ok !$fh->open( '<', "$dir/missing" ), 'open < on a missing file returns false';
}

# --- read of an existing file works ---
run "printf 'abc' > '$dir/present'";
{
    my $fh = Rex::Interface::File->create;
    ok $fh->open( '<', "$dir/present" ), 'open < on an existing file returns true';
    is $fh->read(10), 'abc', 'content read back';
    $fh->close;
}

# --- write into a non-existent directory dies at close ---
{
    my $fh = Rex::Interface::File->create;
    ok $fh->open( '>', "$dir/no/such/dir/f" ), 'open > itself succeeds (cat runs remote)';
    $fh->write("data\n");
    like eval { $fh->close; 1 } ? '' : $@, qr/writing .* failed \(exit [1-9]/,
        'close dies when cat exited non-zero';
}

# --- a good write still works and close returns true ---
{
    my $fh = Rex::Interface::File->create;
    ok $fh->open( '>', "$dir/ok" ), 'open > ok';
    $fh->write("hello\n");
    ok $fh->close, 'close returns true on success';
    is run("cat '$dir/ok'"), 'hello', 'content written';
}

# --- close is idempotent ---
{
    my $fh = Rex::Interface::File->create;
    $fh->open( '>', "$dir/ok2" );
    $fh->close;
    ok eval { $fh->close; 1 }, 'second close does not die';
}

run "rm -rf '$dir'";
done_testing;
