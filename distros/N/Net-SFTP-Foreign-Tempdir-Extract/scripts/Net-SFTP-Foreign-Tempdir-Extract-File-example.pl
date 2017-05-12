#!/usr/bin/perl
use strict;
use warnings;
use Path::Class qw{file};
use Net::SFTP::Foreign::Tempdir::Extract::File;

=head1 NAME

Net-SFTP-Foreign-Tempdir-Extract-File-example.pl - Net::SFTP::Foreign::Tempdir::Extract::File Example with local file

=cut

my $zip=Net::SFTP::Foreign::Tempdir::Extract::File->new(file($0)->dir, "Net-SFTP-Foreign-Tempdir-Extract-file.zip");
die("Error: Cannot read ZIP file.") unless -r $zip;
print "Zip: $zip\n";
my @files=$zip->extract;
foreach my $file (@files) {
  print "File: $file\n";
  printf "Contents: \n%s\n%s\n%s\n", "+" x 80, $file->slurp, "-" x 80;
}
