#!/usr/bin/perl

# Data testing for Parse::CSV

use strict;
use Test::More tests => 11;
use Parse::CSV;


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

