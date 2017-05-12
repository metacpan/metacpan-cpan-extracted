#!/usr/local/bin/perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../Parse-Binary/lib";

use strict;
use DBI;
use DBD::SQLite;
use Data::Dumper;
use Parse::AFP;
use Getopt::Long;
use File::Glob 'bsd_glob';

my %CodePages = (
    947 => {
        FillChar => "\xA1\x40",
        FirstChar => "\xA4\x40",
        CharPattern => qr{
            (
                [\x81-\xA0\xC7-\xC8\xFA-\xFE].      # UDC range 1
                |
                \xC6[\xA1-\xFE]                     # UDC range 2
            )
            |
            ([\x00-\x7f])                           # Single Byte
            |
            (..)                                    # Double Byte
        }x,
        NoUDC => qr{^
            (?:
                [\x00-\x7f]+
            |
                (?:[\xA1-\xC5\xC9-\xF9].)+
            |
                (?:\xC6[^\xA1-\xFE])+
            )*
        $}x,
    },
    835 => {
        FillChar => "\x40\x40",
        FirstChar => "\x4C\x41",
        CharPattern => qr{
            ([\x92-\xFE].)                          # UDC
            |
            ((?!))                                  # Single Byte
            |
            ([\x40-\x91].)                          # Double Byte
        }x,
        NeedDBCSPattern => 1,
        NoUDC => qr{^[^\x92-\xFE]*$}x,
    },
);

my ($dbcs_pattern, @db);
my $codepage    = 947;
my $dir         = 'udcdir';
my $adjust;

our $input;
our $output = 'fixed.afp';

GetOptions(
    'i|input:s'         => \$input,
    'f|fontdb:s@'       => \@db,
    'o|output:s'        => \$output,
    'u|udcdir:s'        => \$dir,
    'd|dbcs-pattern:s'  => \$dbcs_pattern,
    'c|codepage:i'      => \$codepage,
    'a|adjust'          => \$adjust,
);

$input ||= shift;
@db = sort grep /\.f?db$/i, map { (-d $_) ? bsd_glob("$_/*") : $_ } (@db ? @db : 'fonts.db');

die "Usage: $0 [-a] [-c 947|835] -d dbcs_pattern -i input.afp -o output.afp -f fonts.db\n"
    if !@db or grep !defined, $input, $output;

$CodePages{$codepage} or die "Unknown codepage: $codepage";

our ($FillChar, $FirstChar, $CharPattern, $NeedDBCSPattern, $NoUDC)
    = @{$CodePages{$codepage}}{qw( FillChar FirstChar CharPattern NeedDBCSPattern NoUDC )};

die "Need DBCS Pattern with -d for this codepage"
    if $NeedDBCSPattern and !$dbcs_pattern;

my (%FontToId, %IdToFont);

##########################################################################

no warnings qw(once numeric);

my %errors;
my $db = shift(@db);
die "No such database: $db" unless -e $db;
my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$db", '', '', {
        PrintError => 0,
        HandleError => sub { $errors{$_[0]}++ },
    }
) or die $DBI::errstr;
my $fonts = $dbh->selectall_hashref("SELECT * FROM Fonts", 'FontName') or die $dbh->errstr;

foreach my $idx (0..$#db) {
    my $filename = $dbh->quote($db[$idx]);
    $dbh->do("ATTACH DATABASE $filename AS DB$idx") or die $dbh->errstr;
    my $more_fonts = $dbh->selectall_hashref("SELECT * FROM Fonts", 'FontName') or die $dbh->errstr;
    %$fonts = (%$fonts, %$more_fonts);
}

##########################################################################

# SPLIT!
#
udcsplit::run();

##########################################################################

sub udc4pca {
    my ($in, $out) = @_;
    my $afp = Parse::AFP->new($in, {lazy => 1, output_file => $out});
    $afp->callback_members([qw( MCF1 MCF PGD PTX EMO EPG * )]);
}

##########################################################################

my @UDC;
sub __ {
    $_[0]->done;
}

my ($x, $y);
my ($XUnit, $YUnit, $XPageSize, $YPageSize);
sub PGD {
    my $rec = shift;
    $XUnit = $rec->XLUnitsperUnitBase;
    $YUnit = $rec->YLUnitsperUnitBase;
    $XPageSize = $rec->XPageSize;
    $YPageSize = $rec->YPageSize;
    $rec->done;
    $x = $y = 0;
}

sub MCF1 {
    my $rec = shift;
    my $font_e = substr($rec->CodedFontName, 2, 4);
    my $font_eid = $rec->CodedFontLocalId;
    $FontToId{$font_e} = $font_eid;
    $IdToFont{$font_eid} = $font_e;
    $rec->done;
}

sub MCF {
    my $rec = shift;
    $rec->callback_members(['MCF::DataGroup']);
    $rec->done;
}

sub MCF_DataGroup {
    my $data_group = shift;
    $data_group->callback_members(['Triplet::FQN', 'Triplet::RLI']);
}

{
my $font_e;

sub Triplet_FQN {
    my $fqn = shift;
    $font_e = $fqn->Data;
}

sub Triplet_RLI {
    my $rli = shift;
    my $font_eid = $rli->Data;
    $FontToId{$font_e} = $font_eid;
    $IdToFont{$font_eid} = $font_e;
}
}

sub PTX {
    my ($rec, $buf) = @_;
    my $font_eid;

    # Now iterate over $$buf.
    my $pos = 11;
    my $len = length($$buf);

    while ($pos < $len) {
        my ($size, $code) = unpack("x${pos}CC", $$buf);
        $size or do {
            open my $fh, '>:raw', 'buf.afp';
            print $fh $$buf;
            close $fh;
            die "Incorrect parsing: $pos\n";
        };

        if ($code == 0xDA or $code == 0xDB) {
            if (substr($$buf, $pos + 2, $size - 2) !~ $NoUDC) {
                $rec->callback_members([map "PTX::$_", qw(
                    SIM SBI STO SCFL AMI AMB RMI RMB BLN TRN
                )], \$font_eid);
                $rec->refresh;
                last;
            }
        }

        $pos += $size;
    }

    $rec->done;
}

sub PTX_AMI {
    my $rec = shift;
    $x = $rec->Data;
}

sub PTX_AMB {
    my $rec = shift;
    $y = $rec->Data;
}

sub PTX_RMI {
    my $rec = shift;
    $x += $rec->Data;
}

sub PTX_RMB {
    my $rec = shift;
    $y += $rec->Data;
}

my $InlineMargin;
sub PTX_SIM {
    my $rec = shift;
    $InlineMargin = $rec->Data;
}

my $BaselineIncrement;
sub PTX_SBI {
    my $rec = shift;
    $BaselineIncrement = $rec->Data;
}

sub PTX_BLN {
    my $rec = shift;
    $x = $InlineMargin;
    $y += $BaselineIncrement;
}

my ($XOrientation, $YOrientation);
sub PTX_STO {
    my $rec = shift;
    $XOrientation = $rec->Orientation;
    $YOrientation = $rec->WrapDirection;
}

sub PTX_SCFL {
    my ($dat, $font_ref) = @_;
    $$font_ref = $dat->Data;
}

my %Increment;
sub PTX_TRN {
    my ($dat, $font_ref) = @_;

    my $font_eid = $$font_ref;
    my $font_name = $IdToFont{$font_eid};
    $font_name =~ s/^X\d/X0/;

    my $string = $dat->Data;
    my $data = '';

    # if $font_name is single byte...
    # simply add increments together without parsing UDC
    if ($dbcs_pattern and $font_name !~ /$dbcs_pattern/o) {
        $Increment{$font_name} ||= { @{
            $dbh->selectcol_arrayref(
            "SELECT Character, Increment FROM $font_name",
            { Columns=>[1, 2] }
        ) || [] } };
        $x += $Increment{$font_name}{$_}
            or die "Cannot find char ".unpack('(H2)*', $_)." in $font_name"
                foreach split(//, $string);
        return;
    }

    # my $dbcs_space_char = "\xFA\x40";

    while ($string =~ /$CharPattern/go) {
        # ... calculate position, add to fonts to write ...
        if ( $1 || $3 ) {
	    $Increment{$font_name} ||= { @{
		$dbh->selectcol_arrayref(
		"SELECT Character, Increment FROM $font_name",
		{ Columns => [1, 2] }
	    ) || [] } };
	}

	if (defined $1) {
            push @UDC, {
                X => $x,
                Y => $y,
                Character => $1,
                FontName => $font_name
            };
            $data .= $FillChar;
	    $x += $Increment{$font_name}{$1};
	}
	elsif (defined $2) {
	    # single byte
	    $Increment{$font_name} ||= { @{
		$dbh->selectcol_arrayref(
		"SELECT Character, Increment FROM $font_name",
		{ Columns=>[1, 2] }
	    ) || [] } };
	    $x += $Increment{$font_name}{$2}
	      or die "Cannot find char ".unpack('(H2)*', $2)." in $font_name";
	    $data .= $2;
  	    #print $font_name, "=", $x, "\n";
	}
	else {
	    $data .= $3;
	    $x += $Increment{$font_name}{$3} || $Increment{$font_name}{$FirstChar};
	}
    }
    $dat->{struct}{Data} = $data;
}

BEGIN { *EMO = *EPG; }

sub EPG {
    my $rec = shift;

    if (!@UDC) {
	$rec->done;
	return;
    }

    # ... write out the actual BII..IOC..IID..ICP..IRD..EII images ...
    #print "Writing out Bitmap...\n" if @UDC;

    # Construct: 
    $rec->spawn_obj(
	Class => 'BII',
	Data  => 'UDCImage',
    )->write;

    $rec->spawn_obj(
	Class => 'IOC',
	ConstantData1 => ("00" x 8),
	ConstantData2 => ("FF" x 2),
	Reserved1 => '00',
	Reserved2 => '00',
	XMap => '03e8',
	XOffset => 0,
	XOrientation => $XOrientation,
	YMap => '03e8',
	YOffset => 0,
	YOrientation => $YOrientation,
    )->write;

    my %res = @{$dbh->selectcol_arrayref(
        "SELECT FontName, Resolution FROM Fonts", { Columns => [1,2] }
    )};
    my $name = $UDC[0]{FontName};
    $name =~ s/\s//g;
    my $res = $res{$name};

    $rec->spawn_obj(
	Class => 'IID',
	Color => '0008',
	ConstantData1 => '000009600960000000000000',
	ConstantData2 => '000000002D00',
	ConstantData3 => '00',
	XBase => '00',
	XCellSizeDefault => 0,
	XSize => 0,
	XUnits => $res,
	YBase => '00',
	YCellSizeDefault => 0,
	YSize => 0,
	YUnits => $res,
    )->write;

    foreach my $char (@UDC) {
	my $sth = $dbh->prepare("SELECT * FROM $char->{FontName} WHERE Character = ?") or next;
	$sth->execute($char->{Character});

	my $row = $sth->fetchrow_hashref or next;

	my ($X, $Y) = @{$char}{qw( X Y )};
	$X += $row->{ASpace};

	my $oset = $row->{BaseOffset};
	$oset = int($oset * 3 / 4) if $adjust;
	$Y -= $oset;

	if ($YOrientation eq '5a00') {
	    ($X, $Y) = ($XPageSize - $Y, $X);
	}

	$rec->spawn_obj(
	    Class => 'ICP',
	    XCellOffset => $X,
	    XCellSize => $row->{Width},
	    XFillSize => $row->{Width},
	    YCellOffset => $Y,
	    YCellSize => $row->{Height},
	    YFillSize => $row->{Height},
	)->write;
	$rec->spawn_obj(
	    Class => 'IRD',
	    ImageData => $row->{Bitmap},
	)->write;
    }

    $rec->spawn_obj(
	Class => 'EII',
	Data  => 'UDCImage',
    )->write;

    @UDC = ();
    $rec->done;
}

1;

package udcsplit;

my ($has_udc, $name, $prev, $has_BNG, $PTX_cnt);
my ($itmp, $otmp, $ifh, $ofh, $ipos, $opos);

use strict;

sub run {
    *Parse::AFP::Record::new = sub {
        my ($self, $buf, $attr) = @_;
        if (substr($$buf, 3, 3) eq "\xD3\xEE\x9B") { return bless($buf, 'PTX'); }
#        if (substr($$buf, 3, 3) eq "\xD3\xA8\xAD") { return bless($buf, 'BNG'); }
        if (substr($$buf, 3, 3) eq "\xD3\xA8\xAF") { return bless($buf, 'BPG'); }
        if (substr($$buf, 3, 3) eq "\xD3\xA8\xDF") { return bless($buf, 'BMO'); }
        return $self->Parse::Binary::new($buf, $attr);
    };

    *PTX::done = sub { return };
    *BPG::done = sub { return };
    *BMO::done = sub { return };
    *PTX::callback = sub { udcsplit::PTX($_[0]) };
    *BPG::callback = sub { udcsplit::BPG($_[0]) };
    *BMO::callback = sub { udcsplit::BMO($_[0]) };

    $name = $prev = 0;
    $ipos = $opos = 0;
    ($itmp, $otmp) = ("input-$$.afp", "output-$$.afp");

    my $afp = Parse::AFP->new($main::input, { lazy => 1, output_file => $main::output });
    ($ifh, $ofh) = @{$afp}{qw( input output )};

    $afp->callback_members([qw( BMO BPG PTX * )]);
    begin_page(0);
}

sub begin_page {
    $prev = $name; $name++;

    my $pos = tell($ifh) - $_[0];
    udc4pca($pos) if $has_udc;
    $has_udc = 0;

    $ipos = $pos;
    $opos = tell($ofh);
#    print "ipos is now $ipos; opos is now $opos\n";
}

sub udc4pca {
    if (my $pid = fork) {
        waitpid($pid, 0);
        ($? == 0) or die $?;
        print STDERR '.';
    }
    else {
        close $ifh;
        close $ofh;

        my $size = ($_[0] - $ipos);

        open my $nfh, '<:raw', $main::input or die $!;
        seek $nfh, $ipos, 0;

        open my $fh, '>:raw', $itmp or die $!;

        {
            local $/ = \$size;
            print $fh scalar <$nfh>;
        }
        close $fh;

        no warnings 'redefine';
        *Parse::AFP::Record::new = \&Parse::Binary::new;
        undef &PTX::callback;
        undef &PTX::done;

        main::udc4pca($itmp => $otmp);
        exit;
    }

    seek $ofh, $opos, 0;
    open my $fh, '<:raw', $otmp or die $!;
    local $/ = \32768;
    while (<$fh>) {
        print $ofh $_;
    }
    close $fh;

    unlink ("input-$$.afp", "output-$$.afp");
}

sub BNG {
    $has_BNG = 1;
    begin_page(length ${$_[0]});
    $_[0]->done;
}

BEGIN { *BMO = *BPG; }

sub BPG {
    begin_page(length ${$_[0]});
    $_[0]->done;
}

sub PTX {
    my $rec = my $buf = shift;

    return $rec->done if $has_udc;

    # Now iterate over $$buf.
    my $pos = 11;
    my $len = length($$buf);

    while ($pos < $len) {
        my ($size, $code) = unpack("x${pos}CC", $$buf);

        $size or do {
            open my $fh, '>:raw', 'buf.afp';
            print $fh $$buf;
            close $fh;
            die "Wrong parsing: $pos\n";
        };

        if ($code == 0xDA or $code == 0xDB) {
            if ( substr($$buf, $pos + 2, $size - 2) !~ /$main::NoUDC/o) {
                $has_udc = 1;
                last;
            }
        }

        $pos += $size;
    }

    $rec->done;
}

sub __ { $_[0]->done }

1;
