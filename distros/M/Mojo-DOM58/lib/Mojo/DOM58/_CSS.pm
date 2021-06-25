package Mojo::DOM58::_CSS;

# This file is part of Mojo::DOM58 which is released under:
#   The Artistic License 2.0 (GPL Compatible)
# See the documentation for Mojo::DOM58 for full license details.

use strict;
use warnings;
use Carp 'croak';
use Data::Dumper ();

use constant DEBUG => $ENV{MOJO_DOM58_CSS_DEBUG} || 0;

our $VERSION = '3.001';

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
  return $tree->[0] ne 'tag' ? undef : _match(_compile(@_), $tree, $tree, _root($tree));
}

sub select     { _select(0, shift->tree, _compile(@_)) }
sub select_one { _select(1, shift->tree, _compile(@_)) }

sub _absolutize { [map { _is_scoped($_) ? $_ : [[['pc', 'scope']], ' ', @$_] } @{shift()}] }

sub _ancestor {
  my ($selectors, $current, $tree, $scope, $one, $pos) = @_;

  while ($current ne $scope && $current->[0] ne 'root' && ($current = $current->[3])) {
    return 1     if _combinator($selectors, $current, $tree, $scope, $pos);
    return undef if $current eq $scope;
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
  my ($selectors, $current, $tree, $scope, $pos) = @_;

  # Selector
  return undef unless my $c = $selectors->[$pos];
  if (ref $c) {
    return undef unless _selector($c, $current, $tree, $scope);
    return 1 unless $c = $selectors->[++$pos];
  }

  # ">" (parent only)
  return _ancestor($selectors, $current, $tree, $scope, 1, ++$pos) if $c eq '>';

  # "~" (preceding siblings)
  return _sibling($selectors, $current, $tree, $scope, 0, ++$pos) if $c eq '~';

  # "+" (immediately preceding siblings)
  return _sibling($selectors, $current, $tree, $scope, 1, ++$pos) if $c eq '+';

  # " " (ancestor)
  return _ancestor($selectors, $current, $tree, $scope, 0, ++$pos);
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
    elsif ($css =~ /\G\s*([ >+~])\s*/gc) {
      push @$last, ['pc', 'scope'] unless @$last;
      push @$selectors, $1;
    }

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

      # ":is" and ":not" (contains more selectors)
      $args = _compile($args, %ns) if $name eq 'has' || $name eq 'is' || $name eq 'not';

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
  _combinator([reverse @$_], $current, $tree, $scope, 0) and return 1 for @$group;
  return undef;
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
    @siblings = reverse @siblings
      if $class eq 'nth-last-child' || $class eq 'nth-last-of-type';

    for my $i (0 .. $#siblings) {
      next if (my $result = $args->[0] * $i + $args->[1]) < 1;
      return undef unless my $sibling = $siblings[$result - 1];
      return 1 if $sibling eq $current;
    }
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

  my @results;
  my @queue = @$tree[($tree->[0] eq 'root' ? 1 : 4) .. $#$tree];
  while (my $current = shift @queue) {
    next unless $current->[0] eq 'tag';

    unshift @queue, @$current[4 .. $#$current];
    next unless _match($group, $current, $tree, $scope);
    $one ? return $current : push @results, $current;
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

sub _sibling {
  my ($selectors, $current, $tree, $scope, $immediate, $pos) = @_;

  my $found;
  for my $sibling (@{_siblings($current)}) {
    return $found if $sibling eq $current;

    # "+" (immediately preceding sibling)
    if ($immediate) { $found = _combinator($selectors, $sibling, $tree, $scope, $pos) }

    # "~" (preceding sibling)
    else { return 1 if _combinator($selectors, $sibling, $tree, $scope, $pos) }
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
