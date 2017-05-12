#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('Nginx::Control');
}

my $ctl = Nginx::Control->new(
    config_file => [$ENV{PWD}, qw[ t conf nginx.dev.conf ]],
);
isa_ok($ctl, 'Nginx::Control');

SKIP: {
    
skip "No nginx installed (or at least none found), why are you testing this anyway?", 6 
    unless eval { $ctl->binary_path };

ok(!$ctl->is_server_running, '... the server process is not yet running');

$ctl->start;

diag "Wait a moment for nginx to start";
sleep(2);

ok($ctl->is_server_running, '... the server process is now running');

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('http://localhost:3333/' . $ctl->pid_file->basename);
$mech->content_contains($ctl->server_pid, '... got the content we expected');

$ctl->stop;

diag "Wait a moment for Nginx to stop";
sleep(2);

ok(!-e $ctl->pid_file, '... PID file has been removed by Nginx');
ok(!$ctl->is_server_running, '... the server process is no longer running');

}
