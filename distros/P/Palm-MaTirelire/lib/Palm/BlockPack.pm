=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::BlockPack;

use strict;

use Carp qw(carp);
use Palm::FieldPack;

our $VERBOSE = 1;

our $VERSION = '1.0';


my %SPECIAL_TYPES = (UInt8    => [ \&pack_fields_to_UInt8,
				   \&unpack_UInt8_to_fields ],
		     UInt16   => [ \&pack_fields_to_UInt16,
				   \&unpack_UInt16_to_fields ],
		     UInt32   => [ \&pack_fields_to_UInt32,
				   \&unpack_UInt32_to_fields ],
		     DateType => [ \&pack_DateType, \&unpack_DateType ],
		     TimeType => [ \&pack_TimeType, \&unpack_TimeType ],
		     double   => [ \&pack_double, \&unpack_double, 8 ],
		    );

sub pretty_str ($)
{
    my $str = shift;
    my $new = '';

    return $str if ref $str;

    while (length($str) > 0)
    {
        my $char = substr($str, 0, 1, '');

        if (ord($char) < 32)
        {
            if (ord($char) == 10)
            {
                $new .= "\n";
            }
            else
            {
                $new .= "^" . chr(ord($char) + 64);
            }
        }
        else
        {
            $new .= $char;
        }
    }

    return $new;
}


sub __negate ($$)
{
    my($ref, $size) = @_;

    my $array = ref($ref) eq 'ARRAY' ? $ref : [ $$ref ];

    foreach my $elt (@$array)
    {
	# Already null or negative, nothing to do...
	next if $elt <= 0; # (1 << ($size - 1));

	if ($size == 2)
	{
	    $elt = unpack('s', pack('S', $elt));
	}
	else # $size == 4
	{
	    $elt = unpack('l', pack('L', $elt));
	}
    }

    if (ref($ref) ne 'ARRAY')
    {
	$$ref = $array->[0];
    }
}


sub new ($@)
{
    my $class = shift;

    die "Odd number of attributes" if @_ % 2;

    my $self = [ @_ ];

    return bless($self, ref($class) || $class);
}


sub init_block_element ($$$;$)
{
    my($self, $ref_hash, $index, $delete_noinit) = @_;

    my $type = $self->[$index];
    my $value = $self->[$index + 1];

    # Skip bytes
    if ($type eq 'skip')
    {
	# Nothing to do here
    }
    # Bit field
    elsif ($type =~ /^UInt(?:8|16|32)\z/)
    {
	foreach my $field (@$value)
	{
	    # No reference => no init
	    if (ref $field)
	    {
		# The name without bit_width
		my($name) = split(':', $field->[0]);

		$ref_hash->{$name} =  $field->[1];
	    }
	    elsif ($delete_noinit)
	    {
		# The name without bit_width
		my($name) = split(':', $field);

		delete $ref_hash->{$name};
	    }
	}
    }
    elsif ($type eq 'DateType')
    {
	# No reference => no init
	if (ref $value)
	{
	    # 'date_', 'now'
	    if (@$value == 2)
	    {
		if ($value->[1] eq 'now')
		{
		    my @now = localtime(time);
		    $ref_hash->{"$value->[0]day"} = $now[3];
		    $ref_hash->{"$value->[0]month"} = $now[4] + 1;
		    $ref_hash->{"$value->[0]year"} = $now[5] + 1900;
		}
		else
		{
		    $ref_hash->{"$value->[0]day"} = $value->[1];
		    $ref_hash->{"$value->[0]month"} = $value->[1];
		    $ref_hash->{"$value->[0]year"} = $value->[1];
		}
	    }
	    # 'date_', day, month, year
	    else
	    {
		$ref_hash->{"$value->[0]day"} = $value->[1];
		$ref_hash->{"$value->[0]month"} = $value->[2];
		$ref_hash->{"$value->[0]year"} = $value->[3];
	    }
	}
	elsif ($delete_noinit)
	{
	    delete @$ref_hash{"${value}day",
			      "${value}month",
			      "${value}year"};
	}
    }
    elsif ($type eq 'TimeType')
    {
	# No reference => no init
	if (ref $value)
	{
	    # 'time_', 'now'
	    if (@$value == 2)
	    {
		if ($value->[1] eq 'now')
		{
		    my @now = localtime(time);
		    $ref_hash->{"$value->[0]hour"} = $now[2];
		    $ref_hash->{"$value->[0]min"} = $now[1];
		}
		else
		{
		    $ref_hash->{"$value->[0]hour"} = $value->[1];
		    $ref_hash->{"$value->[0]min"} = $value->[1];
		}
	    }
	    # 'time_', hour, min
	    else
	    {
		$ref_hash->{"$value->[0]hour"} = $value->[1];
		$ref_hash->{"$value->[0]min"} = $value->[2];
	    }
	}
	elsif ($delete_noinit)
	{
	    delete @$ref_hash{"${value}hour", "${value}min"};
	}
    }
    # Other types
    else
    {
	# No reference => no init
	if (ref $value)
	{
	    # Liste de nombres
	    if ($type =~ /^\[(?:-?[Nn]|[Cc])[1-9]\d*\]\z/)
	    {
		$ref_hash->{$value->[0]} = [ @$value[1 .. $#$value] ];
	    }
	    else
	    {
		$ref_hash->{$value->[0]} = $value->[1];
	    }
	}
	elsif ($delete_noinit)
	{
	    delete $ref_hash->{$value};
	}
    }
}


#
# Initialise le hash passé avec les valeurs par défaut
sub init_block ($$;$)
{
    my($self, $ref_hash, $delete_noinit) = @_;
    my $index;

    for (my $index = 0; $index < @$self; $index += 2)
    {
	$self->init_block_element($ref_hash, $index, $delete_noinit);
    }
}


sub pack_block ($$)
{
    my($self, $ref_hash) = @_;
    my $index;

    my $pack = '';

    for (my $index = 0; $index < @$self; $index += 2)
    {
	my $type = $self->[$index];
	my $value = $self->[$index + 1];

	# Skip bytes
	if ($type eq 'skip')
	{
	    my($num, $byte);

	    if (ref $value)
	    {
		($num, $byte) = @$value;
	    }
	    else
	    {
		$num = $value;
		$byte = "\0";
	    }

	    $pack .= $byte x $num;
	}
	# Bit field
	elsif ($type =~ /^UInt(?:8|16|32)\z/)
	{
	    $pack .=
	      $SPECIAL_TYPES{$type}[0]->($ref_hash,
					 map {ref($_) ? $_->[0] : $_} @$value);
	}
	else
	{
	    my $field_name = ref($value) ? $value->[0] : $value;

	    # DateType || TimeType
	    if ($type =~ /^(?:Date|Time)Type\z/)
	    {
		$pack .= $SPECIAL_TYPES{$type}[0]->($ref_hash, $field_name);
	    }
	    # Liste de nombres
	    elsif ($type =~ /^\[((?:-?[Nn]|[Cc])([1-9]\d*))\]\z/)
	    {
		my($pack_type, $num) = ($1, $2);

		$pack_type =~ s/^-//; # Negative case deleted here...

		my $ref_list = $ref_hash->{$field_name} || [];

		if (@$ref_list < $num)
		{
		    push(@$ref_list, (0) x (@{$ref_list} - $num));
		}

		$pack .= pack($pack_type, @$ref_list);
	    }
	    else
	    {
		my $field_value = $ref_hash->{$field_name};

		unless (defined $field_value)
		{
		    if ($type =~ /^(?:-?[Nn]|[Cc])\z/
			or exists $SPECIAL_TYPES{$type})
		    {
			$field_value = 0;
		    }
		    elsif ($type =~ /^Z(\*|\d+)\z/)
		    {
			$field_value = '';
		    }
		    else
		    {
			die "Unknown Perl pack type";
		    }
		}

		# Special type
		if (exists $SPECIAL_TYPES{$type})
		{
		    $pack .= $SPECIAL_TYPES{$type}[0]->($field_value);
		}
		# Perl pack type
		else
		{
		    $type =~ s/^-//; # Negative case deleted here...

		    $pack .= pack($type, $field_value);
		}
	    }
	}
    }

    return $pack;
}


sub unpack_block ($$;$$)
{
    my($self, $pack, $ref_hash, $no_nonempty_alert) = @_;

    $ref_hash = {} unless defined $ref_hash;

    my $ref_pack = ref($pack) ? $pack : \$pack;

    for (my $index = 0; $index < @$self; $index += 2)
    {
	my $type = $self->[$index];
	my $value = $self->[$index + 1];
	my $out_of_data = 0;

	if ($type eq 'skip')
	{
	    my $size = ref($value) ? $value->[0] : $value;

	    if (length($$ref_pack) < $size)
	    {
		if ($VERBOSE and not $no_nonempty_alert)
		{
		    carp("unpack_block: out of data, can't skip"
			 . " (only " . length($$ref_pack)
			 . " byte(s) available: \""
			 . pretty_str($$ref_pack)
			 . "\")");
		}
	    }
	    else
	    {
		substr($$ref_pack, 0, $size) = '';
	    }
	}
	# Bit field
	elsif ($type =~ /^UInt(8|16|32)\z/)
	{
	    my $size = $1 / 8;

	    if (length($$ref_pack) < $size)
	    {
		if ($VERBOSE and not $no_nonempty_alert)
		{
		    carp("unpack_block: ",
			 "out of data, can't unpack field $type"
			 . " (only " . length($$ref_pack)
			 . " byte(s) available: \""
			 . pretty_str($$ref_pack)
			 . "\")");
		}
		$out_of_data = 1;
	    }
	    else
	    {
		$SPECIAL_TYPES{$type}[1]->($ref_hash,
					   substr($$ref_pack, 0, $size, ''),
					   map { ref($_) ? $_->[0] : $_ }
					   @$value);
	    }
	}
	else
	{
	    my $field_name = ref($value) ? $value->[0] : $value;

	    # DateType || TimeType
	    if ($type =~ /^(?:Date|Time)Type\z/)
	    {
		if (length($$ref_pack) < 2)
		{
		    if ($VERBOSE and not $no_nonempty_alert)
		    {
			carp("unpack_block: out of data, can't unpack $type"
			     . " (only " . length($$ref_pack)
			     . " byte(s) available: \""
			     . pretty_str($$ref_pack)
			     . "\")");
		    }
		    $out_of_data = 1;
		}
		else
		{
		    $SPECIAL_TYPES{$type}[1]->($ref_hash,
					       substr($$ref_pack, 0, 2, ''),
					       $field_name);
		}
	    }
	    # Special type
	    elsif (exists $SPECIAL_TYPES{$type})
	    {
		if (length($$ref_pack) < $SPECIAL_TYPES{$type}[2])
		{
		    if ($VERBOSE and not $no_nonempty_alert)
		    {
			carp("unpack_block: out of data, can't unpack $type"
			     . " (only " . length($$ref_pack)
			     . " byte(s) available: \""
			     . pretty_str($$ref_pack)
			     . "\")");
		    }
		    $out_of_data = 1;
		}
		else
		{
		    $ref_hash->{$field_name} = $SPECIAL_TYPES{$type}[1]
			->(substr($$ref_pack, 0, $SPECIAL_TYPES{$type}[2],''));
		}
	    }
	    # Liste de nombres
	    elsif ($type =~ /^\[((-?[Nn]|[Cc])([1-9]\d*))\]\z/)
	    {
		my($pack_type, $pack_one, $num) = ($1, $2, $3);

		my $neg = 0;
		if (substr($pack_type, 0, 1) eq '-')
		{
		   substr($pack_type, 0, 1) = '';
		   substr($pack_one, 0, 1) = '';
		   $neg = 1;
		}

		my $size;
		if ($pack_one eq 'N')
		{
		    $size = 4;
		}
		elsif ($pack_one eq 'n')
		{
		    $size = 2;
		}
		else		# $pack_one eq 'C' or $pack_one eq 'c'
		{
		    $size = 1;
		}

		if (length($$ref_pack) < $size * $num)
		{
		    if ($VERBOSE and not $no_nonempty_alert)
		    {
			carp("unpack_block: out of data, can't unpack $type"
			     . " (only " . length($$ref_pack)
			     . " byte(s) available: \""
			     . pretty_str($$ref_pack)
			     . "\")");
		    }
		    $out_of_data = 1;
		}
		else
		{
		    $ref_hash->{$field_name}
		      = [ unpack($pack_type,
				 substr($$ref_pack, 0, $size * $num, '')) ];

		    # 16 bits or 32 bits value is signed...
		    __negate($ref_hash->{$field_name}, $size) if $neg;
		}
	    }
	    # Perl pack type
	    else
	    {
		my($size, $min_size);

		my $neg = 0;

		if ($type =~ s/^(-?)N\z/N/)
		{
		    $neg = $1;
		    $size = $min_size = 4;
		}
		elsif ($type =~ s/^(-?)n\z/n/)
		{
		    $neg = $1;
		    $size = $min_size = 2;
		}
		elsif ($type =~ /^[Cc]\z/)
		{
		    $size = $min_size = 1;
		}
		elsif ($type =~ /^Z(\*|\d+)\z/)
		{
		    if ($1 eq '*')
		    {
			$min_size = 1; # juste \0
			$size = undef;
		    }
		    else
		    {
			$size = $min_size = $1;
		    }
		}
		else
		{
		    die "Unknown Perl unpack type";
		}

		if (length($$ref_pack) < $min_size)
		{
		    if ($VERBOSE and not $no_nonempty_alert)
		    {
			carp("unpack_block: out of data, can't unpack $type"
			     . " (only " . length($$ref_pack)
			     . " byte(s) available: \""
			     . pretty_str($$ref_pack)
			     . "\")");
		    }
		    $out_of_data = 1;
		}
		else
		{
		    if (defined $size)
		    {
			$ref_hash->{$field_name}
			    = unpack($type, substr($$ref_pack, 0, $size, ''));

			# 16 bits or 32 bits value is signed...
			__negate(\$ref_hash->{$field_name}, $size) if $neg;
		    }
		    # On ne pouvait pas connaître la taille avant le unpack
		    else
		    {
			$ref_hash->{$field_name} = unpack($type, $$ref_pack);

			substr($$ref_pack, 0,
			       length($ref_hash->{$field_name}) + 1)
			    = ''; # Longueur avec le \0
		    }
		}
	    }
	}

	# Cas de out of data, il faut initialiser à la valeur par défaut
	$self->init_block_element($ref_hash, $index) if $out_of_data;
    }

    if ($VERBOSE and not $no_nonempty_alert and length($$ref_pack) > 0)
    {
    	carp("unpack_block: ", length($$ref_pack), " bytes of data remain: \""
	     . pretty_str($$ref_pack)
	     . "\"");
    }

    return $ref_hash;
}

1;
__END__

=head1 NAME

Palm::BlockPack - Map palm structures into Perl ones

=head1 SYNOPSIS

  use Palm::BlockPack;

=head1 DESCRIPTION

To be done XXX...

=head1 SEE ALSO

Palm::FieldPack(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
