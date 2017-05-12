#!/usr/local/bin/perl -w
# 
# importM2.pl -- 
# 
# Author          : Maxime Soule
# Created On      : Tue Jun 21 22:44:23 2005
# Last Modified By: Maxime Soule
# Last Modified On: Mon May  3 15:10:16 2010
# Update Count    : 72
# Status          : Unknown, Use with caution!
#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

# 
# (cd html && cp import.html imexport.js /usr/local/www)
# cp importM2.pl /usr/local/www/biz/import
#

use 5.008_000;

use strict;

use POSIX;
use Text::CSV_XS;
use IO::Handle;

use Archive::Zip qw(:CONSTANTS);

use Palm::MaTirelire::AccountsV2;
use Palm::MaTirelire::Modes;
use Palm::MaTirelire::Types;
use Palm::MaTirelire::Currencies;
use Palm::MaTirelire::CGICLI;

$Palm::BlockPack::VERBOSE = 0;

#
# Possible parameters in CLI mode
#
# One FILE per account, the name of each CSV file is the account name:
# -csv0 FILE
# -csv1 FILE
# -csv2 FILE
# -csv3 FILE
# -csv4 FILE
# -csv5 FILE
# -csv6 FILE
# -csv7 FILE
# -csv8 FILE
# -csv9 FILE
# -csv10 FILE
# -csv11 FILE
# -csv12 FILE
# -csv13 FILE
# -csv14 FILE
# -csv15 FILE
#
# -accounts FILE	(Merge into this accounts database: MaTi=XXX.PDB)
# -modes FILE		(Add non-existent payement modes to: MaTi-Modes.PDB)
# -types FILE		(Add non-existent transactions types to: MaTi-Types.PDB)
# -currencies FILE	(Add non-existent currencies to: MaTi-Currencies.PDB)
#
# -fields list,of,exported,fields,separated,by,comma
#   fields can be :
#     account		(Account name (ignored, like empty column))
#     unique_id		(Internal ID (used by transfers))
#     date		(Date)
#     time		(Time)
#     amount		(Amount)
#     checked		(Checked or not)
#     flagged		(Flagged or not)
#     alarm		(Alarm or not)
#     mode_idx		(Mode (only index))
#     mode		(Mode (full name))
#     type_idx		(Type (only index))
#     type		(Type (full name))
#     note		(Description)
#     value_date	(Validity date or empty)
#     cheque_num	(Cheque number or empty)
#     repeat	(Repeat (type + frequency + end date) or empty)
#     xfer_account	(Transfer account or empty)
#     xfer_unique_id	(ID of the linked transaction or empty)
#     statement_num	(Statement number or empty)
#     currency_idx	(Currency (only index) + amount or empty)
#     currency		(Currency (full name) + amount or empty)
#     splits_idx	(Splits ((type index + amount + description) x n))
#     splits		(Splits ((full type name + amount + description) x n))
#     empty		(Empty column)
#
# -col_sep CHAR		(Columns/fields separator char, typicaly ';' or 'tab')
# -eol TYPE		(End of line type: win, mac or unix)
# -date_fmt FORMAT	(Date format)
#   FORMAT can be:
#     0 for M/D/Y
#     1 for D/M/Y
#     2 for D.M.Y
#     3 for D-M-Y
#     4 for Y/M/D
#     5 for Y.M.D
#     6 for Y-M-D
#     7 for M-D-Y
#
# -charset_palm CHARSET		(Palm encoding)
# -charset_host CHARSET		(Host encoding)
#   CHARSET can be:
#     ISO-8859-6	for Arabic (ISO-8859-6)
#     MACARABIC		for Arabic (MacArabic)
#     ISO-8859-13	for Baltic (ISO-8859-13)
#     ISO-8859-4	for Baltic (ISO-8859-4)
#     WINDOWS-1257	for Baltic (Windows-1257)
#     ISO-8859-2	for Central European (ISO-8859-2)
#     WINDOWS-1250	for Central European (Windows-1250)
#     MACCROATIAN	for Croatian (MacCroatian)
#     GB2312		for Chinese Simplified (GB2312)
#     GBK		for Chinese Simplified (GBK)
#     HZ		for Chinese Simplified (HZ)
#     BIG5		for Chinese Traditional (Big5)
#     BIG5-HKSCS	for Chinese Traditional (Big5-HKSCS)
#     ISO-8859-5	for Cyrillic (ISO-8859-5)
#     ISO-IR-111	for Cyrillic (ISO-IR-111)
#     KOI8-R		for Cyrillic (KOI8-R)
#     MACCYRILLIC	for Cyrillic (MacCyrillic)
#     WINDOWS-1251	for Cyrillic (Windows-1251)
#     KOI8-U		for Cyrillic/Ukrainian (KOI8-U)
#     ISO-8859-7	for Greek (ISO-8859-7)
#     WINDOWS-1253	for Greek (Windows-1253)
#     MACGREEK		for Greek (MacGreek)
#     WINDOWS-1255	for Hebrew (Windows-1255)
#     MACHEBREW		for Hebrew (MacHebrew)
#     ISO-8859-8	for Visual Hebrew (ISO-8859-8)
#     ISO-2022-JP	for Japanese (ISO-2022-JP)
#     SHIFT_JIS		for Japanese (Shift_JIS)
#     EUC-JP		for Japanese (EUC-JP)
#     EUC-KR		for Korean (EUC-KR)
#     UHC		for Korean (UHC)
#     ISO-2022-KR	for Korean (ISO-2022-KR)
#     ISO-8859-9	for Turkish (ISO-8859-9)
#     WINDOWS-1254	for Turkish (Windows-1254)
#     MACTURKISH	for Turkish (MacTurkish)
#     UTF-8		for Unicode (UTF-8)
#     WINDOWS-1258	for Vietnamese (Windows-1258)
#     VISCII		for Vietnamese (VISCII)
#     US-ASCII		for English (US-ASCII)
#     ISO-8859-1	for Western (ISO-8859-1)
#     ISO-8859-15	for Western (ISO-8859-15)
#     MACINTOSH		for Western (Macintosh)
#     WINDOWS-1252	for Western (Windows-1252)
#     ISO-8859-14	for Celtic (ISO-8859-14)
#     ISO-8859-10	for Nordic (ISO-8859-10)
#     ISO-8859-16	for Romanian (ISO-8859-16)
#     MACROMANIA	for Romanian (MacRomania)
#     ISO-8859-3	for South European (ISO-8859-3)
#     TIS-620		for Thai (TIS-620)
#     ISO-8859-11	for Thai (ISO-8859-11)
#     WINDOWS-874	for Thai (Windows-874)
#
# -save_conf FILE	(Save all args in file FILE)
# -load_conf FILE	(Load args from file FILE after parsing CLI args)
#
# Example:
# importM2.pl -csv0 CCP.csv -fields unique_id,date,time,amount,splits -col_sep ';' -eol unix -date_fmt 1
#

# For each format, first matches a date, 2nd returns a list (day, month, year)
my @DATE_FMTS = ([ qr!(\d{1,2})/(\d{1,2})/(\d{4})!,
		   sub { ($2, $1, $3) },
		   "%m/%d/%Y" ],
		 [ qr!(\d{1,2})/(\d{1,2})/(\d{4})!,
		   sub { ($1, $2, $3) },
		   "%d/%m/%Y" ],
		 [ qr!(\d{1,2})\.(\d{1,2})\.(\d{4})!,
		   sub { ($1, $2, $3) },
		   "%d.%m.%Y" ],
		 [ qr!(\d{1,2})-(\d{1,2})-(\d{4})!,   
		   sub { ($1, $2, $3) },
		   "%d-%m-%Y" ],
		 [ qr!(\d{4})/(\d{1,2})/(\d{1,2})!,   
		   sub { ($3, $2, $1) },
		   "%Y/%m/%d" ],
		 [ qr!(\d{4})\.(\d{1,2})\.(\d{1,2})!,
		   sub { ($3, $2, $1) },
		   "%Y.%m.%d" ],
		 [ qr!(\d{4})-(\d{1,2})-(\d{1,2})!,   
		   sub { ($3, $2, $1) },
		   "%Y-%m-%d" ],
		 [ qr!(\d{1,2})-(\d{1,2})-(\d{4})!,   
		   sub { ($2, $1, $3) },
		   "%m-%d-%Y" ]);

my %EOC_CHARS = ('tab' => "\t",
		 '"'   => ';');	# " is forbidden as col separator

my %EOL_CHARS = ('win'  => "\015\012",
		 'mac'  => "\015",
		 'unix' => "\012");

my($DATE_FMT, $COLSEP, $EOL_TYPE, $EOL);


my %PDBS;

my(@csv_fields, %csv_fields);

my $num_added_currencies = 0;
my $num_added_modes = 0;
my $num_added_types = 0;

my $RECODE;
sub auto_encode ($;$);

sub field_get ($$;$)
{
    my($ref_cols, $index, $len) = @_;

    return '' unless defined $index;

    my $last = $index;
    $last += $len - 1 if wantarray and defined $len and $len > 1;

    my @contents;
    my $cur;

    for (; $index <= $last; $index++)
    {
	if (defined $ref_cols->[$index])
	{
	    $ref_cols->[$index] =~ /^\s*(.*?)\s*\z/;
	    $cur = $1;
	}
	else
	{
	    $cur = '';
	}

	push(@contents, $cur);
    }

    return wantarray ? @contents : $contents[0];
}


sub field_null_time ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    $rec->{time_hour} = $rec->{time_min} = 0;

    return undef;
}


sub field_time ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my $time = field_get($ref_cols, $index);

    # We don't take into account seconds when present...
    if ($time
	=~ /^([0-2]?\d)[:.,]([0-5]?\d)(?:[:.,][0-5]?\d)?(?:\s*([ap]m))?\z/i)
    {
	my($hour, $min, $ampm) = ($1, $2, $3);

	if ($ampm)
	{
	    return "can't have null hour in AM/PM time format" if $hour == 0;
	    return "can't have hour > 12 in AM/PM time format" if $hour > 12;

	    if (lc($ampm) eq 'pm') # PM
	    {
		$hour += 12 if $hour != 12; # noon stay noon
	    }
	    else		# AM
	    {
		$hour = 0 if $hour == 12; # midnight
	    }
	}
	else
	{
	    return "can't have hour > 23 in time" if $hour > 23;
	}

	$rec->{time_hour} = $hour;
	$rec->{time_min} = $min;
    }
    else
    {
	return "invalid time column: `$time'";
    }

    return undef;
}


sub field_amount ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my $amount = field_get($ref_cols, $index);

    if ($amount !~ /^-?(?:\d+(?:[.,]\d{0,2})?|[.,]\d{1,2})\z/)
    {
	return "invalid amount column: `$amount'";
    }

    $amount =~ tr/,/./;

    $rec->{$field} = sprintf("%.0f", $amount * 100);

    return undef;
}


sub field_flag ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my $flag = field_get($ref_cols, $index);

    if ($flag =~ /^[10]?\z/)
    {
	$rec->{$field} = $flag ? 1 : 0;	# 0 if empty...

	return undef;
    }

    return "invalid $field column: `$field'";
}


sub field_mode ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my($name_field, $idx_field) = @csv_fields{qw(mode mode_idx)};

    my $mode_rec;

    # At least index column
    if (defined $idx_field)
    {
	my $mode_id = field_get($ref_cols, $idx_field);

	if ($mode_id !~ /^(\d+)\z/)
	{
	    return "invalid mode index column: `$mode_id'";
	}

	# Already treated in name column ?
	return undef if $idx_field == $index and defined $name_field;

	# Is this mode the "unfiled" one ?
	if ($mode_id == $PDBS{modes}->unfiled_id)
	{
	    # Fake record, see at the end of the function...
	    $mode_rec = { mode_id => $mode_id };
	}
	else
	{
	    $mode_rec = $PDBS{modes}->get_id($mode_id);

	    # Mode does not exist, create it...
	    unless (defined $mode_rec)
	    {
		my $mode_name = auto_encode(field_get($ref_cols, $name_field));
		
		unless ($mode_name eq '')
		{
		    return "the mode index $mode_id does not "
			. "exists, but you don't give a mode name column "
			. "or it is empty so can't create it";
		}

		if (length($mode_name) > 31)
		{
		    return "the mode name `$mode_name' is too long";
		}

		$mode_rec = $PDBS{modes}->new_RecordWithId($mode_id);

		if (not defined $mode_rec)
		{
		    return "can't create a new mode in modes DB "
			. "($mode_name)";
		}

		$PDBS{modes}->append_Record($mode_rec);
		$num_added_modes++;
	    }

	    if (defined $name_field)
	    {
		my $mode_name = auto_encode(field_get($ref_cols, $name_field));

		$mode_rec->{name} = $mode_name if $mode_name ne '';
	    }
	}
    }
    # Only name column
    elsif (defined $name_field)
    {
	my $mode_name = auto_encode(field_get($ref_cols, $name_field));

	if ($mode_name eq '' or $mode_name eq $PDBS{modes}->unfiled_name)
	{
	    # Fake record, see at the end of the function...
	    $mode_rec = { mode_id => $PDBS{modes}->unfiled_id };
	}
	else
	{
	    $mode_rec = $PDBS{modes}->find_by_full_name($mode_name);

	    # Mode does not exists, create it...
	    unless (defined $mode_rec)
	    {
		$mode_rec = $PDBS{modes}->new_RecordWithAutoId;

		if (not defined $mode_rec)
		{
		    return "no more room in modes DB for create a new one "
			. "($mode_name)";
		}

		if (length($mode_name) > 31)
		{
		    return "the mode name `$mode_name' is too long";
		}

		$mode_rec->{name} = $mode_name;

		$PDBS{modes}->append_Record($mode_rec);
		$num_added_modes++;
	    }
	}
    }
    else
    {
	return "internal error for column $field";
    }

    # The ID field...
    $rec->{mode} = $mode_rec->{mode_id};

    return undef;
}


sub create_new_type ($)
{
    my $type_name = shift;

    # New type(s) with append_Record done
    my $type_rec = $PDBS{types}->new_RecordWithFullName($type_name);
    if (not defined $type_rec)
    {
	return "no more room in types DB for create a new one "
	    . "($type_name)";
    }

    $num_added_types++;

    return $type_rec;
}


sub field_type ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my($name_field, $idx_field) = @csv_fields{qw(type type_idx)};

    my $type_rec;

    # At least index column
    if (defined $idx_field)
    {
	my $type_id = field_get($ref_cols, $idx_field);

	if ($type_id !~ /^(\d+)\z/)
	{
	    return "invalid index $name_field column: `$type_id'";
	}

	# Already treated in name column ?
	return undef if $idx_field == $index and defined $name_field;

	# Is this type the "unfiled" one ?
	if ($type_id == $PDBS{types}->unfiled_id)
	{
	    # Fake record, see at the end of the function...
	    $type_rec = { type_id => $type_id };
	}
	else
	{
	    $type_rec = $PDBS{types}->get_id($type_id);

	    # This type does not exist, create it...
	    unless (defined $type_rec)
	    {
		unless (defined $name_field)
		{
		    return "the $name_field index $type_id does not "
			. "exists, but you don't give a type name column, "
			. "so can't create it";
		}

		my $name = auto_encode(field_get($ref_cols, $name_field));

		# New type(s) with append_Record done
		$type_rec = $PDBS{types}->new_RecordWithFullName($name, 
								 $type_id);
		if (not defined $type_rec)
		{
		    return
			"can't create a new $name_field in types DB ($name)";
		}

		$num_added_types++;
	    }

	    if (defined $name_field)
	    {
		if ($PDBS{types}->full_name($type_id)
		    ne auto_encode(field_get($ref_cols, $name_field)))
		{
		    return "the $name_field index $type_id does not have "
			. "the same full name as in the types DB : "
			. $PDBS{types}->full_name($type_id);
		}
	    }
	}
    }
    # Only name column
    elsif (defined $name_field)
    {
	my $name = auto_encode(field_get($ref_cols, $name_field));

	if ($name eq '' or $name eq $PDBS{types}->unfiled_name)
	{
	    # Fake record, see at the end of the function...
	    $type_rec = { type_id => $PDBS{types}->unfiled_id };
	}
	else
	{
	    $type_rec = $PDBS{types}->find_by_full_name($name);

	    # Type does not exists, create it...
	    unless (defined $type_rec)
	    {
		$type_rec = create_new_type($name);
		return $type_rec unless ref $type_rec;
	    }
	}
    }
    else
    {
	return "internal error for column $field";
    }

    # The ID field...
    $rec->{type} = $type_rec->{type_id};

    return undef;
}


sub field_note ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my $note = auto_encode(field_get($ref_cols, $index), 1);

    unless (defined $note)
    {
	return "can't convert encoding for note field: " . $RECODE->getError;
    }

    $rec->{note} = $note;

    return undef;
}


sub field_value_date ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my $date = field_get($ref_cols, $index);

    if ($date ne '')
    {
	if ($date =~ /^$DATE_FMT->[0]\z/o)
	{
	    @{$rec->{value_date}}{qw(day month year)}
	        = $DATE_FMT->[1]();
	}
	else
	{
	    return "invalid withdrawal date";
	}
    }

    return undef;
}


sub field_number ($$$$$)
{
    my($rec, $field, $ref_cols, $index, $human_name) = @_;

    my $num = field_get($ref_cols, $index);

    if ($num ne '')
    {
	if ($num =~ /^\d+\z/)
	{
	    $rec->{$field} = $num;
	}
	else
	{
	    return "invalid $human_name";
	}
    }

    return undef;
}


my %REPEAT_TYPES =
    (monthly	   => { type => 0,
			freq => { map { ($_ => 1) } (1, 2, 3, 4, 6, 12, 24) }},
     'monthly end' => { type => 1,
			freq => { 1 => 1 } },
     weekly	   => { type => 2,
			freq => { map { ($_ => 1) } (1, 2) } } );

sub field_repeat ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    my @repeat = field_get($ref_cols, $index, 3);

    return undef unless grep { $_ ne '' } @repeat;

    # Repeat type
    if (not exists $REPEAT_TYPES{$repeat[0]})
    {
	return 'invalid repeat type, have to be either "'
	    . join('" or "', keys %REPEAT_TYPES), '"';
    }

    # Repeat frequency
    if ($repeat[1] !~ /^\d+\z/
	and not exists $REPEAT_TYPES{$repeat[0]}{freq}{$repeat[1]})
    {
	return "repeat frequency must be a number, and for \"$repeat[0]\" "
	    . "repeat type, only frequencies ("
	    . join(', ', keys %{$REPEAT_TYPES{$repeat[0]}{freq}})
	    . ") are allowed";
    }

    # Optional repeat end date
    if ($repeat[2] ne '')
    {
	if ($repeat[2] =~ /^$DATE_FMT->[0]\z/o)
	{
	    my @date = $DATE_FMT->[1]();

	    @{$rec->{repeat}}{qw(end_date_day end_date_month end_date_year)}
	        = $DATE_FMT->[1]();
	}
	else
	{
	    return "invalid repeat end date";
	}
    }
    else
    {
	@{$rec->{repeat}}{qw(end_date_day end_date_month end_date_year)}
	    = (0, 0, 0);
    }

    $rec->{repeat}{repeat_type} = $REPEAT_TYPES{$repeat[0]}{type};
    $rec->{repeat}{repeat_freq} = $repeat[1];

    return undef;
}


sub field_xfer ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    # Déjà fait...
    return undef if exists $rec->{xfer};

    my $xfer_account = auto_encode(field_get($ref_cols, 
					     $csv_fields{xfer_account}));
    my $xfer_unique_id_field
	= field_get($ref_cols, $csv_fields{xfer_unique_id});

    return undef if $xfer_account eq '' and $xfer_unique_id_field eq '';

    # We have a record unique ID
    if ($xfer_unique_id_field ne '')
    {
	unless (exists $csv_fields{unique_id})
	{
	    return "can't create linked transaction without a "
		. "unique ID column";
	}

	if ($xfer_unique_id_field !~ /^\d+\z/
	    or ($xfer_unique_id_field & 0xff000000) != 0
	    or $xfer_unique_id_field == 0)
	{
	    return "invalid transfer unique ID column: "
		. "`$xfer_unique_id_field'";
	}

	$rec->{xfer} = $xfer_unique_id_field;
    }
    # We have an account name
    else
    {
	# We will correct this at end when all accounts will exist
	$rec->{xfer} = $xfer_account;
	$rec->{xfer_cat} = 1;
    }

    return undef;
}


my($CUR_ACCOUNT_CURRENCY_ID, $REFERENCE_CURRENCY);
sub field_currency_tr ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    # Déjà fait...
    return undef if exists $rec->{currency};

    my($name_field, $idx_field) = @csv_fields{qw(currency currency_idx)};

    # No currency field contents
    return undef if (field_get($ref_cols, $name_field) eq ''
		     and field_get($ref_cols, $idx_field) eq '');

    unless (defined $CUR_ACCOUNT_CURRENCY_ID)
    {
	return "currency column present, "
	    . "but can't find an account properties line, "
	    . "so don't know the account currency";
    }

    my $currency_rec;
    my $currency_created = 0;

    my $currency_amount;

    # Amount of the transaction
    my $transaction_amount = exists($csv_fields{amount})
	? field_get($ref_cols, $csv_fields{amount}) : $rec->{amount};

    if ($transaction_amount !~ /^-?(?:\d+(?:[.,]\d{0,2})?|[.,]\d{1,2})\z/)
    {
	return "can't treat currency amount, "
	    . "because of an invalid transaction amount";
    }

    $transaction_amount =~ tr/,/./;

    # At least index column
    if (defined $idx_field)
    {
	my $currency_id = field_get($ref_cols, $idx_field);

	if ($currency_id !~ /^(\d+)\z/)
	{
	    return "invalid currency index column: `$currency_id'";
	}

	$currency_rec = $PDBS{currencies}->get_id($currency_id);

	# This currency does not exist, create it...
	unless (defined $currency_rec)
	{
	    my $currency_name = auto_encode(field_get($ref_cols, $name_field));
		
	    unless ($currency_name eq '')
	    {
		return "the currency index $currency_id does not "
		    . "exists, but you don't give a mode name column "
		    . "or it is empty so can't create it";
	    }

	    $currency_rec = $PDBS{currencies}->new_RecordWithId($currency_id);

	    if (not defined $currency_rec)
	    {
		return "can't create a new currency in currencies DB "
		    . "($currency_name)";
	    }

	    $currency_created = 1;
	}

	# The first currency amount column
	$currency_amount = field_get($ref_cols, $idx_field + 1);
	if ($currency_amount ne ''
	    and $currency_amount
	    !~ /^-?(?:\d+(?:[.,]\d{0,2})?|[.,]\d{1,2})\z/)
	{
	    return "invalid currency amount column: `$currency_amount'";
	}

	$currency_amount =~ tr/,/./;

	if (defined $name_field)
	{
	    my $currency_name = auto_encode(field_get($ref_cols, $name_field));

	    $currency_rec->{name} = $currency_name if $currency_name ne '';

	    # The second currency amount column...
	    my $currency_amount2 = field_get($ref_cols, $name_field + 1);
	    if ($currency_amount2 ne '')
	    {
		if ($currency_amount2
		    =~ /^-?(?:\d+(?:[.,]\d{0,2})?|[.,]\d{1,2})\z/)
		{
		    $currency_amount2 =~ tr/,/./;

		    # Take the non-empty currency amount
		    if ($currency_amount eq '')
		    {
			$currency_amount = $currency_amount2;
		    }
		    # both are non-empty: they must equal numerically!
		    elsif ($currency_amount != $currency_amount2
			   # float comparison may be buggy, use string one too
			   and $currency_amount ne $currency_amount2)
		    {
			return "the two given currency amount columns are not "
			    . "equal: $currency_amount != $currency_amount2";
		    }
		}
		else
		{
		    return "invalid currency amount column: "
			. "`$currency_amount2'";
		}
	    }
	}

	if ($currency_amount eq '')
	{
	    return "empty currency amount column";
	}
    }
    # Only name column
    elsif (defined $name_field)
    {
	my $currency_name = auto_encode(field_get($ref_cols, $name_field));

	if ($currency_name eq '')
	{
	    return
		"the currency name column is empty, so can't work with it";
	}

	$currency_rec = $PDBS{currencies}->find_by_full_name($currency_name);

	# Currency does not exists, create it...
	unless (defined $currency_rec)
	{
	    $currency_rec = $PDBS{currencies}->new_RecordWithAutoId;

	    if (not defined $currency_rec)
	    {
		return "no more room in currencies DB for create a new one "
		    . "($currency_name)";
	    }

	    $currency_rec->{name} = $currency_name;

	    $currency_created = 1;
	}

	$currency_amount = field_get($ref_cols, $name_field + 1);

	if ($currency_amount eq '')
	{
	    return "empty currency amount column";
	}

	if ($currency_amount !~ /^-?(?:\d+(?:[.,]\d{0,2})?|[.,]\d{1,2})\z/)
	{
	    return "invalid currency amount column: `$currency_amount'";
	}

	$currency_amount =~ tr/,/./;
    }
    else
    {
	return "internal error for column $field";
    }

    if (($currency_amount == 0) ^ ($transaction_amount == 0))
    {
	return "one of currency or transaction amount is null";
    }

    if (($currency_amount < 0) ^ ($transaction_amount < 0))
    {
	return "the currency amount and the transaction one "
	    . "don't have the same sign";
    }

    if ($currency_created)
    {
	if (length($currency_rec->{name}) > 4)
	{
	    return "the currency name `$currency_rec->{name}' is too long";
	}

	$PDBS{currencies}->append_Record($currency_rec);
	$num_added_currencies++;
    }

    if ($currency_rec->{curr_id} == $CUR_ACCOUNT_CURRENCY_ID)
    {
	return "transaction with the same currency as the account one";
    }

    # The ID field...
    $rec->{currency}{currency} = $currency_rec->{curr_id};

    # The currency amount
    $rec->{currency}{currency_amount} = sprintf("%.0f", $currency_amount * 100);

    # No reference currency yet, create one...
    if (not defined $REFERENCE_CURRENCY)
    {
	$currency_rec->{reference} = 1;
	$REFERENCE_CURRENCY = $currency_rec;
    }

    return undef;
}


sub field_currency_acc ($$$$)
{
    my($rec, $field, $ref_cols, $index) = @_;

    # Déjà fait...
    return undef if defined $CUR_ACCOUNT_CURRENCY_ID;

    my($name_field, $idx_field) = @csv_fields{qw(currency currency_idx)};

    # No currency field contents
    if (field_get($ref_cols, $name_field) eq ''
	and field_get($ref_cols, $idx_field) eq '')
    {
	return "empty currency name or index column for account properties";
    }

    my $currency_rec;
    my $currency_created = 0;

    # The amount part must be empty
    if (field_get($ref_cols,
		  defined($name_field) ? $name_field + 1 : undef) ne ''
	or field_get($ref_cols,
		     defined($idx_field) ? $idx_field + 1 : undef) ne '')
    {
	return "in account properties, "
	    . "a currency can't have a filled amount column";
    }

        # At least index column
    if (defined $idx_field)
    {
	my $currency_id = field_get($ref_cols, $idx_field);

	if ($currency_id !~ /^(\d+)\z/)
	{
	    return "invalid currency index column: `$currency_id'";
	}

	$currency_rec = $PDBS{currencies}->get_id($currency_id);

	# This currency does not exist, create it...
	unless (defined $currency_rec)
	{
	    my $currency_name = auto_encode(field_get($ref_cols, $name_field));
		
	    unless ($currency_name eq '')
	    {
		return "the currency index $currency_id does not "
		    . "exists, but you don't give a mode name column "
		    . "or it is empty so can't create it";
	    }

	    $currency_rec = $PDBS{currencies}->new_RecordWithId($currency_id);

	    if (not defined $currency_rec)
	    {
		return "can't create a new currency in currencies DB "
		    . "($currency_name)";
	    }

	    $currency_created = 1;
	}

	if (defined $name_field)
	{
	    my $currency_name = auto_encode(field_get($ref_cols, $name_field));

	    $currency_rec->{name} = $currency_name if $currency_name ne '';
	}
    }
    # Only name column
    elsif (defined $name_field)
    {
	my $currency_name = auto_encode(field_get($ref_cols, $name_field));

	if ($currency_name eq '')
	{
	    return
		"the currency name column is empty, so can't work with it";
	}

	$currency_rec = $PDBS{currencies}->find_by_full_name($currency_name);

	# Currency does not exists, create it...
	unless (defined $currency_rec)
	{
	    $currency_rec = $PDBS{currencies}->new_RecordWithAutoId;

	    if (not defined $currency_rec)
	    {
		return "no more room in currencies DB for create a new one "
		    . "($currency_name)";
	    }

	    $currency_rec->{name} = $currency_name;

	    $currency_created = 1;
	}
    }
    else
    {
	return "internal error for column $field";
    }

    if ($currency_created)
    {
	if (length($currency_rec->{name}) > 4)
	{
	    return "the currency name `$currency_rec->{name}' is too long";
	}

	$PDBS{currencies}->append_Record($currency_rec);
	$num_added_currencies++;
    }

    $rec->{currency} = $CUR_ACCOUNT_CURRENCY_ID = $currency_rec->{curr_id};

    # No reference currency yet, create one...
    if (not defined $REFERENCE_CURRENCY)
    {
	$currency_rec->{reference} = 1;
	$REFERENCE_CURRENCY = $currency_rec;
    }

    return undef;
}


sub field_splits ($$$$)
{
    my($rec, $field, $ref_cols, $index, $is_type_id) = @_;

    # The remain fields must go by 3
    my $cols = @$ref_cols - $index;
    if ($cols % 3 != 0)
    {
	return "$cols columns for splits, but splits column must go by 3";
    }

    # Pas de split...
    if ($cols == 3
	and $ref_cols->[$index + 0] eq ''
	and $ref_cols->[$index + 1] eq ''
	and $ref_cols->[$index + 2] eq '')
    {
	return undef;
    }

    my $error_prefix = "in splits, column ";

    while ($cols > 0)
    {
	#
	# Type
	#

	my $type_id = field_get($ref_cols, $index);

	# Type ID
	if ($is_type_id)
	{
	    if ($type_id !~ /^(\d+)\z/)
	    {
		return "$error_prefix$index, the type index is invalid "
		       . "`$type_id'";
	    }

	    # We have to create this new type
	    if ($type_id != $PDBS{types}->unfiled_id
		and not defined $PDBS{types}->get_id($type_id))
	    {
		return "$error_prefix$index, the type index $type_id does not "
		       . "exists, so can't create it. "
		       . "Use splits with full type name instead";
	    }
	}
	# Type name
	else
	{
	    my $type_name = auto_encode($type_id);

	    if ($type_name eq '' or $type_name eq $PDBS{types}->unfiled_name)
	    {
		$type_id = $PDBS{types}->unfiled_id;
	    }
	    else
	    {
		my $type_rec = $PDBS{types}->find_by_full_name($type_name);

		# Type does not exists, create it...
		unless (defined $type_rec)
		{
		    $type_rec = create_new_type($type_name);
		    unless (ref $type_rec)
		    {
			return "$error_prefix$index, $type_rec";
		    }
		}

		$type_id = $type_rec->{type_id};
	    }
	}

	#
	# Amount
	#
	$index++;

	my $amount = field_get($ref_cols, $index);

	if ($amount !~ /^-?\d+(?:[.,]\d{0,2})?|[.,]\d{1,2}\z/)
	{
	    return "$error_prefix$index, invalid amount column: `$amount'";
	}
	$amount =~ tr/,/./;

	#
	# Description
	#
	$index++;

	my $desc = auto_encode(field_get($ref_cols, $index), 1);
	unless (defined $desc)
	{
	    return "$error_prefix$index, can't convert encoding for "
		. "description: " . $RECODE->getError;
	}

	#
	# OK we can save this split
	#
	if (not exists $rec->{splits})
	{
	    $rec->{splits} = { reserved => 0, list => [] };
	}

	push(@{$rec->{splits}{list}},
	     {
		 amount => sprintf("%.0f", $amount * 100),
		 type => $type_id,
		 desc => $desc,
		 reserved => 0,
	     });

	# Next split
	$cols -= 3;
	$index++;
    }

    return undef;
}


my %FIELDS = (unique_id	     => {username =>'Internal ID (used by transfers)'},
	      date	     => {},
	      time	     => { import_acc => \&field_null_time,
				  import_tr  => \&field_time },
	      amount	     => { 'import'   => \&field_amount },
	      checked	     => { 'import'   => \&field_flag,
				  username   => 'Checked or not' },
	      flagged	     => { 'import'   => \&field_flag,
				  name	     => 'marked',
				  username   => 'Flagged or not' },
	      alarm	     => { import_tr  => \&field_flag,
				  username   => 'Alarm or not' },
	      mode_idx	     => { import_tr  => \&field_mode,
				  username   => 'Mode (only index)' },
	      mode	     => { import_tr  => \&field_mode,
				  username   => 'Mode (full name)' },
	      type_idx	     => { import_tr  => \&field_type,
				  username   => 'Type (only index)' },
	      type	     => { import_tr  => \&field_type,
				  username   => 'Type (full name)' },
	      note	     => { 'import'   => \&field_note,
				  username   => 'Description' },
	      value_date     => { import_tr  => \&field_value_date,
				  username   => 'Validity date' },
	      cheque_num     => { import_tr  => [ \&field_number,
						  'cheque number' ],
				  name	     => 'check_num',
				  username   => 'Cheque number' },
	      repeat	     => { import_tr  => \&field_repeat,
				  num_cols   => 3,
				  username   => [ 'Repeat type',
						  'Repeat frequency',
						  'Reapeat end date' ]},
	      xfer_account   => { import_tr  => \&field_xfer,
				  username   => 'Transfer account' },
	      xfer_unique_id => { import_tr  => \&field_xfer,
				  username   => 'ID of linked transaction' },
	      statement_num  => { import_tr  => [ \&field_number,
						  'statement number' ],
				  name	     => 'stmt_num',
				  username   => 'Statement number' },
	      currency_idx   => { import_tr  => \&field_currency_tr,
				  import_acc => \&field_currency_acc,
				  num_cols   => 2,
				  username   => [ 'Currency (only index)',
						  'Amount in currency' ] },
	      currency	     => { import_tr  => \&field_currency_tr,
				  import_acc => \&field_currency_acc,
				  num_cols   => 2,
				  username   => [ 'Currency (full name)',
						  'Amount in currency' ] },
	      splits	     => { import_tr  => [ \&field_splits, 0 ],
				  num_cols   => 2_000_000_003,# Eat rest of line
				  username   => [ 'Split type full name',
						  'Split amount',
						  'Split description' ] },
	      splits_idx     => { import_tr  => [ \&field_splits, 1 ],
				  num_cols   => 2_000_000_003,# Eat rest of line
				  username   => [ 'Split type index',
						  'Split amount',
						  'Split description' ] },
	      # Colonnes vide
	      empty	     => {},
	      account	     => {},
    );
use CGI qw(-private_tempfiles);


my $query = new Palm::MaTirelire::CGICLI
			(-cgiopt => '-private_tempfiles',
			 # 300 Ko max par fichier
			 -cgicode => '$CGI::POST_MAX = 300 * 1024');


########################################################################
#
# die and warn handlers...
#
########################################################################
my @WARN;
$SIG{__WARN__} = sub { push(@WARN, join('', @_)) };

if ($query->cgi)
{
    $SIG{__DIE__} = sub
    {
	print $query->header;

	print <<EOFHTML;
<html>
<head><title>Error...</title></head>
<body bgcolor="white">
<h2>An error occured with your file(s):</h2>
EOFHTML

	if (@WARN != 0)
	{
	    print "<h3>Warnings:</h3>\n<ul>\n<li>";
	    print join("\n<li>", @WARN);
	    print "\n</ul>\n";
	}

	print "<h3>Fatal error:</h3>\n<b>", join('', @_), "</b>\n";

	print <<EOFHTML;
</body>
</html>
EOFHTML
	exit 0;
    };
}
else
{
    $SIG{__DIE__} = sub
    {
	print STDERR "Error, an error occured with your file(s):\n";

	if (@WARN != 0)
	{
	    print "\nWarnings:\n- ";
	    print join("\n- ", @WARN);
	    print "\n\n"
	}

	# On vire le HTML au vol
	my @args = @_;
	print "Fatal error: ", join('', map { s,<[\w/].+?>,,g; $_ } @args),"\n";

	exit 0;
    };

    if ($query->param('load_conf'))
    {
	$query->loadCliArgs($query->param('load_conf'));
    }
}


########################################################################
#
# charset encoding management
#
########################################################################
sub auto_encode ($;$)
{
    my($str, $undef_if_error) = @_;

    if (defined $RECODE)
    {
	unless ($RECODE->recode($str))
	{
	    return undef if $undef_if_error;

	    die "Can't convert encoding for `$str'", $RECODE->getError, "\n";
	}
    }

    # Les fins de lignes
    $str =~ s/\012/$EOL/g if $EOL ne "\012";

    return $str;
}
{
    my($charset_palm, $charset_host)
	= map { $query->param($_) } qw(charset_palm charset_host);

    if (defined $charset_palm and defined $charset_host)
    {
	$charset_host =~ tr/-_a-zA-Z0-9//cd;
	$charset_palm =~ tr/-_a-zA-Z0-9//cd;

	if ($charset_host ne '' and $charset_palm ne ''
	    and $charset_host ne $charset_palm)
	{
	    $RECODE = eval <<EOF;
use Locale::Recode;
local \$SIG{__DIE__} = 'IGNORE';
my \$from = Locale::Recode->resolveAlias('$charset_host');
my \$to = Locale::Recode->resolveAlias('$charset_palm');
Locale::Recode->new(from => \$from, to => \$to);
EOF

	    if ($@)
	    {
		chomp(my $err = $@);
		die "Can't convert encodings: $err\n";
	    }
	    die "Can't convert encodings: ", $RECODE->getError, "\n"
		if $RECODE->getError;
	}
    }
}


########################################################################
#
# Load or create Palm databases
#
########################################################################
my($REC_DELETED, $REC_CORRECTED);
foreach my $file (qw(accounts modes types currencies))
{
    my $db;

    my $classname = 'Palm::MaTirelire::'
	. ($file eq 'accounts' ? 'AccountsV2' : ucfirst $file);
    
    if (defined $query->param($file) and $query->param($file) ne '')
    {
	my $fh = $query->upload($file);
	if (defined $fh)
	{
	    my $contents;

	    while (defined(my $line = <$fh>))
	    {
		$contents .= $line;
	    }

	    $db = new Palm::PDB;

	    $db->Load(\$contents);

	    unless ($db->isa($classname))
	    {
		die "The sent $file database is not a MaTirelire2 one.\n";
	    }

	    if ($db->can('validRecords'))
	    {
		($REC_DELETED, $REC_CORRECTED) = $db->validRecords;
	    }
	}
	elsif (my $error = $query->cgi_error)
	{
	    die "$error...\n";
	}
	else
	{
	    die "Can't upload ", $query->param($file), ": unknown error...\n";
	}
    }
    # If the database is left empty, create a new one...
    else
    {
	$db = eval "new $classname";

	if ($@)
	{
	    chomp(my $err = $@);
	    die "Can't construct Palm::MaTirelire::$classname: $err\n";
	}
	die "Can't construct Palm::MaTirelire::$classname: $!\n"
	    unless defined $db;
    }

    # Always change the PDB name...
    $db->{name} = 'MaTi=Imported accounts' if $file eq 'accounts';

    $PDBS{$file} = $db;
}

# Reference currency, possibly non-existent...
$REFERENCE_CURRENCY = $PDBS{currencies}->reference;


my %CACHE_PDB_ACCOUNTS_NAMES;
sub find_or_create_account ($)
{
    my $csv_account = shift;

    # The CSV account name is host encoded, so convert it to Palm one
    my $palm_account = auto_encode($csv_account, 1);
    if (not defined $palm_account)
    {
	die "Can't convert encoding for account $csv_account: ",
	    $RECODE->getError, "\n";
    }

    # Suppress the extension
    $palm_account =~ s/\.\w{3}\z//;

    my $ref_accounts = $PDBS{accounts}{appinfo}{categories};

    # The accounts name cache is not built yet...
    if (keys(%CACHE_PDB_ACCOUNTS_NAMES) == 0)
    {
	for (my $index = 0; $index < @$ref_accounts; $index++)
	{
	    my $cur_account = $ref_accounts->[$index]{name};

	    if (defined $cur_account and $cur_account ne '')
	    {
		$cur_account = lc $cur_account;
		$cur_account =~ tr/ /_/;

		if (exists $CACHE_PDB_ACCOUNTS_NAMES{$cur_account})
		{
		    $cur_account = $ref_accounts->[$index]{name};
		}

		$CACHE_PDB_ACCOUNTS_NAMES{$cur_account} = $index;
	    }
	}
    }

    my $tmp_search_account = lc $palm_account;
    $tmp_search_account =~ tr/ /_/;

    # OK we found the account
    if (not exists $CACHE_PDB_ACCOUNTS_NAMES{$tmp_search_account})
    {
	# No account found, so create it...
	my $first_empty;
	for (my $index = 0; $index < 16; $index++)
	{
	    if (not defined $ref_accounts->[$index]
		or not defined $ref_accounts->[$index]{name}
		or $ref_accounts->[$index]{name} eq '')
	    {
		$first_empty = $index;
		last;
	    }
	}

	if (not defined $first_empty)
	{
	    die "No more room in accounts database to crete a new account\n";
	}

	$ref_accounts->[$first_empty]{name} = $palm_account;

	# Update the cache with the new created account
	$CACHE_PDB_ACCOUNTS_NAMES{$tmp_search_account} = $first_empty;
    }

    my $account_idx = $CACHE_PDB_ACCOUNTS_NAMES{$tmp_search_account};

    # Search the account record in the database
    my $prop = $PDBS{accounts}->findAccountPropertiesByIndex($account_idx);
    if (not defined $prop)
    {
	$prop = $PDBS{accounts}->new_AccountProperties;

	$prop->{category} = $account_idx;

	$PDBS{accounts}->append_Record($prop);
    }

    return $account_idx;
}


# Returns the category index of the passed account or undef if the
# account can't be found...
sub find_account ($)
{
    my $account_name = lc auto_encode(shift);

    $account_name =~ tr/ /_/;

    return $CACHE_PDB_ACCOUNTS_NAMES{$account_name};
}


########################################################################
#
# Other parameters init
#
########################################################################

# Date format
$DATE_FMT = $query->param('date_fmt');
if (not defined $DATE_FMT or $DATE_FMT !~ /^\d+\z/ or $DATE_FMT >= @DATE_FMTS)
{ $DATE_FMT = 0 }
$DATE_FMT = $DATE_FMTS[$DATE_FMT];

# Column separator
$COLSEP = $query->param('col_sep');
$COLSEP = ';' if not defined $COLSEP;
$COLSEP = $EOC_CHARS{$COLSEP} if exists $EOC_CHARS{$COLSEP};
substr($COLSEP, 1) = '';	# Only one char allowed

# End of line
$EOL_TYPE = $query->param('eol');
$EOL_TYPE = 'win' if not defined $EOL_TYPE or not exists $EOL_CHARS{$EOL_TYPE};
$EOL = $EOL_CHARS{$EOL_TYPE};

if ($EOL eq $COLSEP)
{
    die "The end-of-line can not be the same than the columns separator\n";
}


# We don't take care of duplicate columns (only the last one will be
# taken into account)
if (defined $query->param('fields'))
{
    my $index = 0;
    my $cols;
    foreach my $field (split ',', $query->param('fields'))
    {
	$field = 'empty' unless exists $FIELDS{$field};

	$cols = $FIELDS{$field}{num_cols} || 1;

	# Not more dans 10 columns per field. It allows to splits to
	# keep a quasi-infinite columns count
	push(@csv_fields, ($field) x ($cols % 10));
	$csv_fields{$field} = $index;

	# Splits have more than 10 columns AND are always at end of fields list
	last if $cols > 10;

	$index += $cols;
    }
}

die "Too many fields selected.\n" if @csv_fields > 30;


########################################################################
#
# For each CSV account
#
########################################################################
my $csv_num_accounts = 0;
for (my $csv_index = 0; $csv_index < 16; $csv_index++)
{
    if (defined $query->param("csv$csv_index")
	and $query->param("csv$csv_index") ne '')
    {
	my $fh = $query->upload("csv$csv_index");
	if (defined $fh)
	{
	    # Load the file before giving it to Text::CSV_XS because
	    # CGI create its own filehandle class which is not
	    # compatible with the one that Text::CSV_XS getline method
	    # wants: I don't have time to investigate... Too bad...
	    my $csv_contents = '';
	    while (defined(my $line = <$fh>))
	    {
		$csv_contents .= $line;
	    }

	    $fh = IO::Handle->new;
	    open($fh, '<', \$csv_contents);

	    # Text::CSV_XS only handle wind*ws & unix ends of line
	    $csv_contents =~ s/\Q$EOL/\012/og if $EOL_TYPE eq 'mac';

	    my $csv = Text::CSV_XS->new({ sep_char => $COLSEP,
					  binary => 1 });

	    my $filename = $query->param("csv$csv_index");

	    # Delete the basename part
	    $filename =~ s,^(.*)[/\\:],,;

	    my $account_idx = find_or_create_account($filename);

	    my($rec, $rec_just_created);
	    my $line = 0;

	    # Load the account currency (only if the account
	    # properties already exists)
	    $CUR_ACCOUNT_CURRENCY_ID = undef;
	    $rec = $PDBS{accounts}->findAccountPropertiesByIndex($account_idx);
	    if (defined $rec)
	    {
		$CUR_ACCOUNT_CURRENCY_ID = $rec->{currency};
	    }

	    while (defined(my $ref_cols = $csv->getline($fh)))
	    {
		last if @$ref_cols == 0;

		my $account_prop = 0;

		$line++;

		next if $line == 1 and $ref_cols->[0] =~ /^\#/;

		# Watch to see if we have the date, it will allow us
		# to differenciate a record from an account
		my @date;
		if (exists $csv_fields{date})
		{
		    my $date = field_get($ref_cols, $csv_fields{date});
		    if ($date =~ /^$DATE_FMT->[0]\z/o)
		    {
			@date = $DATE_FMT->[1]();
		    }
		    else
		    {
			die("In `$filename', line $line, invalid date: ",
			    "`$date'\n");
		    }

		    # Propriétés de compte
		    $account_prop = 1 if @date && $date[0] == 0;
		}

		# Watch to see if we have a unique_ID column
		my $id = 0;
		if (exists $csv_fields{unique_id}
		    and $csv_fields{unique_id} < @$ref_cols)
		{
		    $id = $ref_cols->[$csv_fields{unique_id}];

		    if ($id !~ /^\d+\z/ or ($id & 0xff000000) != 0 or $id == 0)
		    {
			die("In `$filename', line $line, invalid unique ID: ",
			    "`$id'\n");
		    }

		    $rec = $PDBS{accounts}->findRecordByID($id);
		    if (defined $rec)
		    {
			# We have to delete all M2 options
			delete @$rec{qw(value_date check_num repeat xfer
					xfer_cat stmt_num currency splits)};
		    }
		    else
		    {
			goto create_record;
		    }
		}
		else
		{
		  create_record:
		    # Account properties
		    if ($account_prop)
		    {
			$rec = $PDBS{accounts}->
			    findAccountPropertiesByIndex($account_idx);

			# Account properties built in
			# find_or_create_account() above
			unless (defined $rec)
			{
			    die("In `$filename', line $line, can't ",
				"create account properties for account ",
				"#$account_idx\n");
			}
		    }
		    else
		    {
			$rec = $PDBS{accounts}->new_Record;

			$rec_just_created = 1;
		    }

		    # Dans le cas où on vient du goto create_record;
		    $rec->{id} = $id if $id != 0;
		}

		# On met à jour le compteur de uniqueID dans le header
		# de la base
		if ($rec->{id} > $PDBS{accounts}->{uniqueIDseed})
		{
		    $PDBS{accounts}->{uniqueIDseed} = $rec->{id};
		}

		# Date of the record...
		@{$rec}{qw(date_day date_month date_year)} = @date if @date;

		# For each column....
		for (my $index = 0; $index < @csv_fields; )
		{
		    my $field = $csv_fields[$index];

		    my $sub = $FIELDS{$field}{$account_prop 
						  ? 'import_acc'
						  : 'import_tr'};

		    $sub ||= $FIELDS{$field}{'import'};

		    if (defined $sub)
		    {
			my @params = ($rec, $FIELDS{$field}{name} || $field,
				      $ref_cols, $index);

			if (ref($sub) eq 'ARRAY')
			{
			    push(@params, @$sub[1 .. $#$sub]);
			    $sub = $sub->[0];
			}

			my $error = $sub->(@params);

			die "In `$filename', line $line, $error\n"
			    if defined $error;
		    }

		    $index += ($FIELDS{$field}{num_cols} || 1);
		}

		$rec->{category} = $account_idx;

		$PDBS{accounts}->append_Record($rec) if $rec_just_created;
	    }

	    $fh->close;

	    $csv_num_accounts++;
	}
	elsif (my $error = $query->cgi_error)
	{
	    die "$error...\n";
	}
    }
}

if ($csv_num_accounts == 0)
{
    die "Can't find any CSV accounts file to import\n";
}


# Solve Xfer without unique ID links
foreach my $rec (@{$PDBS{accounts}{records}})
{
    if ($rec->{xfer_cat})
    {
	# In this case $rec->{xfer} contains the account name
	my $account_idx = find_account($rec->{xfer});

	unless (defined $account_idx)
	{
	    die("Can't create transfer link into unknown "
		. "`$rec->{xfer}' account\n");
	}

	$rec->{xfer} = $account_idx;
    }
}


########################################################################
#
# OK all the PDB files are ready, we can create the archive
#
########################################################################
my $ZIP = Archive::Zip->new();
my $ZIP_DIR = 'MaTirelire2-import';

$ZIP->addDirectory("$ZIP_DIR/");

my $readme = POSIX::strftime(<<EOFREADME, gmtime(time));
$csv_num_accounts account@{[ $csv_num_accounts > 1 ? 's' : ''
		          ]} imported at: $DATE_FMT->[2] %H:%M UTC.

Imported fields are:
EOFREADME

foreach my $field (@csv_fields)
{
    my @names;

    if (exists $FIELDS{$field}{username})
    {
	if (ref $FIELDS{$field}{username})
	{
	    @names = @{$FIELDS{$field}{username}};
	}
	else
	{
	    @names = ($FIELDS{$field}{username});
	}
    }
    else
    {
	@names = (ucfirst $field);
    }

    $readme .= "- " . join("\n- ", @names) . "\n";
}

$readme .= "\n";

$readme .= "* ";
$readme .= ($num_added_modes == 0 ? 'No' : $num_added_modes);
$readme .= ' mode' . ($num_added_modes > 1 ? 's' : '');
$readme .= " added\n";

$readme .= "* ";
$readme .= ($num_added_types == 0 ? 'No' : $num_added_types);
$readme .= ' type' . ($num_added_types > 1 ? 's' : '');
$readme .= " added\n";

$readme .= "* ";
$readme .= ($num_added_currencies == 0 ? 'No' : $num_added_currencies);
$readme .= ($num_added_currencies > 1 ? ' currencies' : ' currency');
$readme .= " added\n";


# Some transactions have been deleted and/or corrected in the existing
# accounts database before the import
if ($REC_DELETED or $REC_CORRECTED)
{
    $readme .= "\n*** Before importing, ";
    if ($REC_DELETED > 0)
    {
	$readme .= "$REC_DELETED transaction";
	$readme .= $REC_DELETED > 1 ? "s have" : " has";
	$readme .= " been deleted";

	$readme .= " and " if $REC_CORRECTED > 0;
    }
    if ($REC_CORRECTED > 0)
    {
	$readme .= "$REC_CORRECTED transaction";
	$readme .= $REC_CORRECTED > 1 ? "s have" : " has";
	$readme .= " been corrected";
    }
    $readme .= " in the existing accounts database.\n\n";
}


#($REC_DELETED, $REC_CORRECTED) = $PDBS{accounts}->validRecords;
## Some transactions have been deleted and/or corrected in the existing
## accounts database before the import
#if ($REC_DELETED or $REC_CORRECTED)
#{   
#    $readme .= "\n*** After importing, ";
#    if ($REC_DELETED > 0)
#    {
#        $readme .= "$REC_DELETED transaction";
#        $readme .= $REC_DELETED > 1 ? "s have" : " has";
#        $readme .= "been deleted";
#
#        $readme .= " and " if $REC_CORRECTED > 0;
#    }
#    if ($REC_CORRECTED > 0)
#    {
#        $readme .= "$REC_CORRECTED transaction";
#        $readme .= $REC_CORRECTED > 1 ? "s have" : " has";
#        $readme .= "been corrected";
#    }
#    $readme .= " in the resulting accounts database.\n\n";
#}

$PDBS{accounts}->sortRecords;


$readme .= <<EOFREADME;

Send me bug report at bug\@ma-tirelire.net

Enjoy,

Max.
EOFREADME

$readme = $ZIP->addString($readme, "$ZIP_DIR/README");
$readme->desiredCompressionMethod(COMPRESSION_DEFLATED);
$readme->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);

my $contents;

foreach my $file (qw(accounts modes types currencies))
{
    # Don't save the PDB in the archive if it is empty....
    if (@{$PDBS{$file}{records}} > 0)
    {
	$contents = '';

	$PDBS{$file}->Write(\$contents);

	# All chars before space + space will change in '_'
	(my $filename = $PDBS{$file}{name}) =~ tr/\000-\040/_/;

	$contents = $ZIP->addString($contents, "$ZIP_DIR/$filename.PDB");
	$contents->desiredCompressionMethod(COMPRESSION_DEFLATED);
	$contents->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);

	delete $PDBS{$file};	# free memory...
    }
}


########################################################################
#
# We can send the archive
#
########################################################################
my $filename = 'MaTirelire2-import.zip';

open(my $fh, '>', \$contents);

$ZIP->writeToFileHandle($fh, 0);

close $fh;

die "Too many warnings, contact "
    . "<a href=\"mailto:bug\@Ma-Tirelire.net\">bug\@Ma-Tirelire.net</a> "
    . "to report them\n"
    if @WARN;

if ($query->cgi)
{
    print $query->header('-Content-Length' => length $contents,
			 -type => 'application/x-zip-compressed',
			 '-Content-Disposition'
			 => ($query->user_agent('MSIE [56]')
			     ? "inline; filename=$filename"
			     : "attachment; filename=$filename"));

    print $contents;
}
else
{
    my $output = $query->param('output') || $filename;

    open(OUTPUT, '>', $output) || die "Can't open $output for writing: $!\n";
    print OUTPUT $contents;
    close OUTPUT;

    if ($query->param('save_conf'))
    {
	$query->saveCliArgs($query->param('save_conf'));
    }
}
