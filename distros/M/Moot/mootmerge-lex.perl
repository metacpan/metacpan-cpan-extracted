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
our $verbose_ngrams = 0;
our $outfile = '-';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN

our $lex = Moot::Lexfreqs->new();
foreach $file (@ARGV) {
  $lex->load($file) || die("$prog: load failed for file '$file': $!");
}
$lex->save($outfile);


__END__

=pod

=head1 NAME

 mootmerge-lex.perl - merge moot lexical model files

=head1 SYNOPSIS

 mootmerge-lex.perl [OPTIONS] LEX_FILE(s)...

 Options:
  -help                     # this help message
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

Bryan Jurish E<lt>moocow@bbaw.deE<gt>

=cut
