package RFID::ISO15693::Tag;

our $VERSION = 0.002;
our @ISA = qw(RFID::Tag Exporter);

# Written by SATO 'paina' Taisuke <paina@wide.ad.jp>
# Copyright (C) SATO Taisuke/Auto-ID Labs. Japan
# See the file LICENSE included with the distribution for license
# information.

=head1 NAME

RFID::ISO15693::Tag - An ISO15693 RFID Tag

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;

use RFID::Tag;
use Exporter;

our @EXPORT_OK = qw(PAGE_BYTES
		    %PROPS);

use constant TAGTYPE    => 'iso15693';
use constant PAGE_BYTES => 4;

use overload '+' => "combine";

our %PROPS = (id    => { bytes      =>  8,  #constantつかうべきかもしれないけど、
			 writable   =>  0}, #あまりにめんどくさい
	      b0    => { bytes      => 64,
			 writable   =>  1,
		         page_range => [0..15]},
	      b1    => { bytes      => 48,
			 writable   =>  1,
		         page_range => [0..12]},
	      afi   => { bytes      =>  1,
			 writable   =>  1},
	      dsfid => { bytes      =>  1,
			 writable   =>  1});

sub getprops {
  my $self = shift;

  return %PROPS;
}

=head2 new

Returns a new RFID::ISO15693::Tag object.

=cut

sub new {
  my $class = shift;
  my (%p) = @_;

  my $self = {};
  bless $self, $class;

  my %default;
  foreach my $prop (keys %PROPS) {
    $default{$prop} = '0' x ($PROPS{$prop}->{bytes} * 2)
  }
  $self->set(%default);

  $self->set(%p) if (%p);

  return $self;
}

=head2 combine

Combine two RFID::ISO15693::Tag object and returns

=cut


sub combine {
  my $self = shift;
  my $other = shift;

  unless (ref($self) eq ref($other)) { #selfとotherのクラスを調べる
    carp "combine method can combine same tags only";
    return undef;
  }

  my %add = $other->get;

  foreach my $prop (keys %add) { #keyはあっても空ってことはよくある話
    delete $add{$prop} if (not $add{$prop});
  }

  $self->set($self->get, %add);
}

=head2 set

Set contents of the tag by a hash.

=cut

sub set {
  my $self = shift;
  my (%p) = @_;

  foreach my $prop (keys %p) {
    if (grep { lc $prop eq $_ } keys(%PROPS)) {
      if (not $p{$prop}) {
	delete $self->{$prop};
      } elsif (length($p{$prop}) / 2 == $PROPS{$prop}->{bytes}) {
	$self->{$prop} = $p{$prop};
      } else {
	carp "Length of '$prop' must be ".$PROPS{$prop}->{bytes}." bytes but ".
	     (length($p{$prop}) / 2)." bytes";
      }
    } else {
      carp "No such properties '$prop'";
    }
  }

  return $self;
}

=head2 get

Return contents of the tag as a hash.

=cut

sub get {
  my $self = shift;
  my (@p) = @_ || keys %PROPS; # 特に指定がなければぜんぶ返す。hashだしね
  my (%ret);

  foreach my $prop (@p) {
    if (lc $prop eq 'type') {
      $ret{$prop} = TAGTYPE;
    } elsif (grep { lc $prop eq $_ } keys(%PROPS)) {
      $ret{$prop} = $self->{$prop};
    } else {
      carp "No such properties '$prop' in";
    }
  }

  if (wantarray) {
    return %ret;
  } else {
    return $ret{$_[$#_]}; # return last value
  }
}

=head2 getref

Return contents of the tag as a reference of a hash.

=cut

sub getref {
  my $self = shift;
  my (@p) = @_;

  my %ret = $self->get(@p);

  return \%ret;
}

=head2 pages

Return all pages of bank 0 or bank 1 as a hash.

=cut

sub pages {
#b0かb1をページ単位のhashにして返す
#引数にhashを指定すると、そこだけ置き換える
  my $self = shift;
  my (%p) = @_;


  my $bank = $p{Bank} || 'b0';

  unless ($bank eq 'b0' || $bank eq 'b1') {
    carp "Invalid bank";
    return undef;
  }

  if ($p{Replace}) {
    my %rep_pages = %{$p{Replace}};
    foreach my $rep_page_no (keys %rep_pages) {
      substr($self->{$bank}, $rep_page_no * PAGE_BYTES * 2, PAGE_BYTES * 2)
	= uc $rep_pages{$rep_page_no};
    }
  }

  my %ret;
  foreach my $page (@{$PROPS{$bank}->{page_range}}) {
    $ret{$page} = substr($self->{$bank}, $page * PAGE_BYTES * 2, PAGE_BYTES * 2);
  }

  return %ret;
}

=head2 pagesref

Return all pages of bank 0 or bank 1 as a reference of a hash.

=cut

sub pagesref {
  my $self = shift;
  my (@p) = @_;

  my %ret = $self->pages(@p);

  return \%ret;
}
1;


