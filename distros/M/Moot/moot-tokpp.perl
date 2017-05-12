#!/usr/bin/perl -w

use lib qw(./blib/lib ./blib/arch);
use Moot;
use Moot::Waste;
use Getopt::Long;
use File::Basename qw(basename);
use Pod::Usage;
use utf8;

use open ':std',':utf8';

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our $outfile = '-';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'output|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN

my $wa = Moot::Waste::Annotator->new();
push(@ARGV,'-') if (!@ARGV);

open(OUT,">$outfile") or die("$prog: open failed for output file $outfile: $!");

foreach my $file (@ARGV) {
  open(IN,"<$file") or die("$prog: open failed for input file $file: $!");

  my ($txt,$rest,$atok);
  my $tok = {};
  while (defined($_=<IN>)) {
    if (/^%%/ || /^\s*$/) {
      print OUT $_;
      next;
    }
    chomp;
    ($txt,$rest) = split(/\t/,$_,2);
    $tok->{text} = $txt;
    $atok = $wa->annotate($tok);
    print OUT join("\t",$txt, (defined($rest) ? $rest :qw()), map {$_->{tag}} @{$atok->{analyses}}), "\n";
  }
  close(IN);
}


__END__

=pod

=head1 NAME

  moot-tokpp.perl - simulate dwds_tomasotath v0.4.x tokenizer-supplied pseudo-morphological analysis

=head1 SYNOPSIS

 moot-tokpp.perl [OPTIONS] [INPUT_FILE(s)...]

 Options:
  -help                     # this help message
  -o FILE		    # output file (default: stdout)

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

not yet written.

=cut


##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut


