# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 9;
use Cwd;  

BEGIN {use_ok('Net::SFTP::Foreign::Tempdir::Extract');}

my $run      = $ENV{"Net_SFTP_Foreign_Tempdir_Extract"}          || 0;

SKIP: {
  skip 'export Net_SFTP_Foreign_Tempdir_Extract=1 #to run', 8 unless $run;

  my $dir      = getcwd;
  my $host     = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_host"}     || "127.0.0.1";
  my $folder   = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_folder"}   || "$dir/t/files";

  my $sftp     = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host);
  isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

  my $file     = $sftp->download($folder, "archive-single.zip"); #Explicit folder
  isa_ok($file, "Net::SFTP::Foreign::Tempdir::Extract::File");
  is($file->basename, "archive-single.zip", "filename");
  ok(-f $file, "file exists");

  my @files=$file->extract;
  is(scalar(@files), 1, "size of extract");
  isa_ok($files[0], "Net::SFTP::Foreign::Tempdir::Extract::File");
  is($files[0]->basename, "file1.txt", "basename");
  is(scalar($files[0]->slurp), "file1\n", "content");
}
