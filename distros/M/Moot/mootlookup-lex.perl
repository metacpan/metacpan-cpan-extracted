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
our ($word,$tag);

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'word|w=s' => \$word,
	   'tag|t=s'  => \$tag,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN

our $lxin   = Moot::Lexfreqs->new();
our $lxfile = shift(@ARGV);
$lxin->load($lxfile) || die("$prog: load failed for lexical-frequency file '$lxfile': $!");

$word = shift(@ARGV) if (@ARGV && !$word);
$tag  = shift(@ARGV) if (@ARGV && !$tag);
$word //= '';
$tag  //= '';
my ($count);
if ($word ne '' && $tag ne '') {
  $count = $lxin->f_word_tag($word,$tag);
} elsif ($word ne '') {
  $count = $lxin->f_word($word);
} elsif ($tag ne '') {
  $count = $lxin->f_tag($tag);
} else {
  pod2usage({-exitval=>1, -verbose=>0, -msg=>'You must specify either -word or -tag!'});
}

print join("\t", (map {$_ eq '' ? '*' : $_} ($word,$tag)), $count, "\n");


__END__

=pod

=head1 NAME

  mootlookup-lex.perl - lookup lexical frequency in moot text model files

=head1 SYNOPSIS

 mootlookup-lex.perl [OPTIONS] LEXFREQ_FILE [WORD [TAG]]

 Options:
  -help                     # this help message
  -word=WORD 		    # get count for WORD (maybe be combined with -tag)
  -tag=TAG 		    # get count for TAG (may be combined with -word)

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
