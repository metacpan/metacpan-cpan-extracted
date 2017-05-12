package Palm::Zetetic::Strip::Util;

use strict;

use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(hexdump null_split true false);
$VERSION = "1.02";

sub true
{
    return 1;
}

sub false
{
    return 0;
}

# hexdump was ripped off from the p5-Palm CPAN package in the
# "pdbdump" script.

sub hexdump
{
    my $prefix = shift;         # What to print in front of each line
    my $data = shift;           # The data to dump
    my $maxlines = shift;       # Max # of lines to dump
    my $offset;                 # Offset of current chunk

    for ($offset = 0; $offset < length($data); $offset += 16)
    {
        my $hex;                # Hex values of the data
        my $ascii;              # ASCII values of the data
        my $chunk;              # Current chunk of data

        last if defined($maxlines) && ($offset >= ($maxlines * 16));

        $chunk = substr($data, $offset, 16);

        ($hex = $chunk) =~ s/./sprintf "%02x ", ord($&)/ges;

        ($ascii = $chunk) =~ y/\040-\176/./c;

        printf "%s %-48s|%-16s|\n", $prefix, $hex, $ascii;
    }
}

sub null_split
{
    my ($string) = @_;
    my @strings;

    @strings = ();
    while (length($string) > 0)
    {
        my $x = unpack("Z*", $string);
        push(@strings, $x);
        $string = substr($string, length($x)+1);
    }

    return @strings;
}
