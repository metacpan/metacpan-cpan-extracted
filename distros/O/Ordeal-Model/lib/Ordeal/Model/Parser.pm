package Ordeal::Model::Parser;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.002'; }
use Ouch;

use constant SHOW_CHARS => 20;
use constant ELLIPSIS   => '...';

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

use Exporter qw< import >;
our @EXPORT_OK = qw< PARSE >;

sub PARSE ($text) {
   state $expression = _expression();
   my $ast = $expression->(\$text);
   my $pos = pos $text;
   my ($blanks, $rest) = substr($text, $pos) =~ m{\A (\s*) (.*) }mxs;
   if (length $rest) {
      $pos += length($blanks // '');
      my $prest = $rest;
      $prest = length($rest) > SHOW_CHARS
         ? (substr($rest, 0, SHOW_CHARS - length ELLIPSIS) . ELLIPSIS)
         : $rest;
      ouch 400, "unknown sequence starting at $pos '$prest'", $rest;
   }
   return $ast;
}

########################################################################
# Generic parsing facilities

sub __alternator (@alternatives) {
   return sub ($rtext) {
      __ews($rtext);
      for my $alt (@alternatives) {
         next unless defined(my $retval = $alt->($rtext));
         return $retval;
      }
      return;
   };
}

sub __ews ($rtext) { return __ewsr()->($rtext) }
sub __ewsr { state $retval = __regexper(qr{\s+}) }

sub __exact ($what, @retval) {
   my $wlen = length $what;
   return sub ($rtext) {
      my $pos = pos($$rtext) // 0;
      return if length($$rtext) - $pos < $wlen;
      return if substr($$rtext, $pos, $wlen) ne $what;
      pos($$rtext) = $pos + $wlen;
      return [@retval];
   };
}

sub __lister ($what, $sep = undef) {
   $sep = __exact($sep) if defined($sep) && ! ref($sep);
   return sub ($rtext) {
      __ews($rtext);
      defined(my $base = $what->($rtext)) or return;
      my $rest = __starer(
         sub ($rtext) {
            if ($sep) {
               __ews($rtext);
               $sep->($rtext) or return; # check & discard
            }
            __ews($rtext);
            $what->($rtext);
         }
      )->($rtext);
      $sep->($rtext) if $sep; # optional ending
      unshift $rest->@*, $base;
      return $rest;
   };
}

sub __regexper ($rx) {
   return sub ($rtext) {
      my (undef, $retval) = $$rtext =~ m{\G()$rx}cgmxs or return;
      return [$retval];
   };
}

sub __resolver { # probably unneeded
   state $retval = sub ($what) {
      return $what if ref $what;
      return __PACKAGE__->can($what);
   };
}

sub __sequencer (@items) {
   return sub ($rtext) {
      my $pos = pos $$rtext;
      my @retval;
      for my $item (@items) {
         my $ews = __ews($rtext);
         $item = __exact($item) unless ref $item;
         if (defined(my $piece = $item->($rtext))) {
            push @retval, $piece;
         }
         else { # fail
            pos($$rtext) = $pos;
            return;
         }
      }
      return \@retval;
   };
}

sub __starer ($what, $min = 0) {
   return sub ($rtext) {
      my $pos = pos $$rtext;
      my @retval;
      my $local_min = $min;
      while ('possible') {
         __ews($rtext);
         defined(my $piece = $what->($rtext)) or last;
         push @retval, $piece;
         if ($local_min > 0) {
            --$local_min;
         }
         else {
            $pos = pos $$rtext;
         }
      }
      pos($$rtext) = $pos; # "undo" last try/tries
      return if $local_min > 0; # failed to match at least $min
      return \@retval;
   };
}

########################################################################
# Specific grammar

sub _addend {
   state $r = sub ($rtext) {
      state $op = __regexper(qr{([*x])});
      state $seq = __sequencer(
         __starer(__sequencer(_positive_int(), $op)),
         _atom(),
         __starer(__sequencer($op, _positive_int())),
      );
      my $match = $seq->($rtext) or return;
      my ($pre, $retval, $post) = $match->@*;
      $retval = ___mult($retval, reverse($_->@*)) for reverse($pre->@*);
      $retval = ___mult($retval,        ($_->@*)) for        ($post->@*);
      return $retval;
   }
}

sub _atom {
   state $base = _atom_base();
   state $unaries = __starer(_atom_unary());
   state $retval = sub ($rtext) {
      my $retval = $base->($rtext) or return;
      for my $unary ($unaries->($rtext)->@*) {
         my ($op, @rest) = $unary->@*;
         $retval = [$op, $retval, @rest];
      }
      return $retval;
   };
}

sub _atom_base {
   state $sub_expression = sub ($rtext) {
      state $seq = __sequencer('(', _expression(), ')');
      my $match = $seq->($rtext) or return;
      return $match->[1];
   };
   state $retval = __alternator(
      _identifier(),
      $sub_expression,
   );
}

sub _atom_unary {
   state $r = __alternator(_sslicer(), _slicer(), _sorter(), _shuffler());
}

sub _expression {
   state $r = sub ($rtext) {
      state $addend = _addend();
      state $seq = __sequencer(
         $addend,
         __starer(__sequencer(__regexper(qr{([-+])}), $addend)),
      );
      state $name_for = {'+' => 'sum', '-' => 'subtract'};
      my $match = $seq->($rtext) or return;
      my ($retval, $transformations) = $match->@*;
      for my $t ($transformations->@*) {
         my ($op, $addend) = $t->@*;
         $retval = [$name_for->{"$op->@*"}, $retval, $addend];
      }
      return $retval;
   };
}

sub _identifier {
   state $retval = sub ($rtext) {
      state $alts = __alternator(_token(), _quoted_string());
      my $rv = $alts->($rtext) or return;
      return [resolve => $rv->[0]];
   };
}

sub _int { state $r = __alternator(_simple_int(), _random_int()) }

sub _int_item { state $r = __alternator(_int_sr(), _int_range(), _int()) }

sub _int_item_list { state $r = __lister(_int_item(), ',') }

sub _int_range { state $r = _ranger((_int()) x 2) }

sub _int_sr {
   state $r = sub ($rtext) {
      state $seq = __sequencer('#', _positive_int());
      my $list = $seq->($rtext) or return;
      my ($n) = ___promote_simple_ints($list->[1]);
      return [range => 0 => [math_subtract => $n => 1]];
   }
}

sub _positive_int {
   state $r = __alternator(_positive_simple_int(), _positive_random_int());

}

sub _positive_random_int {
   state $r = sub ($rtext) {
      state $ri = _random_int();
      my $pos = pos $$rtext;
      my $r = $ri->($rtext) or return;

      state $is_positive;
      $is_positive ||= sub ($x) {
         return $x > 0 unless ref $x;
         for my $i (1 .. $#$x) { # skip 1st item in array
            return unless $is_positive->($x->[$i]);
         }
         return 1; # all checks were good
      };
      return $r if $is_positive->($r);

      return;
   };
}

sub _positive_simple_int { state $r = __regexper(qr{([1-9][0-9]*)}) }

sub _quoted_string { state $r = __regexper(qr{"((?:[^\\"]|\\.)*)"}) }

sub _random_int {
   state $r = sub ($rtext) {
      state $seq = __sequencer('{', _int_item_list(), '}');
      my $list = $seq->($rtext) or return;
      return [random => ___promote_simple_ints($list->[1]->@*)];
   };
}

sub _ranger ($t1, $t2) {
   my $ranger = __sequencer($t1, '..', $t2);
   return sub ($rtext) {
      my $range = $ranger->($rtext) or return;
      return [range => ___promote_simple_ints($range->@[0, 2])];
   };
}

sub _shuffler { state $r = __exact('@', 'shuffle') }

sub _simple_int { state $r = __regexper(qr{(0|-?[1-9][0-9]*)}) }

sub _slicer {
   state $r = sub ($rtext) {
      state $slicer = __sequencer('[', _int_item_list(), ']');
      my $slice = $slicer->($rtext) or return;
      return [slice => ___promote_simple_ints($slice->[1]->@*)];
   };
}

sub _sorter { state $r = __exact('!', 'sort') }

sub _sslicer {
   state $r = sub ($rtext) {
      state $catcher = _int();
      my $catched = $catcher->($rtext) or return;
      my ($n) = ___promote_simple_ints($catched);
      return [slice => [range => 0 => [math_subtract => $n => 1]]];
   };
}

sub _token { state $r = __regexper(qr{([a-zA-Z]\w*)}) }



########################################################################
# Convenience functions
sub ___mult ($atom, $op, $n) {
   state $name_for = {'*' => 'repeat', 'x' => 'replicate'};
   return [$name_for->{"$op->@*"}, $atom, ___promote_simple_ints($n)];
}

sub ___promote_simple_ints (@list) {
   map {($_->@* <= 1) ? ($_->@*) : $_} @list;
}

sub ___log ($rtext, $prefix = '') {
   my $pos = pos($$rtext) // 0;
   my $rest = substr $$rtext, $pos;
}

1;
