#
# PHP arrays - a php array is an ordered map.
# http://www.php.net/manual/en/language.types.array.php
#
package PHP::Decode::Array;

use strict;
use warnings;
use Tie::IxHash;
use Exporter qw(import);
our @EXPORT_OK = qw(is_int_index);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.15';

my $arridx = 1;
our $arrpfx = '#arr';
our $class_strmap; # client might override $PHP::Decode::Array::class_strmap = \%strmap;

sub new_name {
	my $name = "$arrpfx$arridx";
	$arridx++;
	return $name;
}

sub is_int_index {
	my ($k) = @_;

	if ($k =~ /^\-?\d+$/) {
		return 1;
	}
	return 0;
}

sub _ordered_map {
	my ($self) = @_;

	# preserve the order of inserted keys
	# https://perldoc.perl.org/perlfaq4#How-can-I-make-my-hash-remember-the-order-I-put-elements-into-it?
	# https://metacpan.org/pod/Tie::IxHash
	#
	tie my %map, "Tie::IxHash";

	# convert existing consecutive numeric map to ordered map
	#
	if (exists $self->{map}) {
		foreach my $k (sort { $a <=> $b } keys %{$self->{map}}) {
			$map{$k} = $self->{map}{$k};
		}
	}
	return \%map;
}

sub new {
	my ($class, %args) = @_;

	# $self->{map} is created on demand and converted to ordered map
	# if required. A native perl hashmap is much faster.
	#
	my $self = bless {
                %args,
		name => new_name(),
		idx => undef,
		pos => 0,
	}, $class;
	$self->{strmap} = $class_strmap unless exists $self->{strmap};

	if (defined $self->{strmap}) {
		$self->{strmap}{$self->{name}} = $self; # register name
	}
	return $self;
}

# return number if key contains numeric value.
#
sub get_index {
	my ($self, $k) = @_;
	my $k0 = $k;

	# float keys are truncated to int,
	# http://php.net/manual/en/language.types.array.php
	# (but only int-strings are converted to int-key)
	#
	if (defined $self->{strmap} && exists $self->{strmap}{$k}) {
		$k = $self->{strmap}{$k};
	}
	if (($k0 =~ /^#str\d+$/) && ($k =~ /^\-?(\d|[1-9]\d+)$/)) {
		$k = int($k);
	} elsif (($k0 !~ /^#str\d+$/) && (ref($k) eq '') && ($k =~ /^\-?(\d|[1-9]\d+|\d+\.\d*|\d*\.\d+)([eE][+-]?\d+)?$/)) {
		$k = int($k);
	} else {
		$k = $k0;
	}
	return $k;
}

sub set {
	my ($self, $k, $v) = @_;

	# without key use the increment of the largest previously used int key
	#
	if (defined $k) {
		$k = $self->get_index($k);
		if (is_int_index($k)) {
			if (!defined $self->{idx} || ($k >= $self->{idx})) {
				$self->{idx} = $k+1;
			}
		} else {
			$self->{non_numeric} = 1;
		}
		if (!exists $self->{map} || !exists $self->{ordered}) {
			$self->{map} = $self->_ordered_map();
			$self->{ordered} = 1;
		}
	} else {
		# use faster unordered map as long as no explicit key is used.
		#
		$self->{map} = {} unless exists $self->{map};
		$self->{idx} = 0 unless defined $self->{idx};
		$k = $self->{idx};
		$self->{idx} += 1;
	}
	if (defined $self->{strmap} && (ref($v) eq ref($self))) {
		$self->{map}{$k} = $v->{name};
	} else {
		$self->{map}{$k} = $v;
	}
	#printf ">> setarr: %s{%s} = %s\n", $self->{name}, $k, $v if $opt{v};
	return $self;
}

sub get {
	my ($self, $k) = @_;

	if (exists $self->{map}) {
		$k = $self->get_index($k);

		if (exists $self->{map}{$k}) {
			return $self->{map}{$k};
		}
	}
	return;
}

sub copy {
	my ($self, $keys) = @_;

	# TODO: #arr$x.$y sub-name here?
	#
	my $c = PHP::Decode::Array->new(strmap => $self->{strmap});

	if (exists $self->{map}) {
		if (exists $self->{ordered} || defined $keys) {
			$c->{map} = $c->_ordered_map();
			$c->{ordered} = 1;
		} else {
			$c->{map} = {};
		}
		unless (defined $keys) {
			$keys = [keys %{$self->{map}}]; # default: all keys
		}
		foreach my $k (@$keys) {
			my $v0 = $self->{map}{$k};
			my $v = $v0;

			if (defined $v && defined $self->{strmap} && exists $self->{strmap}{$v}) {
				$v = $self->{strmap}{$v};
			}
			if (defined $v && (ref($v) eq ref($self))) {
				my $subarray = $v->copy();
				if (defined $self->{strmap}) {
					$c->{map}{$k} = $subarray->{name};
				} else {
					$c->{map}{$k} = $subarray;
				}
			} else {
				$c->{map}{$k} = $v0;
			}
		}
		$c->{idx} = $self->{idx};
		$c->{pos} = $self->{pos};
		$c->{non_mumeric} = 1 if exists $self->{non_numeric};
	}
	return $c;
}

sub delete {
	my ($self, $k) = @_;

	if (exists $self->{map}) {
		# after deletion key order has to be preserved
		#
		unless (exists $self->{ordered}) {
			$self->{map} = $self->_ordered_map();
			$self->{ordered} = 1;
		}
		return delete $self->{map}{$k};
	}
	return;
}

sub val {
	my ($self, $k) = @_;
	exists $self->{map}{$k} || die "assert: bad key $k passed to array->val()";
	return $self->{map}{$k}; # for get_keys lookup
}

sub get_keys {
	my ($self) = @_;

	if (exists $self->{map}) {
		my @keys;
		if (exists $self->{ordered}) {
			# insertion order is preserved by Tie::IxHash
			#
			@keys = keys %{$self->{map}};
		} else {
			@keys = sort { $a <=> $b } keys %{$self->{map}};
		}
		return \@keys;
	}
	return [];
}

sub get_keys_sorted {
	my ($self) = @_;
	my @keys;

	# sort non-hash arrays by index
	#
	if (exists $self->{map}) {
		if (exists $self->{non_numeric}) {
			@keys = sort keys %{$self->{map}};
		} else {
			@keys = sort { $a <=> $b } keys %{$self->{map}};
		}
		return \@keys;
	}
	return [];
}

sub get_pos {
	my ($self) = @_;

	return $self->{pos};
}

sub set_pos {
	my ($self, $pos) = @_;

	$self->{pos} = $pos;
	return;
}

sub is_numerical {
	my ($self) = @_;

	if (exists $self->{non_numeric}) {
		return 0;
	}
	return 1;
}

sub empty {
	my ($self) = @_;

	return (keys %{$self->{map}} == 0);
}

sub to_str {
	my ($self) = @_;
	my $keys = $self->get_keys();
	my $str = '(';

	foreach my $k (@$keys) {
		my $v = $self->{map}{$k};

		if (defined $v && defined $self->{strmap} && exists $self->{strmap}{$v}) {
			$v = $self->{strmap}{$v};
		}
		$str .= ', ' if ($str ne '(');
		if (defined $v && (ref($v) eq ref($self))) {
			$str .= $v->to_str();
		} else {
			if (is_int_index($k)) {
				$str .= "$k => '$v'";
			} else {
				$str .= "'$k' => '$v'";
			}
		}
	}
	$str .= ')';
	return $str;
}

1;

__END__

=head1 NAME

PHP::Decode::Array - php ordered arrays

=head1 SYNOPSIS

  # Create an array

  my $a = PHP::Decode::Array->new();

  $a->set(undef, 'a');
  $a->set(undef, 'b');
  $a->set('x', 'c');
  $a->set('y', PHP::Decode::Array->new());

  # Copy array recursively

  my $a2 = $a->copy();

  # Convert to string

  printf "$a->{name} = %s\n", $a->to_str();

=head1 DESCRIPTION

The PHP::Decode::Array Module implements php compatible arrays

To track the order of insertions of key-value pairs, the internal represention
uses an ordered hashmap.

As long as a php array is used as a classic array, where only values without
a key are appended, the internal representation uses a simple hashmap.

The performance of the ordered hashmap is 3 times slower than the simple map.

As soon as the array switches to an ordered hashmap, the $array->{ordered}
flag will be set.

=head1 METHODS

=head2 new

  my $array = PHP::Decode::Array->new();

Create a new php array.
The $array->{name} field is generated as increasing '#arr<N>' value.

The PHP::Decode::Array module is designed to work together with PHP::Decode::Parser.
If the $PHP::Decode::Array::class_strmap is initialized with a perl hashmap, than
this hashmap is used to track array-names and array-key names other than
numeric values.

  my %strmap;
  $PHP::Decode::Array::class_strmap = \%strmap;

If no class_strmap is set and no 'strmap' option is passed as argument,
then the PHP::Decode::Array module will store the array values directly.

=head2 set

  $array->set(undef, $value);
  $array->set($key, $value);

Set Array entry to value.
If key is omitted, then use max integer key or 0 as next key.

=head2 get

  my $value = $array->get($key);

Get Array entry.

=head2 delete

  my $value = $array->delete($key);

Delete Array entry and return deleted value.

=head2 copy

  $array2 = $array->copy();
  $array2 = $array->copy(\@keys);

Copy array recursively.
Optionally pass a list of toplevel keys to copy (default is all keys).

=head2 get_keys / val

  $keys = $array->get_keys();
  foreach my $key (@$keys) {
	my $val = $array->val($key);
  }

Get list of array keys in insertion order. The val() function returns
the entry stored for a key. The val() function is meant to work on the
list returned by get_keys() - other than get() it does not check for
the validity of the passed index.

=head2 empty

  $is_empty = $array->empty();

Check if array is empty.

=head2 get_pos

  $pos = $array->get_pos();

Get internal array pointer.

=head2 set_pos

  $array->set_pos($pos);

Set internal array pointer.

=head2 to_str

  printf "$array->{name} = %s\n", $array->to_str();

Dump array contents recursively.

=head1 Dependencies

Requires the Tie::IxHash Module.

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut
