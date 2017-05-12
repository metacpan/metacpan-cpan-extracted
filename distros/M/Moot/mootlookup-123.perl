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
our $outfile = '-';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help || @ARGV < 2);

##------------------------------------------------------------------------------
## MAIN

our $ngin = Moot::Ngrams->new();
our $ngfile = shift(@ARGV);
$ngin->load($ngfile) || die("$prog: load failed for n-gram file '$ngfile': $!");

our @ngram = @ARGV[0..($#ARGV >= 2 ? 2 : $#ARGV)];
our $count = $ngin->lookup(@ngram[0..($#ngram > 2 ? 2 : $#ngram)]);

print join("\t", @ngram, $count, "\n");


__END__

=pod

=head1 NAME

  mootlookup-123.perl - lookup N-gram(s) in moot n-gram text model files

=head1 SYNOPSIS

 mootlookup-123.perl [OPTIONS] NGRAM_FILE [TAG_STRING(s)...]

 Options:
  -help                     # this help message

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
