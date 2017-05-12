=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::AccountsV1;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire;
use Palm::StdAppInfo();

use base qw(Palm::MaTirelire Palm::StdAppInfo);

our $VERSION = '1.0';


use constant UNKNOWN_MODE	=> ((1 << 5) - 1);
use constant UNKNOWN_TYPE	=> ((1 << 6) - 1);

my $TRANS_BLOCK = Palm::BlockPack->new
    ('DateType'	=> [ 'date_' => 'now' ],
     'TimeType'	=> [ 'time_' => 'now' ],

     '-N'	=> [ 'amount' => 0 ],

     UInt32	=> [
		    [ 'checked:1'	=> 0 ],
		    'repeat:1',
		    [ 'mode:5' 		=> UNKNOWN_MODE ],
		    [ 'type:6' 		=> UNKNOWN_TYPE ],
		    'check_num:1',
		    'xfer:1',
		    [ 'marked:1'	=> 0 ],
		    [ 'alarm:1'		=> 0 ],
		    'xfer_cat:1',
		    'value_date:1',
		    [ 'reserved:*'	=> 0 ],
		    ],
     );

my $TRANS_CHECKNUM_BLOCK = Palm::BlockPack->new(N => 'check_num');

my $TRANS_VALUEDATE_BLOCK = Palm::BlockPack->new(DateType => '');

my $TRANS_REPEAT_BLOCK = Palm::BlockPack->new
    (UInt16	=> [
		    'repeat_type:2',
		    'repeat_freq:6',
		    'reserved:*',
		    ],
     skip	=> [ 2 => "\xff" ], # End date is not used in M1 and must be -1
     );

my $TRANS_XFER_BLOCK = Palm::BlockPack->new(N => 'xfer');

my $TRANS_DESCRIPTION_BLOCK = Palm::BlockPack->new
    ('Z*' => [ 'description' => '' ]);


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaTi", 'Data' ]);
}


sub new
{
    my $classname   = shift;
    my $self        = $classname->SUPER::new(@_);
    # Create a generic PDB. No need to rebless it,
    # though.

    # Creator for V1 is not the same
    $self->{creator} = "MaTi";

    $self->{name} = "MaTirelire Data"; # Default
    $self->{type} = "Data";

    # Add the standard AppInfo block stuff
    &Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

    return $self;
}


sub ParseAppInfoBlock
{
    my $self = shift;
    my $data = shift;
    my $appinfo = {};
    my $std_len;

    # Get the standard parts of the AppInfo block
    $std_len = &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

    return $appinfo;
}


sub PackAppInfoBlock
{
    my $self = shift;
    my $retval;

    # Pack the AppInfo block
    $retval = &Palm::StdAppInfo::pack_StdAppInfo($self->{appinfo});

    return $retval;
}


sub new_Record
{
    my $classname = shift;
    my $retval = $classname->SUPER::new_Record(@_);

    $TRANS_BLOCK->init_block($retval);
    $TRANS_DESCRIPTION_BLOCK->init_block($retval);

    return $retval;
}


sub ParseRecord
{
    my $self = shift;
    my %record = @_;

    delete $record{offset};	# This is useless
    my $data = delete $record{data};

    $record{size} = length $data; # Used in validRecords method

    $TRANS_BLOCK->unpack_block(\$data, \%record, 1);

    # Cheque number
    if (delete $record{check_num})
    {
	$TRANS_CHECKNUM_BLOCK->unpack_block(\$data, \%record, 1);
    }

    # Value date
    if (delete $record{value_date})
    {
	$record{value_date} = {};
	$TRANS_VALUEDATE_BLOCK->unpack_block(\$data, $record{value_date}, 1);
    }

    # Repetition
    if (delete $record{repeat})
    {
	$record{repeat} = {};
	$TRANS_REPEAT_BLOCK->unpack_block(\$data, $record{repeat}, 1);
    }

    # Transfer
    if (delete $record{xfer})
    {
	$TRANS_XFER_BLOCK->unpack_block(\$data, \%record, 1);
    }
    else
    {
	delete $record{xfer_cat};
    }

    $TRANS_DESCRIPTION_BLOCK->unpack_block(\$data, \%record);

    #if (length($data) > 0)
    #{
    #	use Data::Dumper;
    #
    #	print Dumper(\%record);
    #	print Dumper($data);
    #}

    return \%record;
}


sub PackRecord
{
    my $self = shift;
    my $record = shift;
    my $pack;

    # Small check...
    if ($record->{xfer_cat})
    {
	if (not defined $record->{xfer} or $record->{xfer} >= 16)
	{ delete $record->{xfer_cat} }
    }

    $pack = $TRANS_BLOCK->pack_block($record);

    # Cheque number
    if ($record->{check_num})
    {
	$pack .= $TRANS_CHECKNUM_BLOCK->pack_block($record);
    }

    # Value date
    if ($record->{value_date})
    {
	$pack .= $TRANS_VALUEDATE_BLOCK->pack_block($record->{value_date});
    }

    # Repetition
    if ($record->{repeat})
    {
	$pack .= $TRANS_REPEAT_BLOCK->pack_block($record->{repeat});
    }

    # Transfer
    if ($record->{xfer})
    {
	$pack .= $TRANS_XFER_BLOCK->pack_block($record);
    }

    $pack .= $TRANS_DESCRIPTION_BLOCK->pack_block($record);

    return $pack;
}


sub sortRecords
{
    my $self = shift;

    @{$self->{records}} = sort
    {
	# Pack date and time on an 31 bits width integer...

	# 11 bits: 30 .. 20
	(($a->{date_year} << 20)
	 #  4 bits: 19 .. 16
	 | ($a->{date_month} << 16)
	 #  5 bits: 15 .. 11
	 | ($a->{date_day} << 11)
	 #  5 bits: 10 .. 6
	 | ($a->{time_hour} << 6)
	 #  6 bits: 5 .. 0	 11 bits: 30 .. 20
	 | $a->{time_min}) <=> (($b->{date_year} << 20)
				#  4 bits: 19 .. 16
				| ($b->{date_month} << 16)
				#  5 bits: 15 .. 11
				| ($b->{date_day} << 11)
				#  5 bits: 10 .. 6
				| ($b->{time_hour} << 6)
				#  6 bits: 5 .. 0
				| $b->{time_min})
    }
    @{$self->{records}};
}


#
# Returns a list (number of deleted records, number of errors corrected)
sub validRecords ($;$)
{
    my($self, $verbose) = @_;

    # $verbose can be a reference on a filehandle
    $verbose = \*STDOUT if $verbose && not ref $verbose;

    my $deleted_records = 0;
    my $errors_found = 0;

    my @to_del;
    my %ids;
    my $index = 0;

    foreach my $rec (@{$self->{records}})
    {
	if ($rec->{size} == 0)
	{
	    print $verbose ("Record #$index (cat=$rec->{category}) "
			    . "UniqueID $rec->{id}\n"
			    . "**** empty => deleted\n")
		if $verbose;

	    push(@to_del, $index);
	}
	else
	{
	    $ids{$rec->{id}} = 1;
	}
	$index++;
    }

    if (@to_del)
    {
	$deleted_records = @to_del;

	foreach my $idx (reverse @to_del)
	{
	    splice @{$self->{records}}, $idx, 1;
	}
    }

    my %links;
    $index = 0;

    foreach my $rec (@{$self->{records}})
    {
	my @err_msg;

	# Repeat
	if ($rec->{repeat})
	{
	    if ($rec->{repeat}{repeat_freq} == 0
		or $rec->{repeat}{repeat_type} > 2
		or $rec->{repeat}{reserved} != 0)
	    {
		push(@err_msg, "deleted repeat option");
		delete $rec->{repeat};
	    }
	}

	# Xfer
	if (exists $rec->{xfer})
	{
	    my $error = 0;

	    if ($rec->{xfer_cat})
	    {
		if ($rec->{xfer} >= 16)
		{
		    push(@err_msg, "invalid account (xfer) link");

		    $error = 1;
		}
	    }
	    else
	    {
		if (exists $ids{$rec->{xfer}})
		{
		    $links{$rec->{id}} = $rec->{xfer};
		}
		else
		{
		    push(@err_msg, "invalid transaction (xfer) link");

		    $error = 1;
		}
	    }

	    if ($error)
	    {
		delete @$rec{qw(xfer xfer_cat)};
		push(@err_msg, "deleted transfer option");
	    }
	}

	# No account (not possible ?)
	if ($rec->{category} eq '')
	{
	    $rec->{attributes} = { dirty => 1 };
	    push(@err_msg, "not associated to an account");
	}

	if (@err_msg)
	{
	    if ($verbose)
	    {
		print $verbose
		    ("Record #$index (account=$rec->{category}) "
		     . "UniqueID $rec->{id}\n"
		     . "$rec->{date_year}/$rec->{date_month}/$rec->{date_day} "
		     . "$rec->{time_min}:$rec->{time_hour} "
		     . "amount = ", $rec->{amount} / 100, "\n",
		     "  ");

		print $verbose join("\n  ", @err_msg), "\n";
	    }

	    $rec->{attributes}{Dirty} = 1;

	    $errors_found++;
	}
    }

    while (my($id, $link) = each %links)
    {
	if (not exists $links{$link})
	{
	    print $verbose ("**** Xfer: $id => $link but $link is not linked,",
			    " corrected.\n")
		if $verbose;

	    my $rec = $self->findRecordByID($link);
	    $rec->{xfer} = $id;
	    delete $rec->{xfer_cat};

	    $rec->{attributes}{Dirty} = 1;
	}
	elsif ($links{$link} != $id)
	{
	    print $verbose
		"**** Xfer: $id => $link but $link => $links{$link}\n"
		if $verbose;
	}
    }

    return ($deleted_records, $errors_found);
}

1;
__END__

=head1 NAME

Palm::MaTirelire::AccountsV1 - Handler for Palm MT v1 accounts databases

=head1 SYNOPSIS

  use Palm::MaTirelire::AccountsV1;

=head1 DESCRIPTION

The MaTirelire::AccountsV1 PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v1 accounts databases.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::SavedPreferences(3)

Palm::MaTirelire::AccountsV2(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
