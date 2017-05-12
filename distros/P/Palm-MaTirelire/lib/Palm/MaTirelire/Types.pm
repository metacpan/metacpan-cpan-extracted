=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::Types;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire::DBItemId;

use base qw(Palm::MaTirelire::DBItemId);

our $VERSION = '1.0';


# Each record
my $RECORD_BLOCK = Palm::BlockPack->new
    (UInt32	=> [
		    [ 'type_id:8'	=> 0 ],
		    [ 'parent_id:8'	=> 0xff ],
		    [ 'child_id:8'	=> 0xff ],
		    [ 'brother_id:8'	=> 0xff ],
		    ],
     UInt32	=> [
		    [ 'sign_depend:2'	=> 3 ],
		    [ 'folded:1'	=> 0 ],
		    [ 'reserved:*'	=> 0 ],
		    ],
     'Z24'	=> [ 'only_in_account' => '' ],
     'Z*'	=> [ 'name' => '' ],
     );


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaT2", 'Type' ]);
}


sub meta_infos ($)
{
    return { name	  => "MaTi-Types",
	     type	  => "Type",
	     record_block => $RECORD_BLOCK,
	     id_field	  => 'type_id',
	     unfiled_name => 'Unfiled',
	     num	  => (1 << 8),
	   };
}


sub full_name
{
    my($self, $id) = @_;

    # "Unfiled" case
    my($num, $unfiled_name) = @{$self->meta_infos}{qw(num unfiled_name)};
    return $unfiled_name if $id == $num - 1;

    my $cache = $self->build_cache_id;

    my $rec = $cache->[$id];

    return undef unless defined $rec;

    my $full_name = $rec->{name};

    while (defined $rec and $rec->{parent_id} != 0xff)
    {
	$rec = $cache->[$rec->{parent_id}];

	substr($full_name, 0, 0) = (defined($rec) ? $rec->{name} : '?') . '/';
    }

    return $full_name;
}


sub find_by_full_name ($$)
{
    my($self, $full_name) = @_;

    my($id_field, $unfiled_name)
	= @{$self->meta_infos}{qw(id_field unfiled_name)};

    return wantarray ? () : undef if $full_name eq $unfiled_name;

    my $parent_id = 0xff;
    my $rec;

  type: foreach my $sub_type (split('/', $full_name))
    {
	$sub_type = '<empty>' if $sub_type =~ /^\s*\z/;

	foreach my $cur_rec (@{$self->{records}})
	{
	    if ($cur_rec->{parent_id} == $parent_id
		and $cur_rec->{name} eq $sub_type)
	    {
		$parent_id = $cur_rec->{type_id};
		$rec = $cur_rec;
		next type;
	    }
	}

	# Not found...
	return wantarray ? () : undef;
    }

    return $rec;
}


sub replaceAutoID ($$)
{
    my($self, $rec) = @_;

    my $new_id = $self->get_first_free_id;
    return undef unless defined $new_id;

    my $old_id = $rec->{type_id};
    $rec->{type_id} = $new_id;

    foreach $rec (@{$self->{records}})
    {
	$rec->{parent_id} = $new_id  if $rec->{parent_id} == $old_id;
	$rec->{child_id} = $new_id   if $rec->{child_id} == $old_id;
	$rec->{brother_id} = $new_id if $rec->{brother_id} == $old_id;
    }

    return $new_id;
}


sub new_RecordWithFullName ($$;$)
{
    my($self, $full_name, $final_id) = @_;

    my($id_field, $unfiled_name)
	= @{$self->meta_infos}{qw(id_field unfiled_name)};

    return undef if $full_name eq $unfiled_name;

    my $rec;

    # This final ID already "auto created" ?
    if (defined $final_id
	and defined($rec = $self->build_cache_id->[$final_id]))
    {
	if ($rec->{auto_id})
	{
	    return undef unless defined $self->replaceAutoID($rec);
	}
	else
	{
	    # This ID already exists but is not an auto one!
	    # XXX
	}
    }

    my $parent_id = 0xff;
    my @sub_types = split('/', $full_name);

    # No more than 10 depth levels...
    return undef if @sub_types > 10;

  type: for (;;)
    {
	my $sub_type = shift @sub_types;
	last unless defined $sub_type;

	$sub_type = '<empty>' if $sub_type =~ /^\s*\z/;

	foreach my $cur_rec (@{$self->{records}})
	{
	    if ($cur_rec->{parent_id} == $parent_id
		and $cur_rec->{name} eq $sub_type)
	    {
		$parent_id = $cur_rec->{type_id};

		return $cur_rec if @sub_types == 0;
		next type;
	    }
	}

	unshift(@sub_types, $sub_type);

	# Not found, create this sub type and all behind it
	for (my $sub_idx = 0; $sub_idx < @sub_types; $sub_idx++)
	{
	    $sub_type = $sub_types[$sub_idx];

	    $sub_type = '<empty>' if $sub_type =~ /^\s*\z/;

	    $rec = $self->new_RecordChildOf($parent_id,
					    $sub_idx == @sub_types - 1
					    ? $final_id : undef);
	    last unless defined $rec;

	    $rec->{name} = $sub_type;
	    $parent_id = $rec->{type_id};
	}

	last;
    }

    # This type already exists, returns it (undef if not enough free IDs)
    return $rec;
}


sub new_RecordChildOf ($$;$)
{
    my($self, $parent_id, $final_id) = @_;

    my $rec;

    my $id;
    my $auto_id;
    if (defined($final_id))
    {
	$id = $final_id;

	$rec = $self->build_cache_id->[$id];
	if (defined $rec)
	{
	    if ($rec->{auto_id})
	    {
		return undef unless defined $self->replaceAutoID($rec);
	    }
	    else
	    {
		# This ID already exists but is not an auto one!
		# XXX
	    }
	}
    }
    else
    {
	$id = $self->get_first_free_id;
	$auto_id = 1;
    }

    return undef unless defined $id;

    $rec = $self->new_Record;

    $rec->{type_id} = $id;
    $rec->{auto_id} = 1 if $auto_id;

    # Insert the type somewhere in the top level
    if ($parent_id == 0xff)
    {
	# Nothing to do if no record is present (no brother)
	foreach my $rec_any (@{$self->{records}})
	{
	    # Toplevel record
	    if ($rec_any->{parent_id} == 0xff)
	    {
		$rec->{brother_id} = $rec_any->{brother_id};
		$rec_any->{brother_id} = $id;
		last;
	    }
	}
    }
    else
    {
	my $parent_rec = $self->get_id($parent_id);
	return undef unless defined $parent_rec;

	# Add the type as the first child of parent
	$rec->{parent_id} = $parent_id;
	$rec->{brother_id} = $parent_rec->{child_id};

	$parent_rec->{child_id} = $id;
    }

    $self->append_Record($rec);

    return $rec;
}


sub dump
{
    my $self = shift;

    return if @{$self->{records}} == 0;

    my $first_id = 0xff;
    my $rec;
    my($index, $loops);

    $loops = 0xff;

    # Search the first type
    for ($index = 0; $index < @{$self->{records}}; $index++)
    {
	$rec = $self->{records}[$index];

	if ($rec->{parent_id} == 0xff
	    and ($first_id == 0xff or $rec->{brother_id} == $first_id))
	{
	    $first_id = $rec->{type_id};
	    $index = -1;

	    # Par sécurité... XXX
	    if (--$loops == 0)
	    {
		die "Types first ID loop detected...\n";
		last;
	    }
	}
    }

    my $ref_cache = $self->build_cache_id;

    my $depth_glyphs = '';
    my $depth = 1;
    $rec = $ref_cache->[$first_id];
    my @types;
    my $id;

    for (;;)
    {
	push(@types,
	     {
		 depth => $depth,
		 depth_glyphs => $depth_glyphs . ($rec->{brother_id} == 0xff
						  ? '+-' : '|-'),
		 type_id => $rec->{type_id},
		 name => $rec->{name},
	     });

	# Type has a child
	$id = $rec->{child_id};
	if ($id != 0xff)
	{
	    $depth_glyphs .= $rec->{brother_id} == 0xff ? '  ' : '| ';
	    $depth++;

	    goto load_and_continue;
	}

	# Else type has a brother
      brother:
	$id = $rec->{brother_id};
	goto load_and_continue if $id != 0xff;

	# Else, if the type has a parent => go to his brother OR his parent
	$id = $rec->{parent_id};
	if ($id != 0xff)
	{
	    substr($depth_glyphs, -2) = '';
	    $depth--;

	    $rec = $ref_cache->[$id];

	    goto brother;
	}

	# Else that's all folk...
	last;

      load_and_continue:
	$rec = $ref_cache->[$id];
    }

    if (@types != @{$self->{records}})
    {
	die("Not all types are chained, only ", scalar(@types), " on ",
	    scalar(@{$self->{records}}), "\n");
    }

    return @types if wantarray;

    return join("\n",
		map { "$_->{depth_glyphs} $_->{name} ($_->{type_id})" }
		@types);
}


1;
__END__

=head1 NAME

Palm::MaTirelire::Types - Handler for Palm MT v2 types database

=head1 SYNOPSIS

  use Palm::MaTirelire::Types;

=head1 DESCRIPTION

The MaTirelire::Types PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v2 types database.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItemId(3)

Palm::MaTirelire::AccountsV2(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
