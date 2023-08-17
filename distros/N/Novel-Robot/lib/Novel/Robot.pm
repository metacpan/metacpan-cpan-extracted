# ABSTRACT: download novel /bbs thread
package Novel::Robot;
use strict;
use warnings;
use utf8;

use Novel::Robot::Parser;
use Novel::Robot::Packer;
use File::Copy;
use Encode::Locale;
use Encode;

our $VERSION = 0.43;

sub new {
  my ( $self, %opt ) = @_;
  $opt{max_process_num} ||= 3;
  $opt{type}            ||= 'html';

  my $parser  = Novel::Robot::Parser->new( %opt );
  my $packer  = Novel::Robot::Packer->new( %opt );
  my $browser = $parser->{browser};
  bless { %opt, parser => $parser, packer => $packer, browser => $browser },
    __PACKAGE__;
}

sub set_parser {
  my ( $self, $site ) = @_;
  $self->{site}   = $self->{parser}->detect_site( $site );
  $self->{parser} = Novel::Robot::Parser->new( %$self );
  return $self;
}

sub set_packer {
  my ( $self, $type ) = @_;
  $self->{type}   = $type;
  $self->{packer} = Novel::Robot::Packer->new( %$self );
  return $self;
}

sub get_novel {
  my ( $self, $index_url, %o ) = @_;

  my $novel_ref = $self->{parser}->get_novel_ref( $index_url, %o );
  return unless ( $novel_ref );
  return unless ( @{ $novel_ref->{item_list} } );
  return unless ( grep { $_->{content} } @{ $novel_ref->{item_list} } );

  while( ! $novel_ref->{item_list}[-1]{content}){
      pop @{$novel_ref->{item_list}};
  }

  my $last_item_num =
    scalar( @{ $novel_ref->{item_list} } ) > 0
    ? $novel_ref->{item_list}[-1]{id}
    : ( $novel_ref->{item_num} || scalar( @{ $novel_ref->{item_list} } ) );

  my $dst_f = $self->{packer}->main( $novel_ref, \%o );
  $dst_f = decode(locale=>$dst_f);
  print "info: $novel_ref->{writer}-$novel_ref->{book}-$last_item_num\noutput: $dst_f\nlast_item_num: $last_item_num\n" if ( $o{verbose} );
    
  return wantarray ? ( $dst_f, $novel_ref ) : $dst_f;
} ## end sub get_novel


sub split_index {
  my $s = $_[-1];
  return ( $s, $s ) if ( $s =~ /^\d+$/ );
  if ( $s =~ /^\d*-\d*$/ ) {
    my ( $min, $max ) = split '-', $s;
    return ( $min, $max );
  }
  return;
}

1;

