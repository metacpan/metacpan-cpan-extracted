#!/usr/bin/perl 
use strict;
use warnings;
use utf8;
use Encode qw/:all/;
use Encode::Locale;
use Getopt::Std;
$| = 1;

binmode( STDIN,  ":encoding(console_out)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
getopt( 'fTwb', \%opt );

my $convert_file = convert_novel( %opt );

sub convert_novel {
  my ( %opt ) = @_;
  return unless(-f $opt{f} and -s $opt{f});

  $opt{T} ||= 'mobi';

  my $dst_file = $opt{T};
  unless ( $dst_file =~ /[^.]+\.[^.]+$/ ) {
    $dst_file = $opt{f};
    $dst_file =~ s/[a-z0-9]+$/$opt{T}/i;
  }
  print decode(locale=>"$opt{f} => $dst_file\n");

  my ( $writer, $book ) = $opt{f} =~ /([^\\\/]+?)-([^\\\/]+?)\.[^.\\\/]+$/;
  my %conv = (
    'authors' => $opt{w} || $writer,
    'title'   => $opt{b} || $book,
    'chapter-mark'       => "none",
    'page-breaks-before' => "/",
    'max-toc-links'      => 0,
  );

  my $conv_str = join( " ", map { qq[--$_ "$conv{$_}"] } keys( %conv ) );
  my $cmd = qq[ebook-convert "$opt{f}" "$dst_file" $conv_str];

  $cmd .= " --mobi-keep-original-images" if ( $opt{T} =~ /mobi$/ );
  system( $cmd);

  return $dst_file;
} ## end sub convert_novel
