# -*- perl -*-

use strict;
use warnings;
use Cwd qw{cwd};
use Test::More tests => 12;
use Path::Class qw{dir};

BEGIN {use_ok('Net::SFTP::Foreign::Tempdir::Extract');}

my $run      = $ENV{"Net_SFTP_Foreign_Tempdir_Extract"}          || 0;

SKIP: {
  skip 'export Net_SFTP_Foreign_Tempdir_Extract=1 #to run tests', 11 unless $run;

  my $host   = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_host"}     || "127.0.0.1";
  my $folder = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_folder"}   || dir(cwd(), "t/files");
  diag("Folder: $folder");

  my $sftp   = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host);
  isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

  my $file=$sftp->download($folder, "archive-multi.zip"); #Explicit folder
  diag("File: $file");
  isa_ok($file, "Net::SFTP::Foreign::Tempdir::Extract::File");
  is($file->basename, "archive-multi.zip", "filename");
  ok(-f $file, "file exists");

  my @files=$file->extract;
  diag("File: $_") foreach @files;
  is(scalar(@files), 2, "size of extract");
  isa_ok($files[0], "Net::SFTP::Foreign::Tempdir::Extract::File");
  isa_ok($files[1], "Net::SFTP::Foreign::Tempdir::Extract::File");
  is($files[0]->basename, "file1.txt", "basename");
  is($files[1]->basename, "file2.txt", "basename");
  is(scalar($files[0]->slurp), "file1\n", "content");
  is(scalar($files[1]->slurp), "file2\n", "content");
}
