#!/usr/bin/perl

use if !eval { require Enbugger; Enbugger->VERSION(2.014) },
    'Test::More' => skip_all => 'Enbugger 2.014 not installed';
use t::lib::Test;

start_listening();
run_app('t/apps/enbugger.psgi');

send_request('/');
wait_connection();
command_is([qw(breakpoint_set -t line -f file://t/apps/enbugger.psgi -n 15)], {
    state   => 'enabled',
    id      => 0,
});
command_is(['run'], {
    status  => 'break',
    command => 'run',
});
command_is(['run'], {
    status  => 'stopped',
    command => 'run',
});
response_is('Hello, world');

done_testing();
