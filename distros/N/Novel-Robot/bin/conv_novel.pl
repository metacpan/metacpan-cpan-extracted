#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Long qw(:config no_ignore_case);
use Novel::Robot;

$| = 1;

#binmode( STDIN,  ":encoding(console_out)" );
#binmode( STDOUT, ":encoding(console_out)" );
#binmode( STDERR, ":encoding(console_out)" );

my %opt;

GetOptions(
  \%opt,
  'ebook_input|f=s',
  'ebook_output|o=s',
  'type|t=s',
  'writer|w=s', 'book|b=s',
);

our $xs = Novel::Robot->new( %opt );
$xs->{packer}->convert_novel($opt{ebook_input}, $opt{ebook_output}, \%opt);
