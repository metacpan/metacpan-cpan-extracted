#!perl

use strict;
use warnings;
use Sphinx::Config;
use Path::Class;
use FindBin;

use Test::More tests => 13;

BEGIN { use_ok('Sphinx::Manager'); }

my $pid_file = Path::Class::file->new("data", "searchd_test.pid")->absolute;
my $config_file =  Path::Class::file->new("data", "sphinx.conf")->absolute;
$pid_file->dir->mkpath;

my $c = Sphinx::Config->new;
$c->set('searchd', undef, 'pid_file', "$pid_file");
$c->save($config_file);

my $mgr = Sphinx::Manager->new({ 
    config_file => $config_file, 
    bindir => "$FindBin::Bin/bin",
    debug => 0,
});

if ($ENV{ENABLE_SUDO_TESTS}) {
    $mgr->indexer_sudo('sudo');
    $mgr->searchd_sudo('sudo');
}

ok($mgr, "constructor");

start_reload_restart_stop();
without_pidfile();
non_conflict();
indexer();

sub start_reload_restart_stop {

    $mgr->stop_searchd;

    $mgr->start_searchd;
    sleep(1);
    like(read_status(), qr/STARTED/, "start_searchd");

    eval { $mgr->start_searchd };
    like($@, qr/already running/, "start_searchd while running");

    $mgr->reload_searchd;
    sleep(1);
    like(read_status(), qr/HUP/, "reload");

    my $pid_before = $mgr->get_searchd_pid;
    $mgr->restart_searchd;
    sleep(1);
    like(read_status(), qr/STARTED/, "restart_searchd");
    my $pid_after = $mgr->get_searchd_pid;
    ok($pid_before->[0] != $pid_after->[0], "pid change after restart");

    $pid_before = $mgr->get_searchd_pid;
    $mgr->start_searchd(1);
    $pid_after = $mgr->get_searchd_pid;
    ok($pid_before->[0] == $pid_after->[0], "No pid change after start(1)");

    $mgr->stop_searchd;
    $pid_after = $mgr->get_searchd_pid;
    is_deeply($pid_after, [], "get_searchd_pid when no searchd running");

}

sub without_pidfile {
    $mgr->stop_searchd;

    $mgr->start_searchd;
    sleep(1);

    my $pid_before = $mgr->get_searchd_pid;
    unlink($pid_file);
    $mgr->restart_searchd;
    sleep(1);
    my $pid_after = $mgr->get_searchd_pid;
    ok($pid_before != $pid_after, "pid change after restart without pid_file");

    $mgr->stop_searchd;
    $pid_after = $mgr->get_searchd_pid;
    is_deeply($pid_after, [], "stop without pid_file");
   
}

sub non_conflict {

    $c->set('searchd', undef, 'pid_file', "$pid_file" . '.alt');
    $c->save($config_file . '.alt');

    my $altmgr = Sphinx::Manager->new({ 
	config_file => $config_file . '.alt', 
	bindir => "$FindBin::Bin/bin",
    });
    $altmgr->stop_searchd;
    $altmgr->start_searchd;
    sleep(1);
    my $altpid = $altmgr->get_searchd_pid;

    $mgr->stop_searchd;
    $mgr->start_searchd;
    sleep(1);
    $mgr->restart_searchd;
    $mgr->reload_searchd;
    unlink($pid_file);
    $mgr->restart_searchd;
    $mgr->stop_searchd;

    is_deeply($altmgr->get_searchd_pid, $altpid, "non-conflict with other searchd");
    $altmgr->stop_searchd;

}

sub indexer {

    $mgr->run_indexer;
    ok(1, "indexer"); # if we didn't die.
}

sub read_status {
    my $status_file = $pid_file . '.status';
    local $/ = undef;
    open my $fh, "<", $status_file or die "Failed to open $status_file: $!";
    my $content = <$fh>;
    close($fh);

    return $content;
}

