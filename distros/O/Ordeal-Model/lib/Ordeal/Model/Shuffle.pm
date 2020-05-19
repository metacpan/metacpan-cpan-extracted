package Ordeal::Model::Shuffle;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict; # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.003'; }
use English qw< -no_match_vars >;
use Mo qw< build default >;
use Ouch;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

has auto_reshuffle => (default => 0);
has deck => (default => undef);
has default_n_draw => (default => undef);
has random_source => (default => undef);
has _draw_sorted => (default => 0);
has _i => (default => undef);
has _indexes => (default => undef);

sub BUILD ($self) {
   ouch 400, 'no deck defined' unless $self->deck;
   if (! $self->random_source) {
      require Ordeal::Model::ChaCha20;
      $self->random_source(Ordeal::Model::ChaCha20->new);
   }
   $self->default_n_draw($self->deck->n_cards)
      unless defined $self->default_n_draw;

   $self->shuffle;

   return $self;
}

sub clone ($self, %args) {
   my $other = ref($self)->new(
      auto_reshuffle => $self->auto_reshuffle, # overridable
      default_n_draw => $self->default_n_draw, # overridable
      %args,
      deck => $self->deck, # this can't be overridden
   );
   $other->random_source($self->random_source->clone)
      unless exists $args{random_source};
   $other->_i($self->_i);
   if (my $indexes = $self->_indexes) {
      $other->_indexes([$indexes->@*]);
   }
   else {
      $other->_indexes(undef);
   }
   return $other;
}

sub draw ($self, $n = undef) {
   $n //= $self->default_n_draw;
   ouch 400, 'invalid number of cards', $n
      unless $n =~ m{\A(?: 0 | [1-9]\d*)\z}mxs;
   my $deck = $self->deck;

   my $i = $self->_i;
   $n = $i + 1 if $n == 0; # take them all
   ouch 400, 'not enough cards left', $n, $i + 1
      if $n > $i + 1;

   my @retval;
   if (my $indexes = $self->_indexes) {
      my $rs = $self->random_source;
      while ($n-- > 0) {
         my $j = $rs->int_rand(0, $i); # extremes included
         (my $retval, $indexes->[$j]) = $indexes->@[$j, $i--];
         push @retval, $deck->card_at($retval);
      }
   }
   else {
      my $top_index = $deck->n_cards - 1;
      while ($n-- > 0) {
         push @retval, $deck->card_at($top_index - $i--);
      }
   }

   # prepare for next call
   $self->auto_reshuffle ? $self->shuffle : $self->_i($i);

   return $retval[0] if @retval == 1;
   return @retval;
}

sub is_sorted ($self) { return !($self->_indexes) }

sub n_remaining ($self) { return $self->_i + 1 }

sub reset ($self) {
   $self->random_source->reset;
   return $self->shuffle;
}

sub shuffle ($self) {
   $self->_i(my $i = $self->deck->n_cards - 1);
   $self->_indexes([0 .. $i]);
   return $self;
}

sub sort ($self) {
   $self->_i($self->deck->n_cards - 1);
   $self->_indexes(undef);
   return $self;
}

1;
