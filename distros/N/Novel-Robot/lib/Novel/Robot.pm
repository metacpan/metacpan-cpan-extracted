# ABSTRACT: download novel /bbs thread
package Novel::Robot;
use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Parallel::ForkManager;

use Novel::Robot::Parser;
use Novel::Robot::Packer;

our $VERSION = 0.40;

sub new {
    my ( $self, %opt ) = @_;
    $opt{max_process_num} ||= 3;
    $opt{type}            ||= 'html';

    my $parser  = Novel::Robot::Parser->new(%opt);
    my $packer  = Novel::Robot::Packer->new(%opt);
    my $browser = $parser->{browser};
    bless { %opt, parser => $parser, packer => $packer, browser => $browser },
      __PACKAGE__;
}

sub set_parser {
    my ( $self, $site ) = @_;
    $self->{site} = $self->{parser}->detect_site($site);
    $self->{parser}  = Novel::Robot::Parser->new(%$self);
    return $self;
} ## end sub set_parser

sub set_packer {
    my ( $self, $type ) = @_;
    $self->{type} = $type;
    $self->{packer}  = Novel::Robot::Packer->new(%$self);
    return $self;
} ## end sub set_packer

sub get_item {
    my ( $self, $index_url, %o ) = @_;

    my $item_ref = $self->{parser}->get_item_ref( $index_url, %o );

    my $last_floor_num = $item_ref->{floor_num} || scalar(@{$item_ref->{floor_list}});
    print "last_floor_num: $last_floor_num\n" if ( $o{verbose} );

    return unless ($item_ref);
    return unless(@{$item_ref->{floor_list}});
    return unless(grep { $_->{content} } @{$item_ref->{floor_list}});

    $self->{packer}->format_item_output( $item_ref, \%o );
    my $r = $self->{packer}->main( $item_ref, %o );
    return wantarray ? ( $r, $item_ref ) : $r;
} ## end sub get_item

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
