package Mock::Data::Plugin::Number;
use Mock::Data::Plugin -exporter_setup => 1;
use Mock::Data::Util 'mock_data_subclass';
my @generators= qw( integer decimal float byte sequence uuid );
export(@generators);

# ABSTRACT: Mock::Data plugin that provides basic numeric generators
our $VERSION = '0.03'; # VERSION


sub apply_mockdata_plugin {
	my ($class, $mock)= @_;
	$mock->add_generators(
		map +("Number::$_" => $class->can($_)), @generators
	);
}

our $int_bits= 15;
++$int_bits while (1 << $int_bits) > 1  # old perls used to perform MOD 32 on the shift argument
	and $int_bits < 256; # prevent infinite loop in case of broken assumptions

our $float_bits= 22;
++$float_bits while 2**$float_bits != 2**$float_bits + 1
	and $float_bits < 256; # prevent infinite loop in case of broken assumptions


sub integer {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $size= shift;
	my $signed;
	if ($params) {
		$size //= $params->{digits} // $params->{size};
		$signed= !$params->{unsigned};
	}
	else { $signed= 1; }

	if (defined $size) {
		my $digits= 1 + int rand($size-1);
		my $val= 10**($digits-1) + int rand(9 * 10**($digits-1));
		return $signed && int rand 2? -$val : $val;
	} else {
		my $bits= ($params? $params->{bits} : undef) // 32;
		$bits= $int_bits if $bits > $int_bits; # can't generate more than $int_bits anyway
		$bits= int rand($signed? $bits : $bits+1);
		# calls to rand() only return 53 bits, because it is a double.  To get 64, need to
		# combine multiple rands.  Also, can't get 32 bits from rand on 32bit arch.
		my $val= $bits < $int_bits && $bits < $float_bits? int(rand(1<<$int_bits))
			: unpack('J', byte($mock, 8)) >> ($int_bits-$bits);
		return $signed && int rand 2? -$val : $val;
	}
}


sub decimal {
	my $mock= shift;
	my $params= ref $_ eq 'HASH'? shift : undef;
	my $size= shift // ($params? $params->{size} : undef) // 11;
	my $scale= 0;
	($size, $scale)= @$size if ref $size eq 'ARRAY';
	my $val= integer($mock, $size > $scale? $size : $scale-1);
	if ($scale) {
		if ($val < 0) {
			substr($val,1,0,'0'x($scale+2 - length $val))
				if length $val < $scale+2;
		} else {
			substr($val,0,0,'0'x($scale+1 - length $val))
				if length $val < $scale+1;
		}
		substr($val, -$scale, 0)= '.';
	}
	return $val;
}


sub float {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $size= shift // ($params? ($params->{digits} // $params->{size}) : undef);
	if (defined $size) {
		return decimal($mock, [$size, 1+int rand($size-1)]);
	}
	else {
		my $bits= shift // ($params? $params->{bits} : undef) // 23;
		$bits= $float_bits if $bits > $float_bits;
		# This algorithm chooses floating point numbers that don't lose precision when cast into
		# a float of the specified number of significant bits.
		my $sign= int rand 2? -1 : 1;
		my $exponent= 2 ** -int rand $bits;
		my $significand= int rand 2**$bits;
		return $sign * $exponent * $significand;
	}
}


sub byte {
	my ($mock, $count)= @_;
	return pack('C',rand(256))
		unless $count;
	my $buf= '';
	if (defined $count) {
		if ($int_bits > 32 && $float_bits > 32) {
			$buf .= pack('L', rand(1<<32))
				while length $buf < $count;
		}
		$buf .= pack('S', rand(1<<16))
			while length $buf < $count;
		substr($buf,$count)= '';
	}
	return $buf;
}


sub sequence {
	my $mock= shift;
	my $params= ref $_[0] eq 'HASH'? shift : undef;
	my $name= shift // ($params? $params->{sequence_name} : undef)
		// Carp::croak("sequence_name is required for sequence generator");
	return ++$mock->generator_state->{"Number::sequence"}{$name};
}


sub uuid {
	sprintf "%04x%04x-%04x-%04x-%04x-%04x%04x%04x",
		rand(1<<16), rand(1<<16), rand(1<<16),
		(4<<12)|rand(1<<12), (1<<15)|rand(1<<14),
		rand(1<<16), rand(1<<16), rand(1<<16)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Plugin::Number - Mock::Data plugin that provides basic numeric generators

=head1 SYNOPSIS

  my $mock= Mock::Data->new(['Number']);
  $mock->integer($digits); # signed/unsigned, bit length or digit length
  $mock->decimal([$p,$s]); # [precision,scale] decimal numbers
  $mock->float($digits);   # random significand and exponent floats
  $mock->byte($count);     # string of random bytes
  $mock->sequence($name);  # incrementing named counter, starting from 1
  $mock->uuid;             # UUID version 4 variant 1 (random)

=head1 DESCRIPTION

This plugin provides some basic "random number" support.

=head1 GENERATORS

=head2 integer

  $mock->integer;                    # signed 32-bit by default
  $mock->integer(10);                # up to 10 digits
  $mock->integer({ digits => 10 });
  $mock->integer({ size => 10 });    # alias for digits
  $mock->integer({ bits => 20 });    # up to 20 bits (either signed or unsigned)
  $mock->integer({ unsigned => 1 });

Returns a random integer up to C<$digits> decimal digits (not including sign) or up
to C<$bits> (including sign).
If C<$digits> and C<$bits> are both specified, C<$digits> wins.
If neither are specified, the default is C<< { bits => 32 } >>.
If C<unsigned> is true, this generates non-negative integers.

The randomization chooses the length of the number (either bits or decimal digits)
separately from the value of the number.  This results in numbers tending toward
the middle string length, rather than an even distribution over the range of
values.  The goal is to look more realistic than if nearly half the values were the
maximum length.

=head3 decimal

  $str= $mock->decimal($size);
  $str= $mock->decimal([ $size, $scale ]);
  $str= $mock->decimal({ size => [ $size, $scale ] });

C<$size> is the total number of digits (not characters) and C<$scale> is the number
of digits to the right of the decimal point.

Note that this generator returns strings, to make sure to avoid floating imprecision.

=head3 float

  $str= $mock->float;
  $str= $mock->float({ bits => $significand_bits });
  $str= $mock->float($digits);
  $str= $mock->float({ size => $digits });

If a number of "digits" is requested, this calls L</decimal> with a random scale
and returns a string.

Else, it operates on bits, choosing a random significand, exponent, and sign.
If a number if bits is requested, this applies to the length of the significand.  For example,
C<< bits => 23 >> means that you can pack the number as a IEEE754 32-bit float and get back
the original number, because the IEEE 754 32-bit has a 23 bit significand.  Like the 'digits'
mode, this picks an exponent within the significand, to avoid scientific notation.

The default is C<< bits => 23 >>.

=head2 byte

  $byte= $mock->byte;          # a single random byte
  $str=  $mock->byte($count);  # returns $count random bytes

=head3 sequence

  $int= $mock->sequence($seq_name);
  $int= $mock->sequence({ sequence_name => $seq_name });

Returns the next number in the named sequence, starting with 1.  The sequence name is required.
The state of the sequence is stored in C<< $mock->generator_state->{"Number::sequence"}{$seq_name} >>.

=head2 uuid

Return a "version 4" UUID composed of weak random bits from C<rand()>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
