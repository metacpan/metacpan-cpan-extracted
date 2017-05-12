#!/usr/bin/perl

use strict;
use Encode;
use File::Glob 'bsd_glob';
use File::Basename;
use DBI qw(:sql_types);
use DBD::SQLite;
use Parse::AFP;
use Getopt::Long;

use constant GCG_Elements => [
    qw( Increment Ascend Descend ASpace BSpace CSpace BaseOffset _FNMCount )
];
use constant FNI_Elements => [
    qw( Width Height _FNGOffset )
];
use constant +{ map { +GCG_Elements->[$_] => $_ } 0..$#{+GCG_Elements} };
use constant +{ map { +FNI_Elements->[$_] => $_ } 0..$#{+FNI_Elements} };

$|++;

die "Usage: $0 [ -o fonts.fdb | fdbdir ] [ dir | file... ] \n" unless @ARGV >= 1 or -d 'dir';

my $default_output;
GetOptions(
    'o|output:s' => \$default_output,
);

my ($dbh, $file, $output);

our (%GCG, %FNI, %SpaceIncrement, @FNM, $FNG);
our ($FontName, $Rotation, $Resolution);

my (%initialized, $is_child);
my @inputs = sort map { (-d $_) ? bsd_glob("$_/*") : $_ } (@ARGV ? @ARGV : 'dir');

foreach my $i (@inputs) {
    $file = $i;
    $file =~ /X0.*afp$/i or next;
    if (-d $default_output) {
        $output = "$default_output/".basename((substr($file, 0, -3) . 'fdb'));
    }
    elsif ($default_output) {
        $output = $default_output;
    }
    else {
        $output = substr($file, 0, -3) . 'fdb';
    }

    if (!$initialized{$output}++) {
        unlink $output if -e $output;
        $dbh = DBI->connect("dbi:SQLite:dbname=$output") or die $DBI::errstr;
        init_db();
        $dbh->disconnect;
    }

    if (my $pid = fork) {
        waitpid($pid, 0);
    }
    else {
        $is_child = 1;
        last;
    }
}
$is_child or exit;

$dbh = DBI->connect("dbi:SQLite:dbname=$output") or die $DBI::errstr;

basename($file) =~ /^(X0([^.]+))/ or exit;
$FontName = $1;

$dbh->begin_work;
init_table();

my $name = $2;
print "Parsing font $name.";
Parse::AFP->new($file, { lazy => 1 })->callback_members([qw( CFC CFI )]);

$dbh->commit;
$dbh->begin_work;

# Heuristic: If Variations <= 3, we think it's fixed width font.
my $dimension = "Width || ',' || Height";
my $variations = $dbh->selectall_arrayref(qq(
    SELECT Width, Height, COUNT($dimension)
      FROM $FontName
  GROUP BY $dimension
  ORDER BY Count($dimension) DESC
));

$dbh->do(
    "INSERT INTO Fonts VALUES (?, ?, ?, ?)", {},
    $FontName, $Resolution, (@$variations > 3) ? (0, 0) : @{$variations->[0]}[0, 1]
);

$dbh->commit;

# Heuristic: If there is no "\x40" <= 3, fill in a fake record
my @has_0x40 = @{$dbh->selectcol_arrayref(
    "SELECT Width FROM $FontName WHERE Character = '\x40'"
)||[]};

if (!@has_0x40 and my $inc = $SpaceIncrement{'0000'}{$FontName}) {
    $dbh->begin_work;

    $dbh->do(
        "INSERT INTO $FontName VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {},
        "\x40",
        $inc,
        0, 0,
        0, $inc, 0, 0,
        '',
        $inc,
        $inc,
    );

    foreach my $rotation (qw( 2D 5A 87 )) {
        my $rot_inc = $SpaceIncrement{$rotation.'00'}{$FontName} or next;
        my $angle = hex($rotation) * 2;
        $dbh->do(
            "INSERT INTO RotationInfo VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {},
            "\x40",
            $rot_inc,
            0, 0,
            0, $rot_inc, 0, 0,
            $FontName, $angle
        );
    }

    $dbh->commit;
}

$dbh->disconnect;

print "\n";

exit;

my $CFIRepeatingGroupLength;
sub CFC {
    $CFIRepeatingGroupLength = $_[0]->CFIRepeatingGroupLength;
}

sub CFI {
    my $data = $_[0]->Data;
    my $offset = 0;
    while (my $CFIRepeatingGroup = substr($data, $offset, $CFIRepeatingGroupLength)) {
        my ($fcs_name, $cp_name, $section) = unpack("a8a8x8C", $CFIRepeatingGroup);

        %GCG = %FNI = @FNM = (); $FNG = ''; $Rotation = 0;

        $cp_name = dirname($file)."/".Encode::decode( cp500 => $cp_name ).".afp";
        $fcs_name = dirname($file)."/".Encode::decode( cp500 => $fcs_name ).".afp";

        Parse::AFP->new($cp_name, { lazy => 1 })->callback_members([qw( CPC CPI )]);
        Parse::AFP->new($fcs_name, { lazy => 1 })->callback_members([qw( FNC FNI FNM FNG FNO )]);

        write_record($section); 

        $offset += $CFIRepeatingGroupLength; 

        print ".";
    }
}

sub write_record {
    my $section = shift;
    while (my ($rotation, $fni) = each %FNI) {
        my $sth = $dbh->prepare_cached(
            $rotation
                ? "INSERT INTO RotationInfo VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
                : "INSERT INTO $FontName VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        );

        foreach my $codepoint (keys %GCG) {
            my $gcg = $GCG{$codepoint};
            my $fnc = $fni->{$gcg} or next;

            defined(my $count = pop @$fnc) or next;
            my $fnm = $FNM[$count] or die "Cannot find fnm #$count";

            # printf "%s - 0x%02X 0x%02X - @$fnm\n", $rotation, $section, $codepoint;

            $sth->bind_param(
                1,
                ($section ? pack('n', $section * 256 + $codepoint) : pack('C', $codepoint)),
                SQL_VARCHAR,
            );
            $sth->bind_param(
                2 + $_,
                $fnc->[$_],
                SQL_INTEGER,
            ) for 0..$#$fnc;

            if ($rotation) {
                $sth->bind_param( 9, $FontName, SQL_VARCHAR );
                $sth->bind_param( 10, $rotation, SQL_INTEGER );
            }
            else {
                $sth->bind_param(
                    9,
                    substr($FNG, pop @$fnm, int(($fnm->[Width] + 7)/8)*$fnm->[Height]),
                    SQL_BLOB,
                );
                $sth->bind_param(
                    10 + $_,
                    $fnm->[$_],
                    SQL_INTEGER,
                ) for 0..$#$fnm;
            }

            $sth->execute;
        }
    }
}

my $CPIRepeatingGroupLength;
sub CPC {
    $CPIRepeatingGroupLength = $_[0]->CPIRepeatingGroupLength;
}

sub CPI {
    my $data = $_[0]->Data;
    my $offset = 0;
    while (my $CPIRepeatingGroup = substr($data, $offset, $CPIRepeatingGroupLength)) {
        my ($GCGID, $CodePoint) = unpack("a8xC", $CPIRepeatingGroup);
        $GCG{$CodePoint} = $GCGID;
        $offset += $CPIRepeatingGroupLength; 
    }
}

my $FNIRepeatingGroupLength;
my $FNMRepeatingGroupLength;
sub FNC {
    $FNIRepeatingGroupLength = $_[0]->FNIRepeatingGroupLength;
    $FNMRepeatingGroupLength = $_[0]->FNMRepeatingGroupLength;
    die "UnitXBase other than 00 not handled" unless $_[0]->UnitXBase eq '00';
    $Resolution = $_[0]->UnitXValue;
}

sub FNI {
    my $data = $_[0]->Data;
    my $offset = 0;

    while (my $FNIRepeatingGroup = substr($data, $offset, $FNIRepeatingGroupLength)) {
        my ($GCGID, $CharInc, $AscendHt, $DescendDp, $Reserved, $FNMCnt, $ASpace, $BSpace, $CSpace, $BaseOset) = unpack("a8nnnnnnnnx2n", $FNIRepeatingGroup);  
    
        for ($AscendHt, $DescendDp, $ASpace, $CSpace, $BaseOset) {
            # cast "unsigned short" to "signed short"
            $_ -= 65536 if $_ > 32768;
        }

        $FNI{$Rotation}{$GCGID} = [
            $CharInc, $AscendHt, $DescendDp, $ASpace, $BSpace, $CSpace, $BaseOset, $FNMCnt
        ];

        $offset += $FNIRepeatingGroupLength;
    }

    $Rotation += 90;
}

sub FNM {
    my $data = $_[0]->Data;
    my $offset = 0;
 
    while (my $FNMRepeatingGroup = substr($data, $offset, $FNMRepeatingGroupLength)) {
        my ($w, $h, $o) = unpack("nnN", $FNMRepeatingGroup);
        push @FNM, [ $w+1, $h+1, $o ];
        $offset += $FNMRepeatingGroupLength;
    }
}

sub FNG { $FNG .= $_[0]->Data; }

sub FNO {
    $SpaceIncrement{$_[0]->CharacterRotation}{$FontName}
        = $_[0]->SpaceCharacterIncrement;
}

sub init_db {
    $dbh->do('PRAGMA default_cache_size = 200000; ') or die $dbh->errstr;
    $dbh->do('PRAGMA default_synchronous = OFF; ') or die $dbh->errstr;

    $dbh->do(q(
CREATE TABLE Fonts (
    FontName        VARCHAR(255) PRIMARY KEY,
    Resolution      INTEGER,
    FixedWidth      INTEGER,
    FixedHeight     INTEGER
);
    ));

    $dbh->do(q(
CREATE TABLE RotationInfo (
    Character       VARCHAR(6),

    Increment       INTEGER,
    Ascend          INTEGER,
    Descend         INTEGER,
    ASpace          INTEGER,
    BSpace          INTEGER,
    CSpace          INTEGER,
    BaseOffset      INTEGER,

    FontName        VARCHAR(255),
    Rotation        INTEGER
);
    ));

    $dbh->do(q(
CREATE INDEX RotationInfo_1 ON RotationInfo(FontName, Character, Rotation);
    ));
}

sub init_table {
    $dbh->do(qq(
CREATE TABLE $FontName (
    Character       VARCHAR(6) PRIMARY KEY,

    Increment       INTEGER,
    Ascend          INTEGER,
    Descend         INTEGER,
    ASpace          INTEGER,
    BSpace          INTEGER,
    CSpace          INTEGER,
    BaseOffset      INTEGER,

    Bitmap          LONGBLOB,

    Width           INTEGER,
    Height          INTEGER
);
    ));
}

