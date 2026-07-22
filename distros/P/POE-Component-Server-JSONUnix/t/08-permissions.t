use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Socket qw(PF_UNIX SOCK_STREAM);

BEGIN {
    unless ( eval { require POE; require JSON::MaybeXS; 1 } ) {
        plan skip_all =>
            'POE and JSON::MaybeXS are required for the permissions test';
    }
}

plan skip_all => 'fork is not available on this platform'
    unless $Config{d_fork};
plan skip_all => 'Unix domain sockets are unavailable'
    unless eval { socket( my $s, PF_UNIX, SOCK_STREAM, 0 ) };

use POE;
use POE::Component::Server::JSONUnix;
use POE::Component::Server::JSONUnix::BlockingClient;

# ---------------------------------------------------------------------------
# Who are we, according to NSS? Computed with the same getpw*/getgr* walk the
# server uses, so the expectations below are what the server must arrive at.
# ---------------------------------------------------------------------------
my $my_uid      = $>;
my $my_username = ( getpwuid($my_uid) )[0] // '';
plan skip_all => 'cannot resolve the current user in the passwd database'
    unless length $my_username;

my ( %exp_group_names, %exp_gids );
my $primary_gid = ( getpwuid($my_uid) )[3];
$exp_gids{$primary_gid} = 1;
my $primary_group = getgrgid($primary_gid);
$exp_group_names{$primary_group} = 1 if defined $primary_group;

setgrent();
while ( my @gr = getgrent() ) {
    my ( $group_name, $gid, $members ) = @gr[ 0, 2, 3 ];
    next unless defined $members && grep { $_ eq $my_username } split ' ', $members;
    $exp_gids{$gid} = 1;
    $exp_group_names{$group_name} = 1 if defined $group_name;
}
endgrent();

my @expected_groups = sort keys %exp_group_names;

# A genuinely secondary group (not the primary), if the user has one.
my ($secondary_group) =
    grep { $_ ne ( $primary_group // '' ) } @expected_groups;

# A group the user does NOT belong to, if one exists on the system.
my $foreign_group;
setgrent();
while ( my @gr = getgrent() ) {
    next if $exp_gids{ $gr[2] } || $exp_group_names{ $gr[0] };
    $foreign_group = $gr[0];
    last;
}
endgrent();

# ---------------------------------------------------------------------------
# Servers (in a forked child): one default-allow with per-command rules, one
# default-deny with carve-outs.
# ---------------------------------------------------------------------------
my $dir           = tempdir( CLEANUP => 1 );
my $sock_allow    = "$dir/allow.sock";
my $sock_deny     = "$dir/deny.sock";
my $sock_fallback = "$dir/fallback.sock";
my $auth_tmp      = "$dir/auth_files";
mkdir $auth_tmp or die "mkdir: $!";

my $pid = fork;
defined $pid or plan skip_all => "fork failed: $!";

if ( $pid == 0 ) {
    my $ran = sub { return { ran => 1 } };

    POE::Component::Server::JSONUnix->spawn(
        socket_path   => $sock_allow,
        alias         => 'server_allow',
        auth_temp_dir => $auth_tmp,
        permissions   => {
            default  => 'allow',
            commands => {
                by_name            => { users => [$my_username] },
                by_uid             => { users => [$my_uid] },
                by_primary_group   => { groups => [ $primary_group // 'no_such_group_zz' ] },
                by_gid             => { groups => [$primary_gid] },
                by_secondary_group => { groups => [ $secondary_group // 'no_such_group_zz' ] },
                other_user         => { users  => ['no_such_user_zz'] },
                other_group        => { groups => [ $foreign_group // 'no_such_group_zz' ] },
                deny_wins          => { users => [$my_username], deny_users  => [$my_username] },
                deny_group_wins    => { users => [$my_username], deny_groups => [ $primary_group // 'no_such_group_zz' ] },
                checked            => {
                    check => sub {
                        my ( $server, $ctx, $command ) = @_;
                        return ( $ctx->request->{args}{magic} // '' ) eq 'xyzzy';
                    },
                },
                blocked => 'deny',
            },
        },
        commands => {
            (   map { $_ => $ran }
                    qw(by_name by_uid by_primary_group by_gid by_secondary_group
                    other_user other_group deny_wins deny_group_wins checked blocked open_cmd)
            ),
            report => sub {
                my ( $server, $req, $ctx ) = @_;
                return {
                    groups      => $ctx->groups,
                    in_primary  => $ctx->in_group( $primary_group // '' )        ? 1 : 0,
                    in_gid      => $ctx->in_group($primary_gid)                  ? 1 : 0,
                    in_foreign  => $ctx->in_group( $foreign_group // 'no_such' ) ? 1 : 0,
                    may_by_name => $ctx->may('by_name')                          ? 1 : 0,
                    may_blocked => $ctx->may('blocked')                          ? 1 : 0,
                };
            },
        },
    );

    POE::Component::Server::JSONUnix->spawn(
        socket_path   => $sock_deny,
        alias         => 'server_deny',
        auth_temp_dir => $auth_tmp,
        permissions   => {
            default  => 'deny',
            commands => {
                status => 'allow',
                gated  => { users => [$my_username] },
            },
        },
        commands => {
            status => sub { return { up => 1 } },
            gated  => sub { return { ran => 1 } },
        },
    );

    POE::Component::Server::JSONUnix->spawn(
        socket_path   => $sock_fallback,
        alias         => 'server_fallback',
        auth_temp_dir => $auth_tmp,
        permissions   => {
            default  => 'deny',    # the '%DEFAULT%' entry below must win over this
            commands => {
                '%DEFAULT%' => { users => [$my_username] },
                carved      => 'allow',
                not_me      => { users => ['no_such_user_zz'] },
            },
        },
        commands => {
            anything => sub { return { ran => 1 } },
            carved   => sub { return { ran => 1 } },
            not_me   => sub { return { ran => 1 } },
        },
    );

    $poe_kernel->run;
    require POSIX;
    POSIX::_exit(0);
} ## end if ( $pid == 0 )

# ---------------------------------------------------------------------------
# Parent: drive both servers through the BlockingClient.
# ---------------------------------------------------------------------------
sub connect_client {
    my ($path) = @_;
    for ( 1 .. 100 ) {
        my $client = eval {
            POE::Component::Server::JSONUnix::BlockingClient->new(
                socket_path => $path,
                timeout     => 10,
            );
        };
        return $client if $client;
        select undef, undef, undef, 0.05;
    }
    return;
}

my $client = connect_client($sock_allow);
unless ( ok( $client, 'default-allow server came up' ) ) {
    kill 'TERM', $pid;
    waitpid $pid, 0;
    done_testing();
    exit 0;
}

# --- before authentication ---------------------------------------------------

my $r = $client->call( command => 'ping' );
is( $r->{status}, 'ok', 'no rule + default allow: works unauthenticated' );

$r = $client->call( command => 'open_cmd' );
is( $r->{status}, 'ok', 'unrestricted command works unauthenticated' );

$r = $client->call( command => 'by_name' );
is( $r->{status}, 'error',         'user/group rule requires authentication' );
is( $r->{code},   'auth_required', 'auth_required code' );

$r = $client->call( command => 'blocked' );
is( $r->{status}, 'error',             "'deny' rule refuses unauthenticated callers too" );
is( $r->{code},   'permission_denied', 'permission_denied code' );

# --- authenticate -------------------------------------------------------------

my $auth = $client->authenticate;
is( $auth->{status}, 'ok', 'authentication succeeds' );
is_deeply(
    $auth->{result}{groups},
    \@expected_groups,
    'auth_verify reports the NSS group list (primary + secondary)'
);
is_deeply( $client->groups, \@expected_groups, 'client groups() accessor matches' );

# --- allows -------------------------------------------------------------------

for my $command (qw(by_name by_uid by_gid)) {
    $r = $client->call( command => $command );
    is( $r->{status}, 'ok', "$command: allowed" );
}

SKIP: {
    skip 'current user has no resolvable primary group name', 1
        unless defined $primary_group;
    $r = $client->call( command => 'by_primary_group' );
    is( $r->{status}, 'ok', 'by_primary_group: allowed' );
}

SKIP: {
    skip 'current user has no secondary group', 1
        unless defined $secondary_group;
    $r = $client->call( command => 'by_secondary_group' );
    is( $r->{status}, 'ok', 'by_secondary_group: allowed via supplementary membership' );
}

$r = $client->call( command => 'checked', args => { magic => 'xyzzy' } );
is( $r->{status}, 'ok', 'check coderef: allowed when it returns true' );

# --- denies -------------------------------------------------------------------

for my $command (qw(other_user other_group deny_wins deny_group_wins blocked)) {
    $r = $client->call( command => $command );
    is( $r->{status}, 'error',             "$command: denied" );
    is( $r->{code},   'permission_denied', "$command: permission_denied code" );
}

$r = $client->call( command => 'checked', args => { magic => 'wrong' } );
is( $r->{status}, 'error',             'check coderef: denied when it returns false' );
is( $r->{code},   'permission_denied', 'check coderef: permission_denied code' );

# --- discovery and context helpers --------------------------------------------

$r = $client->call( command => 'commands' );
is( $r->{status}, 'ok', 'commands builtin works' );
my %listed = map { $_ => 1 } @{ $r->{result}{commands} };
ok( $listed{by_name},   'commands lists a permitted command' );
ok( $listed{ping},      'commands lists an unrestricted command' );
ok( !$listed{blocked},  'commands hides a denied command' );
ok( !$listed{other_user}, 'commands hides a command allowed only to others' );

$r = $client->call( command => 'report' );
is( $r->{status}, 'ok', 'report handler ran' );
is_deeply( $r->{result}{groups}, \@expected_groups, 'ctx->groups matches NSS expectation' );
SKIP: {
    skip 'current user has no resolvable primary group name', 1
        unless defined $primary_group;
    is( $r->{result}{in_primary}, 1, 'ctx->in_group by name' );
}
is( $r->{result}{in_gid}, 1, 'ctx->in_group by gid' );
SKIP: {
    skip 'no foreign group found on this system', 1
        unless defined $foreign_group;
    is( $r->{result}{in_foreign}, 0, 'ctx->in_group false for a foreign group' );
}
is( $r->{result}{may_by_name}, 1, 'ctx->may true for a permitted command' );
is( $r->{result}{may_blocked}, 0, 'ctx->may false for a denied command' );

# Unknown commands still behave normally under default allow.
$r = $client->call( command => 'no_such_command_zz' );
is( $r->{status}, 'error', 'unknown command still errors' );
like( $r->{error}, qr/unknown command/, 'unknown-command message' );

$client->disconnect;

# ---------------------------------------------------------------------------
# Default-deny server.
# ---------------------------------------------------------------------------
my $deny_client = connect_client($sock_deny);
ok( $deny_client, 'default-deny server came up' );

$r = $deny_client->call( command => 'ping' );
is( $r->{status}, 'error',             'default deny: unlisted builtin refused' );
is( $r->{code},   'permission_denied', 'default deny: permission_denied code' );

$r = $deny_client->call( command => 'no_such_command_zz' );
is( $r->{status}, 'error',             'default deny: unknown command refused the same way' );
is( $r->{code},   'permission_denied', 'default deny: does not reveal whether the command exists' );

$r = $deny_client->call( command => 'status' );
is( $r->{status}, 'ok', "explicit 'allow' carve-out works unauthenticated" );

$r = $deny_client->call( command => 'gated' );
is( $r->{code}, 'auth_required', 'default deny: user rule still asks for auth first' );

$auth = $deny_client->authenticate;
is( $auth->{status}, 'ok', 'handshake commands are always reachable under default deny' );

$r = $deny_client->call( command => 'gated' );
is( $r->{status}, 'ok', 'user rule allows after authentication' );

$r = $deny_client->call( command => 'ping' );
is( $r->{status}, 'error', 'default deny still applies to unlisted commands after auth' );

$deny_client->disconnect;

# ---------------------------------------------------------------------------
# '%DEFAULT%' fallback rule.
# ---------------------------------------------------------------------------
my $fallback_client = connect_client($sock_fallback);
ok( $fallback_client, '%DEFAULT% server came up' );

$r = $fallback_client->call( command => 'anything' );
is( $r->{code}, 'auth_required',
    '%DEFAULT% hash rule asks for auth, taking precedence over default deny' );

$r = $fallback_client->call( command => 'carved' );
is( $r->{status}, 'ok', "an explicit 'allow' entry still wins over %DEFAULT%" );

$auth = $fallback_client->authenticate;
is( $auth->{status}, 'ok', 'handshake works on the %DEFAULT% server' );

$r = $fallback_client->call( command => 'anything' );
is( $r->{status}, 'ok', '%DEFAULT% allows a matching user on an unlisted command' );

$r = $fallback_client->call( command => 'ping' );
is( $r->{status}, 'ok', '%DEFAULT% covers builtins without entries too' );

$r = $fallback_client->call( command => 'not_me' );
is( $r->{code}, 'permission_denied', "a command's own rule beats %DEFAULT%" );

$r = $fallback_client->call( command => 'no_such_command_zz' );
like( $r->{error}, qr/unknown command/,
    '%DEFAULT% lets an unknown command through the gate to the normal error' );

$fallback_client->disconnect;

# ---------------------------------------------------------------------------
# spawn() validation and no-policy compatibility, in-process (no kernel run).
# ---------------------------------------------------------------------------
for my $bad (
    [ 'not a hashref'   => 'nope' ],
    [ 'bad default'     => { default => 'maybe' } ],
    [ 'unknown key'     => { defualt => 'deny' } ],
    [ 'bad spec string' => { commands => { x => 'never' } } ],
    [ 'bad spec type'   => { commands => { x => ['wheel'] } } ],
    [ 'bad list type'   => { commands => { x => { users => 'zane' } } } ],
    [ 'unknown rule key' => { commands => { x => { group => ['wheel'] } } } ],
    [ 'bad check'       => { commands => { x => { check => 1 } } } ],
    )
{
    my ( $label, $perms ) = @$bad;
    my $lived = eval {
        POE::Component::Server::JSONUnix->spawn(
            socket_path => "$dir/never_$label.sock",
            permissions => $perms,
        );
        1;
    };
    ok( !$lived, "spawn croaks on invalid permissions: $label" );
}

# ---------------------------------------------------------------------------
kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();
