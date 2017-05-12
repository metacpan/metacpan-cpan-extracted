#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);
use Devel::Debug::DBGp;

my $DBGP_VERSION = Devel::Debug::DBGp->VERSION;

start_listening();
run_app('t/apps/base.psgi');
send_request('/?name=debugger');
wait_connection();

init_is({
    idekey => 'dbgp_test',
});

command_is(['eval', encode_base64('$env->{"QUERY_STRING"}')], {
    command => 'eval',
    result  => {
        name        => '$env->{"QUERY_STRING"}',
        fullname    => '$env->{"QUERY_STRING"}',
        type        => ($DBGP_VERSION ge '0.13' ? 'undef' : 'string'),
        constant    => '0',
        children    => '0',
        value       => undef,
    },
});

send_command('step_into');
send_command('step_into');

command_is(['eval', encode_base64('$env->{"QUERY_STRING"}')], {
    command => 'eval',
    result  => {
        name        => '$env->{"QUERY_STRING"}',
        fullname    => '$env->{"QUERY_STRING"}',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'name=debugger',
    },
});

send_command('detach');
response_is('Hello, debugger');

done_testing();
