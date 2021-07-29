# -*- perl -*-

use strict;
use warnings;
use Cwd qw{cwd};
use Test::More tests => 18;
use Path::Class qw{dir};

BEGIN {use_ok('Net::SFTP::Foreign::Tempdir::Extract');}

my $run      = $ENV{"Net_SFTP_Foreign_Tempdir_Extract"}          || 0;

SKIP: {
  skip 'export Net_SFTP_Foreign_Tempdir_Extract=1 #to run tests', 17 unless $run;

  my $host   = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_host"}     || "127.0.0.1";
  my $folder = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_folder"}   || dir(cwd(), "t/files");
  diag("Folder: $folder");

  my $sftp   = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host);
  isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

  my $file=$sftp->download($folder, "archive-multi-hierarchy.zip"); #Explicit folder
  diag("File: $file");
  isa_ok($file, "Net::SFTP::Foreign::Tempdir::Extract::File");
  is($file->basename, "archive-multi-hierarchy.zip", "filename");
  ok(-f $file, "file exists");

  my @files=$file->extract;
  diag("File: $_") foreach @files;
  is(scalar(@files), 4, "size of extract");
  foreach my $f (@files) {
    isa_ok($f, "Net::SFTP::Foreign::Tempdir::Extract::File");
    like($f->basename, qr/\A[abcd].txt\Z/, "basename");
    my $basename = $f->basename;
    my $content  = substr($basename, 0, 1);
    is(scalar($f->slurp), "$content\n", "content");
  }
}
