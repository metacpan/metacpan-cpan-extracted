=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::DBItemId;

use strict;

use Palm::MaTirelire::DBItem;

use base qw(Palm::MaTirelire::DBItem);

our $VERSION = '1.0';


sub name ($$;$)
{
    my($self, $id, $ref_cache) = @_;

    my($num, $unfiled_name) = @{$self->meta_infos}{qw(num unfiled_name)};

    # "Unfiled" case...
    return $unfiled_name if defined $unfiled_name and $id == $num - 1;

    my $rec = defined($ref_cache) ? $ref_cache->[$id] : $self->get_id($id);

    return undef unless defined $rec;

    return $rec->{name};
}


sub full_name ($$;$)
{
    my($self, $id, $ref_cache) = @_;

    return $self->name($id, $ref_cache);
}


sub unfiled_id ($)
{
    my $self = shift;

    my($unfiled_name, $num) = @{$self->meta_infos}{qw(unfiled_name num)};

    return undef unless defined $unfiled_name;

    return $num - 1;
}


sub unfiled_name ($)
{
    return shift->meta_infos->{unfiled_name};
}


sub new_RecordWithAutoId ($)
{
    my $self = shift;

    my $rec = $self->new_Record;

    my $id_field = $self->meta_infos->{id_field};

    $rec->{$id_field} = $self->get_first_free_id;

    return defined($rec->{$id_field}) ? $rec : undef;
}


sub new_RecordWithId ($$)
{
    my($self, $id) = @_;

    my($id_field, $unfiled_name, $num)
	= @{$self->meta_infos}{qw(id_field unfiled_name num)};

    return undef if $id >= $num - (defined($unfiled_name) ? 1 : 0);

    my $rec = $self->new_Record;

    $rec->{$id_field} = $id;

    return defined($rec->{$id_field}) ? $rec : undef;
}


sub get_first_free_id ($)
{
    my $self = shift;

    my($id_field, $unfiled_name, $num)
	= @{$self->meta_infos}{qw(id_field unfiled_name num)};
    my @ids;

    foreach my $rec (@{$self->{records}})
    {
	$ids[$rec->{$id_field}] = 1;
    }

    my $free_id;
    for ($free_id = 0; $free_id < @ids; $free_id++)
    {
	return $free_id unless defined $ids[$free_id];
    }

    return $free_id if $free_id < $num - (defined($unfiled_name) ? 1 : 0);

    return undef;
}


sub get_id ($$)
{
    my($self, $id) = @_;

    my($id_field, $unfiled_name, $num)
	= @{$self->meta_infos}{qw(id_field unfiled_name num)};

    if ($id >= $num - (defined($unfiled_name) ? 1 : 0))
    {
	# XXX
	return undef;
    }

    foreach my $rec (@{$self->{records}})
    {
	return $rec if exists $rec->{$id_field} and $rec->{$id_field} == $id;
    }

    return undef;
}


sub find_by_full_name ($$)
{
    my($self, $name) = @_;

    my($id_field, $unfiled_name)
	= @{$self->meta_infos}{qw(id_field unfiled_name)};

    return wantarray ? () : undef if $name eq $unfiled_name;

    my $ref_cache = $self->build_cache_id;
    my @ret_list;

    foreach my $rec (@{$self->{records}})
    {
	if (exists $rec->{$id_field}
	    and $name eq $self->full_name($rec->{$id_field}, $ref_cache))
	{
	    return $rec unless wantarray;

	    push(@ret_list, $rec);
	}
    }

    return wantarray ? @ret_list : undef;
}


sub build_cache_id ($)
{
    my $self = shift;

    my($id_field, $unfiled, $num)
	= @{$self->meta_infos}{qw(id_field unfiled_name num)};

    $unfiled = defined($unfiled) ? 1 : 0;

    my @cache;
    foreach my $rec (@{$self->{records}})
    {
	if (exists $rec->{$id_field})
	{
	    my $id = $rec->{$id_field};

	    if ($id >= $num - $unfiled)
	    {
		# XXX
	    }
	    else
	    {
		$cache[$id] = $rec;
	    }
	}
    }

    return \@cache;
}

1;
__END__

=head1 NAME

Palm::MaTirelire::DBItemId - Superclass handler for some Palm MT databases

=head1 SYNOPSIS

  use Palm::MaTirelire::DBItemId;

=head1 DESCRIPTION

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItem(3)

Palm::MaTirelire::Currencies(3)

Palm::MaTirelire::Modes(3)

Palm::MaTirelire::Types(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
