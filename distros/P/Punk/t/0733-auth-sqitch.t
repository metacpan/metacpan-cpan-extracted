#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Spec ();

# `auth sqitch => 1`: the schema Punk::Auth's defaults expect, shipped as
# the Sqitch project punk_auth under lib/Punk/Auth/sqitch and registered
# with Punk-Sqitch, which deploys it before the application's own. A
# stand-in Punk::Plugin::Sqitch records the registration, so this needs
# nothing installed; the shipped project's files are checked directly, and
# deployed for real when App::Sqitch and sqlite3 are around.

my $dir = do {
    (my $d = $INC{'Punk.pm'}) =~ s/\.pm\z//;
    "$d/Auth/sqitch";
};
ok(-f "$dir/sqitch.plan", 'the punk_auth project ships with Punk');
ok(-f "$dir/sqitch.conf", 'with a conf routing each engine to its scripts');
{
    open my $fh, '<', "$dir/sqitch.plan" or die $!;
    my $plan = do { local $/; <$fh> };
    like($plan, qr/^%project=punk_auth$/m, 'named punk_auth');
    like($plan, qr/^users /m, 'a users change');
    like($plan, qr/^auth_tokens \[users\] /m, 'an auth_tokens change depending on it');
}
for my $e (qw(sqlite pg mysql)) {
    for my $kind (qw(deploy revert verify)) {
        ok(-f "$dir/$e/$kind/users.sql" && -f "$dir/$e/$kind/auth_tokens.sql", "$e: $kind scripts for both changes");
    }
}

# ---- without Punk-Sqitch: an error, not a silence ------------------------------
# Only assertable where Punk-Sqitch is genuinely absent: the keyword's croak
# is what a machine without it sees, and a machine with it installed cannot
# be made to forget (the module would already be in %INC by the time any
# @INC trick applied).
SKIP: {
    skip 'Punk-Sqitch is installed here, so its absence cannot be staged', 1
        if eval { require Punk::Plugin::Sqitch; 1 };
    package NoSqitchApp;
    use Punk;
    session secret => 'x' x 32;
    package main;
    my $e = ''; eval { NoSqitchApp->punk_app->auth(model => 'User', sqitch => 1) } or $e = $@;
    like($e, qr/auth sqitch => 1 needs Punk-Sqitch \(Punk::Plugin::Sqitch\) installed/,
        'sqitch => 1 without Punk-Sqitch croaks at the keyword');
}

# ---- with a stand-in Punk-Sqitch: the registration --------------------------------
# A stand-in for the registration, so this needs nothing installed. When the
# real Punk-Sqitch IS installed its `project` is replaced for the rest of
# this file: what is under test is that `auth` calls it with the right
# arguments, not what Punk-Sqitch then does with them.
{
    package Punk::Plugin::Sqitch;
    our @PROJECTS;
    # `once` as well as `redefine`: this glob is the only mention of
    # Punk::Plugin::Sqitch::project in the file, and when the real module is
    # not installed there is nothing else to mention it either.
    no warnings qw(redefine once);
    *project = sub { my ($class, $app, $name, $dir, %o) = @_; push @PROJECTS, [ $app, $name, $dir, \%o ]; return };
    $INC{'Punk/Plugin/Sqitch.pm'} ||= __FILE__;
}
{
    package SqitchApp;
    use Punk;
    session secret => 'x' x 32;
    auth model => 'User', sqitch => 1;
    package main;
    is(scalar @Punk::Plugin::Sqitch::PROJECTS, 1, 'auth sqitch => 1 registered one project');
    my ($app, $name, $d, $o) = @{ $Punk::Plugin::Sqitch::PROJECTS[0] };
    is($name, 'punk_auth', 'named punk_auth');
    is($d, $dir, 'the shipped directory, located from Punk.pm');
    is_deeply($o, { engines => [qw(sqlite pg mysql)] }, 'for the three engines it ships scripts for');
    isa_ok($app, 'Punk::App', 'with the registrar');
    ok(!exists SqitchApp->punk_app->{auth}{sqitch}, 'and the option does not linger in the frozen auth config')
        if ref SqitchApp->punk_app eq 'HASH';
}
{
    package PlainApp;
    use Punk;
    session secret => 'x' x 32;
    auth model => 'User';
    package main;
    is(scalar @Punk::Plugin::Sqitch::PROJECTS, 1, 'without sqitch => 1 nothing is registered');
}

# ---- the project deploys ---------------------------------------------------------------
# App::Sqitch being loadable does not mean its `sqitch` is runnable: it installs
# into the perl's own script directory, which is not on PATH on every machine
# (a CPAN Testers box reported the deploy failing with no output at all, which
# is what backticks give for a command that could not be executed). So the
# command is located and proved to run before anything is asserted about it.
my $sqitch = do {
    require File::Basename;
    require Config;
    my @try = ('sqitch');
    unshift @try, map { "$_/sqitch" }
                  grep { defined && length }
                  File::Basename::dirname($^X),
                  @Config::Config{qw(installsitescript installscript installvendorscript)};
    my $found;
    for my $c (@try) {
        next unless $c eq 'sqitch' || -x $c;
        my $q = $c =~ /\s/ ? qq{"$c"} : $c;
        my $v = `$q --version 2>/dev/null`;
        if (defined $v && $v =~ /sqitch/i) { $found = $q; last }
    }
    $found;
};
SKIP: {
    skip 'a runnable sqitch, DBD::SQLite and sqlite3 required to deploy the project', 4
        unless $sqitch
            && eval { require App::Sqitch; require DBI; require DBD::SQLite; 1 }
            && `sqlite3 -version 2>/dev/null` =~ /\A\d/;
    require File::Temp;
    require Cwd;
    my $tmp = File::Temp->newdir;
    my $cwd = Cwd::getcwd();
    chdir $dir or die $!;
    my $out = `$sqitch deploy --target db:sqlite:$tmp/auth.db 2>&1`;
    my $rc  = $?;
    chdir $cwd;
    $out = '' unless defined $out;
    # The exit status, not the output. Sqitch speaks the smoker's language:
    # under LC_ALL=de_DE it reports "+ users ........ OK", and a pattern
    # written against the English "ok" fails on a deploy that worked. What
    # the deploy actually did is asserted below, against the database.
    is($rc, 0, 'deploys on SQLite') or diag $out;
    # PrintError off: the last assertion provokes a constraint violation on
    # purpose, and with it on DBI also writes the failure to stderr, which
    # reads like a broken test in a smoker report of a passing run.
    my $dbh = DBI->connect("dbi:SQLite:dbname=$tmp/auth.db", '', '',
                           { RaiseError => 1, PrintError => 0 });
    my $cols = $dbh->selectcol_arrayref('PRAGMA table_info(users)', { Columns => [2] });
    is_deeply($cols, [qw(id email password_hash verified)], 'users has the columns Punk::Auth\'s defaults expect');
    $cols = $dbh->selectcol_arrayref('PRAGMA table_info(auth_tokens)', { Columns => [2] });
    is_deeply($cols, [qw(id user_id kind digest expires)], 'and auth_tokens too');
    $dbh->do("INSERT INTO users (email) VALUES ('A\@x')");
    my $e = ''; eval { $dbh->do("INSERT INTO users (email) VALUES ('a\@X')") } or $e = $@;
    like($e, qr/UNIQUE constraint failed/, 'the email index is case-insensitive');
}

done_testing();
