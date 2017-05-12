#!/usr/local/bin/perl -w
# 
# exportM2.pl -- 
# 
# Author          : Maxime Soulé
# Created On      : Thu May 26 22:05:17 2005
# Last Modified By: Maximum Solo
# Last Modified On: Sun Feb 12 09:48:02 2012
# Update Count    : 42
# Status          : Unknown, Use with caution!
#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

# 
# (cd html && cp export.html imexport.js /usr/local/www)
# cp exportM2.pl /usr/local/www/biz/export
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
# -accounts FILE	(Accounts database: MaTi=XXX.PDB)
# -modes FILE		(Payment modes database: MaTi-Modes.PDB)
# -types FILE		(Transactions types database: MaTi-Types.PDB)
# -currencies FILE	(Currencies database: MaTi-Currencies.PDB)
#
# -fields list,of,exported,fields,separated,by,comma
#   fields can be :
#     account		(Account name (can not be used for import))
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
# -export_types		(Add a file Type.cvs that contains types database
#			 need MaTi-Types.PDB)
#
# -col_sep CHAR		(Columns/fields separator char, typicaly ';' or 'tab')
# -eol TYPE		(End of line type: win, mac or unix)
# -time_fmt FORMAT	(Time format)
#   FORMAT can be:
#     0 for HH:MM am/pm
#     1 for H:MM
#     2 for HH.MM am/pm
#     3 for HH.MM
#     4 for HH,MM
#
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
# -dec_sep CHAR		(Decimal separator either , or .)
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
# exportM2.pl -accounts MaTi=Test.PDB -types MaTi-Types.PDB -fields unique_id,date,time,amount,splits -col_sep ';' -eol unix -time_fmt 1 -date_fmt 1 -dec_sep .
#


my %EOC_CHARS = ('tab' => "\t",
		 '"'   => ';');	# " is forbidden as col separator

my %EOL_CHARS = ('win'  => "\015\012",
		 'mac'  => "\015",
		 'unix' => "\012");

my @DATE_FMTS = ("%m/%d/%Y",
		 "%d/%m/%Y",
		 "%d.%m.%Y",
		 "%d-%m-%Y",
		 "%Y/%m/%d",
		 "%Y.%m.%d",
		 "%Y-%m-%d",
		 "%m-%d-%Y");

my @TIME_FMTS = ("%I:%M %p",
		 "%H:%M",
		 "%I:%M %p",
		 "%H.%M",
		 "%H,%M");

my @DECSEP_FMTS = (',', '.');

my($TIME_FMT, $DATE_FMT, $DECSEP, $COLSEP, $EOL);


my %PDBS;
my $REC_INDEX;


########################################################################
#
# Special fields management
#
########################################################################
sub field_date ($$$)
{
    my($rec, $is_account, $field) = @_;

    my $date = '';
    if ($is_account)
    {
	$date = $DATE_FMT;
	$date =~ s/%[dm]/00/g;
	$date =~ s/%Y/0000/g;
    }
    else
    {
	my($day, $month, $year);

	# Si le champ existe, le reste se trouve dessous
	if (exists $rec->{$field})
	{
	    ($day, $month, $year) = @{$rec->{$field}}{qw(day month year)};
	}
	elsif (exists $rec->{"${field}_day"})
	{
	    ($day, $month, $year) 
		= @{$rec}{map { "${field}_$_" } qw(day month year)};
	}

	if (defined $day)
	{
	    $date = POSIX::strftime($DATE_FMT,
				    0, 0, 0, $day, $month - 1, $year - 1900);

	    # Pour que excel le reconnaisse bien comme une date
	    $date =~ s/^0//;
	}
    }

    return $date;
}


sub field_time ($$$)
{
    my($rec, $is_account, $field) = @_;

    my $time = '';
    if ($is_account)
    {
	$time = $TIME_FMT;
	$time =~ s/%[IHM]/00/g;
	$time =~ s/\s*%p//g;
    }
    else
    {
	$time = POSIX::strftime($TIME_FMT, 0, 
				$rec->{"${field}_min"},
				$rec->{"${field}_hour"},
				1, 0, 70);
    }

    return $time;
}


sub field_amount ($$$)
{
    my($rec, $is_account, $field) = @_;

    my $amount;
    if (exists $rec->{$field})
    {
	$amount = sprintf("%.2f", $rec->{$field} / 100);
	substr($amount, -3, 1) = $DECSEP;
    }
    else
    {
	$amount = "0${DECSEP}00";
    }

    return $amount;
}


sub field_note ($$$)
{
    my($rec, $is_account, $field) = @_;

    return auto_encode($rec->{$field});
}


my %DBITEMID_CACHE;
sub field_dbitemid_fullname ($$$$)
{
    my($rec, $is_account, $field, $dbitemid) = @_;

    # Le cache n'existe pas encore
    if (not exists $DBITEMID_CACHE{$field})
    {
	$DBITEMID_CACHE{$dbitemid} = $PDBS{$dbitemid}->build_cache_id;
    }

    my $fullname = $PDBS{$dbitemid}->full_name($rec->{$field},
					       $DBITEMID_CACHE{$dbitemid});
    $fullname = $rec->{$field} if not defined $fullname;

    return auto_encode($fullname);
}


sub field_currency ($$$$)
{
    my($rec, $is_account, $field, $is_fullname) = @_;

    my($curr_id, $fullname);
    my @result;

    # Propriétés de compte
    if ($is_account)
    {
	# Juste la devise du compte
	$curr_id = $rec->{currency};
    }
    # Opération...
    else
    {
	return ('', '') unless exists $rec->{currency};

	# Devise + montant
	$curr_id = $rec->{currency}{currency};

	@result = (sprintf("%.2f", $rec->{currency}{currency_amount} / 100));
	substr($result[0], -3, 1) = $DECSEP;
    }

    if ($is_fullname)
    {
	# Le cache n'existe pas encore
	if (not exists $DBITEMID_CACHE{currencies})
	{
	    $DBITEMID_CACHE{currencies} = $PDBS{currencies}->build_cache_id;
	}

	$fullname = $PDBS{currencies}->full_name($curr_id,
						 $DBITEMID_CACHE{currencies});
	$fullname = $curr_id if not defined $fullname;
    }
    else
    {
	$fullname = $curr_id;
    }

    # Le nom de la devise doit venir en tête
    unshift(@result, auto_encode($fullname));

    return @result;
}


sub field_splits ($$$$)
{
    my($rec, $is_account, $field, $is_fullname) = @_;

    # Pour les sous-opérations, cas particulier : s'il n'y en a pas,
    # on ne renvoie aucune colonne
    return () unless exists $rec->{splits};

    # Le cache des types
    if ($is_fullname and not exists $DBITEMID_CACHE{types})
    {
	$DBITEMID_CACHE{types} = $PDBS{types}->build_cache_id;
    }

    my @ret;

    foreach my $ref_split (@{$rec->{splits}{list}})
    {
	# Le type
	my $type_name;
	if ($is_fullname)
	{
	    $type_name = $PDBS{types}->full_name($ref_split->{type},
						 $DBITEMID_CACHE{types});
	    $type_name = $ref_split->{type} if not defined $type_name;
	}
	else
	{
	    $type_name = $ref_split->{type};
	}

	my $amount = sprintf("%.2f", $ref_split->{amount} / 100);
	substr($amount, -3, 1) = $DECSEP;

	push(@ret, auto_encode($type_name),
	     $amount, auto_encode($ref_split->{desc}));
    }

    return @ret;
}


sub field_xfer_account ($$$)
{
    my($rec, $is_account, $field) = @_;

    if (exists $rec->{xfer})
    {
	my $account;

	if ($rec->{xfer_cat})
	{
	    $account = $rec->{xfer};
	}
	else
	{
	    my $link = $PDBS{accounts}->findRecordByID($rec->{xfer});
	    die "Record link for #$REC_INDEX not found\n" unless defined $link;

	    $account = $link->{category};
	}

	return 
	    auto_encode($PDBS{accounts}{appinfo}{categories}[$account]{name});
    }

    return '';
}


sub field_xfer_id ($$$)
{
    my($rec, $is_account, $field) = @_;

    if (exists $rec->{xfer} and not $rec->{xfer_cat})
    {
	return $rec->{xfer};
    }

    return '';
}


my @REPEAT_TYPES = ('monthly', 'monthly end', 'weekly');
sub field_repeat ($$$)
{
    my($rec, $is_account, $field) = @_;

    return ('', '', '') unless exists $rec->{repeat};

    my $end_date = '';

    if ($rec->{repeat}{end_date_day} > 0)
    {
	$end_date = POSIX::strftime($DATE_FMT, 0, 0, 0,
				    $rec->{repeat}{end_date_day},
				    $rec->{repeat}{end_date_month} - 1,
				    $rec->{repeat}{end_date_year} - 1900);

	# Pour que excel le reconnaisse bien comme une date
	$end_date =~ s/^0//;
    }

    return ($rec->{repeat}{repeat_type} >= @REPEAT_TYPES
	    ? 0 : $REPEAT_TYPES[$rec->{repeat}{repeat_type}],
	    $rec->{repeat}{repeat_freq}, 
	    $end_date);
}


sub field_rec_account ($$$)
{
    my($rec, $is_account, $field) = @_;

    return auto_encode($PDBS{accounts}{appinfo}{categories}
		       [$rec->{category}]{name});
}


# Chaque fonction reçoit les paramètres suivant dans l'ordre
# - $record
# - 0 si propriétés de compte, 1 si opération
# - nom du champ
my %FIELDS = (account	     => {
				  username =>'Account name',
				  str	   => \&field_rec_account,
				},
	      unique_id      => { 
				  str	   => 'id',
				  username =>'Internal ID (used by transfers)',
			        },
	      date	     => { str => \&field_date },
	      time	     => { str => \&field_time },
	      amount	     => { str => \&field_amount },
	      checked	     => {
				  str	   => 'checked',
				  username => 'Checked or not',
			        },
	      flagged	     => {
				  str	   => 'marked',
				  username => 'Flagged or not',
			        },
	      alarm	     => {
				  str_tr   => 'alarm',
				  username => 'Alarm or not',
				},
	      mode_idx	     => {
				  str_tr   => 'mode',
				  username => 'Mode (only index)',
				},
	      mode	     => {
				  needDB   => 'modes',
				  str_tr   => \&field_dbitemid_fullname,
				  params   => 'modes',
				  username => 'Mode (full name)',
				},
	      type_idx	     => {
				  str_tr   => 'type',
				  username => 'Type (only index)',
			        },
	      type	     => {
				  needDB   => 'types',
				  str_tr   => \&field_dbitemid_fullname,
				  params   => 'types',
				  username => 'Type (full name)',
				},
	      note	     => {
				  str	   => \&field_note,
				  username => 'Description',
				},
	      value_date     => {
				  str_tr   => \&field_date,
				  username => 'Validity date',
				},
	      cheque_num     => {
				  str_tr   => 'check_num',
				  username => 'Cheque number',
				},
	      repeat	     => {
				  str_tr   => \&field_repeat,
				  username => [ 'Repeat type',
						'Repeat frequency',
						'Reapeat end date' ],
				},
	      xfer_account   => {
				  str_tr   => \&field_xfer_account,
				  username => 'Transfer account',
				},
	      xfer_unique_id => {
				  str_tr   => \&field_xfer_id,
				  username => 'ID of linked transaction',
				},
	      statement_num  => {
				  str_tr   => 'stmt_num',
				  username => 'Statement number',
				},
	      currency_idx   => {
				  str	   => \&field_currency,
				  params   => 0, # Pas full name
				  username => [ 'Currency (only index)',
						'Amount in currency' ],
				},
	      currency	     => {
				  needDB   => 'currencies',
				  str	   => \&field_currency,
				  params   => 1, # Avec full name
				  username => [ 'Currency (full name)',
						'Amount in currency' ],
			        },
	      splits	     => {
				  needDB   => 'types',
				  str_tr   => \&field_splits,
				  params   => 1, # Avec full name
				  username => [ 'Split type full name',
						'Split amount',
						'Split description' ],
				},
	      splits_idx     => {
				  str_tr   => \&field_splits,
				  params   => 0, # Pas full name
				  username => [ 'Split type index',
						'Split amount',
						'Split description' ],
				},
	      # Colonne vide
	      empty	     => { 
				  str => \&field_null,
				  username => '',
				},
	      );

sub field_simple ($$$)
{
    my($rec, $is_account, $field) = @_;

    return defined($rec->{$field}) ? $rec->{$field} : '';
}


sub field_null ($$$)
{
    return '';
}


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
my $RECODE;
sub auto_encode ($;$)
{
    my($str, $undef_if_error) = @_;

    if (defined $RECODE)
    {
	unless ($RECODE->recode($str))
	{
	    return undef if $undef_if_error;

	    die "Can't convert encoding for record #$REC_INDEX: ",
		$RECODE->getError, "\n";
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
my \$from = Locale::Recode->resolveAlias('$charset_palm');
my \$to = Locale::Recode->resolveAlias('$charset_host');
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
# Load palm databases
#
########################################################################
my($REC_DELETED, $REC_CORRECTED);
foreach my $file (qw(accounts modes types currencies))
{
    if (defined $query->param($file) and $query->param($file) ne '')
    {
	my $fh = $query->upload($file);
	if (defined $fh)
	{
	    my $classname = 'Palm::MaTirelire::'
		. ($file eq 'accounts' ? 'AccountsV2' : ucfirst $file);
    
	    my($contents, $db);

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

	    $PDBS{$file} = $db;

	    if ($db->can('validRecords'))
	    {
		($REC_DELETED, $REC_CORRECTED) = $db->validRecords;
	    }

	    next;
	}

	if (my $error = $query->cgi_error)
	{
	    die "$error...\n";
	}
    }
}


#
# The accounts DB must exists AND be a M2 one
die "No accounts database sent...\n" unless exists $PDBS{accounts};

# We don't take care of duplicate columns
my @fields = grep { exists $FIELDS{$_} } split ',', $query->param('fields');
die "Too many fields selected.\n" if @fields > 30;


########################################################################
#
# Other parameters init
#
########################################################################
# Some databases have to be present
foreach my $field (@fields)
{
    if (exists $FIELDS{$field}{needDB})
    {
	my $dbname = $FIELDS{$field}{needDB};

	die "No $dbname database sent...\n" unless exists $PDBS{$dbname};
    }
}


# We want to export types database, but we don't have this database
if ($query->param('export_types') and not $PDBS{types})
{
    die "No types database sent, so can't export types...\n";
}


# Hour format
$TIME_FMT = $query->param('time_fmt');
if (not defined $TIME_FMT or $TIME_FMT !~ /^\d+\z/ or $TIME_FMT >= @TIME_FMTS)
{ $TIME_FMT = 0 }
$TIME_FMT = $TIME_FMTS[$TIME_FMT];

# Date format
$DATE_FMT = $query->param('date_fmt');
if (not defined $DATE_FMT or $DATE_FMT !~ /^\d+\z/ or $DATE_FMT >= @DATE_FMTS)
{ $DATE_FMT = 0 }
$DATE_FMT = $DATE_FMTS[$DATE_FMT];

# Decimal separator
$DECSEP = $query->param('dec_sep');
$DECSEP = '.' if not defined $DECSEP;
substr($DECSEP, 1) = '';	# Only one char allowed

# Column separator
$COLSEP = $query->param('col_sep');
$COLSEP = ';' if not defined $COLSEP;
$COLSEP = $EOC_CHARS{$COLSEP} if exists $EOC_CHARS{$COLSEP};
substr($COLSEP, 1) = '';	# Only one char allowed

# End of line
$EOL = $query->param('eol');
$EOL = 'win' if not defined $EOL or not exists $EOL_CHARS{$EOL};
$EOL = $EOL_CHARS{$EOL};

if ($EOL eq $COLSEP)
{
    die "The end-of-line can not be the same than the columns separator\n";
}


# We need one file per account
my @ACCOUNTS;

my $CSV = Text::CSV_XS->new({ eol => $EOL,
			      sep_char => $COLSEP,
			      binary => 1 });


########################################################################
#
# For each record...
#
########################################################################
$REC_INDEX = 0;
my $num_accounts = 0;
foreach my $rec (@{$PDBS{accounts}{records}})
{
    $REC_INDEX++;

    my $is_account = ($rec->{date_day} == 0 
		      && $rec->{date_month} == 0 && $rec->{date_year} == 0);
    my @line;

    # For each field
    foreach my $field (@fields)
    {
	my $ref_field = $FIELDS{$field};
	my $field_name = $field;
	my $sub;

	if (ref $ref_field)
	{
	    $sub = $FIELDS{$field}{$is_account ? 'str_acc' : 'str_tr'};
	    $sub = $FIELDS{$field}{str} unless defined $sub;

	    # No function found
	    unless (ref $sub)
	    {
		if (defined $sub)
		{
		    $field_name = $sub;
		    $sub = \&field_simple;
		}
		else
		{
		    $sub = \&field_null;
		}
	    }
	}
	else
	{
	    $field_name = $$ref_field;
	    $sub = \&field_simple;
	}

	my @params;
	if (exists $FIELDS{$field}{params})
	{
	    if (ref $FIELDS{$field}{params})
	    { @params = @{$FIELDS{$field}{params}} }
	    else
	    { @params = ($FIELDS{$field}{params}) }
	}

	push(@line, $sub->($rec, $is_account, $field_name, @params));
    }

    # The matching filehandle account
    my $fh_acc = $ACCOUNTS[$rec->{category}][1];
    unless (defined $fh_acc)
    {
	$fh_acc = IO::Handle->new;
	open($fh_acc, '>', \$ACCOUNTS[$rec->{category}][0]);

	$ACCOUNTS[$rec->{category}][1] = $fh_acc;

	$num_accounts++;

	my @headers;
	foreach my $field (@fields)
	{
	    if (exists $FIELDS{$field}{username})
	    {
		if (ref $FIELDS{$field}{username})
		{
		    push(@headers, @{$FIELDS{$field}{username}});
		}
		else
		{
		    push(@headers, $FIELDS{$field}{username});
		}
	    }
	    else
	    {
		push(@headers, ucfirst $field);
	    }
	}
	substr($headers[0], 0, 0) = '# '; # To flag the header line

	unless ($CSV->print($fh_acc, \@headers))
	{
	    die "Can't create account header\n";
	}
    }

    unless ($CSV->print($fh_acc, \@line))
    {
	die "Can't convert record #$REC_INDEX into a CSV line\n";
    }
}


########################################################################
#
# For each type
#
########################################################################
my $TYPES;
if ($query->param('export_types'))
{
    my $fh = IO::Handle->new;
    open($fh, '>', \$TYPES);

    my @columns = qw(type_id parent_id child_id brother_id
		     name only_in_account sign_depend folded);

    unless ($CSV->print($fh, [ '# Type index',
			       'Parent index',
			       'First child index',
			       'Next brother index',
			       'Type name',
			       'Only in account',
			       'Only for sign',
			       'Folded in M2' ]))
    {
	die "Can't create types header\n";
    }

    my $types_db = $PDBS{types};

    my $first_id = 0xff;
    my $rec;
    my($index, $loops);

    $loops = 0xff;

    # Search the first type
    for ($index = 0; $index < @{$types_db->{records}}; $index++)
    {
	$rec = $types_db->{records}[$index];

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

    my $ref_cache = $types_db->build_cache_id;

    $rec = $ref_cache->[$first_id];
    my $id;

    $REC_INDEX = 0;

    for (;;)
    {
	$REC_INDEX++;

	unless ($CSV->print($fh, [ map { auto_encode($_) } @{$rec}{@columns} ]))
	{
	    die "Can't convert type #$REC_INDEX into a CSV line\n";
	}

	# Type has a child
	$id = $rec->{child_id};
	goto load_and_continue if $id != 0xff;

	# Else type has a brother
      brother:
	$id = $rec->{brother_id};
	if ($id != 0xff)
	{
	    goto load_and_continue;
	}

	# Else, if the type has a parent => go to his brother OR his parent
	$id = $rec->{parent_id};
	if ($id != 0xff)
	{
	    $rec = $ref_cache->[$id];
	    goto brother;
	}

	# Else that's all folk...
	last;

      load_and_continue:
	$rec = $ref_cache->[$id];
    }

    if ($REC_INDEX != @{$types_db->{records}})
    {
	die("Not all types are chained, only $REC_INDEX on ",
	    scalar(@{$types_db->{records}}), "\n");
    }

    # Unfiled type
    unless ($CSV->print($fh, [ 0xff, 0xff, 0xff, 0xff, 'Unfiled', '', 3, 0 ]))
    {
	die "Can't convert unfiled type into a CSV line\n";
    }
}

undef $CSV;


########################################################################
#
# OK all the CSV files are ready, we can create the archive
#
########################################################################
my $ZIP = Archive::Zip->new();
my $ZIP_DIR = 'MaTirelire2-export';

$ZIP->addDirectory("$ZIP_DIR/");

my $readme = POSIX::strftime(<<EOFREADME, gmtime(time));
$num_accounts account@{[ $num_accounts > 1 ? 's' : ''
		       ]} exported at: $DATE_FMT $TIME_FMT UTC.

Exported fields are, from left to right:
EOFREADME

foreach my $field (@fields)
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

# Some transactions have been deleted and/or corrected before the export
if ($REC_DELETED or $REC_CORRECTED)
{
    $readme .= "\n*** Before exporting, ";
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
    $readme .= ".\n\n";
}

if (defined $TYPES)
{
}


$readme .= <<EOFREADME;

Send me bug report at bug\@ma-tirelire.net

Enjoy,

Max.
EOFREADME

$readme = $ZIP->addString($readme, "$ZIP_DIR/README");
$readme->desiredCompressionMethod(COMPRESSION_DEFLATED);
$readme->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);


for (my $account = 0; $account < @ACCOUNTS; $account++)
{
    if (defined $ACCOUNTS[$account][1])
    {
	$ACCOUNTS[$account][1]->close;
	undef $ACCOUNTS[$account][1];

	my $account_name;
	if (exists($PDBS{accounts}{appinfo}{categories}[$account]{name})
	    and $PDBS{accounts}{appinfo}{categories}[$account]{name} ne '')
	{
	    $account_name = auto_encode($PDBS{accounts}{appinfo}
					{categories}[$account]{name}, 1);
	}
	$account_name = "Account #$account" unless defined $account_name;

	# All chars before space + space will change in '_'
	$account_name =~ tr/\000-\040/_/;

	my $csv = $ZIP->addString($ACCOUNTS[$account][0],
				  "$ZIP_DIR/$account_name.csv");
	$csv->desiredCompressionMethod(COMPRESSION_DEFLATED);
	$csv->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);
    }
}


# We have to include types
if (defined $TYPES)
{
    $TYPES = $ZIP->addString($TYPES, "$ZIP_DIR/Types.csv");
    $TYPES->desiredCompressionMethod(COMPRESSION_DEFLATED);
    $TYPES->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);
}


########################################################################
#
# We can send the archive
#
########################################################################
my $filename = 'MaTirelire2-export.zip';
my $contents = '';

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
