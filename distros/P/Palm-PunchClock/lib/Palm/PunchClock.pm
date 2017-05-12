package Palm::PunchClock;

use strict;
use Palm::PDB;
use Palm::StdAppInfo;

use vars qw($VERSION @ISA $AUTOLOAD);

$VERSION = '1.2';
@ISA = qw( Palm::PDB Palm::StdAppInfo );

sub import {
    Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "PClk", "TIME" ] );
}

#my $pack = __PACKAGE__."::";
#
#sub AUTOLOAD {
#    my($self) = shift;
#    my(%data) = @_;
#
#    my($sub) = $AUTOLOAD;
#    $sub =~ s/$pack//;
#    printf "AUTOLOAD(%s) [%s]\n", $sub, join "] [", @_;
#
#    return \%data;
#}

sub ParseRecord {
    my($self) = shift;
    my(%rec) = @_;
    my($again) = 1;

    local $_ = $rec{data};

    $rec{data} = { };
    
    while ($again && $_) {
	if (/^\000/) {			# Unknown ???
	    #	    $rec{data}{HEX00} = unpack "xH2", 
	    substr $_, 0, 2, '';

	} elsif (/^\001/) {		# startdate MMDDYYYY
	    my($raw) = unpack "N", substr $_, 0, 4, '';

	    $rec{data}{month} = ($raw & 0xF00000) >> 20;
	    $rec{data}{day}   = ($raw & 0x0F8000) >> 15;
	    $rec{data}{year}  = ($raw & 0x007fff);
	    
	} elsif (/^\002/) {		# starttime
	    my($hour, $min) = unpack "xCC", substr $_, 0, 3, '';

	    $rec{data}{hour} = $hour;
	    $rec{data}{min} = $min;

	} elsif (/^\005/) {		# duration in seconds
	    my($duration) = unpack "xN", substr $_, 0, 5, '';
	    
	    $rec{data}{duration} = $duration/60;
	    
	} elsif (/^\006/) {		# Zero terminated note
	    my($note) = unpack "xZ*", $_;
	    substr $_, 0, 2+length $note, '';

	    $rec{data}{note} = $note;

	} else {
	    warn "unknown data!";
	    $again = 0;
	}
    }

    return \%rec;
}

sub ParseAppInfoBlock {
    my($self) = shift;
    my($data) = @_;
    my($appinfo) = Palm::StdAppInfo::ParseAppInfoBlock($self, $data);

    substr $data, 0, $Palm::StdAppInfo::stdAppInfoSize, '';

#    $appinfo->{DATA} = $data if $data;

    return $appinfo;
}

1;
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Palm::PunchClock - Perl extension for parsing PunchClock pdb files

=head1 SYNOPSIS

  use Palm::PDB
  use Palm::PunchClock;

  $pdb = new Palm::PDB;
  $pdb->Load("PC_Div-PClk.PDB");

=head1 DESCRIPTION

The Palm::PunchClock module does an attempt to parse PuchClock pdb
files. PunchClock is a timemanagement program for PalmOS written by
Psync, Inc.

=head1 BUGS

Since this module was written in a few hours with no knowlegde of
PunchClocks internal format I have only guessed at the format, thus it
only parses the most vital data. Categories and such is ignored :-)

=head1 AUTHOR

Peder Stray <pederst@cpan.org>

PunchClock is written by Psync, Inc. http://www.psync.com/

=head1 SEE ALSO

perl(1), Palm::PDB(3).

=cut
