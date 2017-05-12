=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::SavedPreferences;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire;

use base qw(Palm::MaTirelire);

our $VERSION = '1.0';


my $ACCOUNTV1_BLOCK = Palm::BlockPack->new
    (n		=> 'version',
     C		=> 'cur_category',
     UInt8	=> [
		    'country_conv:4',
		    'reserved1:*',
		    ],
     UInt16	=> [
		    'warning:1',
		    'check_locked:1',
		    'repeat_startup:1',
		    'sum_type:3',
		    'replace_desc:1',
		    'repeat_days:6',
		    'show_all_cat:1',
		    'updown_action:2'
		    ],
     UInt32	=> [
		    'sum_date:5',
		    'sum_todayplus:5',
		    'time_select3:1',
		    'remove_type:1',
		    'db_must_be_corrected:1',
		    'left_handed:1',
		    'timeout:3',
		    'reserved2:*'
		    ],
     N		=> 'access_code',
     skip	=> 12,
     );

my $ACCOUNTV2_BLOCK = Palm::BlockPack->new
    (
     n		=> 'version',
     UInt32	=> [
		    'no_beta_alert:1',
		    'db_must_be_corrected:1',
		    'replace_desc:1',
		    'updown_action:2',
		    'time_select3:1',
		    'left_handed:1',
		    'timeout:3',
		    'remove_type:1',
		    'XXX:2',
		    'firstnext_action:2',
		    'first_form:3',
		    'select_focused_num_flds:1',
		    'reserved:*'
		    ],
     N		=> 'access_code',
     'Z32'	=> 'last_db',
     'N'	=> 'list_font',
     'N'	=> 'list_bold_font',
     '[C8]'	=> 'colors',
     'n'	=> 'list_flags',
     );


sub import
{
    &Palm::PDB::RegisterPRCHandlers(__PACKAGE__, [ "psys", 'sprf' ]);
}


sub ParseResource
{
    my $self = shift;
    my %record = @_;

    my $data = delete $record{data};

    if ($record{type} eq 'MaTi')
    {
	$record{data} = {};

	$ACCOUNTV1_BLOCK->unpack_block(\$data, $record{data}, 1);

	my @lists = qw(modes types descriptions);
	@{$record{data}}{@lists} = ([], [], []);

	while ($data ne '')
	{
	    my $elt = unpack('Z*', $data);

	    substr($data, 0, length($elt) + 1) = '';

	    if ($elt eq '')
	    {
		shift @lists;

		if (@lists == 0)
		{
		    # Too many bytes
		    last;
		}
	    }
	    else
	    {
		push(@{$record{data}{$lists[0]}}, $elt);
	    }
	}
    }
    elsif ($record{type} eq 'MaT2')
    {
	$record{data} = {};

	$ACCOUNTV2_BLOCK->unpack_block(\$data, $record{data});
    }
    else
    {
	$record{data} = $data;
    }

    return \%record;
}


sub PackResource
{
    my $self = shift;
    my $record = shift;
    my $pack;

    if ($record->{type} eq 'MaTi')
    {
	my $ref_data = $record->{data};

	if (ref $ref_data)
	{
	    $pack = $ACCOUNTV1_BLOCK->pack_block($ref_data);

	    $pack .= join("\0",
			  join('', map { "$_\0" } @{$ref_data->{modes}}),
			  join('', map { "$_\0" } @{$ref_data->{types}}),
			  join('', map { "$_\0" } @{$ref_data->{descriptions}})
			  );

	    $pack .= "\0";	# Compatibility
	}
	else
	{
	    $pack = $ref_data;
	}
    }
    elsif ($record->{type} eq 'MaT2')
    {
	my $ref_data = $record->{data};

	if (ref $ref_data)
	{
	    $pack = $ACCOUNTV2_BLOCK->pack_block($ref_data);
	}
	else
	{
	    $pack = $ref_data;
	}
    }
    else
    {
	$pack = $record->{data};
    }

    return $pack;
}

1;
__END__

=head1 NAME

Palm::MaTirelire::SavedPreferences - Handler for Palm system preferences

=head1 SYNOPSIS

  use Palm::MaTirelire::SavedPreferences;

=head1 DESCRIPTION

The MaTirelire::SavedPreferences PRC handler is a helper class for the
Palm::PDB package.
It parses Palm system saved preferences resources database, ignore
(don't modify) all preferences except Ma Tirelire v1 and v2 ones..

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

=head1 BUGS

This module have to be reworked to be more generic and each
application, that use system preferences, should attach to it like it
does for PRC or PDB handler.

It would be put in Palm:: namespace instead.

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
