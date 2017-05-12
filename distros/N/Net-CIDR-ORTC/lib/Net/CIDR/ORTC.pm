package Net::CIDR::ORTC;

use 5.010;
use strict;
use warnings;

use Carp qw/carp croak/;

our $VERSION = '0.02';

=head1 NAME

Net::CIDR::ORTC - CIDR map compression

=head1 SYNOPSIS

  use Net::CIDR::ORTC;

  my $map = Net::CIDR::ORTC->new();

  $map->add('0.0.0.0/0', 0);
  $map->add('192.168.0.0/24', 'value1');
  $map->add('192.168.1.0/24', 'value1');

  $map->compress();

  my $prefixes = $map->list;

  foreach (@$prefixes) {
    say $_->[0] . "\t" . $_->[1];
  }

=head1 DESCRIPTION

This module implements Optimal Routing Table Compressor (ORTC) algorithm as described in
L<Technical Report MSR-TR-98-59|http://research.microsoft.com/pubs/69698/tr-98-59.pdf>.

This module intended for offline data processing and not optimal in terms of
CPU time and memory usage, but output table should have smallest number of
prefixes whits same behaviour (with longest-prefix match lookup).

Sometimes this algorithm makes unnecessary changes to input data (prefixes
changed, but number of prefixes in output is same as in input), but it is not
easy to fix this without making algorithm non-optimal (increasing number of
output prefixes in general case).

=cut

use constant IPv4_BITS => 32;
use constant ALL_ONES => 2**IPv4_BITS - 1;

# node array fields
use constant {
	LEFT    => 0,
	RIGHT   => 1,
	VALUE   => 2,
	OLD_VAL => 3,
};

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	# tree root node (head)
	$self->{root} = [];
	return $self;
}

sub add {
	my $self = shift;
	my ($ip, $pref_len) = split '/', shift;
	my $value = shift;

	croak 'missing required argument: prefix in ip/len form' unless defined $ip && defined $pref_len;
	croak 'value should be defined' unless defined $value;
	croak "bad prefix length: $pref_len in prefix $ip/$pref_len" unless $pref_len =~ /^\d+$/ && $pref_len >= 0 && $pref_len <= IPv4_BITS;

	my $i_ip = dd2int($ip);
	croak "bad ip address: $ip in prefix $ip/$pref_len" unless defined $i_ip;
	carp "low address bits of $ip/$pref_len are meaningless" unless is_valid_prefix($i_ip, $pref_len);

	my $mask = len2mask($pref_len);
	# start from most significant bit
	my $bit_to_test = 1 << (IPv4_BITS - 1);

	my $node = $self->{root};
	my $next = $self->{root};

	while ($bit_to_test & $mask) {
		if ($i_ip & $bit_to_test) {
			$next = $node->[RIGHT]
		}
		else {
			$next = $node->[LEFT]
		}
		last unless defined $next;

		$bit_to_test >>= 1;
		$node = $next;
	}

	if (defined $next) {
		carp "prefix $ip/$pref_len already exists with value ". $next->[VALUE] if defined $next->[VALUE];
		$next->[VALUE] = $value;
		return;
	}

	while ($bit_to_test & $mask) {
		$next = [];
		if ($i_ip & $bit_to_test) {
			$node->[RIGHT] = $next;
		}
		else {
			$node->[LEFT] = $next;
		}

		$bit_to_test >>= 1;
		$node = $next;
	}
	$node->[VALUE] = $value;
}

sub remove {
	my $self = shift;
	my ($ip, $pref_len) = split '/', shift;
	my $value = shift;

	croak "bad prefix length: $pref_len in prefix $ip/$pref_len" unless $pref_len =~ /^\d+$/ && $pref_len >= 0 && $pref_len <= IPv4_BITS;

	my $i_ip = dd2int($ip);
	croak "bad ip address: $ip in prefix $ip/$pref_len" unless defined $i_ip;

	my $mask = len2mask($pref_len);
	# start from most significant bit
	my $bit_to_test = 1 << (IPv4_BITS - 1);

	my $node = $self->{root};
	my $prev;

	while  ($node && ($bit_to_test & $mask)) {
		$prev = $node;
		if ($i_ip & $bit_to_test) {
			$node = $node->[RIGHT];
		} else {
			$node = $node->[LEFT];
		}
		$bit_to_test >>= 1;
	}
	return undef unless defined $node;

	if ($node->[LEFT] || $node->[RIGHT]) {
		undef $node->[VALUE];
	} else {
		# delete leaf node
		$bit_to_test <<= 1;
		if ($i_ip & $bit_to_test) {
			undef $prev->[RIGHT];
		} else {
			undef $prev->[LEFT];
		}
	}
	return 1;
}

# dump all prefixes into array ref
sub list {
	my $self = shift;

	my $r = [];

	_list($self->{root}, 0, 0, $r);

	return $r;
}

# recursive depth-first preorder tree traversal
sub _list {
	my ($node, $int_ip, $depth, $r) = @_;

	if (defined $node->[VALUE]) {
		my $ip = int2dd($int_ip);
		push @$r, [ "$ip/$depth", $node->[VALUE] ];
	}

	$depth++;
	_list($node->[LEFT], $int_ip, $depth, $r)
		if $node->[LEFT];
	# set current bit to 1
	_list($node->[RIGHT], $int_ip | (1 << IPv4_BITS - $depth), $depth, $r)
		if $node->[RIGHT];
}

sub compress {
	my $self = shift;

	croak 'value for default (0.0.0.0/0) should be defined' unless defined $self->{root}->[VALUE];

	pass_one_and_two($self->{root});
	pass_three($self->{root});
}

# internal functions

# recursive tree traversal
sub pass_one_and_two {
	my ($node, $parent_value) = @_;

	$parent_value = $node->[VALUE] if defined $node->[VALUE];

	# expand (deaggregate) tree
	# if node has exactly one child - create second one
	# this operation performed in depth-first preorder
	if ($node->[LEFT] xor $node->[RIGHT]) {
		my $new_node = [];
		$new_node->[VALUE] = $parent_value;
		$node->[LEFT] = $new_node unless $node->[LEFT];
 		$node->[RIGHT] = $new_node unless $node->[RIGHT];
	}

	pass_one_and_two($node->[LEFT], $parent_value)  if $node->[LEFT];
	pass_one_and_two($node->[RIGHT], $parent_value) if $node->[RIGHT];

	# at this point all nodes has two or no children

	# this operation performed depth-first postorder
	if ($node->[LEFT]) { # if node has 2 children

		# compute  nexthops(left) # nexthops(right)
		my %left = ref $node->[LEFT]->[VALUE] eq 'ARRAY' ?
						map { $_ => 1 } @{ $node->[LEFT]->[VALUE] } :
						( $node->[LEFT]->[VALUE] => 1 );
		my %right = ref $node->[RIGHT]->[VALUE] eq 'ARRAY' ?
						map { $_ => 1 } @{ $node->[RIGHT]->[VALUE] } :
						( $node->[RIGHT]->[VALUE] => 1);
		my @intersect = grep { $left{$_} } keys %right;

		if (scalar @intersect == 1) {
			# old value don't need for node with single new value
			$node->[VALUE] = $intersect[0];
		}
		elsif (scalar @intersect > 1) {
			$node->[OLD_VAL] = $node->[VALUE] if defined $node->[VALUE];
			$node->[VALUE] = \@intersect;
		}
		else {
			# intersect empty, use union
			$node->[OLD_VAL] = $node->[VALUE] if defined $node->[VALUE];
			my %union = (%left, %right);
			$node->[VALUE] = [ keys %union ];
		}
	}
}

# recursive depth-first preorder traversal
sub pass_three {
	my ($node, $parent, $parent_value) = @_;

	if ($parent_value ~~ $node->[VALUE]) {
		# parent value is member of node's potential values
		undef $node->[VALUE];
	}
	else {
		if (ref $node->[VALUE] ne 'ARRAY') {
			# only one value, leave it as is
			$parent_value = $node->[VALUE];
		} else {
			# there are several values
			if (!defined $node->[OLD_VAL]) {
				# there is more than one new values in this node (so this node has children
				# with different values) but in original tree there is no value for this node
				# remove this value (prefixes from children will be used)
				undef $node->[VALUE];
			} elsif ($node->[OLD_VAL] ~~ $node->[VALUE]) {
				# use old value if it found in set of potential new values
				$node->[VALUE] = $node->[OLD_VAL];
				$parent_value = $node->[VALUE];
			} else {
				# last resort: use arbitrary value e. g. first one
				$node->[VALUE] = $node->[VALUE]->[0];
				$parent_value = $node->[VALUE];
			}
		}
	}
	undef $node->[OLD_VAL];

	pass_three($node->[LEFT], $node, $parent_value)  if $node->[LEFT];
	pass_three($node->[RIGHT], $node, $parent_value) if $node->[RIGHT];

	# delete empty leaf nodes
	if (!defined $node->[VALUE] && !$node->[LEFT] && !$node->[RIGHT]) {
		if (ref $parent->[LEFT] && $parent->[LEFT] == $node) {
			undef $parent->[LEFT];
		} elsif (ref $parent->[RIGHT] && $parent->[RIGHT] == $node) {
			undef $parent->[RIGHT];
		} else {
			die 'internal error: bad parent for this node';
		}
	}
}

# utility functions

# same as unpack('N*',inet_aton($x));
# Parameters:
#  - ip in dot-decimal form, e. g. 192.0.2.1
# Returns:
#  - undef if ip is bad
#  - integer ip
sub dd2int {
	my @oct = split /\./, $_[0];
	return undef unless @oct == IPv4_BITS / 8;
	my $ip = 0;
	foreach(@oct) {
		return undef if $_ > 255 || $_ < 0;
		$ip = $ip<<8 | $_;
	}
	return $ip;
}

# ip from integer to dot-decimal (text) form
# reverse to dd2int
sub int2dd {
	return join '.', unpack('C*', pack('N', $_[0]));
}

# convert prefix length to netmask as integer
sub len2mask {
	die "bad prefix length $_[0]" if $_[0] < 0 || $_[0] > IPv4_BITS;
	return ALL_ONES - 2**(IPv4_BITS - $_[0]) + 1;
}

# $net - is integer
# $len - is prefix length 0 .. 32
sub is_valid_prefix {
	my ($net, $len) = @_;
	return (($net & len2mask($len)) == $net);
}

1;
__END__

=head1 METHODS

=head2 new

create a Net::CIDR::ORTC object

Arguments: none
Returns: new object

=head2 add

Add prefix -> value pair to internal tree.

Arguments:
  net - prefix in ip/len form, e. g. 192.0.2.0/24
  value - any defined scalar

Returns: none

=head2 remove

Remove exactly matches prefix from tree.

Arguments:
  net - prefix in ip/len form, e. g. 192.0.2.0/24

Returns:
 true if prefix found and removed, undef if prefix is not found

=head2 compress

Compress tree using ORTC algorithm

Arguments: none
Returns: none

=head2 list

Return list of current prefixes with values

Arguments: none
Returns: reference to array like:

    [ ['0.0.0.0/0', 'default'], ['64.0.0.0/2', 2], ['192.0.0.0/2', 3]

=head1 LIMITATIONS

Only IPv4 currently supported.

=head1 BUGS

Please report bugs to L<https://bitbucket.org/citrin/p5-net-cidr-ortc/issues>

=head1 AUTHORS

Anton Yuzhaninov <ayuzhaninov@openstat.ru>,
Denis Pokataev <dpokataev@openstat.ru>.
Initial version was sponsored by L<Openstat|http://openstat.com/>.

=head1 LICENCE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself, either Perl version 5.16.2 or, at your option, any later
version of Perl 5 you may have available.

=cut
