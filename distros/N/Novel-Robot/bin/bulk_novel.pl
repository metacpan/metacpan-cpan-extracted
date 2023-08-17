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
getopt( 'sbqkjiD', \%opt );

my %opt_out = read_option( %opt );
our $xs = Novel::Robot->new( type => 'txt', site => $opt_out{site} );

my $info;
my $items_ref;

if ( $opt{q} ) {
  ( $info, $items_ref ) = $xs->{parser}->get_query_ref( $opt_out{query_keyword}, %opt_out );
} elsif ( $opt{b} ) {
  ( $info, $items_ref ) = $xs->{parser}->get_board_ref( $opt{b}, %opt_out );
}

exit unless ( $items_ref );

for my $r ( @$items_ref ) {
  my $u = $r->{url};
  if ( $opt_out{not_download} ) {
    print join( ",", $r->{writer} || $info, $r->{book} || $r->{title}, $r->{url} ), "\n";
  } else {
    $xs->get_novel( $u, %opt_out );
  }
}

sub read_option {
  my ( %opt ) = @_;

  my %opt_out = (
    site => $opt{s} || $opt{b},
    board         => $opt{b},
    query_type    => $opt{q} ? decode( locale => $opt{q} ) : undef,
    query_keyword => $opt{k} ? decode( locale => $opt{k} ) : undef,
    not_download => $opt{D} // 1,
  );

  if ( $opt{j} ) {
    @opt_out{qw/min_page_num max_page_num/} = Novel::Robot::split_index( $opt{P} );
  }

  if ( $opt{i} ) {
    @opt_out{qw/min_item_num max_item_num/} = Novel::Robot::split_index( $opt{i} );
  }

  return %opt_out;
} ## end sub read_option
