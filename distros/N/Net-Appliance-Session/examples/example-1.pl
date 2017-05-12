#!/usr/bin/perl -n

# This (fictional) example shows how you can save time if there are many
# devices that require manual login reconfiguration (e.g. no SNMP).
# 
# The program is a filter, so wants a list of hosts on standard input or a
# filename containing hosts as an argument, and will go through each one,
# connecting to and reconfiguring the device.

BEGIN {
    use strict;
    use warnings FATAL => 'all';

    use Net::Appliance::Session;
}

my $host = $_; chomp $host;
die "one and only param is a device FQDN or IP!\n"
    if ! defined $host;

my $s = Net::Appliance::Session->new({
    transport => 'SSH', # or 'Telnet' or 'Serial'
    personality => 'ios', # or many others, see docs
    host => $host,
});
$s->set_global_log_at('notice'); # maximum debugging is 'debug'

try {
    $s->connect({
        name     => $username,
        password => $password,
    });
    $s->begin_privileged; # use same pass as login

    # is this a device with FastEthernet or GigabitEthernet ports?
    # let's do a test and find out, for use in the later commands.

    my $type = $s->cmd('show interfaces status | incl 1/0/24');
    $type = ($type =~ m/^Gi/ ? 'GigabitEthernet' : 'FastEthernet');

    # now actually do some work...
    # (lines which make changes are commented in this example!)

    $s->begin_configure;

    $s->cmd("interface ${type}1/0/13");
    # $s->cmd('no shutdown');
    $s->cmd("interface ${type}1/0/14");
    # $s->cmd('no shutdown');
    $s->cmd("interface ${type}1/0/15");
    # $s->cmd('no shutdown');

    $s->end_configure;
    # $s->cmd('write memory');
    $s->end_privileged;
}
catch {
    warn $_;
}
finally {
    $s->close;
};
