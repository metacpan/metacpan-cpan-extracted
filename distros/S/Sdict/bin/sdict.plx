#!/usr/bin/perl
#
# $RCSfile: sdict.plx,v $
# $Author: swaj $
# $Revision: 1.12 $
#
# Sdict simple search tool
#
# Copyright (c) Alexey Semenoff 2001-2007. All rights reserved.
# Distributed under GNU Public License.
#


use 5.008;
use strict;
no warnings;
use Encode qw /encode decode from_to /;
use Data::Dumper;
use Getopt::Long;


use vars qw /
    $debug
    $list
    $csv
    $find
    $word
    $help
    $path
    $sd
    $sdict
    /;


BEGIN {
  $_=$0;
  s|^(.+)/.*|$1|;
  push @INC, ($_, "$_/lib", "$_/../lib", "$_/..") ;
  $debug = 0;
  $list = 0;
  $path = '';
  $csv = 0; 
  $find =0;
  $word = '';
  $help = 0;
  $sdict = '';
};


sub printd (;@);

use Sdict;


GetOptions(
	   "debug" => \$debug,
	   "list" => \$list,
	   "csv" => \$csv,
	   "find" => \$find,
	   "word=s" => \$word,
	   "help" => \$help,
	   "path=s" => \$path,
	   "sdict=s" => \$sdict
	   );

PrintHelpQuit() if $help;

$sd = Sdict->new;

if ($list) {
    printd '--list';
    my $p = $path eq '' ? '.' : $path; 
    printd "path = '$p'";
    $p =~ s|/$||;
    my $patt = "$p/*" . Sdict::SDICT_FILE_EXT;

    my @files = glob ($patt);

    unless (@files) {
	printd 'No dictionaries found';
    } else {
	for my $j (sort @files) {

	    printd "Looking at '$j'";

	    $sd->init ( { file => $j } );

	    unless ($sd->read_header) {
		printd "Unable to load dictionary from file '$j'";
		next;
	    }

	    unless ($csv) {
		print <<EOS;
File      : $j
Title     : $sd->{header}->{title}
Copyright : $sd->{header}->{copyright} 
Version   : $sd->{header}->{version}
Words     : $sd->{header}->{words_total}
Langs     : $sd->{header}->{w_lang}/$sd->{header}->{a_lang}

EOS
            } else {

$j =~ s|"|""|g;
$sd->{header}->{title} =~ s|"|""|g;
$sd->{header}->{copyright} =~ s|"|""|g;
$sd->{header}->{version} =~ s|"|""|g;

		print '"',
		$j, '","',
		$sd->{header}->{title}, '","',
		$sd->{header}->{copyright}, '","',
		$sd->{header}->{version}, '","',
		$sd->{header}->{words_total}, '","',
		$sd->{header}->{w_lang}, '/', $sd->{header}->{a_lang}, '"', "\n";
	    }

	    $sd->unload_dictionary;
	}
    }

} elsif ($find) {

    printd '--find';

    if (($sdict eq '') || ($word  eq '')) {
	PrintHelpQuit();
    }

    $sd->init ( { file => $sdict } );

    unless ($sd->read_header) {
	printd "Unable to load dictionary header from file '$sdict'";
	exit 1;
    }

     unless ($sd->load_dictionary_fast) {
	printd "Unable to load dictionary from file '$sdict'";
	exit 1;
    }

    my $art = $sd->search_word($word);

    if ($art ne '') {

	print <<EOS;
$word

$art
EOS
	    exit 0;

    }

    printd 'Not found';
    exit 1;

} else {
    PrintHelp();
}

exit 0;    

####
#  #
####

sub printd (;@) {
    $debug && print STDERR '"DEBUG: ', @_, "\n";
}

sub PrintHelpQuit {
    PrintHelp();
    exit 0;
}

sub PrintHelp {
    print <<EOS;
Usage: $0
           --list [--path] [--csv] List all available dictionaries, optionally in CSV format;
           --find --sdict=path/to/.dct --word=word Lookup word in dictionary
EOS
}



__END__
