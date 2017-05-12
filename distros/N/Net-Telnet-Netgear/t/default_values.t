#!/usr/bin/env perl
use strict;
use warnings;
use Net::Telnet::Netgear;
use Test::More;

my $instance = Net::Telnet::Netgear->new;

# No plan, because it's difficult to anticipate the number of default values
check_values_ok();
check_values_ok (exit_on_destroy => '');
check_values_ok (packet => 'testity test');

{
    local %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (exit_on_destroy => 1);
    check_values_ok();
}

done_testing();

sub check_values_ok
{
    $instance->apply_netgear_defaults (@_);
    local %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (
        %Net::Telnet::Netgear::NETGEAR_DEFAULTS, @_
    ) if @_ > 1;
    foreach (keys %Net::Telnet::Netgear::NETGEAR_DEFAULTS)
    {
        next if $_ eq 'waitfor'; # not a mutator
        is (
            $instance->can ($_)->($instance),
            $Net::Telnet::Netgear::NETGEAR_DEFAULTS{$_},
            "$_ has the correct default value"
        );
    }
}
