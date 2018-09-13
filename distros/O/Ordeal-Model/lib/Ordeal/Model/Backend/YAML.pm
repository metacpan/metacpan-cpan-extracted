package Ordeal::Model::Backend::YAML;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.002'; }
use Mo qw< default builder >;
use Ouch;
use Path::Tiny;
use YAML::Tiny qw< LoadFile >;
use autodie;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

extends 'Ordeal::Model::Backend::PlainFile';

use Ordeal::Model::Deck;

has _decks => (is => 'rw', lazy => 1, builder => '_build_decks');

sub deck ($self, $id) {
   my $d = $self->_decks->{$id} or ouch 404, "not found: deck '$id'";
   $_ = $self->card($_) for $d->{cards}->@*; # turn cards into Cards
   return Ordeal::Model::Deck->new(
      name => $id, # default value
      group => '', # default value
      $d->%*,      # whatever was read
      id => $id,   # this overrides whatever is in $d->%*
   );
}

sub decks ($self) { keys $self->_decks->%* }

sub _build_decks ($s) {
   return LoadFile(path($s->base_directory, 'decks.yml')->stringify);
}

1;
__END__
