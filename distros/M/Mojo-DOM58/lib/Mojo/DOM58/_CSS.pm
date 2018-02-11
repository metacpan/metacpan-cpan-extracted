package Mojo::DOM58::_CSS;

# This file is part of Mojo::DOM58 which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for Mojo::DOM58 for full license details.

use strict;
use warnings;

our $VERSION = '1.005';

my $ESCAPE_RE = qr/\\[^0-9a-fA-F]|\\[0-9a-fA-F]{1,6}/;
my $ATTR_RE   = qr/
  \[
  ((?:$ESCAPE_RE|[\w\-])+)                              # Key
  (?:
    (\W)?=                                              # Operator
    (?:"((?:\\"|[^"])*)"|'((?:\\'|[^'])*)'|([^\]]+?))   # Value
    (?:\s+(i))?                                         # Case-sensitivity
  )?
  \]
/x;

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub tree {
  my $self = shift;
  return $self->{tree} unless @_;
  $self->{tree} = shift;
  return $self;
}

sub matches {
  my $tree = shift->tree;
  return $tree->[0] ne 'tag' ? undef : _match(_compile(shift), $tree, $tree);
}

sub select     { _select(0, shift->tree, _compile(@_)) }
sub select_one { _select(1, shift->tree, _compile(@_)) }

sub _ancestor {
  my ($selectors, $current, $tree, $one, $pos) = @_;

  while ($current = $current->[3]) {
    return undef if $current->[0] eq 'root' || $current eq $tree;
    return 1 if _combinator($selectors, $current, $tree, $pos);
    last if $one;
  }

  return undef;
}

sub _attr {
  my ($name_re, $value_re, $current) = @_;

  my $attrs = $current->[2];
  for my $name (keys %$attrs) {
    my $value = $attrs->{$name};
    next if $name !~ $name_re || (!defined $value && defined $value_re);
    return 1 if !(defined $value && defined $value_re) || $value =~ $value_re;
  }

  return undef;
}

sub _combinator {
  my ($selectors, $current, $tree, $pos) = @_;

  # Selector
  return undef unless my $c = $selectors->[$pos];
  if (ref $c) {
    return undef unless _selector($c, $current);
    return 1 unless $c = $selectors->[++$pos];
  }

  # ">" (parent only)
  return _ancestor($selectors, $current, $tree, 1, ++$pos) if $c eq '>';

  # "~" (preceding siblings)
  return _sibling($selectors, $current, $tree, 0, ++$pos) if $c eq '~';

  # "+" (immediately preceding siblings)
  return _sibling($selectors, $current, $tree, 1, ++$pos) if $c eq '+';

  # " " (ancestor)
  return _ancestor($selectors, $current, $tree, 0, ++$pos);
}

sub _compile {
  my $css = "$_[0]";
  $css =~ s/^\s+//;
  $css =~ s/\s+$//;

  my $group = [[]];
  while (my $selectors = $group->[-1]) {
    push @$selectors, [] unless @$selectors && ref $selectors->[-1];
    my $last = $selectors->[-1];

    # Separator
    if ($css =~ /\G\s*,\s*/gc) { push @$group, [] }

    # Combinator
    elsif ($css =~ /\G\s*([ >+~])\s*/gc) { push @$selectors, $1 }

    # Class or ID
    elsif ($css =~ /\G([.#])((?:$ESCAPE_RE\s|\\.|[^,.#:[ >~+])+)/gco) {
      my ($name, $op) = $1 eq '.' ? ('class', '~') : ('id', '');
      push @$last, ['attr', _name($name), _value($op, $2)];
    }

    # Attributes
    elsif ($css =~ /\G$ATTR_RE/gco) {
      push @$last, [
        'attr', _name($1),
        _value(
          defined($2) ? $2 : '',
          defined($3) ? $3 : defined($4) ? $4 : $5,
          $6
        ),
      ];
    }

    # Pseudo-class
    elsif ($css =~ /\G:([\w\-]+)(?:\(((?:\([^)]+\)|[^)])+)\))?/gcs) {
      my ($name, $args) = (lc $1, $2);

      # ":matches" and ":not" (contains more selectors)
      $args = _compile($args) if $name eq 'matches' || $name eq 'not';

      # ":nth-*" (with An+B notation)
      $args = _equation($args) if $name =~ /^nth-/;

      # ":first-*" (rewrite to ":nth-*")
      ($name, $args) = ("nth-$1", [0, 1]) if $name =~ /^first-(.+)$/;

      # ":last-*" (rewrite to ":nth-*")
      ($name, $args) = ("nth-$name", [-1, 1]) if $name =~ /^last-/;

      push @$last, ['pc', $name, $args];
    }

    # Tag
    elsif ($css =~ /\G((?:$ESCAPE_RE\s|\\.|[^,.#:[ >~+])+)/gco) {
      push @$last, ['tag', _name($1)] unless $1 eq '*';
    }

    else {last}
  }

  return $group;
}

sub _empty { $_[0][0] eq 'comment' || $_[0][0] eq 'pi' }

sub _equation {
  return [0, 0] unless my $equation = shift;

  # "even"
  return [2, 2] if $equation =~ /^\s*even\s*$/i;

  # "odd"
  return [2, 1] if $equation =~ /^\s*odd\s*$/i;

  # "4", "+4" or "-4"
  return [0, $1] if $equation =~ /^\s*((?:\+|-)?\d+)\s*$/;

  # "n", "4n", "+4n", "-4n", "n+1", "4n-1", "+4n-1" (and other variations)
  return [0, 0]
    unless $equation =~ /^\s*((?:\+|-)?(?:\d+)?)?n\s*((?:\+|-)\s*\d+)?\s*$/i;
  return [$1 eq '-' ? -1 : !length $1 ? 1 : $1, join('', split(' ', $2 || 0))];
}

sub _match {
  my ($group, $current, $tree) = @_;
  _combinator([reverse @$_], $current, $tree, 0) and return 1 for @$group;
  return undef;
}

sub _name {qr/(?:^|:)\Q@{[_unescape(shift)]}\E$/}

sub _pc {
  my ($class, $args, $current) = @_;

  # ":checked"
  return exists $current->[2]{checked} || exists $current->[2]{selected}
    if $class eq 'checked';

  # ":not"
  return !_match($args, $current, $current) if $class eq 'not';

  # ":matches"
  return !!_match($args, $current, $current) if $class eq 'matches';

  # ":empty"
  return !grep { !_empty($_) } @$current[4 .. $#$current] if $class eq 'empty';

  # ":root"
  return $current->[3] && $current->[3][0] eq 'root' if $class eq 'root';

  # ":nth-child", ":nth-last-child", ":nth-of-type" or ":nth-last-of-type"
  if (ref $args) {
    my $type = $class =~ /of-type$/ ? $current->[1] : undef;
    my @siblings = @{_siblings($current, $type)};
    @siblings = reverse @siblings if $class =~ /^nth-last/;

    for my $i (0 .. $#siblings) {
      next if (my $result = $args->[0] * $i + $args->[1]) < 1;
      last unless my $sibling = $siblings[$result - 1];
      return 1 if $sibling eq $current;
    }
  }

  # ":only-child" or ":only-of-type"
  elsif ($class eq 'only-child' || $class eq 'only-of-type') {
    my $type = $class eq 'only-of-type' ? $current->[1] : undef;
    $_ ne $current and return undef for @{_siblings($current, $type)};
    return 1;
  }

  return undef;
}

sub _select {
  my ($one, $tree, $group) = @_;

  my @results;
  my @queue = @$tree[($tree->[0] eq 'root' ? 1 : 4) .. $#$tree];
  while (my $current = shift @queue) {
    next unless $current->[0] eq 'tag';

    unshift @queue, @$current[4 .. $#$current];
    next unless _match($group, $current, $tree);
    $one ? return $current : push @results, $current;
  }

  return $one ? undef : \@results;
}

sub _selector {
  my ($selector, $current) = @_;

  for my $s (@$selector) {
    my $type = $s->[0];

    # Tag
    if ($type eq 'tag') { return undef unless $current->[1] =~ $s->[1] }

    # Attribute
    elsif ($type eq 'attr') { return undef unless _attr(@$s[1, 2], $current) }

    # Pseudo-class
    elsif ($type eq 'pc') { return undef unless _pc(@$s[1, 2], $current) }
  }

  return 1;
}

sub _sibling {
  my ($selectors, $current, $tree, $immediate, $pos) = @_;

  my $found;
  for my $sibling (@{_siblings($current)}) {
    return $found if $sibling eq $current;

    # "+" (immediately preceding sibling)
    if ($immediate) { $found = _combinator($selectors, $sibling, $tree, $pos) }

    # "~" (preceding sibling)
    else { return 1 if _combinator($selectors, $sibling, $tree, $pos) }
  }

  return undef;
}

sub _siblings {
  my ($current, $type) = @_;

  my $parent = $current->[3];
  my @siblings = grep { $_->[0] eq 'tag' }
    @$parent[($parent->[0] eq 'root' ? 1 : 4) .. $#$parent];
  @siblings = grep { $type eq $_->[1] } @siblings if defined $type;

  return \@siblings;
}

sub _unescape {
  my $value = shift;

  # Remove escaped newlines
  $value =~ s/\\\n//g;

  # Unescape Unicode characters
  $value =~ s/\\([0-9a-fA-F]{1,6})\s?/pack 'U', hex $1/ge;

  # Remove backslash
  $value =~ s/\\//g;

  return $value;
}

sub _value {
  my ($op, $value, $insensitive) = @_;
  return undef unless defined $value;
  $value = ($insensitive ? '(?i)' : '') . quotemeta _unescape($value);

  # "~=" (word)
  return qr/(?:^|\s+)$value(?:\s+|$)/ if $op eq '~';

  # "*=" (contains)
  return qr/$value/ if $op eq '*';

  # "^=" (begins with)
  return qr/^$value/ if $op eq '^';

  # "$=" (ends with)
  return qr/$value$/ if $op eq '$';

  # Everything else
  return qr/^$value$/;
}

1;

=for Pod::Coverage *EVERYTHING*

=cut
