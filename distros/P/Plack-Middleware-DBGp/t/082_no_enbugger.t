#!/usr/bin/perl

use if do { require Config; $Config::Config{usethreads} },
    'Test::More' => 'skip_all' => 'does not apply to threaded Perls';
use t::lib::Test;

start_listening();
run_app('t/apps/no_enbugger.psgi');

send_request('/');
wait_connection();
command_is([qw(breakpoint_set -t line -f file://t/apps/no_enbugger.psgi -n 15)], {
    code    => 202,
    apperr  => 4,
    message => "Line 15 isn't breakable",
});
command_is(['run'], {
    status  => 'stopped',
    command => 'run',
});
response_is('Hello, world');

done_testing();
