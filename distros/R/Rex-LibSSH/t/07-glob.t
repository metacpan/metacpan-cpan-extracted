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
use Rex::Interface::Fs::LibSSH;
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

my $dir = "/tmp/rex-libssh-glob-$$";
run "mkdir '$dir' '$dir/my dir'";
run "touch '$dir/a.conf' '$dir/b.conf' '$dir/with space.conf' '$dir/my dir/x.txt'";
run "ln -s '$dir/nowhere' '$dir/dangling.conf'";

my $fs = Rex::Interface::Fs::LibSSH->new;

is_deeply [ $fs->glob("$dir/*.xyz") ], [], 'wildcard without matches returns ()';

is_deeply [ $fs->glob("$dir/*.conf") ],
    [ "$dir/a.conf", "$dir/b.conf", "$dir/dangling.conf", "$dir/with space.conf" ],
    'one element per file, name with a space stays whole, dangling link kept';

is_deeply [ $fs->glob("$dir/my dir/*") ], [ "$dir/my dir/x.txt" ],
    'pattern with a space in the directory expands as one word';

is_deeply [ $fs->glob("$dir/a.conf") ], [ "$dir/a.conf" ],
    'literal existing path is returned';

is_deeply [ $fs->glob("$dir/missing.conf") ], ["$dir/missing.conf"],
    'plain missing path is returned unchanged, like perl glob';

is_deeply [ $fs->glob("$dir/{a,nope,with space}.conf") ],
    [ "$dir/a.conf", "$dir/nope.conf", "$dir/with space.conf" ],
    'braces without wildcard: all alternatives, existing or not';

is_deeply [ $fs->glob("$dir/{a,zzz}.conf") ], [ "$dir/a.conf", "$dir/zzz.conf" ],
    'brace alternatives returned in order';

is_deeply [ $fs->glob("$dir/{b,*.xyz}.conf") ], ["$dir/b.conf"],
    'brace alternative with an unmatched wildcard yields nothing';

run "rm -rf '$dir'";
done_testing;
