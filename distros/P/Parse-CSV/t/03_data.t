#!/usr/bin/perl

# Data testing for Parse::CSV

use strict;
use warnings FATAL => 'all';
use Test::More tests => 13;
use Text::CSV_XS;
use Parse::CSV;
use File::Temp qw(tempfile);


{
  my $data = <<EOF;
this,file,contains,umlaute
föo,bär,bäz,x
one,two,three,four
EOF

  open my $fh, '<', \$data or die $!;
  my $csv = Text::CSV_XS->new({binary =>1, decode_utf8 => undef});
  isa_ok( $csv, 'Text::CSV_XS' );

  my $row = $csv->getline($fh);
  is_deeply( $row, [ qw{this file contains umlaute} ], '->fetch returns as expected' );

  $row = $csv->getline($fh);
  is_deeply( $row, [ qw{föo bär bäz x} ], '->fetch returns as expected' );

  $row = $csv->getline($fh);
  is_deeply( $row, [ qw{one two three four} ], '->fetch returns as expected' );
}


{
  my $data = <<EOF;
this,file,contains,umlaute
föo,bär,bäz,x
one,two,three,four
EOF

  open my $fh, '<', \$data or die $!;
  my $csv = Parse::CSV->new( handle => $fh, csv_attr => { binary => 1, decode_utf8 => undef });
  isa_ok( $csv, 'Parse::CSV' );

  my $row = $csv->fetch;
  is_deeply( $row, [ qw{this file contains umlaute} ], '->fetch returns as expected' );
  is( $csv->errstr, '', '->errstr returns ""' );

  $row = $csv->fetch;
  is_deeply( $row, [ qw{föo bär bäz x} ], '->fetch returns as expected' );
  is( $csv->errstr, '', '->errstr returns ""' );

  $row = $csv->fetch;
  is_deeply( $row, [ qw{one two three four} ], '->fetch returns as expected' );
  is( $csv->errstr, '', '->errstr returns ""' );
}

{
  # Byte-order mark - https://github.com/kenahoo/Perl-Parse-CSV/issues/8
  my $data = <<EOF;
domain,first,last,reference,type
broadbean.com,peter,sergeant,peters\@broadbean.com,good
EOF

  # Need to write data to a real file, or else we get the error "Strings with code points over 0xFF may not be mapped into in-memory file handles"
  my ($fh, $filename) = tempfile();
  binmode $fh, ":utf8";
  print {$fh} chr(0xfeff);
  print {$fh} $data;
  close $fh or die $!;

  open $fh, '<', $filename or die $!;
  my $csv = Parse::CSV->new( handle => $fh, names => 1, csv_attr => { binary => 1, decode_utf8 => undef });

  my $row = $csv->fetch;
  is_deeply($row,
            {domain=>'broadbean.com', first=>'peter', last=>'sergeant', reference=>'peters@broadbean.com', type=>'good'},
            '->fetch returns as expected');
  is( $csv->errstr, '', '->errstr returns ""' );
}
