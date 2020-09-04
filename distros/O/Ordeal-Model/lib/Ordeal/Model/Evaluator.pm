package Ordeal::Model::Evaluator;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.004'; }
use Scalar::Util qw< blessed >;
use Mo qw< build default >;
use Ouch;
use Ordeal::Model::Deck;
use Ordeal::Model::Shuffle;

use Exporter qw< import >;
our @EXPORT_OK = qw< EVALUATE >;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

has _dc => (); # deck cache
has _model => ();
has _rs => (
   default => sub {
      require Ordeal::Model::ChaCha20;
      return Ordeal::Model::ChaCha20->new;
   }
);
has _stack => ();

sub BUILD ($self) {
   my $m = delete($self->{model}) or ouch 400, 'no model provided';
   $self->_model($m);
   $self->_rs(delete $self->{random_source})
      if exists $self->{random_source};
   $self->_dc({});
   $self->_stack([]);
   return $self;
}

sub EVALUATE (%args) {
   my $ast = delete($args{ast}) or ouch 400, 'no ast provided';
   return __PACKAGE__->new(%args)->_eval($ast);
}

sub _eval ($self, $ast) {
   my ($op, @params) = $ast->@*;
   my $method = eval {
      die '' if substr($op, 0, 1) eq '_'; # no "private" stuff
      die '' if lc($op) ne $op;           # no "uppercase" stuff
      $self->can($op);
   } or ouch 400, 'unknown op', $op;
   return $self->$method(@params);
}

sub _get_integer ($self, $n) {
   push $self->_stack->@*, 0;
   ($n) = $self->_unroll($n);
   pop $self->_stack->@*;
   return $n;
}

sub _shuffle ($self, $deck) {
   $deck = Ordeal::Model::Deck->new(cards => $deck) unless blessed $deck;
   return Ordeal::Model::Shuffle->new(
      auto_reshuffle => 0,
      deck           => $deck,
      default_n_draw => $deck->n_cards,
      random_source  => $self->_rs,
   )->sort;
} ## end sub _shuffle ($self, $deck)

sub _unroll ($self, @potentials) {
   my $N = $self->_stack->[-1];
   return map { $N ? ($_ % $N) : $_ } map {
      ref($_) ? $self->_eval($_) : $_;
   } @potentials;
}

sub math_subtract ($self, $t1, $t2) {
   return $self->_get_integer($t1) - $self->_get_integer($t2);
}

sub random ($self, @potentials) {
   my @candidates = $self->_unroll(@potentials);
   return $candidates[$self->_rs->int_rand(0, $#candidates)];
}

sub range ($self, $lo, $hi) {
   ($lo, $hi) = $self->_unroll($lo, $hi);
   return $lo .. $hi;
}

sub repeat ($self, $s_ast, $n) {
   $n = $self->_get_integer($n);
   my @cards;
   while ($n-- > 0) {
      my $s = $self->_eval($s_ast);
      push @cards, $s->draw;
   }
   return $self->_shuffle(\@cards);
}

sub replicate ($self, $s_ast, $n) {
   $n = $self->_get_integer($n);
   my $s = $self->_eval($s_ast);
   my @cards = $s->draw;
   return $self->_shuffle([(@cards) x $n]);
}

sub resolve ($self, $shuffle) {
   return $shuffle
     if blessed($shuffle) && $shuffle->isa('Ordeal::Model::Shuffle');
   my $deck = $self->_dc->{$shuffle} //= $self->_model->get_deck($shuffle);
   return $self->_shuffle($deck);
}

sub shuffle ($self, $s_ast) { return $self->_eval($s_ast)->shuffle }

sub slice ($self, $s_ast, @slices) {
   my $s = $self->_eval($s_ast)           # 400's upon error
      or ouch 500, 'slice: invalid AST', $s_ast; # "my" error => 500

   push $self->_stack->@*, $s->deck->n_cards;
   my @indexes = $self->_unroll(@slices);
   pop $self->_stack->@*;

   my $max = 0;
   $max = ($max < $_ ? $_ : $max) for @indexes;
   my @cards = $s->draw($max + 1);
   return $self->_shuffle([@cards[@indexes]]);
}

sub sort ($self, $s_ast) { return $self->_eval($s_ast)->sort }

sub subtract ($self, $s1_ast, $s2_ast) {
   my $s1 = $self->_eval($s1_ast);
   my $s2 = $self->_eval($s2_ast);
   my @cards = $s1->draw;
   for my $deleted ($s2->draw) {
      for my $i (0 .. $#cards) {
         next if $cards[$i] ne $deleted;
         splice @cards, $i, 1;
         last;
      }
   }
   return $self->_shuffle(\@cards);
}

sub sum ($self, $s1_ast, $s2_ast) {
   my $s1 = $self->_eval($s1_ast);
   my $s2 = $self->_eval($s2_ast);
   return $self->_shuffle([$s1->draw, $s2->draw]);
}

1;
