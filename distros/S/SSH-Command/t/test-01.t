#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN { plan tests => $ENV{test_ssh} ? 5 : 1; }

use_ok('SSH::Command');

exit unless $ENV{test_ssh};

### Test prototypes

#
# Test local user: suxx / qwerty
#

# Get uname from host and check it by regexp
sub get_uname_from_host_regexp_verify {

    return ssh_execute(
        host     => '127.0.0.1',
        username => 'suxx',
        password => 'qwerty',
        commands =>
        [
            {
                cmd    => 'uname -a',     # for check connection
                verify => qr/linux/i,
            }
        ]
    );
}

# get uname from host and check in by full match
sub get_uname_from_host_full_match {

    return ssh_execute(
        host     => '127.0.0.1',
        username => 'suxx',
        password => 'qwerty',
        commands =>
        [
            {
                cmd    => 'uname -r',     # for check connection
                verify => '2.6.24-22-generic',
            }
        ]
    );
}

# Check SCP file operations
sub check_scp {

    return ssh_execute(
        host     => '127.0.0.1',
        username => 'suxx',
        password => 'qwerty',
        commands =>
        [
            {
                cmd       => 'scp_put',
                string    => 'php suxx',
                dest_path => '/tmp/php_suxx',
            },

            {
                cmd    => 'cat /tmp/php_suxx',     # for check connection
                verify => 'php suxx',
            }
        ]
    );
}


sub check_ssh_command {
   return ssh_execute(
        host     => '127.0.0.1',
        username => 'suxx',
        password => 'qwerty',
        command  => 'uname',     # for check connection
    );
}

ok( get_uname_from_host_full_match(),    "Simple compare test"  );   
ok( get_uname_from_host_regexp_verify(), "RegExp fail"          );
ok( check_scp(),                         "SCP test"             );
is(check_ssh_command, 'Linux');
