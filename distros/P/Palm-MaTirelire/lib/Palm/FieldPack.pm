=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::FieldPack;

use Exporter;

use base qw(Exporter);

our @EXPORT = qw(pack_fields_to_UInt8 unpack_UInt8_to_fields
		 pack_fields_to_UInt16 unpack_UInt16_to_fields
		 pack_fields_to_UInt32 unpack_UInt32_to_fields
		 pack_DateType unpack_DateType
		 pack_TimeType unpack_TimeType
		 pack_double unpack_double);

our $VERSION = '1.0';


my $big_endian;
BEGIN
{
    if (length(pack('d', 0)) != 8)
    {
	die "Can't manage double values in this database, abort.\n";
    }

    if (pack('I', 0x12345678) eq pack('N', 0x12345678))
    {
	$big_endian = 1;
    }
    elsif (pack('I', 0x12345678) eq pack('V', 0x12345678))
    {
	$big_endian = 0;
    }
    else
    {
	die "Can't guess indianess of this host, abort\n";
    }
}


#
# Arguments are :
#   nbits, [hash,] packed_val, "name1:bitfld1_width", "name2:bitfld2_width",etc
#   "nameX:bitfield_widths" are in the same order than in the C struct
# Returns values for each bitfield in the same order
sub __unpack_fields
{
    my $cur_shift = shift;	# Bit width...
    my($ref_hash, $uint);
    my @result;

    $ref_hash = shift;
    if (ref($ref_hash) eq 'HASH')
    {
	$uint = shift;
    }
    else
    {
	$uint = $ref_hash;
	$ref_hash = undef;
    }

    $uint = unpack($cur_shift == 32 ? 'N' : ($cur_shift == 16 ? 'n' : 'C'),
		   $uint);

    foreach my $width_str (@_)
    {
	my($name, $width) = split(':', $width_str);

	$width = $cur_shift if $width eq '*';

	$cur_shift -= $width;

	my $value = ($uint >> $cur_shift) & ((1 << $width) - 1);

	$ref_hash->{$name} = $value if defined $ref_hash;
	push(@result,  $value);
    }

    return unless defined wantarray;

    return wantarray ? @result : \@result;
}


#
# Arguments are : bits, hash, "name1:bitfld1_width", "name1:bitfld2_width", etc
# Returns the packed value
sub __pack_fields
{
    my $uint = 0;
    my $cur_shift = shift;
    my $ref_hash = shift;

    my $pack_char = $cur_shift == 32 ? 'N' : ($cur_shift == 16 ? 'n' : 'C');

    foreach my $width_str (@_)
    {
	my($name, $width) = split(':', $width_str);

	$width = $cur_shift if $width eq '*';

	$cur_shift -= $width;

	my $val = $ref_hash->{$name};

	if (defined $val)
	{
	    # Référence => consider 1
	    if (ref $val)
	    {
		$val = 1;
	    }
	    # Boolean value
	    elsif ($width == 1)
	    {
		$val = ($val != 0);
	    }
	}
	else
	{
	    $val = 0;
	}

	$uint |= ($val & ((1 << $width) - 1)) << $cur_shift;
    }

    return pack($pack_char, $uint);
}


sub pack_double ($)
{
    my $pack = pack('d', shift);

    return $pack if $big_endian;

    return scalar reverse $pack;
}


sub unpack_double ($)
{
    my $pack = shift;

    $pack = scalar reverse $pack unless $big_endian;

    return unpack('d', $pack);
}


#
# Arguments are : hash, "name1:bitfld1_width", "name1:bitfld2_width", etc
#			in the same order than in the C struct
# Returns the packed value
sub pack_fields_to_UInt32
{
    return __pack_fields(32, @_);
}


#
# Arguments are : hash, "name1:bitfld1_width", "name1:bitfld2_width", etc
#			in the same order than in the C struct
# Returns the packed value
sub pack_fields_to_UInt16
{
    return __pack_fields(16, @_);
}


#
# Arguments are : hash, "name1:bitfld1_width", "name1:bitfld2_width", etc
#			in the same order than in the C struct
# Returns the packed value
sub pack_fields_to_UInt8
{
    return __pack_fields(8, @_);
}


#
# Arguments are :
#   [hash,] packed_val, "name1:bitfld1_width", "name2:bitfld2_width",etc
#			in the same order than in the C struct
# Returns values for each bitfield in the same order
sub unpack_UInt8_to_fields
{
    return __unpack_fields(8, @_);
}


#
# Arguments are :
#   [hash,] packed_val, "name1:bitfld1_width", "name2:bitfld2_width",etc
#			in the same order than in the C struct
# Returns values for each bitfield in the same order
sub unpack_UInt16_to_fields
{
    return __unpack_fields(16, @_);
}


#
# Arguments are :
#   [hash,] packed_val, "name1:bitfld1_width", "name2:bitfld2_width",etc
#			in the same order than in the C struct
# Returns values for each bitfield in the same order
sub unpack_UInt32_to_fields
{
    return __unpack_fields(32, @_);
}


#
# Arguments are : hash [, "prefix_"]
sub pack_DateType
{
    my($ref_hash, $prefix) = @_;

    $prefix = '' unless defined $prefix;

    # Sometimes we want the date to be totaly zeroed, don't add 1904
    # in these cases
    if (defined $ref_hash->{"${prefix}year"}
	and $ref_hash->{"${prefix}year"} > 0)
    {
	$ref_hash->{"${prefix}year"} -= 1904;
    }

    my $pack = pack_fields_to_UInt16($ref_hash,
				     "${prefix}year:7",
				     "${prefix}month:4",
				     "${prefix}day:5");

    # Sometimes we want the date to be totaly zeroed, don't add 1904
    # in these cases
    if (defined $ref_hash->{"${prefix}year"}
	and $ref_hash->{"${prefix}year"} > 0)
    {
	$ref_hash->{"${prefix}year"} += 1904;
    }

    return $pack;
}


#
# Arguments are : [hash,] packed_val [, "prefix_" (only if hash is present)]
sub unpack_DateType
{
    my $ref_hash = $_[0];
    my $prefix = @_ == 3 ? pop : '';
    my @result;

    @result = unpack_UInt16_to_fields(@_,
				      "${prefix}year:7",
				      "${prefix}month:4",
				      "${prefix}day:5");

    # Sometimes we want the date to be totaly zeroed, don't add 1904
    # in these cases
    if (ref($ref_hash) eq 'HASH' and $ref_hash->{"${prefix}year"} > 0)
    {
	$ref_hash->{"${prefix}year"} += 1904;
    }

    return unless defined wantarray;

    # Sometimes we want the date to be totaly zeroed, don't add 1904
    # in these cases
    if ($result[0] != 0 or $result[1] != 0 or $result[2] != 0)
    {
	$result[0] += 1904;
    }

    return wantarray ? @result : \@result;
}


#
# Arguments are : hash [, "prefix_"]
sub pack_TimeType
{
    my($ref_hash, $prefix) = @_;

    $prefix = '' unless defined $prefix;

    return pack('CC', map { defined($_) ? (ref($_) ? 1 : $_) : 0 }
		@$ref_hash{"${prefix}hour", "${prefix}min"});
}


#
# Arguments are : [hash,] packed_val [, "prefix_"]
sub unpack_TimeType
{
    my($ref_hash, $packed_value, $prefix);
    my @result;

    $ref_hash = shift;

    if (ref($ref_hash) eq 'HASH')
    {
	($packed_value, $prefix) = @_;

	$prefix = '' unless defined $prefix;
    }
    else
    {
	$packed_value = $ref_hash;
	$ref_hash = undef;
    }

    @result = unpack('CC', $packed_value);

    @$ref_hash{"${prefix}hour", "${prefix}min"} = @result if defined $ref_hash;

    return unless defined wantarray;

    return wantarray ? @result : \@result;
}

1;
__END__

=head1 NAME

Palm::FieldPack - Pack Palm data types and bitfield into perl structures

=head1 SYNOPSIS

  use Palm::FieldPack;

=head1 DESCRIPTION

To be done XXX...

=head1 SEE ALSO

Palm::BlockPack(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
