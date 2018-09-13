package Ordeal::Model::Backend::PlainFile;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.002'; }
use Mo qw< default >;
use Path::Tiny;
use Ouch;
use autodie;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

use Ordeal::Model::Card;
use Ordeal::Model::Deck;

has base_directory => (default => 'ordeal-assets');

sub card ($self, $id) {
   my ($name, $extension) = $id =~ m{\A (.*) \. (.*) \z}mxs
      or ouch 400, 'invalid identifier', $id;
   my $content_type = $self->content_type_for($extension);
   my $path = $self->path_for(cards => $id);
   return Ordeal::Model::Card->new(
      content_type => $content_type,
      group        => '',
      id           => $id,
      name         => $name,
      data         => sub { $path->slurp_raw },
   );
} ## end sub get_card

sub content_type_for ($self, $extension) {
   state $content_type_for = {
      png => 'image/png',
      jpg => 'image/jpeg',
      svg => 'image/svg+xml',
   };
   my $content_type = $content_type_for->{lc($extension)}
     or ouch 400, 'invalid extension', $extension;
   return $content_type;
}

sub deck ($self, $id) {
   my $path = $self->path_for(decks => $id);

   my @cards;
   if ($path->is_dir) {
      @cards =
        map  { $_->realpath->basename }
        sort { $a->basename cmp $b->basename } $path->children;
   }
   else {
      @cards = $path->lines({chomp => 1});
   }
   $_ = $self->card($_) for @cards;

   return Ordeal::Model::Deck->new(
      group => '',
      id    => $id,
      name  => $id,
      cards => \@cards,
   );
}

sub decks ($s) {
   return
      grep { ! m{\A [._]}mxs } # nothing hidden or starting with underscore
      map { $_->basename }     # return identifiers of decks
      path($s->base_directory)->children;
}

sub path_for ($self, $type, $id) {
   my $path = path($self->base_directory)->child($type => $id);
   $path->exists or ouch 404, 'not found', $id;
   return $path;
}

1;
__END__
