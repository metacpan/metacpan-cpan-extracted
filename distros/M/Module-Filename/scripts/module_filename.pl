#/usr/bin/perl
use strict;
use warnings;
use Module::Filename qw{module_filename};

die("module_filename.pl Module::Name [Module::Two] [Module::Three]\n") unless @ARGV;

my $summary=@ARGV > 1 ? 1 : 0; #Add summary if more than one package on command line

foreach my $package (@ARGV) {
  my $filename=module_filename($package) || "not found";
  print $summary ? "$package: " : "", 
        "$filename\n";
}
