#!/usr/bin/perl

use t::lib::Test;

start_listening();
run_app('t/apps/session.psgi');

send_request('/');
response_is('Enabled: 0', { value => undef });

send_request('/?XDEBUG_SESSION_START=test_session_1');
wait_connection();
init_is({
    idekey => 'test_session_1',
});
command_is(['run'], {
    status  => 'stopped',
    command => 'run',
});
response_is('Enabled: 1', { value => 'XDEBUG_SESSION=test_session_1', expires => 1800 });

send_request('/', 'XDEBUG_SESSION=test_session_2');
wait_connection();
init_is({
    idekey => 'test_session_2',
});
command_is(['run'], {
    status  => 'stopped',
    command => 'run',
});
response_is('Enabled: 1', { value => undef });

send_request('/?XDEBUG_SESSION_STOP=abcd');
response_is('Enabled: 0', { value => 'XDEBUG_SESSION=', expires => -1 });

send_request('/?XDEBUG_SESSION_STOP=abcd', 'XDEBUG_SESSION=test');
response_is('Enabled: 0', { value => 'XDEBUG_SESSION=', expires => -1 });

send_request('/?XDEBUG_SESSION_STOP=', 'XDEBUG_SESSION=test');
response_is('Enabled: 0', { value => 'XDEBUG_SESSION=', expires => -1 });

done_testing();
