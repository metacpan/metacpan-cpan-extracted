# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 15;
use Cwd;

BEGIN { use_ok( 'Net::SFTP::Foreign::Tempdir::Extract' ); }

my $run      = $ENV{"Net_SFTP_Foreign_Tempdir_Extract"}          || 0;

SKIP: {
  skip 'export Net_SFTP_Foreign_Tempdir_Extract=1 #to run', 14 unless $run;

  my $dir      = getcwd;
  my $host     = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_host"}     || "127.0.0.1";
  my $folder   = $ENV{"Net_SFTP_Foreign_Tempdir_Extract_folder"}   || "$dir/t/files";

  my $fileX="";
  {
    my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host, folder=>"/foobar");
    isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');
    is($sftp->folder, "/foobar", "folder");
  
    my $file=$sftp->download($folder, "hello-world.txt"); #Explicit folder
    isa_ok($file, "Net::SFTP::Foreign::Tempdir::Extract::File");
    is($file->basename, "hello-world.txt", "filename");
    ok(-f $file, "file exists");
    $fileX="$file";
    my $content=$file->slurp;
    is($content, "Hello World!\n", "content");
  }
  ok(not(-f $fileX), "file cleaned");
  
  {
    my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host, folder=>$folder);
    isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');
    is($sftp->folder, "$folder", "folder");
  
    my $file=$sftp->download("hello-world.txt"); #Explicit folder
    isa_ok($file, "Net::SFTP::Foreign::Tempdir::Extract::File");
    is($file->basename, "hello-world.txt", "filename");
    ok(-f $file, "file exists");
    $fileX="$file";
    my $content=$file->slurp;
    is($content, "Hello World!\n", "content");
  }
  ok(not(-f $fileX), "file cleaned");

}
