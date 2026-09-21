use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use TestSSHD;

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

use Rex -feature => ['1.4'];
use Rex::Group::Entry::Server;
use Rex::Commands::Run;
use Rex::Commands::Fs;
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

# ---------------------------------------------------------------------------
# 1. Env hash handover through the 4-arg exec($cmd, $path, $option) signature.
#
# Rex::Commands::Run::run invokes $exec->exec($cmd, $path, $option); the 2-arg
# form on Exec::Base bound $path to $option, so $option ended up undef and the
# env hash never reached the shell wrapper. Commit d2a197d rewrote exec() to
# the 4-arg form and routes $option->{env} through Rex::Interface::Shell::Bash,
# which prepends `export KEY=val;` to the command.
#
# Without the fix, $MYVAR on the remote is empty and the assertion fails.
# ---------------------------------------------------------------------------
my $out = run 'echo $MYVAR', env => { MYVAR => 'hello-libssh' };
chomp $out;
is $out, 'hello-libssh',
  'env => { MYVAR => ... } reaches the remote shell (4-arg exec)';

# A second env variable, just to confirm the hash shape isn't a coincidence.
my $out2 = run 'echo "$A/$B"', env => { A => 'alpha', B => 'beta' };
chomp $out2;
is $out2, 'alpha/beta', 'env with multiple keys reaches the remote shell';

# $? must still capture the remote exit code after a failed run. The 4-arg
# rewrite kept the $? = $exit << 8 assignment in _exec; this is the contract
# every Fs predicate below relies on.
run 'exit 7', auto_die => 0;
is $?, 7 << 8, '$? captures remote exit status after run';

# ---------------------------------------------------------------------------
# 2. 1-arg call ($exec->exec($cmd)) still works.
#
# Fs::LibSSH::_run (and Fs::Base::_exec, used by ln/rmdir/chown/chmod/cp)
# call $exec->exec($cmd) with $path and $option undef. The 4-arg form has to
# tolerate that or every is_file / stat / ls / mkdir would crash.
#
# Exercising is_file / stat here is the contract: if exec() crashes on the
# 1-arg path the test never reaches the assertion.
# ---------------------------------------------------------------------------
ok is_file('/etc/hostname'),       'is_file via 1-arg exec path';
ok is_dir('/tmp'),                 'is_dir via 1-arg exec path';
ok !is_file('/nonexistent/path/x'), 'is_file negative via 1-arg exec path';

my %st = stat('/etc/hostname');
ok $st{size} > 0,     'stat returns size > 0 via 1-arg exec path';
ok defined $st{uid},  'stat returns uid via 1-arg exec path';
ok defined $st{mode}, 'stat returns mode via 1-arg exec path';

# ---------------------------------------------------------------------------
# Behavioural changes that came along with d2a197d (not asserted here):
#
#   * $shell->set_locale("C") on every command — mirrors Exec::SSH, makes
#     command output deterministic regardless of the user's locale.
#   * Rex::Config->get_source_global_profile / get_source_profile are
#     honoured — mirrors Exec::SSH, lets Rexfiles opt in to sourcing
#     /etc/profile and ~/.profile before each command.
#
# These are intentional and documented in the commit message.
# ---------------------------------------------------------------------------

Rex::pop_connection();

done_testing;
