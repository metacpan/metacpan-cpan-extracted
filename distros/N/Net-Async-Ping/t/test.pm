package t::test;

use strict;
use warnings;

use Test::More 0.88;

use Net::Async::Ping;
use IO::Async::Loop;

use Test::Fatal;

my $expected = 0; # Expected number of tests, adjusted as we go

my $loop = IO::Async::Loop->new;

sub run_tests
{
    my ($type, $params) = @_;

    # Horribly hacky. We guess what might be an unreachable address, and
    # see whether it actually is with a call to the external ping command.
    # We do this now, so we know how many tests we need to skip.
    my $unreach         = $params->{unreachable};
    my $ping_command   = $type eq 'icmpv6' || $type eq 'icmpv6_ps'
        ? 'ping6'
        : 'ping';
    my $return          = qx($ping_command -c 1 $unreach) || '';
    my $has_unreachable = $return =~ /Destination Host Unreachable/;

    my %options;
    if ($type eq 'icmp' || $type eq 'icmpv6') {
        %options = (use_ping_socket => 0);
    }
    elsif ($type eq 'icmp_ps' || $type eq 'icmpv6_ps') {
        %options = (use_ping_socket => 1); # default
    }

    # Test old and new API (with and without $loop)
    foreach my $legacy (0..1)
    {
        my $t = $type;
        $t = 'icmp'
            if $type eq 'icmp_ps';
        $t = 'icmpv6'
            if $type eq 'icmpv6_ps';
        my $p = Net::Async::Ping->new($t => { default_timeout => 1, %options });
        $loop->add($p) if !$legacy;

        my @params = $legacy ? ($loop, 'localhost') : ('localhost');
        $p->ping(@params)
           ->then(sub {
              pass "type: $type, legacy: $legacy, pinged localhost!";
              note("success future: @_");
              Future->done
           })->else(sub {
              fail "type: $type, legacy: $legacy, pinged localhost!";
              note("failure future: @_");
              Future->fail('failed to ping localhost!')
           })->get;

        # http://en.wikipedia.org/wiki/Reserved_IP_addresses
        my $reserved = $params->{reserved};
        @params = $legacy ? ($loop, $reserved) : ($reserved);
        my $f = $p->ping(@params)
           ->then(sub {
              fail qq(type: $type, legacy: $legacy, couldn't reach $reserved);
              note("success future: @_");
              Future->done
           })->else(sub {
              pass qq(type: $type, legacy: $legacy, couldn't reach $reserved);
              note("failure future: @_");
              Future->fail('expected failure')
           });
        like exception { $f->get }, qr/expected failure/, 'expected failure';

        if ($type eq 'icmp' || $type eq 'icmpv6') # Unreachable replies do not seem to work with ping sockets
        {
            SKIP: {
                ++$expected && skip "$unreach is not unreachable: skipping unreachable IP address tests"
                    unless $has_unreachable;
                @params = $legacy ? ($loop, $unreach) : ($unreach);
                my $f = $p->ping(@params, 5); # Longer timeout needed for unreachable packets
                like exception { $f->get }, qr/ICMP(v6)? Unreachable/, "type: $type, legacy: $legacy, expected failure";
                $expected++;
            }
        }

        # RFC6761, invalid domain to check resolver failure
        @params = $legacy ? ($loop, 'nothing.invalid') : ('nothing.invalid');
        $f = $p->ping(@params)
           ->then(sub {
              fail qq(type: $type, legacy: $legacy, couldn't reach nothing.invalid);
              note("success future: @_");
              Future->done
           })->else(sub {
              pass qq(type: $type, legacy: $legacy, couldn't reach nothing.invalid);
              note("failure future: @_");
              Future->fail('expected failure')
           });

        like exception { $f->get }, qr/expected failure/, "type: $type, legacy: $legacy, expected failure";
        $expected += 5; # 5 tests above, not including unreachable

        $loop->remove($p) if !$legacy;
    }

    done_testing($expected);
}


1;
