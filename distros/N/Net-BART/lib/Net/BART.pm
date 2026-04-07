package Net::BART;

use strict;
use warnings;
use Carp qw(croak);
use Net::BART::BitSet256;
use Net::BART::SparseArray256;
use Net::BART::Art qw(pfx_to_idx octet_to_idx idx_to_pfx prefix_decompose);
use Net::BART::LPM qw(@LOOKUP_TBL);
use Net::BART::Node;

our $VERSION = '0.01';

# --- Fast IPv4 parsing (no regex on hot path) ---

sub _parse_prefix {
    my ($str) = @_;
    my $slash = index($str, '/');
    my ($addr_str, $prefix_len);
    if ($slash >= 0) {
        $addr_str = substr($str, 0, $slash);
        $prefix_len = substr($str, $slash + 1) + 0;
    } else {
        $addr_str = $str;
    }

    my $is_ipv6 = (index($addr_str, ':') >= 0);
    my $bytes = $is_ipv6 ? _parse_ipv6($addr_str) : _parse_ipv4_fast($addr_str);

    if (!defined $prefix_len) {
        $prefix_len = $is_ipv6 ? 128 : 32;
    }

    _mask_prefix($bytes, $prefix_len);
    return ($bytes, $prefix_len, $is_ipv6);
}

sub _parse_ip {
    my ($str) = @_;
    if (index($str, ':') >= 0) {
        return (_parse_ipv6($str), 1);
    }
    return (_parse_ipv4_fast($str), 0);
}

# Fast IPv4 parser - no regex, no validation overhead on hot path
sub _parse_ipv4_fast {
    my ($str) = @_;
    my $d1 = index($str, '.');
    my $d2 = index($str, '.', $d1 + 1);
    my $d3 = index($str, '.', $d2 + 1);
    return [
        substr($str, 0, $d1) + 0,
        substr($str, $d1 + 1, $d2 - $d1 - 1) + 0,
        substr($str, $d2 + 1, $d3 - $d2 - 1) + 0,
        substr($str, $d3 + 1) + 0,
    ];
}

sub _parse_ipv6 {
    my ($str) = @_;
    my @halves;
    if (index($str, '::') >= 0) {
        my ($left, $right) = split /::/, $str, 2;
        my @left_groups  = $left  ? (split /:/, $left)  : ();
        my @right_groups = $right ? (split /:/, $right) : ();
        my $fill = 8 - @left_groups - @right_groups;
        croak "Invalid IPv6 address: $str" if $fill < 0;
        @halves = (@left_groups, (('0') x $fill), @right_groups);
    } else {
        @halves = split /:/, $str;
    }
    croak "Invalid IPv6 address: $str" unless @halves == 8;
    my @bytes;
    for my $h (@halves) {
        my $val = hex($h);
        push @bytes, ($val >> 8) & 0xFF, $val & 0xFF;
    }
    return \@bytes;
}

sub _mask_prefix {
    my ($bytes, $prefix_len) = @_;
    my $full_bytes = $prefix_len >> 3;
    my $remaining = $prefix_len & 7;
    my $total = scalar @$bytes;
    if ($remaining && $full_bytes < $total) {
        $bytes->[$full_bytes] &= (0xFF << (8 - $remaining)) & 0xFF;
        $full_bytes++;
    }
    for my $i ($full_bytes .. $total - 1) {
        $bytes->[$i] = 0;
    }
}

sub _format_ip {
    my ($bytes, $is_ipv6) = @_;
    if ($is_ipv6) {
        my @groups;
        for (my $i = 0; $i < 16; $i += 2) {
            push @groups, sprintf("%x", ($bytes->[$i] << 8) | $bytes->[$i + 1]);
        }
        return join(':', @groups);
    }
    return join('.', @$bytes);
}

# --- Table ---

sub new {
    return bless {
        root4 => Net::BART::Node::Bart->new,
        root6 => Net::BART::Node::Bart->new,
        size4 => 0,
        size6 => 0,
    }, $_[0];
}

sub insert {
    my ($self, $prefix_str, $value) = @_;
    my ($addr, $prefix_len, $is_ipv6) = _parse_prefix($prefix_str);
    my $root = $is_ipv6 ? $self->{root6} : $self->{root4};
    my $is_new = _do_insert($root, $addr, $prefix_len, 0, $value);
    if ($is_new) {
        if ($is_ipv6) { $self->{size6}++ } else { $self->{size4}++ }
    }
    return $is_new;
}

# Non-method for speed (avoids $self-> dispatch overhead in recursion)
sub _do_insert {
    my ($node, $addr, $prefix_len, $depth, $value) = @_;

    my $strides = $prefix_len >> 3;
    my $lastbits = $prefix_len & 7;

    if ($prefix_len == 0) {
        return $node->insert_prefix(1, $value);
    }

    if ($lastbits && $depth == $strides) {
        return $node->insert_prefix(pfx_to_idx($addr->[$depth], $lastbits), $value);
    }

    if (!$lastbits && $depth == $strides - 1) {
        return _do_insert_fringe($node, $addr, $prefix_len, $depth, $value);
    }

    # Navigate
    my $octet = $addr->[$depth];
    my ($child, $exists) = $node->get_child($octet);

    if (!$exists) {
        $node->set_child($octet, Net::BART::Node::Leaf->new(
            addr => [@$addr], prefix_len => $prefix_len, value => $value,
        ));
        return 1;
    }

    my $ref = ref($child);

    if ($ref eq 'Net::BART::Node::Leaf') {
        if ($child->matches_prefix($addr, $prefix_len)) {
            $child->[2] = $value;  # LEAF_VALUE
            return 0;
        }
        my $new_node = Net::BART::Node::Bart->new;
        _do_insert($new_node, $child->[0], $child->[1], $depth + 1, $child->[2]);
        $node->set_child($octet, $new_node);
        return _do_insert($new_node, $addr, $prefix_len, $depth + 1, $value);
    }

    if ($ref eq 'Net::BART::Node::Fringe') {
        if (!$lastbits && $depth == $strides - 1) {
            $child->[0] = $value;
            return 0;
        }
        my $new_node = Net::BART::Node::Bart->new;
        $new_node->insert_prefix(1, $child->[0]);
        $node->set_child($octet, $new_node);
        return _do_insert($new_node, $addr, $prefix_len, $depth + 1, $value);
    }

    return _do_insert($child, $addr, $prefix_len, $depth + 1, $value);
}

sub _do_insert_fringe {
    my ($node, $addr, $prefix_len, $depth, $value) = @_;
    my $octet = $addr->[$depth];
    my ($child, $exists) = $node->get_child($octet);

    if (!$exists) {
        $node->set_child($octet, Net::BART::Node::Fringe->new(value => $value));
        return 1;
    }

    my $ref = ref($child);

    if ($ref eq 'Net::BART::Node::Fringe') {
        $child->[0] = $value;
        return 0;
    }

    if ($ref eq 'Net::BART::Node::Bart') {
        return $child->insert_prefix(1, $value);
    }

    if ($ref eq 'Net::BART::Node::Leaf') {
        my $new_node = Net::BART::Node::Bart->new;
        _do_insert($new_node, $child->[0], $child->[1], $depth + 1, $child->[2]);
        $new_node->insert_prefix(1, $value);
        $node->set_child($octet, $new_node);
        return 1;
    }

    return 0;
}

sub delete {
    my ($self, $prefix_str) = @_;
    my ($addr, $prefix_len, $is_ipv6) = _parse_prefix($prefix_str);
    my $root = $is_ipv6 ? $self->{root6} : $self->{root4};
    my ($val, $ok) = _do_delete($root, $addr, $prefix_len, 0);
    if ($ok) {
        if ($is_ipv6) { $self->{size6}-- } else { $self->{size4}-- }
    }
    return ($val, $ok);
}

sub _do_delete {
    my ($node, $addr, $prefix_len, $depth) = @_;

    my $strides = $prefix_len >> 3;
    my $lastbits = $prefix_len & 7;

    if ($prefix_len == 0) {
        return $node->delete_prefix(1);
    }

    if ($lastbits && $depth == $strides) {
        return $node->delete_prefix(pfx_to_idx($addr->[$depth], $lastbits));
    }

    if (!$lastbits && $depth == $strides - 1) {
        my $octet = $addr->[$depth];
        my ($child, $exists) = $node->get_child($octet);
        return (undef, 0) unless $exists;

        my $ref = ref($child);
        if ($ref eq 'Net::BART::Node::Fringe') {
            $node->delete_child($octet);
            return ($child->[0], 1);
        }
        if ($ref eq 'Net::BART::Node::Bart') {
            my ($val, $ok) = $child->delete_prefix(1);
            if ($ok && $child->is_empty) {
                $node->delete_child($octet);
            }
            return ($val, $ok);
        }
        return (undef, 0);
    }

    my $octet = $addr->[$depth];
    my ($child, $exists) = $node->get_child($octet);
    return (undef, 0) unless $exists;

    my $ref = ref($child);
    if ($ref eq 'Net::BART::Node::Leaf') {
        if ($child->matches_prefix($addr, $prefix_len)) {
            $node->delete_child($octet);
            return ($child->[2], 1);
        }
        return (undef, 0);
    }

    if ($ref eq 'Net::BART::Node::Fringe') {
        return (undef, 0);
    }

    my ($val, $ok) = _do_delete($child, $addr, $prefix_len, $depth + 1);
    if ($ok && $child->is_empty) {
        $node->delete_child($octet);
    }
    return ($val, $ok);
}

# Lookup: longest matching prefix for an IP address.
# Heavily optimized - this is the primary hot path.
sub lookup {
    my ($self, $ip_str) = @_;

    # Inline fast IPv4 parse
    my ($bytes, $is_ipv6);
    if (index($ip_str, ':') >= 0) {
        $bytes = _parse_ipv6($ip_str);
        $is_ipv6 = 1;
    } else {
        my $d1 = index($ip_str, '.');
        my $d2 = index($ip_str, '.', $d1 + 1);
        my $d3 = index($ip_str, '.', $d2 + 1);
        $bytes = [
            substr($ip_str, 0, $d1) + 0,
            substr($ip_str, $d1 + 1, $d2 - $d1 - 1) + 0,
            substr($ip_str, $d2 + 1, $d3 - $d2 - 1) + 0,
            substr($ip_str, $d3 + 1) + 0,
        ];
        $is_ipv6 = 0;
    }

    my $root = $is_ipv6 ? $self->{root6} : $self->{root4};
    my $max_depth = $is_ipv6 ? 16 : 4;

    # Walk down, storing nodes/octets for backtrack LPM.
    # Use flat arrays instead of array-of-arrays for speed.
    my (@nodes, @octets);
    my $node = $root;
    my $sp = 0;

    for my $depth (0 .. $max_depth - 1) {
        my $octet = $bytes->[$depth];
        $nodes[$sp] = $node;
        $octets[$sp] = $octet;
        $sp++;

        # Inline get_child: $node->[1] is children sparse array
        my $chd = $node->[1];
        my $chd_bs = $chd->[0];
        unless ($chd_bs->[$octet >> 6] & (1 << ($octet & 63))) {
            last;  # no child
        }
        my $child = $chd->[1][$chd_bs->rank($octet) - 1];

        my $ref = ref($child);
        if ($ref eq 'Net::BART::Node::Fringe') {
            return ($child->[0], 1);
        }
        if ($ref eq 'Net::BART::Node::Leaf') {
            if ($child->contains_ip($bytes)) {
                return ($child->[2], 1);
            }
            last;
        }
        $node = $child;
    }

    # Backtrack: LPM at each stacked node
    for (my $i = $sp - 1; $i >= 0; $i--) {
        my ($val, $ok) = $nodes[$i]->lpm($octets[$i]);
        return ($val, 1) if $ok;
    }

    return (undef, 0);
}

# Contains: check if any prefix contains the IP.
sub contains {
    my ($self, $ip_str) = @_;

    my ($bytes, $is_ipv6);
    if (index($ip_str, ':') >= 0) {
        $bytes = _parse_ipv6($ip_str);
        $is_ipv6 = 1;
    } else {
        my $d1 = index($ip_str, '.');
        my $d2 = index($ip_str, '.', $d1 + 1);
        my $d3 = index($ip_str, '.', $d2 + 1);
        $bytes = [
            substr($ip_str, 0, $d1) + 0,
            substr($ip_str, $d1 + 1, $d2 - $d1 - 1) + 0,
            substr($ip_str, $d2 + 1, $d3 - $d2 - 1) + 0,
            substr($ip_str, $d3 + 1) + 0,
        ];
        $is_ipv6 = 0;
    }

    my $node = $is_ipv6 ? $self->{root6} : $self->{root4};
    my $max_depth = $is_ipv6 ? 16 : 4;

    for my $depth (0 .. $max_depth - 1) {
        my $octet = $bytes->[$depth];

        # Inline lpm_test
        my $pfx_bs = $node->[0][0];
        my $lut = $LOOKUP_TBL[($octet >> 1) + 128];
        if (($pfx_bs->[0] & $lut->[0]) | ($pfx_bs->[1] & $lut->[1]) |
            ($pfx_bs->[2] & $lut->[2]) | ($pfx_bs->[3] & $lut->[3])) {
            return 1;
        }

        # Inline get_child
        my $chd = $node->[1];
        my $chd_bs = $chd->[0];
        unless ($chd_bs->[$octet >> 6] & (1 << ($octet & 63))) {
            return 0;
        }
        my $child = $chd->[1][$chd_bs->rank($octet) - 1];

        my $ref = ref($child);
        if ($ref eq 'Net::BART::Node::Fringe') { return 1 }
        if ($ref eq 'Net::BART::Node::Leaf') {
            return $child->contains_ip($bytes) ? 1 : 0;
        }
        $node = $child;
    }
    return 0;
}

# Exact match get.
sub get {
    my ($self, $prefix_str) = @_;
    my ($addr, $prefix_len, $is_ipv6) = _parse_prefix($prefix_str);
    my $root = $is_ipv6 ? $self->{root6} : $self->{root4};
    return _do_get($root, $addr, $prefix_len, 0);
}

sub _do_get {
    my ($node, $addr, $prefix_len, $depth) = @_;

    my $strides = $prefix_len >> 3;
    my $lastbits = $prefix_len & 7;

    if ($prefix_len == 0) {
        return $node->get_prefix(1);
    }

    if ($lastbits && $depth == $strides) {
        return $node->get_prefix(pfx_to_idx($addr->[$depth], $lastbits));
    }

    if (!$lastbits && $depth == $strides - 1) {
        my ($child, $exists) = $node->get_child($addr->[$depth]);
        return (undef, 0) unless $exists;
        my $ref = ref($child);
        if ($ref eq 'Net::BART::Node::Fringe') { return ($child->[0], 1) }
        if ($ref eq 'Net::BART::Node::Bart')   { return $child->get_prefix(1) }
        return (undef, 0);
    }

    my ($child, $exists) = $node->get_child($addr->[$depth]);
    return (undef, 0) unless $exists;
    my $ref = ref($child);
    if ($ref eq 'Net::BART::Node::Leaf') {
        return $child->matches_prefix($addr, $prefix_len) ? ($child->[2], 1) : (undef, 0);
    }
    return (undef, 0) if $ref eq 'Net::BART::Node::Fringe';
    return _do_get($child, $addr, $prefix_len, $depth + 1);
}

sub size  { return $_[0]->{size4} + $_[0]->{size6} }
sub size4 { return $_[0]->{size4} }
sub size6 { return $_[0]->{size6} }

# Walk all prefixes.
sub walk {
    my ($self, $callback) = @_;
    _walk_node($self->{root4}, [], 0, 0, $callback);
    _walk_node($self->{root6}, [], 1, 0, $callback);
}

sub _walk_node {
    my ($node, $path, $is_ipv6, $depth, $callback) = @_;
    my $total_bytes = $is_ipv6 ? 16 : 4;

    # Visit prefixes at this node
    $node->[0]->each_pair(sub {
        my ($idx, $val) = @_;
        my ($octet, $pfx_len_in_stride) = idx_to_pfx($idx);
        my $total_bits = $depth * 8 + $pfx_len_in_stride;
        my @addr = @$path;
        push @addr, $octet if $pfx_len_in_stride > 0;
        while (@addr < $total_bytes) { push @addr, 0 }
        _mask_prefix(\@addr, $total_bits);
        $callback->(_format_ip(\@addr, $is_ipv6) . "/$total_bits", $val);
    });

    # Visit children
    $node->[1]->each_pair(sub {
        my ($octet, $child) = @_;
        my @child_path = (@$path, $octet);
        my $ref = ref($child);

        if ($ref eq 'Net::BART::Node::Leaf') {
            $callback->(_format_ip($child->[0], $is_ipv6) . "/$child->[1]", $child->[2]);
        } elsif ($ref eq 'Net::BART::Node::Fringe') {
            my $total_bits = ($depth + 1) * 8;
            my @addr = @child_path;
            while (@addr < $total_bytes) { push @addr, 0 }
            $callback->(_format_ip(\@addr, $is_ipv6) . "/$total_bits", $child->[0]);
        } else {
            _walk_node($child, \@child_path, $is_ipv6, $depth + 1, $callback);
        }
    });
}

1;

__END__

=head1 NAME

Net::BART - Balanced Routing Tables for IPv4 and IPv6

=head1 SYNOPSIS

    use Net::BART;

    my $table = Net::BART->new;

    # Insert prefixes with values
    $table->insert("10.0.0.0/8", "private-10");
    $table->insert("10.1.0.0/16", "office");
    $table->insert("192.168.1.0/24", "home");
    $table->insert("2001:db8::/32", "documentation");

    # Longest-prefix match lookup
    my ($val, $ok) = $table->lookup("10.1.2.3");
    # $val = "office", $ok = 1

    # Exact match
    my ($val, $ok) = $table->get("10.0.0.0/8");

    # Containment check
    my $found = $table->contains("10.1.2.3");  # 1

    # Delete
    my ($old, $ok) = $table->delete("10.1.0.0/16");

    # Walk all prefixes
    $table->walk(sub {
        my ($prefix, $value) = @_;
        print "$prefix => $value\n";
    });

=head1 DESCRIPTION

BART implements a multibit trie with fixed 8-bit strides for fast IP prefix
lookup. Based on Knuth's ART (Allotment Routing Tables) algorithm with
popcount-compressed sparse arrays for memory efficiency.

Based on L<https://github.com/gaissmai/bart>.

=cut
