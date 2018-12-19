# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 8;
use File::Tempdir qw{};
use Path::Class qw{file};

BEGIN { use_ok( 'Net::SFTP::Foreign::Tempdir::Extract' ); }
BEGIN { use_ok( 'File::Tempdir' ); }

my $run      = $ENV{"Net_SFTP_Foreign_Tempdir_Extract"}          || 0;

SKIP: {
  skip 'export Net_SFTP_Foreign_Tempdir_Extract=1 #to run', 6 unless $run;

  my $host          = "127.0.0.1";
  my $port          = 22;
  my $local_folder  = File::Tempdir->new    or die('Error: Could not create File::Tempdir object');
  my $local_file    = file($local_folder->name => "hello.txt");
  my $fh            = $local_file->open("w") or die("$@ $!");
  print $fh "Hello World"; #no spew support
  $fh->close;

  {
    my $remote_folder = File::Tempdir->new    or die('Error: Could not create File::Tempdir object');
    my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host, folder=>$remote_folder->name, port=>22);
    isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

    my $return=$sftp->upload($local_file);
    is($return, 1, "upload return code");
    my $remote_file=file($remote_folder->name => "hello.txt");
    my $hello=$remote_file->slurp;
    is($hello, "Hello World", "content");
  }

  {
    my $remote_folder = File::Tempdir->new    or die('Error: Could not create File::Tempdir object');
    my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new(host=>$host, folder=>$remote_folder->name, port=>2222);
    isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

    local $@;
    my $return=eval{$sftp->upload("$local_file")};
    my $error = $@;
    diag("Expected Error: $error");
    like($error, qr{Error connecting to sftp://127\.0\.0\.1:2222/}, 'error trapped');
    like($error, qr{Connection to remote server is broken}, 'error trapped');
  }
}
