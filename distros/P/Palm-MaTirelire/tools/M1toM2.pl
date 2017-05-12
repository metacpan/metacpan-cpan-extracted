#!/usr/local/bin/perl -w
# 
# M1toM2.pl -- 
# 
# Author          : Maxime Soule
# Created On      : Mon Jan 24 16:43:05 2005
# Last Modified By: Maxime Soule
# Last Modified On: Thu Jan 27 10:25:22 2005
# Update Count    : 10
# Status          : Unknown, Use with caution!
#

use 5.008_000;

use strict;

# *** For DEBUG ONLY ***
use lib qw(p5-Palm-MaTirelire/lib);

use Archive::Zip qw(:CONSTANTS);

use Palm::MaTirelire::AccountsV1;
use Palm::MaTirelire::SavedPreferences;

use Palm::MaTirelire::AccountsV2;
use Palm::MaTirelire::Descriptions;
use Palm::MaTirelire::Modes;
use Palm::MaTirelire::Types;

$Palm::BlockPack::VERBOSE = 0;


my $ACCOUNTS_V1;
my($PREFS, $DESC, $MODES, $TYPES);

my($num_accounts, $num_transactions, $num_desc, $num_modes, $num_types) 
    = (0) x 5;

my @contents;

my $query;

# We are in the CGI
if (exists $ENV{SERVER_NAME})
{
    eval <<'EOFCGI';
use CGI qw(-private_tempfiles);

    $CGI::POST_MAX = 300 * 1024; # 300 Ko max (moi le 30/1/2004 c'est 59+15)

    $query = new CGI;
EOFCGI

    my $contents;

    my @WARN;
    $SIG{__WARN__} = sub { push(@WARN, join('', @_)) };
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

    for my $idx (1 .. 2)
    {
	if (defined $query->param("pdb$idx") and $query->param("pdb$idx") ne'')
	{
	    my $fh = $query->upload("pdb$idx");
	    if (defined $fh)
	    {
		my $contents;

		while (defined(my $line = <$fh>))
		{
		    $contents .= $line;
		}

		push(@contents, $contents);

		next;
	    }
	}

	if (my $error = $query->cgi_error)
	{
	    die "$error...\n";
	}
    }

    if (@contents == 0)
    {
	die "No database sent...\n";
    }
}
# We are launched from shell...
else
{
    local $/ = undef;

    die "usage: $0 'MaTirelire Data.pdb' ['Saved Preferences.prc']\n"
	unless @ARGV == 1 or @ARGV == 2;

    my $contents;
    foreach my $filename (@ARGV)
    {
	open(FILE, '<', $filename) or die "Can't open $filename: $!\n";
	push(@contents, <FILE>);
	close FILE;
    }
}


#
# Load PDB contents
{
    my @DBS;
    while (@contents > 0)
    {
	my $db = new Palm::PDB;

	$db->Load(\$contents[0]);

	push(@DBS, $db);

	shift @contents;
    }


    #
    # Organize
    if ($DBS[0]->isa('Palm::MaTirelire::AccountsV1'))
    {
	$ACCOUNTS_V1 = $DBS[0];

	if (@DBS > 1)
	{
	    if ($DBS[1]->isa('Palm::MaTirelire::SavedPreferences'))
	    {
		$PREFS = $DBS[1];
	    }
	    else
	    {
		die "Saved Preferences not found\n";
	    }
	}
    }
    elsif (@DBS > 1 and $DBS[1]->isa('Palm::MaTirelire::AccountsV1'))
    {
	$ACCOUNTS_V1 = $DBS[1];

	if ($DBS[0]->isa('Palm::MaTirelire::SavedPreferences'))
	{
	    $PREFS = $DBS[0];
	}
	else
	{
	    die "Saved Preferences not found\n";
	}
    }
    else
    {
	die "V1 accounts not found...\n";
    }
}


#
# Check and correct V1 Accounts contents before continuing
my($v1_deleted, $v1_corrected) = $ACCOUNTS_V1->validRecords;


#
# Prepare output PDBs
my $ACCOUNTS_V2 = Palm::MaTirelire::AccountsV2->new;

$ACCOUNTS_V2->{name} = 'MaTi=Accounts M1-2';

# One give us a preferences database
if (defined $PREFS)
{
    $DESC  = Palm::MaTirelire::Descriptions->new;
    $MODES = Palm::MaTirelire::Modes->new;
    $TYPES = Palm::MaTirelire::Types->new;

    #
    # Preferences...
    my($prefs_v1, $prefs_v2, $add_v2);
    foreach my $res (@{$PREFS->{resources}})
    {
	if ($res->{type} eq 'MaTi')
	{
	    $prefs_v1 = $res->{data};
	    last if defined $prefs_v2;
	}

	if ($res->{type} eq 'MaT2')
	{
	    $prefs_v2 = $res->{data};
	    last if defined $prefs_v1;
	}
    }

    die "V1 preferences not found\n" unless defined $prefs_v1;

    # No M2 preferences found
    unless (defined $prefs_v2)
    {
	$prefs_v2 = {};
	$add_v2 = 1;
    }

    $prefs_v2->{last_db} = $ACCOUNTS_V2->{name};
    $prefs_v2->{first_form} = 2; # Transactions list screen

    # Convert preferences
    foreach my $key (qw(replace_desc updown_action time_select3 left_handed
			timeout remove_type)) # access_code))
    {
	$prefs_v2->{$key} = $prefs_v1->{$key};
    }

    # M2 preferences don't exist, we have to add them...
    if ($add_v2)
    {
	my $new_res = $PREFS->new_Resource;

	$new_res->{type} = 'MaT2';
	$new_res->{data} = $prefs_v2;

	$PREFS->append_Resource($new_res);
    }

    # Descriptions
    foreach my $desc (@{$prefs_v1->{descriptions}})
    {
	my $rec = $DESC->new_Record;

	my($name, $macro, $sign, $amount, $mode, $type, $xfer)
	    = ($desc =~ /^(.*?)
			  (?:\ ?\((([-+]?)
			           (\d*\.?\d*)
			           (?:;([^;)]*)
			              (?:;([^;)]*)
				         (?:;([^;)]*))?
				         )?
			              )?
			          )\)\s*)?\z/sx);

	# A macro is present
	if (defined $macro and $macro ne '')
	{
	    # Amount sign
	    if ($sign eq '-')
	    { $rec->{sign} = 1 }
	    elsif ($sign eq '+')
	    { $rec->{sign} = 2 }

	    # Mode
	    if (defined $mode and $mode ne '')
	    {
		if ($mode =~ s/\*\z//)
		{
		    $rec->{cheque_num} = 1;
		}

		for (my $index = 0; $index < @{$prefs_v1->{modes}}; $index++)
		{
		    if ($prefs_v1->{modes}[$index] =~ /^$mode/i)
		    {
			$rec->{is_mode} = 1;
			$rec->{mode} = $index;
			last;
		    }
		}
	    }

	    # Type
	    if (defined $type and $type ne '')
	    {
		for (my $index = 0; $index < @{$prefs_v1->{types}}; $index++)
		{
		    if ($prefs_v1->{types}[$index] =~ /^$type/i)
		    {
			$rec->{is_type} = 1;
			$rec->{type} = $index;
			last;
		    }
		}
	    }

	    # Amount
	    if (defined $amount and $amount ne '')
	    {
		$rec->{amount} = $amount;
	    }

	    # Xfer account
	    if (defined $xfer and $xfer ne '')
	    {
		foreach my $ref_account(@{$ACCOUNTS_V1->{appinfo}{categories}})
		{
		    if ($ref_account->{name} =~ /^$xfer/i)
		    {
			$rec->{xfer} = $ref_account->{name};
			last;
		    }
		}
	    }
	}

	if ($name =~ s/\^(.)// or $name =~ s/\~(.)/$1/)
	{
	    $rec->{shortcut} = ord $1;
	}

	$rec->{name} = $name;

	$DESC->append_Record($rec);
	$num_desc++;
    }

    my $id;

    # Modes
    $id = 0;
    foreach my $mode (@{$prefs_v1->{modes}})
    {
	my $rec = $MODES->new_Record;

	my $name = $mode;

	$rec->{mode_id} = $id;

	if ($name =~ s/\s+\((?:\+(\d{1,2})|(\d{1,2})([-=])(\d{1,2}))\)\z//)
	{
	    # (+X)
	    if (defined $1)
	    {
		$rec->{value_date} = 3;

		$rec->{first_val} = $1;
	    }
	    # (XX-YY) ou (XX=YY)
	    else
	    {
		$rec->{value_date} = ($3 eq '-') ? 2 : 1;

		$rec->{first_val} = $2;
		$rec->{debit_date} = $4;
	    }
	}

	$rec->{cheque_auto} = 1 if $name =~ s/\s*\*\z//;

	$rec->{name} = $name;

	$MODES->append_Record($rec);
	$num_modes++;

	$id++;
    }

    # Types
    $id = 0;
    foreach my $type (@{$prefs_v1->{types}})
    {
	my $rec = $TYPES->new_Record;

	$rec->{type_id} = $id;
	$rec->{brother_id}= ($id == $#{$prefs_v1->{types}}) ? 0xff : ($id + 1);

	$rec->{name} = $type;

	$TYPES->append_Record($rec);
	$num_types++;

	$id++;
    }

    # Keep database preferences items
    foreach my $key (qw(cur_category
			remove_type check_locked repeat_startup
			repeat_days sum_date sum_todayplus))
    {
	$ACCOUNTS_V2->{appinfo}{$key} = $prefs_v1->{$key};
    }
}


#
# For each V1 account, create a V2 one with its properties
my $index = 0;
foreach my $ref_account (@{$ACCOUNTS_V1->{appinfo}{categories}})
{
    if (defined $ref_account->{name} and $ref_account->{name} ne '')
    {
	my $ref_v2 = $ACCOUNTS_V2->{appinfo}{categories}[$index];

	$ref_v2->{name} = $ref_account->{name};
	$ref_v2->{id} = $ref_account->{id};

	# Create account properties...
	my $account_prop = $ACCOUNTS_V2->new_AccountProperties;

	$account_prop->{category} = $index;

	$ACCOUNTS_V2->append_Record($account_prop);
	$num_accounts++;
    }

    $index++;
}


#
# For each V1 transaction, create a V2 one
{
    my %xfer_ids;
    foreach my $v1_rec (@{$ACCOUNTS_V1->{records}})
    {
	my $v2_rec = $ACCOUNTS_V2->new_Record;

	# Compute uniqueID now...
	$ACCOUNTS_V2->_setUniqueID($v2_rec);

	foreach my $key (qw(category
			    date_day date_month date_year
			    time_hour time_min
			    amount
			    checked marked alarm
			    check_num
			    ))
	{
	    $v2_rec->{$key} = $v1_rec->{$key};
	}

	# Description/note
	$v2_rec->{note} = $v1_rec->{description};

	# Mode...
	if ($v1_rec->{mode} == Palm::MaTirelire::AccountsV1::UNKNOWN_MODE)
	{
	    $v2_rec->{mode} = Palm::MaTirelire::AccountsV2::UNKNOWN_MODE;
	}
	else
	{
	    $v2_rec->{mode} = $v1_rec->{mode};
	}

	# Type
	if ($v1_rec->{type} == Palm::MaTirelire::AccountsV1::UNKNOWN_TYPE)
	{
	    $v2_rec->{type} = Palm::MaTirelire::AccountsV2::UNKNOWN_TYPE;
	}
	else
	{
	    $v2_rec->{type} = $v1_rec->{type};
	}

	# Repeat option
	if ($v1_rec->{repeat})
	{
	    $v2_rec->{repeat} = {};

	    foreach my $key (qw(repeat_type repeat_freq))
	    {
		$v2_rec->{repeat}{$key} = $v1_rec->{repeat}{$key};
	    }
	}

	# Transfer
	if ($v1_rec->{xfer})
	{
	    if ($v1_rec->{xfer_cat})
	    {
		$v2_rec->{xfer_cat} = 1;
	    }
	    else
	    {
		$xfer_ids{$v1_rec->{id}} = $v2_rec->{id};
	    }

	    $v2_rec->{xfer} = $v1_rec->{xfer};
	}

	# Value date
	if ($v1_rec->{value_date})
	{
	    $v2_rec->{value_date} = { %{$v1_rec->{value_date}} };
	}

	$ACCOUNTS_V2->append_Record($v2_rec);
	$num_transactions++;
    }


    #
    # Second pass to solve transfer IDs
    foreach my $rec (@{$ACCOUNTS_V2->{records}})
    {
	if ($rec->{xfer} and not $rec->{xfer_cat})
	{
	    $rec->{xfer} = $xfer_ids{$rec->{xfer}};
	}
    }
}
undef $ACCOUNTS_V1;


#
# Sort V2 records
$ACCOUNTS_V2->sortRecords;


#
# Zip the V2 database with the new preferences database if present
my $zip = Archive::Zip->new();

$zip->addDirectory('MaTirelire2/');


#
# README file...
my $readme = $zip->addString(<<EOFREADME, 'MaTirelire2/README');
*********** WARNING ***********
Ma Tirelire 2 is a beta version
   USE IT AT YOUR OWN RISKS
*********** WARNING ***********

You can find the last version of Ma Tirelire 2 beta version at
http://ma-tirelire.net/beta

First, install the last beta of Ma Tirelire 2:

  - MaTirelire2-bXXXX-en.prc file for the english version;
  - MaTirelire2-bXXXX-fr.prc file for the french version.

@{[ $PREFS ?
"Next, install the PDB and PRC files present in this ZIP file on
your device (prefer the emulator or simulator for a first try).

The `Saved_Preferences.prc' file was modified to add
Ma Tirelire 2 preferences created from Ma Tirelire 1 ones.
Preferences of other applications (including Ma Tirelire 1 ones)
remain untouched.

You are not obliged to install this file if you don't trust,
Ma Tirelire 2 install its preferences automaticaly with default
values when they do not exists at startup." 
:
"Next, install the PDB file present in this ZIP file on your
device (prefer the emulator or simulator for a first try)." ]}

Once, you can launch Ma Tirelire 2, all your V1 accounts were
imported.

Send me bug report at bug\@ma-tirelire.net

Enjoy,

Max.

Conversion summary
------------------
$num_accounts V2 account(s) created
$num_transactions V2 transaction(s) created
@{[ $PREFS ? "
$num_desc V2 description(s)/macro(s) created
$num_modes V2 payment mode(s) created
$num_types V2 transaction type(s) created
" : "" ]}
$v1_deleted V1 invalid transactions deleted (so not converted)
$v1_corrected V1 invalid transactions corrected (before conversion)
EOFREADME

$readme->desiredCompressionMethod(COMPRESSION_DEFLATED);
$readme->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);


my $DB = '';

#
# Create in memory V2 database
foreach my $pdb ($ACCOUNTS_V2, $PREFS, $DESC, $MODES, $TYPES)
{
    if (defined $pdb)
    {
	$DB = '';
	$pdb->Write(\$DB);

	(my $name = $pdb->{name}) =~ tr/ /_/;

	my $ext = $pdb->{attributes}{resource} ? 'prc' : 'pdb';

	$pdb = $zip->addString($DB, "MaTirelire2/$name.$ext");
	$pdb->desiredCompressionMethod(COMPRESSION_DEFLATED);
	$pdb->desiredCompressionLevel(COMPRESSION_LEVEL_FASTEST);
    }
}
undef $DB;


my $filename = 'MaTirelire-1-2.zip';

if ($query)
{
    my $contents = '';

    open(my $fh, '>', \$contents);

    $zip->writeToFileHandle($fh, 0);

    close $fh;

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
    $zip->writeToFileNamed($filename);
}
