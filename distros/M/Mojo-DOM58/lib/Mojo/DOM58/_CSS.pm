package Mojo::DOM58::_CSS;

# This file is part of Mojo::DOM58 which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for Mojo::DOM58 for full license details.

use strict;
use warnings;
use Carp 'croak';
use Data::Dumper ();

use constant DEBUG => $ENV{MOJO_DOM58_CSS_DEBUG} || 0;

our $VERSION = '3.003';

my $ESCAPE_RE = qr/\\[^0-9a-fA-F]|\\[0-9a-fA-F]{1,6}/;
my $ATTR_RE   = qr/
  \[
  ((?:$ESCAPE_RE|[\w\-])+)                              # Key
  (?:
    (\W)?=                                              # Operator
    (?:"((?:\\"|[^"])*)"|'((?:\\'|[^'])*)'|([^\]]+?))   # Value
    (?:\s+(?:(i|I)|s|S))?                               # Case-sensitivity
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
  return undef if $tree->[0] ne 'tag';
  return _match(_compile(@_), $tree, $tree, _root($tree));
}

sub select     { _select(0, shift->tree, _compile(@_)) }
sub select_one { _select(1, shift->tree, _compile(@_)) }

sub _absolutize { [map { _is_scoped($_) ? $_ : [[['pc', 'scope']], ' ', @$_] } @{shift()}] }

sub _all_tags {
  my $tree = shift;

  my @tags;
  my @queue = @$tree[($tree->[0] eq 'root' ? 1 : 4) .. $#$tree];
  while (my $current = shift @queue) {
    next unless $current->[0] eq 'tag';
    push @tags, $current;
    unshift @queue, @$current[4 .. $#$current];
  }

  return \@tags;
}

sub _attr {
  my ($name, $value_re, $current) = @_;

  my $attrs = $current->[2];
  return undef unless exists $attrs->{$name};

  my $value = $attrs->{$name};
  return undef if !defined $value && defined $value_re;
  return 1 if !defined $value_re || $value =~ $value_re;

  return undef;
}

sub _compile {
  my ($css, %ns) = ('' . shift, @_);
  $css =~ s/^\s+//;
  $css =~ s/\s+$//;

  my $group = [[]];
  while (my $selectors = $group->[-1]) {
    push @$selectors, [] unless @$selectors && ref $selectors->[-1];
    my $last = $selectors->[-1];

    # Separator
    if ($css =~ /\G\s*,\s*/gc) { push @$group, [] }

    # Combinator
    elsif ($css =~ /\G\s*([>+~])\s*/gc) {
      push @$last, ['pc', 'scope'] unless @$last;
      push @$selectors, $1;
    }

    # Descendent combinator
    elsif ($css =~ /\G\s+/gc) {
      push @$last, ['pc', 'scope'] unless @$last;
      push @$selectors, ' ';
    }

    # Class or ID
    elsif ($css =~ /\G([.#])((?:$ESCAPE_RE\s?|[^,.#:[\s>~+])+)/gco) {
      my ($name, $op) = $1 eq '.' ? ('class', '~') : ('id', '');
      push @$last, ['attr', $name, _value($op, $2)];
    }

    # Attributes
    elsif ($css =~ /\G$ATTR_RE/gco) {
      push @$last, [
        'attr', _unescape($1),
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

      # ":text" (raw text)
      $args = [$args =~ m!^/(.+)/$! ? qr/$1/ : qr/\Q$args\E/i] if $name eq 'text';

      # ":is" and ":not" (contains more selectors)
      $args = _compile($args, %ns) if $name eq 'has' || $name eq 'is' || $name eq 'not';

      # ":nth-*" (with An+B notation)
      $args = _equation($args) if $name =~ /^nth-/;

      # ":first-*", ":last-*" (rewrite to ":nth-(last-)*")
      ($name, $args) = ("nth-$+", [0, 1]) if $name =~ /^(?:first-(.+)|(last-.+))$/;

      push @$last, ['pc', $name, $args];
    }

    # Tag
    elsif ($css =~ /\G((?:$ESCAPE_RE\s|\\[\s\S]|[^,.#:[\s>~+])+)/gco) {
      my $alias = (my $name = $1) =~ s/^([^|]*)\|// && $1 ne '*' ? $1 : undef;
      return [['invalid']] if defined $alias && length $alias && !defined $ns{$alias};
      my $ns = defined $alias && length $alias ? $ns{$alias} : $alias;
      push @$last, ['tag', $name eq '*' ? undef : _name($name), _unescape($ns)];
    }

    else { pos $css < length $css ? croak "Unknown CSS selector: $css" : last }
  }

  warn qq{-- CSS Selector ($css)\n@{[_dumper($group)]}} if DEBUG;
  return $group;
}

sub _dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

sub _equation {
  return [0, 0] unless my $equation = shift;

  # "even"
  return [2, 0] if $equation =~ /^\s*even\s*$/i;

  # "odd"
  return [2, 1] if $equation =~ /^\s*odd\s*$/i;

  # "4", "+4" or "-4"
  return [0, $1] if $equation =~ /^\s*((?:\+|-)?\d+)\s*$/;

  # "n", "4n", "+4n", "-4n", "n+1", "4n-1", "+4n-1" (and other variations)
  return [0, 0]
    unless $equation =~ /^\s*((?:\+|-)?(?:\d+)?)?n\s*((?:\+|-)\s*\d+)?\s*$/i;
  return [$1 eq '-' ? -1 : !length $1 ? 1 : $1, join('', split(' ', $2 || 0))];
}

sub _evaluate {
  my ($group, $tree, $scope, $pool) = @_;

  my (@results, %seen);
  push @results, grep { !$seen{$_}++ } _evaluate_one($_, $tree, $scope, $pool) for @$group;

  return \@results;
}

sub _evaluate_one {
  my ($selector, $tree, $scope, $pool) = @_;

  # Match the leftmost compound, then propagate forward through combinators
  my @parts = @$selector;
  my $compound = shift @parts;
  return () unless ref $compound;
  my @candidates = grep { _selector($compound, $_, $tree, $scope) } @$pool;

  while (@parts) {
    my $combinator = shift @parts;
    my $next = shift @parts;
    return () unless ref $next;

    my (%seen, @new);
    for my $node (@candidates) {
      for my $cand (_step_forward($combinator, $node)) {
        next if $seen{$cand}++;
        push @new, $cand if _selector($next, $cand, $tree, $scope);
      }
    }
    @candidates = @new;
  }

  return @candidates;
}

sub _is_scoped {
  my $selector = shift;

  for my $pc (grep { $_->[0] eq 'pc' } map { ref $_ ? @$_ : () } @$selector) {

    # Selector with ":scope"
    return 1 if $pc->[1] eq 'scope';

    # Argument of functional pseudo-class with ":scope"
    return 1 if ($pc->[1] eq 'has' || $pc->[1] eq 'is' || $pc->[1] eq 'not') && grep { _is_scoped($_) } @{$pc->[2]};
  }

  return undef;
}

sub _match {
  my ($group, $current, $tree, $scope) = @_;
  _match_one($_, $current, $tree, $scope) and return 1 for @$group;
  return undef;
}

sub _match_one {
  my ($selector, $current, $tree, $scope) = @_;

  # Match the rightmost compound, then propagate backward through combinators
  my @parts = reverse @$selector;
  my $compound = shift @parts;
  return undef unless ref $compound && _selector($compound, $current, $tree, $scope);

  my @candidates = ($current);
  while (@parts) {
    my $combinator = shift @parts;
    my $next = shift @parts;
    return undef unless ref $next;

    my (%seen, @new);
    for my $node (@candidates) {
      for my $cand (_step_back($combinator, $node, $scope)) {
        next if $seen{$cand}++;
        push @new, $cand if _selector($next, $cand, $tree, $scope);
      }
    }
    return undef unless @new;
    @candidates = @new;
  }

  return 1;
}

sub _name {qr/(?:^|:)\Q@{[_unescape(shift)]}\E$/}

sub _namespace {
  my ($ns, $current) = @_;

  my $attr = $current->[1] =~ /^([^:]+):/ ? "xmlns:$1" : 'xmlns';
  while ($current) {
    last if $current->[0] eq 'root';
    return $current->[2]{$attr} eq $ns if exists $current->[2]{$attr};

    $current = $current->[3];
  }

  # Failing to match yields true if searching for no namespace, false otherwise
  return !length $ns;
}

sub _pc {
  my ($class, $args, $current, $tree, $scope) = @_;

  # ":scope" (root can only be a :scope)
  return $current eq $scope if $class eq 'scope';
  return undef              if $current->[0] eq 'root';

  # ":checked"
  return exists $current->[2]{checked} || exists $current->[2]{selected}
    if $class eq 'checked';

  # ":not"
  return !_match($args, $current, $current, $scope) if $class eq 'not';

  # ":is"
  return !!_match($args, $current, $current, $scope) if $class eq 'is';

  # ":has"
  return !!_select(1, $current, $args) if $class eq 'has';

  # ":empty"
  return !grep { !($_->[0] eq 'comment' || $_->[0] eq 'pi') } @$current[4 .. $#$current] if $class eq 'empty';

  # ":root"
  return $current->[3] && $current->[3][0] eq 'root' if $class eq 'root';

  # ":text"
  return grep { ($_->[0] eq 'text' || $_->[0] eq 'raw') && $_->[1] =~ $args->[0] } @$current[4 .. $#$current]
    if $class eq 'text';

  # ":any-link", ":link" and ":visited"
  if ($class eq 'any-link' || $class eq 'link' || $class eq 'visited') {
    return undef unless $current->[0] eq 'tag' && exists $current->[2]{href};
    return !!grep { $current->[1] eq $_ } qw(a area link);
  }

  # ":only-child" or ":only-of-type"
  if ($class eq 'only-child' || $class eq 'only-of-type') {
    my $type = $class eq 'only-of-type' ? $current->[1] : undef;
    $_ ne $current and return undef for @{_siblings($current, $type)};
    return 1;
  }

  # ":nth-child", ":nth-last-child", ":nth-of-type" or ":nth-last-of-type"
  if (ref $args) {
    my $type = $class eq 'nth-of-type'
      || $class eq 'nth-last-of-type' ? $current->[1] : undef;
    my @siblings = @{_siblings($current, $type)};
    my $index;
    for my $i (0 .. $#siblings) {
      $index = $i, last if $siblings[$i] eq $current;
    }
    $index = $#siblings - $index if $class eq 'nth-last-child' || $class eq 'nth-last-of-type';
    $index++;

    my $delta = $index - $args->[1];
    return 1 if $delta == 0;
    return $args->[0] != 0 && ($delta < 0) == ($args->[0] < 0) && $delta % $args->[0] == 0;
  }

  # Everything else
  return undef;
}

sub _root {
  my $tree = shift;
  $tree = $tree->[3] while $tree->[0] ne 'root';
  return $tree;
}

sub _select {
  my ($one, $scope, $group) = @_;

  # Scoped selectors require the whole tree to be searched
  my $tree = $scope;
  ($group, $tree) = (_absolutize($group), _root($scope)) if grep { _is_scoped($_) } @$group;

  # Without combinators the first match in document order can be returned right away
  if ($one && !grep { @$_ != 1 || !ref $_->[0] } @$group) {
    my @queue = @$tree[($tree->[0] eq 'root' ? 1 : 4) .. $#$tree];
    while (my $current = shift @queue) {
      next unless $current->[0] eq 'tag';
      return $current if grep { _selector($_->[0], $current, $tree, $scope) } @$group;
      unshift @queue, @$current[4 .. $#$current];
    }
    return undef;
  }

  # Pool includes $tree so ":scope" can match it, but results exclude it
  my $tags = _all_tags($tree);
  my %match = map { $_ => 1 } @{_evaluate($group, $tree, $scope, [$tree, @$tags])};

  my @results;
  for my $node (@$tags) {
    next unless $match{$node};
    return $node if $one;
    push @results, $node;
  }

  return $one ? undef : \@results;
}

sub _selector {
  my ($selector, $current, $tree, $scope) = @_;

  # The root might be the scope
  my $is_tag = $current->[0] eq 'tag';
  for my $s (@$selector) {
    my $type = $s->[0];

    # Tag
    if ($is_tag && $type eq 'tag') {
      return undef if defined $s->[1] && $current->[1] !~ $s->[1];
      return undef if defined $s->[2] && !_namespace($s->[2], $current);
    }

    # Attribute
    elsif ($is_tag && $type eq 'attr') { return undef unless _attr(@$s[1, 2], $current) }

    # Pseudo-class
    elsif ($type eq 'pc') { return undef unless _pc(@$s[1, 2], $current, $tree, $scope) }

    # No match
    else { return undef }
  }

  return 1;
}

sub _siblings {
  my ($current, $type) = @_;

  my $parent = $current->[3];
  my @siblings = grep { $_->[0] eq 'tag' }
    @$parent[($parent->[0] eq 'root' ? 1 : 4) .. $#$parent];
  @siblings = grep { $type eq $_->[1] } @siblings if defined $type;

  return \@siblings;
}

sub _step_back {
  my ($combinator, $node, $scope) = @_;

  # " " (ancestors) and ">" (parent only)
  if ($combinator eq ' ' || $combinator eq '>') {
    my @ancestors;
    while ($node ne $scope && $node->[0] ne 'root' && ($node = $node->[3])) {
      push @ancestors, $node;
      last if $combinator eq '>' || $node eq $scope;
    }
    return @ancestors;
  }

  # "~" (preceding siblings) and "+" (immediately preceding)
  return () if $node->[0] eq 'root';
  my @prev;
  for my $sib (@{_siblings($node)}) {
    last if $sib eq $node;
    push @prev, $sib;
  }
  return $combinator eq '+' ? ($prev[-1] || ()) : @prev;
}

sub _step_forward {
  my ($combinator, $node) = @_;

  # " " (descendants)
  return @{_all_tags($node)} if $combinator eq ' ';

  # ">" (children only)
  return grep { $_->[0] eq 'tag' } @$node[($node->[0] eq 'root' ? 1 : 4) .. $#$node] if $combinator eq '>';

  # "~" (following siblings) and "+" (immediately following)
  return () if $node->[0] eq 'root';
  my (@next, $found);
  for my $sib (@{_siblings($node)}) {
    push @next, $sib if $found;
    $found = 1 if $sib eq $node;
  }
  return $combinator eq '+' ? ($next[0] || ()) : @next;
}

sub _unescape {
  return undef unless defined(my $value = shift);

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

  # "|=" (hyphen-separated)
  return qr/^$value(?:-|$)/ if $op eq '|';

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
