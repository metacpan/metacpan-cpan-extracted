#!/usr/bin/perl 
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;
use Novel::Robot;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );

my %opt;
getopt( 'sufwbRtoCGFANDpviP', \%opt );

my %opt_out = read_option( %opt );

sub read_option {
  my ( %opt ) = @_;

  my %opt_out = (
    site => $opt{s} || $opt{u} || $opt{f},

    url => $opt{u},

    file          => $opt{f},
    writer        => $opt{w} ? decode( locale => $opt{w} ) : undef,
    book          => $opt{b} ? decode( locale => $opt{b} ) : undef,
    chapter_regex => $opt{R} ? decode( locale => $opt{R} ) : undef,

    type => $opt{t} || 'html',
    output   => $opt{o},
    with_toc => $opt{C} // 1,

    grep_content   => $opt{G} ? decode( locale => $opt{G} ) : undef,
    filter_content => $opt{F} ? decode( locale => $opt{F} ) : undef,
    only_poster    => $opt{A},
    min_content_word_num => $opt{N},

    max_process_num => $opt{p} // 1,

    not_download => $opt{D},
    verbose      => $opt{v} // 1,
  );

  if ( $opt{P} ) {
    @opt_out{qw/min_page_num max_page_num/} = Novel::Robot::split_index( $opt{P} );
  }

  if ( $opt{i} ) {
    @opt_out{qw/min_item_num max_item_num/} = Novel::Robot::split_index( $opt{i} );
  }

  if ( $opt{f} ) {
    my $tf = decode( locale => $opt{f} );
    my ( $tw, $tb, $suffix ) = $tf =~ m#([^\/\\]+)-([^\/\\]+)\.([^.]+)$#;
    $opt_out{site} = lc($suffix);
    $opt_out{writer} = $tw unless ( defined $opt_out{writer} );
    $opt_out{book}   = $tb unless ( defined $opt_out{book} );
  }

  return %opt_out;
} ## end sub read_option

our $xs = Novel::Robot->new( type => $opt_out{type}, site => $opt_out{site} );

if ( $opt{f} ) {
  my @path = split ',', $opt{f};
  $xs->get_item( \@path, %opt_out );
} elsif ( $opt{u} ) {
  if ( $opt{D} ) {
    my $r = $xs->{parser}->get_item_info( $opt{u}, %opt_out, max_page_num => 1 );
    print join( ",", $r->{writer} || '', $r->{book} || $r->{title} || '', $r->{url} || '', $r->{chapter_num} || '' ), "\n";
  } else {
    $xs->get_item( $opt{u}, %opt_out );
  }
} elsif ($opt{s} and $opt{w} and $opt{b}){
    $xs->get_item( "$opt{w}:$opt{b}", %opt_out );
}

