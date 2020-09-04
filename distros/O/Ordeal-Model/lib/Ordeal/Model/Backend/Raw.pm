package Ordeal::Model::Backend::Raw;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.004'; }
use Mo qw< build default >;
use Ouch;
use autodie;

use experimental qw< postderef signatures >;
no warnings qw< experimental::postderef experimental::signatures>;

use Ordeal::Model::Card;
use Ordeal::Model::Deck;

has data      => (default => undef);
has _card_for => (default => undef);
has _deck_for => (default => undef);
has _deck_ids => (default => undef);

sub BUILD ($self) {
   my $data = $self->data;
   $self->data(undef);    # no need to keep this around any more

   ouch 400, 'invalid data for Raw backend', $data
     unless ref($data) eq 'HASH';
   ouch 400, "invalid 'cards' in data for Raw backend", $data->{cards}
     unless ref($data->{cards}) eq 'ARRAY';
   ouch 400, "invalid 'decks' in data for Raw backend", $data->{decks}
     unless ref($data->{decks}) eq 'ARRAY';

   # expand and arrange cards in hash, keyed by id
   $self->_card_for(\my %card_for);
   for my $card ($data->{cards}->@*) {
      ouch 400, 'invalid card', $card unless ref($card) eq 'HASH';
      my $id = $card->{id};
      ouch 400, 'invalid id in card', $card unless defined $id;
      ouch 400, 'duplicated card id', $id if exists $card_for{$id};
      $card_for{$id} = Ordeal::Model::Card->new($card->%*);
   } ## end for my $card ($data->{cards...})

   # expand and arrange decks in hash, keyed by id. Save list of
   # deck identifiers in the order they appear, too.
   $self->_deck_for(\my %deck_for);
   $self->_deck_ids(\my @deck_ids);
   for my $deck ($data->{decks}->@*) {
      ouch 400, 'invalid deck', $deck unless ref($deck) eq 'HASH';
      my $id = $deck->{id};
      ouch 400, 'invalid id in deck', $deck unless defined $id;
      ouch 400, 'duplicated deck id', $id if exists $deck_for{$id};

      # Resolve cards in deck
      my $cards = $deck->{cards};
      ouch 400, 'invalid cards in deck', $deck
        unless ref($cards) eq 'ARRAY';
      my @cs = map {
         my $card = $card_for{$_} or ouch 404, 'card not found', $_;
         $card;
      } $cards->@*;

      $deck_for{$id} = Ordeal::Model::Deck->new(
         name => $id, # default
         $deck->%*,
         cards => \@cs, # override
      );
      push @deck_ids, $deck->{id};
   } ## end for my $deck ($data->{decks...})

   return;
} ## end sub BUILD ($self)

sub card ($self, $id) {
   my $card = $self->_card_for->{$id} or ouch 404, 'card not found', $id;
   return $card;
}

sub deck ($self, $id) {
   my $deck = $self->_deck_for->{$id} or ouch 404, 'deck not found', $id;
   return $deck;
}

sub decks ($s) { return $s->_deck_ids->@* }

1;
__END__
