=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::AccountsV2;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire;
use Palm::StdAppInfo();

use base qw(Palm::MaTirelire Palm::StdAppInfo);

our $VERSION = '1.0';

use constant UNKNOWN_MODE	=> ((1 << 5) - 1);
use constant UNKNOWN_TYPE	=> ((1 << 8) - 1);

use constant MATI_DB_PREFS_VERSION	=> 1;


# AppInfoBlock
my $APPINFO_BLOCK = Palm::BlockPack->new
    ('N'	=> [ 'access_code' => 0 ],
     UInt32	=> [
		    [ 'version:4'	  => 1 ],
		    [ 'cur_category:4'	  => 0 ],
		    [ 'show_all_cat:1'	  => 0 ],
		    [ 'remove_type:1'	  => 0 ],#DmRemoveRecord really deletes
		    [ 'deny_find:1'	  => 0 ],
		    [ 'sort_type:3'	  => 0 ],
		    [ 'list_date:1'	  => 0 ],
		    [ 'check_locked:1'	  => 0 ],
		    [ 'repeat_startup:1'  => 0 ],
		    [ 'repeat_days:7'	  => 15 ],
		    [ 'reserved1:*'	  => 0 ],
		    ],
     UInt32	=> [
		    [ 'sum_type:4'	  => 0 ],
		    [ 'sum_date:5'	  => 1 ],
		    [ 'sum_todayplus:5'	  => 10 ],
		    [ 'sum_at_date:1'	  => 0 ],
		    [ 'accounts_sel_type:2' => 0 ],
		    [ 'accounts_currency:8' => 0 ],
		    [ 'reserved2:*'	  => 0 ],
		    ],
     'n'	=> [ 'selected_accounts'  => 0x0 ],
     'DateType' => 'sum_',
    );

use constant DB_PREFS_STATS_NUM => 14;
my $APPINFO_BLOCK_STATS = Palm::BlockPack->new
    ('DateType' => [ 'beg_date_' => 0 ],
     'DateType' => [ 'end_date_' => 0 ],
     UInt32	=> [
		    [ 'menu_choice:3' => 0 ],
		    [ 'week_bounds:1' => 0 ],
		    [ 'by:4' => 0 ],
		    [ 'type_any:1' => 0 ],
		    [ 'type:8' => 0 ],
		    [ 'mode_any:1' => 0 ],
		    [ 'mode:5' => 0 ],
		    [ 'on:2' => 0 ],
		    [ 'val_date:1' => 0 ],
		    [ 'ignore_nulls:1' => 0 ],
		    [ 'type_children:1' => 0 ],
		    [ 'reserved:*' => 0 ],
		   ],
     'n'	=> [ 'checked_accounts' => 0 ],
    );

my $APPINFO_BLOCK_END = Palm::BlockPack->new('Z*' => [ 'note' => '' ]);

my $ACCOUNT_BLOCK = Palm::BlockPack->new
    ('DateType'	=> [ 'date_' => 0 ],
     'TimeType'	=> [ 'time_' => 0 ],

     '-N'	=> [ 'amount' => 0 ],

     UInt32	=> [
		    [ 'checked:1'	=> 1 ],
		    [ 'marked:1'	=> 0 ],
		    [ 'warning:1'	=> 0 ],
		    [ 'stmt_num:1'	=> 0 ],
		    [ 'currency:8'	=> 0 ],
		    [ 'cheques_by_cbook:6' => 25 ],
		    [ 'num_chequebook:2'=> 0 ],
		    [ 'take_last_date:1'=> 0 ],
		    [ 'reserved:*'	=> 0 ],
		    ],
     '-N'	=> [ 'overdraft_thresold'	=> 0 ],
     '-N'	=> [ 'non_overdraft_thresold'	=> 0 ],

     '[N4]'	=> [ 'check_books' ],

     'Z24'	=> [ 'number' => '' ],

     'Z*'	=> [ 'note' => '' ],
     );

my $TRANS_BLOCK = Palm::BlockPack->new
    ('DateType'	=> [ 'date_' => 'now' ],
     'TimeType'	=> [ 'time_' => 'now' ],

     '-N'	=> [ 'amount' => 0 ],

     UInt32	=> [
		    [ 'checked:1'	=> 0 ],
		    [ 'marked:1'	=> 0 ],
		    [ 'alarm:1'		=> 0 ],
		    [ 'mode:5'		=> UNKNOWN_MODE ],
		    [ 'type:8'		=> UNKNOWN_TYPE ],
		    'value_date:1',
		    'check_num:1',
		    'repeat:1',
		    'xfer:1',
		    'xfer_cat:1',
		    'stmt_num:1',
		    'currency:1',
		    'splits:1',
		    [ 'reserved:*'	=> 0 ],
		    ],
     );

my $TRANS_VALUEDATE_BLOCK = Palm::BlockPack->new(DateType => '');

my $TRANS_CHECKNUM_BLOCK = Palm::BlockPack->new(N => 'check_num');

my $TRANS_REPEAT_BLOCK = Palm::BlockPack->new
    (UInt16	=> [
		    'repeat_type:2',
		    'repeat_freq:6',
		    'reserved:*',
		    ],
     DateType	=> 'end_date_',
     );

my $TRANS_XFER_BLOCK = Palm::BlockPack->new(N => 'xfer');

my $TRANS_STMTNUM_BLOCK = Palm::BlockPack->new(N => 'stmt_num');

my $TRANS_CURRENCY_BLOCK = Palm::BlockPack->new
    ('-N'	=> 'currency_amount',
     UInt32	=> [
		    'currency:8',
		    'reserved:*',
		    ]);

my $TRANS_SUBTR_BLOCK = Palm::BlockPack->new
    (UInt16	=> [
		    'num:8',
		    'reserved:*',
		    ],
     n		=> 'size');

my $TRANS_SUBTR_SUB_BLOCK = Palm::BlockPack->new
    (
     UInt32	=> [
		    'type:8',
		    'reserved:*',
		    ],
     '-N'	=> 'amount',
     'Z*'	=> 'desc',
  );

my $TRANS_NOTE_BLOCK = Palm::BlockPack->new('Z*' => [ note => '' ]);


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaT2", 'Acnt' ]);
}


sub new
{
    my $classname   = shift;
    my $self        = $classname->SUPER::new(@_);

    # Create a generic PDB. No need to rebless it,
    # though.

    $self->{name} = "MaTi=Default"; # Default name
    $self->{type} = "Acnt";

    # Add the standard AppInfo block stuff
    &Palm::StdAppInfo::seed_StdAppInfo($self->{appinfo});

    # delete the auto-created "Unfiled" category
    $self->{appinfo}{categories}[0]{name} = undef;

    # The AppInfo block stuff
    $APPINFO_BLOCK->init_block($self->{appinfo});
    $self->{appinfo}{stats} = [ ({}) x DB_PREFS_STATS_NUM ];
    foreach my $idx (0 .. DB_PREFS_STATS_NUM - 1)
    {
	$APPINFO_BLOCK_STATS->init_block($self->{appinfo}{stats}[$idx]);
    }
    $APPINFO_BLOCK_END->init_block($self->{appinfo});

    return $self;
}


sub ParseAppInfoBlock
{
    my $self = shift;
    my $data = shift;
    my $appinfo = {};
    my $std_len;

    # Get the standard parts of the AppInfo block
    &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $data);

    # Palm::StdAppInfo::parse_StdAppInfo nous laisse le reste dans
    # $appinfo->{other}
    $data = delete $appinfo->{other};
    $APPINFO_BLOCK->unpack_block(\$data, $appinfo, 1);

    if ($appinfo->{version} >= MATI_DB_PREFS_VERSION)
    {
	foreach my $idx (0 .. DB_PREFS_STATS_NUM - 1)
	{
	    unless (defined $appinfo->{appinfo}{stats}[$idx])
	    {
		$appinfo->{appinfo}{stats}[$idx] = {};
	    }

	    $APPINFO_BLOCK_STATS->unpack_block(\$data,
					       $appinfo->{appinfo}{stats}[$idx],
					       1);
	}
    }
    # La version 0 n'avait pas encore les stats
    else
    {
	$appinfo->{version} = MATI_DB_PREFS_VERSION;

	$self->{appinfo}{stats} = [ ({}) x DB_PREFS_STATS_NUM ];
	foreach my $idx (0 .. DB_PREFS_STATS_NUM - 1)
	{
	    $APPINFO_BLOCK_STATS->init_block($self->{appinfo}{stats}[$idx]);
	}
    }
    $APPINFO_BLOCK_END->unpack_block(\$data, $appinfo);

    return $appinfo;
}


sub PackAppInfoBlock
{
    my $self = shift;
    my $appinfo = $self->{appinfo};
    my $pack;

    $appinfo->{other} = $APPINFO_BLOCK->pack_block($appinfo);
    foreach my $idx (0 .. DB_PREFS_STATS_NUM - 1)
    {
	$appinfo->{other} .=
	    $APPINFO_BLOCK_STATS->pack_block($appinfo->{stats}[$idx]);
    }
    $appinfo->{other} .=
	$APPINFO_BLOCK_END->pack_block($appinfo);

    # Pack the AppInfo block (and then append $appinfo->{other})
    $pack = &Palm::StdAppInfo::pack_StdAppInfo($appinfo);

    return $pack;
}


sub new_Record
{
    my $classname = shift;
    my $retval = $classname->SUPER::new_Record(@_);

    $TRANS_BLOCK->init_block($retval);
    $TRANS_NOTE_BLOCK->init_block($retval);

    return $retval;
}


sub new_AccountProperties
{
    my $classname = shift;
    my $retval = $classname->SUPER::new_Record(@_);

    $ACCOUNT_BLOCK->init_block($retval);

    return $retval;
}


sub findAccountPropertiesByName ($$)
{
    my($self, $account_name) = @_;

    my $ref_accounts = $self->{appinfo}{categories};

    for (my $index = 0; $index < @$ref_accounts; $index++)
    {
	my $cur_account = $ref_accounts->[$index]{name};

	if (defined $cur_account and $cur_account eq $account_name)
	{
	    return $self->findAccountPropertiesByIndex($index);
	}
    }

    return undef;
}


sub findAccountPropertiesByIndex ($$)
{
    my($self, $account_idx) = @_;

    foreach my $rec (@{$self->{records}})
    {
	# Account properties
	if ($rec->{date_day} == 0 and $rec->{date_month} == 0
	    and $rec->{date_year} == 0 and $rec->{category} == $account_idx)
	{
	    return $rec;
	}
    }

    return undef;
}


sub ParseRecord
{
    my $self = shift;
    my %record = @_;

    delete $record{offset};	# This is useless
    my $data = delete $record{data};

    $record{size} = length $data; # used in validRecords sub

    # !!! PROBLÈME !!!
    return \%record if $record{size} < 4;

    # Propriétés du compte
    if (unpack('N', $data)  == 0)
    {
	$ACCOUNT_BLOCK->unpack_block(\$data, \%record);
    }
    # Opération...
    else
    {
	$TRANS_BLOCK->unpack_block(\$data, \%record, 1);

	# Value date
	if (delete $record{value_date})
	{
	    $record{value_date} = {};
	    $TRANS_VALUEDATE_BLOCK->unpack_block(\$data,$record{value_date}, 1);
	}

	# Cheque number
	if (delete $record{check_num})
	{
	    $TRANS_CHECKNUM_BLOCK->unpack_block(\$data, \%record, 1);
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

	# Statement number
	if (delete $record{stmt_num})
	{
	    $TRANS_STMTNUM_BLOCK->unpack_block(\$data, \%record, 1);
	}

	# Currency
	if (delete $record{currency})
	{
	    $record{currency} = {};
	    $TRANS_CURRENCY_BLOCK->unpack_block(\$data, $record{currency}, 1);
	}

	# Sub-transactions
	if (delete $record{splits})
	{
	    $record{splits} = {};
	    $TRANS_SUBTR_BLOCK->unpack_block(\$data, $record{splits}, 1);

	    if ($record{splits}{size} > 0)
	    {
		my $subtrs = substr($data, 0, $record{splits}{size}, '');

		$record{splits}{list} = [];

		while (length $subtrs > 0)
		{
		    my %subtr;

		    $TRANS_SUBTR_SUB_BLOCK->unpack_block(\$subtrs, \%subtr, 1);

		    # La somme des sous-op est égale à la valeur
		    # absolue du montant de l'opération. Donc on
		    # corrige au chargement si le montant de
		    # l'opération est < 0
		    if ($record{amount} < 0)
		    {
			$subtr{amount} = - $subtr{amount};
		    }

		    # La description a toujours une longueur multiple de 2
		    # y compris le \0 de fin
		    substr($subtrs, 0, 1) = '' if length($subtr{desc}) % 2 == 0;

		    push(@{$record{splits}{list}}, \%subtr);
		}
	    }

	    # Here we can delete the number and the size, they will be
	    # recomputed at PackRecord
	    delete @{$record{splits}}{qw(num size)};
	}

	$TRANS_NOTE_BLOCK->unpack_block(\$data, \%record);
    }

    return \%record;
}


sub PackRecord
{
    my $self = shift;
    my $record = shift;
    my $pack;

    # Propriétés du compte
    if ($record->{date_day} == 0)
    {
	$pack = $ACCOUNT_BLOCK->pack_block($record);
    }
    # Opération...
    else
    {
	# Small check...
	if ($record->{xfer_cat})
	{
	    if (not defined $record->{xfer} or $record->{xfer} >= 16)
	    { delete $record->{xfer_cat} }
	}

	$pack = $TRANS_BLOCK->pack_block($record);

	# Value date
	if ($record->{value_date})
	{
	    $pack .= $TRANS_VALUEDATE_BLOCK->pack_block($record->{value_date});
	}

	# Cheque number
	if ($record->{check_num})
	{
	    $pack .= $TRANS_CHECKNUM_BLOCK->pack_block($record);
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

	# Statement number
	if ($record->{stmt_num})
	{
	    $pack .= $TRANS_STMTNUM_BLOCK->pack_block($record);
	}

	# Currency
	if ($record->{currency})
	{
	    $pack .= $TRANS_CURRENCY_BLOCK->pack_block($record->{currency});
	}

	# Sub-transactions
	if ($record->{splits})
	{
	    my $subtrs = '';
	    foreach my $ref_subtr (@{$record->{splits}{list}})
	    {
		# La somme des sous-op doit être égale à la valeur
		# absolue du montant de l'opération. Donc on corrige à
		# la sauvegarde si le montant de l'opération est < 0
		if ($record->{amount} < 0)
		{
		    $ref_subtr->{amount} = - $ref_subtr->{amount};
		}

		$subtrs .= $TRANS_SUBTR_SUB_BLOCK->pack_block($ref_subtr);

		# La description a toujours une longueur multiple de 2
		# y compris le \0 de fin
		$subtrs .= "\0" if length($subtrs) % 2;
	    }

	    $record->{splits}{num} = @{$record->{splits}{list}};
	    $record->{splits}{size} = length $subtrs;

	    $pack .= $TRANS_SUBTR_BLOCK->pack_block($record->{splits});

	    $pack .= $subtrs;

	    # Here we can delete the number and the size, they will be
	    # recomputed the next time
	    delete @{$record->{splits}}{qw(num size)};
	}

	$pack .= $TRANS_NOTE_BLOCK->pack_block($record);
    }

    return $pack;
}


#
# À faire les différentes sortes de tri...
sub sortRecords
{
    my $self = shift;

    # Sort by value date
    if ($self->{appinfo}{sort_type} == 1)
    {
	@{$self->{records}} = sort
	{
	    my($refa, $refb) = ($a, $b);

	    # Account properties don't have value_date
	    if ($a->{value_date})
	    {
		$refa = { date_day   => $a->{value_date}{day},
			  date_month => $a->{value_date}{month},
			  date_year  => $a->{value_date}{year},
			  time_hour  => $a->{time_hour},
			  time_min   => $a->{time_min},
		        };
	    }

	    # Account properties don't have value_date
	    if ($b->{value_date})
	    {
		$refb = { date_day   => $b->{value_date}{day},
			  date_month => $b->{value_date}{month},
			  date_year  => $b->{value_date}{year},
			  time_hour  => $b->{time_hour},
			  time_min   => $b->{time_min},
		        };
	    }

	    # Pack date and time on an 31 bits width integer...

	    # 11 bits: 30 .. 20
	    (($refa->{date_year} << 20)
	     #  4 bits: 19 .. 16
	     | ($refa->{date_month} << 16)
	     #  5 bits: 15 .. 11
	     | ($refa->{date_day} << 11)
	     #  5 bits: 10 .. 6
	     | ($refa->{time_hour} << 6)
	     #  6 bits: 5 .. 0	 11 bits: 30 .. 20
	     | $refa->{time_min}) <=> (($refb->{date_year} << 20)
				       #  4 bits: 19 .. 16
				       | ($refb->{date_month} << 16)
				       #  5 bits: 15 .. 11
				       | ($refb->{date_day} << 11)
				       #  5 bits: 10 .. 6
				       | ($refb->{time_hour} << 6)
				       #  6 bits: 5 .. 0
				       | $refb->{time_min})
	}
	@{$self->{records}};
    }
    # Sort by date
    else
    {
	# Force "sort by date" as there is no other sort type at this time
	$self->{appinfo}{sort_type} = 0;

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
	if ($rec->{attributes}{expunged})
	{
	    print $verbose "Record #$index expunged => delete it really\n"
		if $verbose;

	    # No need to count these already deleted records
	    push(@to_del, $index);
	}
	elsif ($rec->{size} == 0)
	{
	    print $verbose ("Record #$index (cat=$rec->{category}) "
			    . "UniqueID $rec->{id}\n"
			    . "**** empty => deleted\n")
		if $verbose;

	    push(@to_del, $index);
	    $deleted_records++;
	}
	else
	{
	    $ids{$rec->{id}} = 1;
	}
	$index++;
    }

    if (@to_del)
    {
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

	if ($rec->{reserved})
	{
	    $rec->{reserved} = 0;
	    push(@err_msg, "null reserved field corrected");
	}

	# Account properties
	if ($rec->{date_day} == 0 and $rec->{date_month} == 0
	    and $rec->{date_year} == 0)
	{
	    # Nothing to do here...
	}
	else
	{
	    # Repeat
	    if ($rec->{repeat})
	    {
		if ($rec->{repeat}{repeat_freq} == 0
		    or $rec->{repeat}{repeat_type} > 2)
		{
		    push(@err_msg, "deleted repeat option");
		    delete $rec->{repeat};
		}

		if ($rec->{repeat}{reserved} != 0)
		{
		    $rec->{repeat}{reserved} = 0;
		    push(@err_msg, "repeat option, reserved corrected");
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

	    # Splits
	    if (exists $rec->{splits})
	    {
		if (not defined $rec->{splits}{list}
		    or @{$rec->{splits}{list}} == 0)
		{
		    push(@err_msg, "deleted splits option");
		    delete $rec->{splits};
		}

		for (my $split_idx = @{$rec->{splits}{list}}; $split_idx-- > 0;)
		{
		    if ($rec->{splits}{list}[$split_idx]{reserved})
		    {
			$rec->{splits}{list}[$split_idx]{reserved} = 0;
			push(@err_msg, "split #$split_idx, reserved corrected");
		    }
		}

		if ($rec->{splits}{reserved})
		{
		    $rec->{splits}{reserved} = 0;
		    push(@err_msg, "splits option, reserved corrected");
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
			("Record #$index (account=$rec->{category}) ",
			 "UniqueID $rec->{id}\n",
			 "$rec->{date_year}/$rec->{date_month}/$rec->{date_day} ",
			 "$rec->{time_hour}:$rec->{time_min} ",
			 "amount = ", $rec->{amount} / 100, "\n",
			 "  ");

		    print $verbose join("\n  ", @err_msg), "\n";
		}

		$rec->{attributes}{Dirty} = 1;

		$errors_found++;
	    }
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

Palm::MaTirelire::AccountsV2 - Handler for Palm MT v2 accounts databases

=head1 SYNOPSIS

  use Palm::MaTirelire::AccountsV2;

=head1 DESCRIPTION

The MaTirelire::AccountsV2 PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v2 accounts databases.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::Currencies(3)

Palm::MaTirelire::Descriptions(3)

Palm::MaTirelire::Modes(3)

Palm::MaTirelire::Types(3)

Palm::MaTirelire::SavedPreferences(3)

Palm::MaTirelire::AccountsV1(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
