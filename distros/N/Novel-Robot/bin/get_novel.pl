#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Long;
use Novel::Robot;
use Data::Dumper;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
GetOptions(
    \%opt,
    'site|s=s', 'url|u=s', 'file|f=s', 'writer|w=s', 'book|b=s',
    'type|t=s', 'output|o=s',
    'chapter_regex|r=s', 
    'item|i=s', 'page|p=s', 'cookie|c=s',

    'with_toc|C', 'grep_content|G=s', 'filter_content|F=s', 'only_poster|A', 'min_content_word_num|N=i',

    'not_download|D', 'max_process_num|P=i', 'verbose|v',

    'content_path=s',  'writer_path=s',  'book_path=s', 'novel_list_path=s',
    'content_regex=s', 'writer_regex=s', 'book_regex=s',
);

%opt = read_option( %opt );

#our $xs = Novel::Robot->new( type => $opt{type}, site => $opt{site} );
our $xs = Novel::Robot->new( %opt );
if ( $opt{cookie} ) {
  my ( $dom, $base_dom ) = $xs->{parser}->detect_domain( $xs->{parser}->domain() || $opt{url} );
  $xs->{browser}->read_moz_cookie( $opt{cookie}, $base_dom );
}

if ( $opt{file} ) {
  my @path = split ',', $opt{file};
  $xs->get_item( \@path, %opt );
} elsif ( $opt{url} ) {
  if ( $opt{not_download} ) {
    my $r = $xs->{parser}->get_item_info( $opt{url}, %opt, max_page_num => 1 );
    print join( ",", $r->{writer} || '', $r->{book} || $r->{title} || '', $r->{url} || '', $r->{floor_num} || '' ), "\n";
  } else {
    $xs->get_item( $opt{url}, %opt );
  }
} elsif ( $opt{site} and $opt{writer} and $opt{book} ) {
  $xs->get_item( "$opt{writer}:$opt{book}", %opt );
}

sub read_option {
  my ( %opt ) = @_;
  $opt{site} ||= $opt{url} || $opt{file};
  $opt{type} ||= 'html';
  $opt{with_toc}        //= 1;
  $opt{max_process_num} //= 1;
  $opt{verbose}         //= 1;

  for my $k (
    qw/writer writer_path writer_regex book book_path book_regex content_path content_regex novel_list_path
    chapter_regex
    grep_content filter_content
    /
    ) {
    next unless ( exists $opt{$k} );
    $opt{$k} = decode( locale => $opt{$k} );
  }

  if ( $opt{page} ) {
    @opt{qw/min_page_num max_page_num/} = Novel::Robot::split_index( $opt{page} );
  }

  if ( $opt{item} ) {
    @opt{qw/min_item_num max_item_num/} = Novel::Robot::split_index( $opt{item} );
  }

  if ( $opt{file} ) {
    my $tf = decode( locale => $opt{file} );
    my ( $tw, $tb, $suffix ) = $tf =~ m#([^\/\\]+)-([^\/\\]+)\.([^.]+)$#;
    $opt{site}   = lc( $suffix );
    $opt{writer} = $tw unless ( defined $opt{writer} );
    $opt{book}   = $tb unless ( defined $opt{book} );
  }

  return %opt;
} ## end sub read_option
