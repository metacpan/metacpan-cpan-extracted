#!/usr/bin/perl
use strict;
use warnings;
use Path::Class qw{file};
use Net::SFTP::Foreign::Tempdir::Extract;

=head1 NAME

Net-SFTP-Foreign-Tempdir-Extract-download-example.pl - Net::SFTP::Foreign::Tempdir::Extract Example with local SSH server

=cut

my $sftp=Net::SFTP::Foreign::Tempdir::Extract->new(
                                                   user   => undef, #use current user from OS
                                                   host   => "127.0.0.1",
                                                   folder => file($0)->dir->absolute,
                                                  );

my $zip = $sftp->download("Net-SFTP-Foreign-Tempdir-Extract-file.zip");
die("Error: Cannot read ZIP file") unless -r $zip;
print "Zip: $zip\n";
my @files=$zip->extract;
foreach my $file (@files) {
  print "File: $file\n";
  printf "Contents: \n%s\n%s\n%s\n", "+" x 80, $file->slurp, "-" x 80;
}
