package Params::PatternMatch;

# ABSTRACT: Pattern match-based argument binding for Perl.

use strict;
use warnings;
use B;
use Carp;
use Data::Compare;
use Exporter::Lite;
use Scalar::Util qw/blessed/;
use TryCatch;

our $COMPARATOR = Data::Compare->new;

our @EXPORT_OK = qw/as case match otherwise rest then/;

our $VERSION = '0.01';

our @args;

sub as(&) { @_ }

sub case {
  my $action = pop;
  Carp::croak('Not a CodeRef.') if ref $action ne 'CODE';

  my ($i, $j) = (0, 0);
  for (; $i < @args and $j < @_; ++$i, ++$j) {
    if (is_slurp_arg($_[$j])) {
      $_[$j]->set(@args[$i .. $#args]);
      $i = $#args;
      next;
    }
    if (is_lvalue($_[$j])) {
      $_[$j] = $args[$i];
      next;
    }
    next if $COMPARATOR->Cmp($args[$i], $_[$j]) != 0;

    return;  # Pattern didn't match.
  }
  return unless $i == @args and $j == @_ or is_slurp_arg($_[$j]);

  die Params::PatternMatch::Values->new($action->(@args));
}

sub is_lvalue($) { +(B::svref_2object(\$_[0])->FLAGS & B::SVf_READONLY) == 0 }

sub is_slurp_arg($) {
  blessed $_[0] and $_[0]->isa('Params::PatternMatch::SlurpArg');
}

sub match {
  my $patterns = pop;
  Carp::croak('Not a CodeRef.') if ref $patterns ne 'CODE';

  local *args = \@_;
  try {
    $patterns->();
  } catch (Params::PatternMatch::Values $retval) {
    return $retval->values;
  } catch ($error) {
    die $error;
  };
}

sub otherwise(&) {
  Carp::croak('Not a CodeRef.') if ref $_[0] ne 'CODE';
  die Params::PatternMatch::Values->new($_[0]->(@args));
}

sub rest(\@) { Params::PatternMatch::SlurpArg->new($_[0]) }

sub then(&) { @_ }

package Params::PatternMatch::SlurpArg;

sub new { bless $_[1] => $_[0] }

sub set { @{ $_[0] } = @_[1 .. $#_ ] }

package Params::PatternMatch::Values;

sub new { bless \@_ => shift }

sub values { wantarray ? @{ $_[0] } : $_[0][0] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Params::PatternMatch - Pattern match-based argument binding for Perl.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Carp ();
  use Params::PatternMatch qw/as case match otherwise rest then/;
  
  sub sum {
    match @_ => as {
      my ($n, @rest);
      case +() => then { 0 };
      case $n, rest(@rest) => then { $n + sum(@rest) };
    };
  }
  
  say sum(1 .. 10);  # 55
  
  sub factorial {
    match @_ => as {
      my $n;
      case 0 => then { 1 };
      case $n => then { $n * factorial($n - 1) };
      otherwise { Carp::croak('factorial: requires exactly 1 argument.') };
    };
  }
  
  say factorial(5);  # 120
  say factorial(1 .. 10);  # Error

=head1 DESCRIPTION

This extension provides keywords for pattern match-based argument binding like functional languages, such as Scala or ML.

=head2 CAVEAT

Note that the implementation is not tail call-optimized; Unlike real functional languages, you cannot use recursive C<match> instead of loop.

=head1 FUNCTIONS

None of them liseted below are exported by default. So you need to C<import> explicitly.

=head2 as(\&block), then(\&block)

Synonyms for C<sub>.

=head2 case(@pattern, \&then)

Returns evaluation value for C<&then> if the C<@pattern> matched with C<match>'s arguments.

=head2 match(@arguments, \&patterns)

Returns evaluation value for C<&patterns>.
C<@arguments> is passed as C<@_> to C<case>/C<otherwise> blocks.

=head2 otherwise(\&block)

Returns evaluation value for &block without pattern match.

=head2 rest(@slurped)

Slurps all the rest unbound arguments.

=head1 PATTERN MATCH RULE

Now I'll describe how the pattern match performs. C<match>'s arguments are element-wise-compared with C<case>'s pattern.

If an element in pattern is:

=over 4

=item an lvalue (i.e., a variable)

Always matches (except if no corresponding argument exists.) Corresponding argument will be assigned as its value.

=item C<rest>

Always matches. All the rest arguments will be slurped.

=item an rvalue (i.e., an immediate value)

The value will be compared with corresponding argument using L<Data::Compare>.

=back

The C<Data::Compare> instance used for rvalue comparison is stored in C<$Params::PatternMatch::COMPARATOR>. You can override match rule by C<local>ize the comparator:

  {
    local $Params::PatternMatch::COMPARATOR = Data::Compare->new(...);
    # Or anything having Cmp() method:
    package MyComparator {
      sub new { ... }
      
      # Returns 1 if the given $x and $y are equivalent, 0 otherwise.
      sub Cmp { my ($self, $x, $y) = @_; ... }
    }
    local $Params::PatternMatch::COMPARATOR = MyComparator->new(...);
    
    match @_ => as { ... };
  }

=head1 AUTHOR

Koichi SATOH <sato@seesaa.co.jp>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
