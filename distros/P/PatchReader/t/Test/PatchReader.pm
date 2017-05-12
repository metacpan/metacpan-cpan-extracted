package Test::PatchReader;

use strict;
use base qw(Exporter);
use Test::More;
use Data::Dumper;

@Test::PatchReader::EXPORT = qw(convert_patch);

sub convert_patch {
  my ($patch, $expected, $files, $pluslines, $minuslines, $canonical,
      $filename, $oldrev, $newrev, $rcsfile, $extra, $opts) = @_;
  my $rawout;

  plan tests => ($extra ? 14 : 13);

  # Use necessary modules
  use_ok('PatchReader::Raw');
  use_ok('PatchReader::PatchInfoGrabber');
  use_ok('PatchReader::DiffPrinter::raw');
  use_ok($extra) if $extra;

  # Output goes to a local variable
  open(RAWF, ">", \$rawout);

  # Configure objects for testing
  my $reader = new PatchReader::Raw();
  my $patch_info = new PatchReader::PatchInfoGrabber();
  my $output_raw = new PatchReader::DiffPrinter::raw(*RAWF);
  my $extraobj = new $extra($opts) if $extra;
  if ($extra) {
    $reader->sends_data_to($extraobj);
    $extraobj->sends_data_to($patch_info);
  } else {
    $reader->sends_data_to($patch_info);
  }
  $patch_info->sends_data_to($output_raw);

  # Run patch through reader and verify correct output
  $reader->iterate_string("cvs diff", $patch);
  is($rawout, $expected, "Unified diff raw output");

  my $info = $patch_info->patch_info();
  is(keys %{$info->{files}}, $files, "Number of files");
  ok(exists $info->{files}->{$filename}, "Wanted filename in the output hash")
    or diag(Dumper($info));
  is($info->{files}->{$filename}->{plus_lines}, $pluslines, "Added lines");
  is($info->{files}->{$filename}->{minus_lines}, $minuslines, "Removed lines");
  is($info->{files}->{$filename}->{canonical}, $canonical, "Canonical names");
  is($info->{files}->{$filename}->{filename}, $filename, "Filename");
  is($info->{files}->{$filename}->{old_revision}, $oldrev, "Old revision");
  is($info->{files}->{$filename}->{new_revision}, $newrev, "New revision");
  is($info->{files}->{$filename}->{rcs_filename}, $rcsfile, "RCS filename");
}

1;
