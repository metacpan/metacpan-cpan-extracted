package Ordeal::Model;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;
use warnings;
{ our $VERSION = '0.004'; }

use English qw< -no_match_vars >;
use Ouch;
use Mo qw< default >;
use Path::Tiny;
use Scalar::Util qw< blessed >;
use Module::Runtime qw< use_module require_module is_module_name >;

use Ordeal::Model::ChaCha20;
use Ordeal::Model::Evaluator;
use Ordeal::Model::Parser;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

has 'backend';
has random_source => (
   default => sub {
      require Ordeal::Model::ChaCha20;
      return Ordeal::Model::ChaCha20->new;
   }
);

sub _backend_factory ($package, $name, @args) {
   $name = $package->resolve_backend_name($name);
   return use_module($name)->new(@args);
}

sub _default_backend ($package) {
   require Ordeal::Model::Backend::PlainFile;
   return Ordeal::Model::Backend::PlainFile->new;
}

sub evaluate ($self, $what, %args) {
   my $ast = ref($what) ? $what : $self->parse($what);
   return Ordeal::Model::Evaluator::EVALUATE(
      ast           => $ast,
      model         => $self,
      random_source => $self->_random_source(%args),
   );
}

sub get_card ($self, $id) { return $self->backend->card($id) }
sub get_deck ($self, $id) { return $self->backend->deck($id) }
sub get_deck_ids ($self)  { return $self->backend->decks     }

sub new ($package, @rest) {
   my %args = (@_ && ref($_[0])) ? %{$rest[0]} : @rest;
   my $backend;
   if (defined(my $b = $args{backend})) {
      $backend = blessed($b)   ? $args{backend}
        : (ref($b) eq 'ARRAY') ? $package->_backend_factory(@$b)
        :                        ouch 400, 'invalid backend';
   }
   elsif (scalar(keys %args) == 0) {
      $backend = $package->_default_backend;
   }
   elsif (scalar(keys %args) == 1) {
      my ($name, $as) = %args;
      my @args = ref($as) eq 'ARRAY' ? @$as : %$as;
      $backend = $package->_backend_factory($name, @args);
   }
   else {
      ouch 400, 'too many arguments to initialize Model';
   }

   return $package->SUPER::new(backend => $backend);
}

sub parse ($self, $text) {
   ouch 400, 'undefined input expression to parse()' unless defined $text;
   return Ordeal::Model::Parser::PARSE($text);
}

sub _random_source ($self, %args) {
   return $args{random_source} if $args{random_source};

   return Ordeal::Model::ChaCha20->new->restore($args{random_source_state})
      if defined $args{random_source_state};

   return Ordeal::Model::ChaCha20->new(seed => $args{seed})
      if defined $args{seed};

   return $self->random_source;
}

sub resolve_backend_name ($package, $name) {
   $package = ref($package) || $package;
   my $invalid_error = "invalid name '$name' for module resolution";

   # if it has "::" *inside* but does not start with them, use directly
   if (($name =~ s{\A - }{}mxs) || ($name =~ m{\A [^:]+ ::})) {
      is_module_name($name) or ouch 400, $invalid_error;
      return $name;
   }

   # otherwise, remove any leading "::"
   $name =~ s{\A ::}{}mxs;
   is_module_name($name) or ouch 400, $invalid_error;

   # look for classes inside "backend" kind
   my %flag;
   for my $base ($package, __PACKAGE__) {
      next if $flag{$base}++;
      my $class = $base . '::Backend::' . $name;
      eval { require_module($class) } and return $class;
   }

   ouch 400, "cannot resolve '$name' to a backend module package";
}

1;
