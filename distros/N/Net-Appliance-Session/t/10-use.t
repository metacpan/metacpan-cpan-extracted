#!/usr/bin/perl -w
use strict;
use Test::More 0.88;

BEGIN { use_ok('Net::Appliance::Session') }

my $s = new_ok('Net::Appliance::Session' => [{
        transport => 'Serial',
        personality => 'cisco',
    }], 'new instance' );

foreach (qw(
    logged_in
    in_privileged_mode
    in_configure_mode
    do_paging
    do_login
    do_privileged_mode
    do_configure_mode
    get_username
    get_password
    set_username
    set_password
    pager_disable_lines
    pager_enable_lines
    connect
    close
    enable_paging
    disable_paging
    begin_privileged
    end_privileged
    begin_configure
    end_configure
)) {
    ok( $s->can($_), "can do method $_");
}

done_testing;
