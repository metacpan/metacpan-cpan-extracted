#!/usr/bin/perl -w

use lib qw(./blib/lib ./blib/arch);
use Moot;
use Getopt::Long;
use File::Basename qw(basename);
use Pod::Usage;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = basename($0);
our $compact_ngrams = 1;
our $trace = 0;
our $outfile = '-';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'trace|t!' => \$trace,
	   'quiet|silent|q' => sub { $trace=0; },

	   ##-- misc
	   'verbose-ngrams|verbose|v|N!' => sub { $compact_ngrams=!$_[1]; },
	   'compact-ngrams|compact|z!' => \$compact_ngrams,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN

our $ng = Moot::Ngrams->new();
foreach $file (@ARGV) {
  print STDERR "$0: load($file)\n" if ($trace);
  $ng->load($file) || die("$prog: load failed for file '$file': $!");
}
print STDERR "$0: save($outfile)\n" if ($trace);
$ng->save($outfile,($compact_ngrams ? 1 : 0));


__END__

=pod

=head1 NAME

 mootmerge-123.perl - merge moot N-gram model files

=head1 SYNOPSIS

 mootmerge-123.perl [OPTIONS] NGRAM_FILE(s)...

 Options:
  -help                     # this help message
  -trace   , -notrace       # do/don't trace execution to STDERR (default=-notrace)
  -compact , -verbose       # do/don't generate compact n-gram output (default=-compact)
  -output OUTFILE           # save output to OUTFILE (default=STDOUT)

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

Bryan Jurish E<lt>jurish@uni-potsdam.deE<gt>

=cut
