#!/usr/bin/perl
use strict;
use NetSNMP::agent;
use NetSNMP::ASN;
use POE qw< Component::NetSNMP::agent >;
use Test::More;


# try to determine the AgentX socket
my $socket = "/var/agentx/master";

PATH:
for my $path (qw< /etc/snmp/snmpd.conf /etc/snmp/snmpd.local.conf >) {
    open my $fh, "<", $path or next;
    my @lines = grep { /^\s*agentXSocket/i } <$fh>;

    for my $line (@lines) {
        $socket = $1, last PATH if $line =~ /agentXSocket\s+(.+)/
    }
}

# determine the transport specification and address of the socket
my ($spec, $addr);

if ($socket =~ m:^/:) {
    ($spec, $addr) = ("unix", $socket);
}
else {
    ($spec, $addr) = split /:/, $socket;
}

# check if we can access the socket
if ($spec eq "unix") {
    my @stat = stat($addr);
    plan skip_all => "because this script is running under an account "
        . "which can't access AgentX socket $addr"
        if not @stat or $< != $stat[4];
}


plan tests => 7;

use constant {
    AGENT_OID   => ".1.3.6.1.4.1.32272",
};

my $agent = eval { POE::Component::NetSNMP::agent->spawn(
    Alias   => "snmp_agent",
    AgentX  => 1,
)};
is($@, "", "spawn a session");

my $r = eval { $agent->register(AGENT_OID.".1", \&agent_handler_as_coderef) };
is($@, "", "registering an OID with a coderef");

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "registering an OID with a POE event";
            $_[KERNEL]->post("snmp_agent", register => AGENT_OID.".2", "handler");

            $_[KERNEL]->delay_add("snmpget", 1, AGENT_OID.".1");
            $_[KERNEL]->delay_add("snmpget", 2, AGENT_OID.".2");

            $_[KERNEL]->delay("stop", 3);
        },
        stop    => sub { $_[KERNEL]->stop },
        reaper  => sub {},
        handler => \&agent_handler_as_event,
        snmpget => sub {
            my $pid = fork;

            if ($pid == 0) {
                exec qw< snmpget -v2c -c public localhost >, $_[ARG0];
                exit
            }

            $_[KERNEL]->sig_child($pid, "reaper");
        },
    },
);

POE::Kernel->run;
exit;


sub agent_handler_as_coderef {
    my ($kernel, $heap, $args) = @_[ KERNEL, HEAP, ARG1 ];
    my ($handler, $reg_info, $request_info, $requests) = @$args;

    pass "agent handler (coderef)";

    # the rest of the code works like a classic NetSNMP::agent callback
    my $mode = $request_info->getMode;

    for (my $request = $requests; $request; $request = $request->next) {
        if ($mode == MODE_GET) {
            pass "'get' request";
            $request->setValue(ASN_OCTET_STR, "ichi");
        }
        else {
            fail "unexpected request"
        }
    }
}


sub agent_handler_as_event {
    my ($kernel, $heap, $args) = @_[ KERNEL, HEAP, ARG1 ];
    my ($handler, $reg_info, $request_info, $requests) = @$args;

    pass "agent handler (event)";

    # the rest of the code works like a classic NetSNMP::agent callback
    my $mode = $request_info->getMode;

    for (my $request = $requests; $request; $request = $request->next) {
        if ($mode == MODE_GET) {
            pass "'get' request";
            $request->setValue(ASN_OCTET_STR, "ni");
        }
        else {
            fail "unexpected request"
        }
    }
}

