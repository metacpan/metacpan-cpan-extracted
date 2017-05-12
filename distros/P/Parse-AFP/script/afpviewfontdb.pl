#!/usr/bin/perl

use strict;
use DBI;
use DBD::SQLite;
use Data::Dumper;

$|++;

die "Usage: $0 fonts.db\n" unless @ARGV >= 1 or -e 'fonts.db';

my $input = shift || 'fonts.db';
my $dbh = DBI->connect("dbi:SQLite:dbname=$input") or die $DBI::errstr;
my $fonts = $dbh->selectall_arrayref("SELECT FontName, FixedWidth, FixedHeight, Resolution FROM Fonts")
  or die $dbh->errstr;

while (1) {
    for (1 .. @$fonts) {
        my ($name, $width, $height, $resolution) = @{$fonts->[$_-1]};
        my $dimension = ($width ? "$width * $height" : 'variable width');
        print "$_: $name - $resolution - $dimension\n";
    }
    print "Choose a font to display: ";
    my $choice = int(<STDIN>) or exit;
    my $name = $fonts->[$choice-1][0] or next;

    my $sth = $dbh->prepare("SELECT * FROM $name ORDER BY Character");
    $sth->execute;

    while ( my $row = $sth->fetchrow_hashref ) {
        my $map = unpack('B*', $row->{Bitmap});
        while (my $x = substr($map, 0, int(($row->{Width} + 7)/8)*8, '')) {
            $x =~ s/0/./g;
            $x =~ s/1/@/g;
            print "$x\n";
        }

        printf "[0x%s] %s*%s Inc/Asc/Desc:%s/%s/%s A/B/C:%s/%s/%s Offset:%s | Stop? ", (
            uc(unpack('H*', $row->{Character})), @{$row}{qw(
                Width Height Increment Ascend Descend
                ASpace BSpace CSpace BaseOffset
            )}
        );

        $row->{Bitmap} or next;
        last if <STDIN> =~ /^\z|[yq!]/i;
    }
}
