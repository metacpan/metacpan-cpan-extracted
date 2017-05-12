use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;
use silktest;

use Test::More tests => 4;

use Net::Silk qw( :basic );
use Net::Silk::RWRec;

BEGIN { use_ok( SILK_FILE_CLASS ) }

###

my $Tempfile = t_tmp_filename();

my $baserec = SILK_RWREC_CLASS->new(
  application      => 1,
  bytes            => 2,
  dip              => "3.4.5.6",
  dport            => 7,
  duration         => 8 * 1000,
  initial_tcpflags => 'FP',
  input            => 10,
  nhip             => "11.12.13.14",
  output           => 15,
  packets          => 16,
  protocol         => 6,
  session_tcpflags => 'SA',
  sip              => "19.20.21.22",
  sport            => 23,
  stime            => time(),
  tcpflags         => 'FPA',
);

sub test_read_write_default {

  plan tests => 5;

  my($f, @recs);
  for my $i (0..9) {
    push(@recs, $baserec->new(input => $i));
  }
  $f = SILK_FILE_CLASS->open("$Tempfile", ">");
  for my $x (@recs) {
    $f->write($x);
  }
  $f->close;
  $f = SILK_FILE_CLASS->open("$Tempfile");
  isa_ok($f, SILK_FILE_CLASS);
  $f = SILK_FILE_CLASS->open("$Tempfile", "<");
  isa_ok($f, SILK_FILE_CLASS);
  my @nrecs;
  while (my $x = <$f>) {
    push(@nrecs, $x);
  }
  $f->close;
  is_deeply(\@recs, \@nrecs, "rec <> retrieve");
  $f = SILK_FILE_CLASS->open("$Tempfile");
  @nrecs = ();
  my $x = $f->read;
  while ($x) {
    push(@nrecs, $x);
    $x = $f->read;
  }
  $f->close;
  is_deeply(\@recs, \@nrecs, "rec read retrieve");
  $f = SILK_FILE_CLASS->open("$Tempfile");
  @nrecs = ();
  @nrecs = $f->read;
  $f->close;
  is_deeply(\@recs, \@nrecs, "rec slurp retrieve");

  unlink $Tempfile;

}

sub test_read_write_annotations {

  plan tests => 5;

  my @recs;
  for my $i (0..9) {
    push(@recs, $baserec->new(input => $i));
  }
  my @anno = qw( Annot1 Annot2 );
  my @invo = qw( Invoc1 Invoc2 );
  my $f = SILK_FILE_CLASS->open("$Tempfile", ">", notes => \@anno,
                                                  invocations => \@invo);
  $f->write(@recs);
  $f->close;
  my(@res, @nrecs);
  $f = SILK_FILE_CLASS->open($Tempfile);
  @res = $f->notes;
  is_deeply(\@res, \@anno, "annotations eq");
  @res = $f->invocations;
  is_deeply(\@res, \@invo, "invocations eq");
  @nrecs = $f->read;
  $f->close;
  is_deeply(\@nrecs, \@recs, "records eq");
  unlink $Tempfile;
  $f = SILK_FILE_CLASS->open("$Tempfile", ">");
  $f->write(@recs);
  $f->close;
  $f = SILK_FILE_CLASS->open($Tempfile);
  @res = $f->notes;
  ok(!@res, "no annotations");
  @res = $f->invocations;
  ok(!@res, "no invocations");

  unlink $Tempfile;

}

sub test_read_write_compression {

  plan tests => 4;

  my($f, @recs, @nrecs, $skip);
  for my $i (0..9) {
    push(@recs, $baserec->new(input => $i));
  }

  $f = SILK_FILE_CLASS->open("$Tempfile", ">", compression => 'default');
  $f->write(@recs);
  $f->close;
  $f = SILK_FILE_CLASS->open($Tempfile);
  @nrecs = $f->read;
  $f->close;
  unlink $Tempfile;
  is_deeply(\@recs, \@nrecs, "default compression");

  $f = SILK_FILE_CLASS->open("$Tempfile", ">", compression => 'none');
  $f->write(@recs);
  $f->close;
  $f = SILK_FILE_CLASS->open($Tempfile);
  @nrecs = $f->read;
  $f->close;
  unlink $Tempfile;
  is_deeply(\@recs, \@nrecs, "no compression");

  eval { $f = SILK_FILE_CLASS->open("$Tempfile", ">", compression => 'zlib') };
  SKIP: {
    skip("zlib not enabled", 1) if $@;
    $f->write(@recs);
    $f->close;
    $f = SILK_FILE_CLASS->open($Tempfile);
    @nrecs = $f->read;
    $f->close;
    unlink $Tempfile;
    is_deeply(\@recs, \@nrecs, "zlib");
  }

  eval { $f = SILK_FILE_CLASS->open("$Tempfile", ">",
                                    compression => 'lzo1x') };
  SKIP: {
    skip("lzo1x not enabled", 1) if $@;
    $f->write(@recs);
    $f->close;
    $f = SILK_FILE_CLASS->open($Tempfile);
    @nrecs = $f->read;
    $f->close;
    unlink $Tempfile;
    is_deeply(\@recs, \@nrecs, "lzo1x");
  }

  unlink $Tempfile;

}

###

sub test_all {

  subtest "read_write_default"     => \&test_read_write_default;
  subtest "read_write_annotations" => \&test_read_write_annotations;
  subtest "read_write_compression" => \&test_read_write_compression;

}

test_all();

###
