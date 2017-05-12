package Physics::Unit::Script::GenPages;

# This test program generates the UnitsByName.html and
# UnitsByType.html pages.

use strict;
use warnings;

our $VERSION = '0.54';
$VERSION = eval $VERSION;

use Physics::Unit ':ALL';

use parent 'Exporter';
our @EXPORT = qw/GenPages/;
our @EXPORT_OK = qw/GenNameTable GenTypeTable/;

#-----------------------------------------------------------
sub GenPages
{
    my @return;
    my $outFile;

    # Generate Units by Name

    $outFile = "UnitsByName.html";
    push @return, $outFile;
    open my $fh, ">", "$outFile" or die "Can't open $outFile for output";
    print $fh header("Name");

    GenNameTable($fh);

    print $fh trailer();
    close $fh;


    # Generate Units by Type

    $outFile = "UnitsByType.html";
    push @return, $outFile;
    open $fh, ">", "$outFile" or die "Can't open $outFile for output";
    print $fh header("Type");

    # Print out the "Table of Contents"

    my @t = ('unknown', 'prefix', ListTypes());
    my @links = map "      <a href='#$_'>$_</a>", @t;
    print $fh join ",\n", @links;

    # Print out the table

    print $fh "\n      <p>\n";

    GenTypeTable($fh);

    print $fh trailer();
    close $fh;

    return @return;
}

#-----------------------------------------------------------
sub GenNameTable
{
    my $fh = shift;

    print $fh tableHeader(1);

    for my $name (ListUnits()) {
        my $n = GetUnit($name);

        printrow($fh, 1, $name, $n->type(), $n->def(), $n->expanded());
    }

    print $fh "      </table>\n";
}

#-----------------------------------------------------------
sub GenTypeTable
{
    my $fh = shift;

    print $fh tableHeader(0);

    my $lastType = '-';
    for my $name (sort byType ListUnits())
    {
        my $n = GetUnit($name);
        my $t = $n->type || '';
        if ($t ne $lastType) {
            print $fh typeRow($t);
            $lastType = $t;
        }

        printrow($fh, 0, $name, $t, $n->def, $n->expanded);
    }

    print $fh "      </table>\n";
}

#-----------------------------------------------------------
sub header
{
    my $sortBy = shift;
    my $title = "Units by $sortBy";

    return <<END_HEADER;
<html>
  <head>
    <title>$title</title>
    <link rel="stylesheet" href="http://st.pimg.net/tucs/style.css" type="text/css" />
  </head>
  <body>
    <div class='pod'>
      <h1>$title</h1>
END_HEADER
}

#-----------------------------------------------------------
sub trailer
{
    return <<END_TRAILER;
    </div>
  </body>
</html>
END_TRAILER
}

#-----------------------------------------------------------
sub tableHeader
{
    my $printType = shift;

    my $th = "      <table border='1' cellpadding='2'>\n" .
             "        <tr bgcolor='#003070'>\n" .
             "          <th>Unit</th>\n" .
             ($printType ? "          <th>Type</th>\n" : '') .
             "          <th>Value</th>\n" .
             "          <th>Expanded</th>\n" .
             "        </tr>\n";

    return $th;
}

#-----------------------------------------------------------
sub printrow
{
    my ($fh, $printType, $name, $t, $d, $ex) = @_;
    print $fh "        <tr>\n" .
                "          <td>$name</td>\n" .
                ($printType ?
                    "          <td>" . typeStr($t) . "</td>\n" : '') .
                "          <td>$d</td>\n" .
                "          <td>$ex</td>\n" .
                "        </tr>\n";
}

#-----------------------------------------------------------
# This is used in a couple of places.  It returns a human-readable
# string for a type.  If $t is undef, this returns "unknown";
# otherwise, this returns $t.

sub typeStr
{
    my $t = shift;
    return !defined $t || $t eq '' ? 'unknown' : $t;
}

#-----------------------------------------------------------
# Used for sorting an array of unit names by type.
# Note: 'unknown' is first, 'prefix' next

sub byType
{
    my $ua = GetUnit($a);
    my $ub = GetUnit($b);

    return altType($ua->type) cmp altType($ub->type) ||
           $ua->factor <=> $ub->factor ||
           $a cmp $b;
}

#-----------------------------------------------------------
# This is used by the byType comparison routine.  This takes a
# unit's type and returns a value that ensures that undef (type is
# unknown) is sorted first, then 'prefix' and then the other types.

sub altType
{
    my $t = shift;

    return !defined $t ? 0 :
           $t eq 'prefix'  ? 1 :
           $t;
}

#-----------------------------------------------------------
sub typeRow
{
    my $t = shift;
    my $ts = typeStr($t);

    return "      <tr bgcolor='#B0D8FC'>\n" .
           "        <td colspan='4'>\n" .
           "          <a name='$ts'>" .
           ($ts eq 'prefix' ? 'prefix (dimensionless)' : $ts) .
           "</a>\n" .
           "        </td>\n" .
           "      </tr>\n";
}


