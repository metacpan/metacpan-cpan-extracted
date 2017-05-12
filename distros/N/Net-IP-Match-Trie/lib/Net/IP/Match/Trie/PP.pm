# -*- mode: coding: utf-8; -*-
package Net::IP::Match::Trie;

use strict;
use warnings;
no warnings qw(redefine);

use Socket qw(inet_aton);

our $VERSION = '1.00';

our $CIDR_TABLE_BITS = 8;
our $CIDR_TABLE_SIZE = (1 << $CIDR_TABLE_BITS);

# helper
sub itonetmask($) {
    my($n, $netmask) = @_;

    return () if ($n < 0 || 32 < $n);

    my $m = 1 << (32 - $n);
    --$m;
    $netmask = ~$m;
    return $netmask & 0xFFFFFFFF;
}

sub is_leaf($) {
    my($pt) = @_;
    return $pt->{child}[0] == $pt;
}

sub new_trie_node() {
    my $node = { name => "", bits => 0, child => [] };
    for (my $i = 0; $i < $CIDR_TABLE_SIZE; $i++) {
        $node->{child}[$i] = $node;
    }
    return $node;
}

sub digg_trie($) {
    my($child) = @_;
    my $parent = new_trie_node;
    for (my $i = 0; $i < $CIDR_TABLE_SIZE; $i++) {
        $parent->{child}[$i] = $child;
    }
    return $parent;
}

sub update_leaf($$) {
    my($pt, $leaf) = @_;
    my $used = 0;

    for (my $i = 0; $i < $CIDR_TABLE_SIZE; $i++) {
        my $next = $pt->{child}[$i];
        if (is_leaf($next)) {
            if ($next->{bits} < $leaf->{bits}) {
                $pt->{child}[$i] = $leaf;
                $used = 1;
            }
        } else {
            $used |= &update_leaf($next, $leaf);
        }
    }

    return $used;
}


sub new {
    my($class, %opt) = @_;

    my $self = bless {
       }, $class;

    my $root      = new_trie_node;
    $root->{name} = "R";
    my $nullnode  = new_trie_node;
    for (my $i=0; $i < $CIDR_TABLE_SIZE; $i++) {
        $root->{child}[$i] = $nullnode;
    }
    $self->{root} = $root;

    return $self;
}

# name => [ cidr1, cidr2, ... ]
sub add {
    my($self, $name, $cidrs) = @_;

    my $ad;
    my $nm = 0xFFFFFFFF;

    ### name: $name
    for my $cidr (@$cidrs) {
        my($ip, $len) = split m{/}, $cidr, 2;
        $len ||= 32;
        ### cidr, ip, len: join ', ', $cidr, $ip, $len

        $ad = unpack "N", inet_aton($ip);
        $nm = itonetmask($len);
        ### ad   : sprintf "%08X", $ad
        ### nm   : sprintf "%08X", $nm

        $ad = $ad & ($nm & 0xFFFFFFFF);
        ### ad&nm: sprintf "%08X", $ad

        my $pt = $self->{root};
        my $p_leaf = new_trie_node;

        $p_leaf->{name} = $name;
        $p_leaf->{bits} = $len;

        while ($len > $CIDR_TABLE_BITS) {
            ### ad   : sprintf "%08X", $ad
            my $b = $ad >> (32 - $CIDR_TABLE_BITS);
            ### b: $b
            my $next = $pt->{child}[$b];
            if (is_leaf($next)) {
                $pt->{child}[$b] = $next = digg_trie($next);
            }
            $pt = $next;
            $ad = $ad << $CIDR_TABLE_BITS & 0xFFFFFFFF;
            $len -= $CIDR_TABLE_BITS;
        }

        {
            my $bmin = $ad >> (32 - $CIDR_TABLE_BITS);
            my $bmax = $bmin + (1 << ($CIDR_TABLE_BITS - $len));
            my $used = 0;
            for (my $i = $bmin; $i < $bmax; $i++) {
                my $target = $pt->{child}[$i];
                if (is_leaf($target)) {
                    if ($target->{bits} < $p_leaf->{bits}) {
                        $pt->{child}[$i] = $p_leaf;
                        $used = 1;
                    }
                } else {
                    for (my $j = 0; $j < $CIDR_TABLE_SIZE; $j++) {
                        $used |= update_leaf($target, $p_leaf);
                    }
                }
            }
        }
    }
}

sub match_ip {
    my($self, $ip) = @_;

    my @addrs = split /\./, $ip, 4;
    return $self->{root}{child}[$addrs[0]]->{child}[$addrs[1]]->{child}[$addrs[2]]->{child}[$addrs[3]]->{name};
}

sub impl {
    my($self) = @_;
    return "PP";
}

1;
