package Mojo::DOM58;

use strict;
use warnings;

use overload
  '@{}'    => sub { shift->child_nodes },
  '%{}'    => sub { shift->attr },
  bool     => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;

use Exporter 'import';
use Mojo::DOM58::_Collection;
use Mojo::DOM58::_CSS;
use Mojo::DOM58::_HTML 'tag_to_html';
use Scalar::Util qw(blessed weaken);
use Storable 'dclone';

our $VERSION = '3.001';

our @EXPORT_OK = 'tag_to_html';

sub new {
  my $class = shift;
  my $self = bless \Mojo::DOM58::_HTML->new, ref $class || $class;
  return @_ ? $self->parse(@_) : $self;
}

sub new_tag {
  my $self = shift;
  my $new  = $self->new;
  $$new->tag(@_);
  $$new->xml($$self->xml) if ref $self;
  return $new;
}

sub TO_JSON { ${shift()}->render }

sub all_text { _text(_nodes($_[0]->tree), $_[0]->xml, 1) }

sub ancestors { _select($_[0]->_collect([_ancestors($_[0]->tree)]), $_[1]) }

sub append { shift->_add(1, @_) }
sub append_content { shift->_content(1, 0, @_) }

sub at {
  my $self = shift;
  return undef unless my $result = $self->_css->select_one(@_);
  return $self->_build($result, $self->xml);
}

sub attr {
  my $self = shift;

  # Hash
  my $tree = $self->tree;
  my $attrs = $tree->[0] ne 'tag' ? {} : $tree->[2];
  return $attrs unless @_;

  # Get
  return $attrs->{$_[0]} unless @_ > 1 || ref $_[0];

  # Set
  my $values = ref $_[0] ? $_[0] : {@_};
  @$attrs{keys %$values} = values %$values;

  return $self;
}

sub child_nodes { $_[0]->_collect(_nodes($_[0]->tree)) }

sub children { _select($_[0]->_collect(_nodes($_[0]->tree, 1)), $_[1]) }

sub content {
  my $self = shift;

  my $type = $self->type;
  if ($type eq 'root' || $type eq 'tag') {
    return $self->_content(0, 1, @_) if @_;
    my $html = Mojo::DOM58::_HTML->new(xml => $self->xml);
    return join '', map { $html->tree($_)->render } @{_nodes($self->tree)};
  }

  return $self->tree->[1] unless @_;
  $self->tree->[1] = shift;
  return $self;
}

sub descendant_nodes { $_[0]->_collect(_all(_nodes($_[0]->tree))) }

sub find {
  my $self = shift;
  return $self->_collect($self->_css->select(@_));
}

sub following { _select($_[0]->_collect(_siblings($_[0]->tree, 1, 1)), $_[1]) }
sub following_nodes { $_[0]->_collect(_siblings($_[0]->tree, 0, 1)) }

sub matches { shift->_css->matches(@_) }

sub namespace {
  my $self = shift;

  return undef if (my $tree = $self->tree)->[0] ne 'tag';

  # Extract namespace prefix and search parents
  my $ns = $tree->[1] =~ /^(.*?):/ ? "xmlns:$1" : undef;
  for my $node ($tree, _ancestors($tree)) {

    # Namespace for prefix
    my $attrs = $node->[2];
    if ($ns) { $_ eq $ns and return $attrs->{$_} for keys %$attrs }

    # Namespace attribute
    elsif (defined $attrs->{xmlns}) { return $attrs->{xmlns} }
  }

  return undef;
}

sub next      { $_[0]->_maybe(_siblings($_[0]->tree, 1, 1, 0)) }
sub next_node { $_[0]->_maybe(_siblings($_[0]->tree, 0, 1, 0)) }

sub parent {
  my $self = shift;
  return undef if (my $tree = $self->tree)->[0] eq 'root';
  return $self->_build(_parent($tree), $self->xml);
}

sub parse { ${$_[0]}->parse($_[1]) and return $_[0] }

sub preceding { _select($_[0]->_collect(_siblings($_[0]->tree, 1, 0)), $_[1]) }
sub preceding_nodes { $_[0]->_collect(_siblings($_[0]->tree, 0)) }

sub prepend { shift->_add(0, @_) }
sub prepend_content { shift->_content(0, 0, @_) }

sub previous      { $_[0]->_maybe(_siblings($_[0]->tree, 1, 0, -1)) }
sub previous_node { $_[0]->_maybe(_siblings($_[0]->tree, 0, 0, -1)) }

sub remove { shift->replace('') }

sub replace {
  my ($self, $new) = @_;
  return $self->parse($new) if (my $tree = $self->tree)->[0] eq 'root';
  return $self->_replace(_parent($tree), $tree, _nodes($self->_parse($new)));
}

sub root {
  my $self = shift;
  return $self unless my $tree = _ancestors($self->tree, 1);
  return $self->_build($tree, $self->xml);
}

sub selector {
  return undef unless (my $tree = shift->tree)->[0] eq 'tag';
  return join ' > ',
    reverse map { $_->[1] . ':nth-child(' . (@{_siblings($_, 1)} + 1) . ')' }
    $tree, _ancestors($tree);
}

sub strip {
  my $self = shift;
  return $self if (my $tree = $self->tree)->[0] ne 'tag';
  return $self->_replace($tree->[3], $tree, _nodes($tree));
}

sub tag {
  my ($self, $tag) = @_;
  return undef if (my $tree = $self->tree)->[0] ne 'tag';
  return $tree->[1] unless $tag;
  $tree->[1] = $tag;
  return $self;
}

sub tap { Mojo::DOM58::_Collection::tap(@_) }

sub text { _text(_nodes(shift->tree), 0, 0) }

sub to_string { ${shift()}->render }

sub tree { @_ > 1 ? (${$_[0]}->tree($_[1]) and return $_[0]) : ${$_[0]}->tree }

sub type { shift->tree->[0] }

sub val {
  my $self = shift;

  # "option"
  return defined($self->{value}) ? $self->{value} : $self->text
    if (my $tag = $self->tag) eq 'option';

  # "input" ("type=checkbox" and "type=radio")
  my $type = $self->{type} || '';
  return defined $self->{value} ? $self->{value} : 'on'
    if $tag eq 'input' && ($type eq 'radio' || $type eq 'checkbox');

  # "textarea", "input" or "button"
  return $tag eq 'textarea' ? $self->text : $self->{value} if $tag ne 'select';

  # "select"
  my $v = $self->find('option:checked:not([disabled])')
    ->grep(sub { !$_->ancestors('optgroup[disabled]')->size })->map('val');
  return exists $self->{multiple} ? $v->size ? $v->to_array : undef : $v->last;
}

sub with_roles { Mojo::DOM58::_Collection::with_roles(@_) }

sub wrap         { shift->_wrap(0, @_) }
sub wrap_content { shift->_wrap(1, @_) }

sub xml { @_ > 1 ? (${$_[0]}->xml($_[1]) and return $_[0]) : ${$_[0]}->xml }

sub _add {
  my ($self, $offset, $new) = @_;

  return $self if (my $tree = $self->tree)->[0] eq 'root';

  my $parent = _parent($tree);
  splice @$parent, _offset($parent, $tree) + $offset, 0,
    @{_link($parent, _nodes($self->_parse($new)))};

  return $self;
}

sub _all {
  my $nodes = shift;
  @$nodes = map { $_->[0] eq 'tag' ? ($_, @{_all(_nodes($_))}) : ($_) } @$nodes;
  return $nodes;
}

sub _ancestors {
  my ($tree, $root) = @_;

  return () unless $tree = _parent($tree);
  my @ancestors;
  do { push @ancestors, $tree }
    while ($tree->[0] eq 'tag') && ($tree = $tree->[3]);
  return $root ? $ancestors[-1] : @ancestors[0 .. $#ancestors - 1];
}

sub _build { shift->new->tree(shift)->xml(shift) }

sub _collect {
  my ($self, $nodes) = (shift, shift || []);
  my $xml = $self->xml;
  return Mojo::DOM58::_Collection->new(map { $self->_build($_, $xml) } @$nodes);
}

sub _content {
  my ($self, $start, $offset, $new) = @_;

  my $tree = $self->tree;
  unless ($tree->[0] eq 'root' || $tree->[0] eq 'tag') {
    my $old = $self->content;
    return $self->content($start ? $old . $new : $new . $old);
  }

  $start  = $start  ? ($#$tree + 1) : _start($tree);
  $offset = $offset ? $#$tree       : 0;
  splice @$tree, $start, $offset, @{_link($tree, _nodes($self->_parse($new)))};

  return $self;
}

sub _css { Mojo::DOM58::_CSS->new(tree => shift->tree) }

sub _fragment { _link(my $r = ['root', @_], [@_]); $r }

sub _link {
  my ($parent, $children) = @_;

  # Link parent to children
  for my $node (@$children) {
    my $offset = $node->[0] eq 'tag' ? 3 : 2;
    $node->[$offset] = $parent;
    weaken $node->[$offset];
  }

  return $children;
}

sub _maybe { $_[1] ? $_[0]->_build($_[1], $_[0]->xml) : undef }

sub _nodes {
  return () unless my $tree = shift;
  my @nodes = @$tree[_start($tree) .. $#$tree];
  return shift() ? [grep { $_->[0] eq 'tag' } @nodes] : \@nodes;
}

sub _offset {
  my ($parent, $child) = @_;
  my $i = _start($parent);
  $_ eq $child ? last : $i++ for @$parent[$i .. $#$parent];
  return $i;
}

sub _parent { $_[0]->[$_[0][0] eq 'tag' ? 3 : 2] }

sub _parse {
  my ($self, $input) = @_;
  return Mojo::DOM58::_HTML->new(xml => $self->xml)->parse($input)->tree
    unless blessed $input && $input->isa('Mojo::DOM58');
  my $tree = dclone $input->tree;
  return $tree->[0] eq 'root' ? $tree : _fragment($tree);
}

sub _replace {
  my ($self, $parent, $child, $nodes) = @_;
  splice @$parent, _offset($parent, $child), 1, @{_link($parent, $nodes)};
  return $self->parent;
}

sub _select { $_[1] ? $_[0]->grep(matches => $_[1]) : $_[0] }

sub _siblings {
  my ($tree, $tags, $tail, $i) = @_;

  return defined $i ? undef : [] if $tree->[0] eq 'root';

  my $nodes = _nodes(_parent($tree));
  my $match = -1;
  defined($match++) and $_ eq $tree and last for @$nodes;

  if ($tail) { splice @$nodes, 0, $match + 1 }
  else       { splice @$nodes, $match, ($#$nodes + 1) - $match }

  @$nodes = grep { $_->[0] eq 'tag' } @$nodes if $tags;

  return defined $i ? $i == -1 && !@$nodes ? undef : $nodes->[$i] : $nodes;
}

sub _start { $_[0][0] eq 'root' ? 1 : 4 }

sub _text {
  my ($nodes, $xml, $all) = @_;

  my $text = '';
  while (my $node = shift @$nodes) {
    my $type = $node->[0];

    # Text
    if ($type eq 'text' || $type eq 'cdata' || $type eq 'raw') {
      $text .= $node->[1];
    }

    # Nested tag
    elsif ($type eq 'tag' && $all) {
      unshift @$nodes, @{_nodes($node)} if $xml || ($node->[1] ne 'script' && $node->[1] ne 'style');
    }
  }

  return $text;
}

sub _wrap {
  my ($self, $content, $new) = @_;

  return $self if (my $tree = $self->tree)->[0] eq 'root' && !$content;
  return $self if $tree->[0] ne 'root' && $tree->[0] ne 'tag' && $content;

  # Find innermost tag
  my $current;
  my $first = $new = $self->_parse($new);
  $current = $first while $first = _nodes($first, 1)->[0];
  return $self unless $current;

  # Wrap content
  if ($content) {
    push @$current, @{_link($current, _nodes($tree))};
    splice @$tree, _start($tree), $#$tree, @{_link($tree, _nodes($new))};
    return $self;
  }

  # Wrap element
  $self->_replace(_parent($tree), $tree, _nodes($new));
  push @$current, @{_link($current, [$tree])};
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::DOM58 - Minimalistic HTML/XML DOM parser with CSS selectors

=head1 SYNOPSIS

  use Mojo::DOM58;

  # Parse
  my $dom = Mojo::DOM58->new('<div><p id="a">Test</p><p id="b">123</p></div>');

  # Find
  say $dom->at('#b')->text;
  say $dom->find('p')->map('text')->join("\n");
  say $dom->find('[id]')->map(attr => 'id')->join("\n");

  # Iterate
  $dom->find('p[id]')->reverse->each(sub { say $_->{id} });

  # Loop
  for my $e ($dom->find('p[id]')->each) {
    say $e->{id}, ':', $e->text;
  }

  # Modify
  $dom->find('div p')->last->append('<p id="c">456</p>');
  $dom->at('#c')->prepend($dom->new_tag('p', id => 'd', '789'));
  $dom->find(':not(p)')->map('strip');

  # Render
  say "$dom";

=head1 DESCRIPTION

L<Mojo::DOM58> is a minimalistic and relaxed pure-perl HTML/XML DOM parser based
on L<Mojo::DOM>. It supports the L<HTML Living Standard|https://html.spec.whatwg.org/>
and L<Extensible Markup Language (XML) 1.0|https://www.w3.org/TR/xml/>, and
matching based on L<CSS3 selectors|https://www.w3.org/TR/selectors/>. It will
even try to interpret broken HTML and XML, so you should not use it for
validation.

=head1 FORK INFO

L<Mojo::DOM58> is a fork of L<Mojo::DOM> and tracks features and fixes to stay
closely compatible with upstream. It differs only in the standalone format and
compatibility with Perl 5.8. Any bugs or patches not related to these changes
should be reported directly to the L<Mojolicious> issue tracker.

This release of L<Mojo::DOM58> is up to date with version C<9.0> of
L<Mojolicious>.

=head1 NODES AND ELEMENTS

When we parse an HTML/XML fragment, it gets turned into a tree of nodes.

  <!DOCTYPE html>
  <html>
    <head><title>Hello</title></head>
    <body>World!</body>
  </html>

There are currently eight different kinds of nodes, C<cdata>, C<comment>,
C<doctype>, C<pi>, C<raw>, C<root>, C<tag> and C<text>. Elements are nodes of
the type C<tag>.

  root
  |- doctype (html)
  +- tag (html)
     |- tag (head)
     |  +- tag (title)
     |     +- raw (Hello)
     +- tag (body)
        +- text (World!)

While all node types are represented as L<Mojo::DOM58> objects, some methods like
L</"attr"> and L</"namespace"> only apply to elements.

=head1 CASE-SENSITIVITY

L<Mojo::DOM58> defaults to HTML semantics, that means all tags and attribute
names are lowercased and selectors need to be lowercase as well.

  # HTML semantics
  my $dom = Mojo::DOM58->new('<P ID="greeting">Hi!</P>');
  say $dom->at('p[id]')->text;

If an XML declaration is found, the parser will automatically switch into XML
mode and everything becomes case-sensitive.

  # XML semantics
  my $dom = Mojo::DOM58->new('<?xml version="1.0"?><P ID="greeting">Hi!</P>');
  say $dom->at('P[ID]')->text;

HTML or XML semantics can also be forced with the L</"xml"> method.

  # Force HTML semantics
  my $dom = Mojo::DOM58->new->xml(0)->parse('<P ID="greeting">Hi!</P>');
  say $dom->at('p[id]')->text;

  # Force XML semantics
  my $dom = Mojo::DOM58->new->xml(1)->parse('<P ID="greeting">Hi!</P>');
  say $dom->at('P[ID]')->text;

=head1 SELECTORS

L<Mojo::DOM58> uses a CSS selector engine based on L<Mojo::DOM::CSS>. All CSS
selectors that make sense for a standalone parser are supported.

=over

=item Z<>*

Any element.

  my $all = $dom->find('*');

=item E

An element of type C<E>.

  my $title = $dom->at('title');

=item E[foo]

An C<E> element with a C<foo> attribute.

  my $links = $dom->find('a[href]');

=item E[foo="bar"]

An C<E> element whose C<foo> attribute value is exactly equal to C<bar>.

  my $case_sensitive = $dom->find('input[type="hidden"]');
  my $case_sensitive = $dom->find('input[type=hidden]');

=item E[foo="bar" i]

An C<E> element whose C<foo> attribute value is exactly equal to any
(ASCII-range) case-permutation of C<bar>. Note that this selector is
B<EXPERIMENTAL> and might change without warning!

  my $case_insensitive = $dom->find('input[type="hidden" i]');
  my $case_insensitive = $dom->find('input[type=hidden i]');
  my $case_insensitive = $dom->find('input[class~="foo" i]');

This selector is part of
L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work
in progress.

=item E[foo="bar" s]

An C<E> element whose C<foo> attribute value is exactly and case-sensitively
equal to C<bar>. Note that this selector is B<EXPERIMENTAL> and might change
without warning!

  my $case_sensitive = $dom->find('input[type="hidden" s]');

This selector is part of
L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work
in progress.

=item E[foo~="bar"]

An C<E> element whose C<foo> attribute value is a list of whitespace-separated
values, one of which is exactly equal to C<bar>.

  my $foo = $dom->find('input[class~="foo"]');
  my $foo = $dom->find('input[class~=foo]');

=item E[foo^="bar"]

An C<E> element whose C<foo> attribute value begins exactly with the string
C<bar>.

  my $begins_with = $dom->find('input[name^="f"]');
  my $begins_with = $dom->find('input[name^=f]');

=item E[foo$="bar"]

An C<E> element whose C<foo> attribute value ends exactly with the string
C<bar>.

  my $ends_with = $dom->find('input[name$="o"]');
  my $ends_with = $dom->find('input[name$=o]');

=item E[foo*="bar"]

An C<E> element whose C<foo> attribute value contains the substring C<bar>.

  my $contains = $dom->find('input[name*="fo"]');
  my $contains = $dom->find('input[name*=fo]');

=item E[foo|="en"]

An C<E> element whose C<foo> attribute has a hyphen-separated list of values
beginning (from the left) with C<en>.

  my $english = $dom->find('link[hreflang|=en]');

=item E:root

An C<E> element, root of the document.

  my $root = $dom->at(':root');

=item E:nth-child(n)

An C<E> element, the C<n-th> child of its parent.

  my $third = $dom->find('div:nth-child(3)');
  my $odd   = $dom->find('div:nth-child(odd)');
  my $even  = $dom->find('div:nth-child(even)');
  my $top3  = $dom->find('div:nth-child(-n+3)');

=item E:nth-last-child(n)

An C<E> element, the C<n-th> child of its parent, counting from the last one.

  my $third    = $dom->find('div:nth-last-child(3)');
  my $odd      = $dom->find('div:nth-last-child(odd)');
  my $even     = $dom->find('div:nth-last-child(even)');
  my $bottom3  = $dom->find('div:nth-last-child(-n+3)');

=item E:nth-of-type(n)

An C<E> element, the C<n-th> sibling of its type.

  my $third = $dom->find('div:nth-of-type(3)');
  my $odd   = $dom->find('div:nth-of-type(odd)');
  my $even  = $dom->find('div:nth-of-type(even)');
  my $top3  = $dom->find('div:nth-of-type(-n+3)');

=item E:nth-last-of-type(n)

An C<E> element, the C<n-th> sibling of its type, counting from the last one.

  my $third    = $dom->find('div:nth-last-of-type(3)');
  my $odd      = $dom->find('div:nth-last-of-type(odd)');
  my $even     = $dom->find('div:nth-last-of-type(even)');
  my $bottom3  = $dom->find('div:nth-last-of-type(-n+3)');

=item E:first-child

An C<E> element, first child of its parent.

  my $first = $dom->find('div p:first-child');

=item E:last-child

An C<E> element, last child of its parent.

  my $last = $dom->find('div p:last-child');

=item E:first-of-type

An C<E> element, first sibling of its type.

  my $first = $dom->find('div p:first-of-type');

=item E:last-of-type

An C<E> element, last sibling of its type.

  my $last = $dom->find('div p:last-of-type');

=item E:only-child

An C<E> element, only child of its parent.

  my $lonely = $dom->find('div p:only-child');

=item E:only-of-type

An C<E> element, only sibling of its type.

  my $lonely = $dom->find('div p:only-of-type');

=item E:empty

An C<E> element that has no children (including text nodes).

  my $empty = $dom->find(':empty');

=item E:any-link

Alias for L</"E:link">. Note that this selector is B<EXPERIMENTAL> and might
change without warning! This selector is part of
L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a
work in progress.

=item E:link

An C<E> element being the source anchor of a hyperlink of which the target is
not yet visited (C<:link>) or already visited (C<:visited>). Note that
L<Mojo::DOM58> is not stateful, therefore C<:any-link>, C<:link> and
C<:visited> yield exactly the same results.

  my $links = $dom->find(':any-link');
  my $links = $dom->find(':link');
  my $links = $dom->find(':visited');

=item E:visited

Alias for L</"E:link">.

=item E:scope

An C<E> element being a designated reference element. Note that this selector is B<EXPERIMENTAL> and might change
without warning!

  my $scoped = $dom->find('a:not(:scope > a)');
  my $scoped = $dom->find('div :scope p');
  my $scoped = $dom->find('~ p');

This selector is part of L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work in progress.

=item E:checked

A user interface element C<E> which is checked (for instance a radio-button or
checkbox).

  my $input = $dom->find(':checked');

=item E.warning

An C<E> element whose class is "warning".

  my $warning = $dom->find('div.warning');

=item E#myid

An C<E> element with C<ID> equal to "myid".

  my $foo = $dom->at('div#foo');

=item E:not(s1, s2)

An C<E> element that does not match either compound selector C<s1> or compound
selector C<s2>. Note that support for compound selectors is B<EXPERIMENTAL> and
might change without warning!

  my $others = $dom->find('div p:not(:first-child, :last-child)');

Support for compound selectors was added as part of
L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work
in progress.

=item E:is(s1, s2)

An C<E> element that matches compound selector C<s1> and/or compound selector
C<s2>. Note that this selector is B<EXPERIMENTAL> and might change without warning!

  my $headers = $dom->find(':is(section, article, aside, nav) h1');

This selector is part of
L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work
in progress.

=item E:has(rs1, rs2)

An C<E> element, if either of the relative selectors C<rs1> or C<rs2>, when evaluated with C<E> as the :scope elements,
match an element. Note that this selector is B<EXPERIMENTAL> and might change without warning!

  my $link = $dom->find('a:has(> img)');

This selector is part of L<Selectors Level 4|https://dev.w3.org/csswg/selectors-4>, which is still a work in progress.
Also be aware that this feature is currently marked C<at-risk>, so there is a high chance that it will get removed
completely.

=item A|E

An C<E> element that belongs to the namespace alias C<A> from
L<CSS Namespaces Module Level 3|https://www.w3.org/TR/css-namespaces-3/>.
Key/value pairs passed to selector methods are used to declare namespace
aliases.

  my $elem = $dom->find('lq|elem', lq => 'http://example.com/q-markup');

Using an empty alias searches for an element that belongs to no namespace.

  my $div = $dom->find('|div');

=item E F

An C<F> element descendant of an C<E> element.

  my $headlines = $dom->find('div h1');

=item E E<gt> F

An C<F> element child of an C<E> element.

  my $headlines = $dom->find('html > body > div > h1');

=item E + F

An C<F> element immediately preceded by an C<E> element.

  my $second = $dom->find('h1 + h2');

=item E ~ F

An C<F> element preceded by an C<E> element.

  my $second = $dom->find('h1 ~ h2');

=item E, F, G

Elements of type C<E>, C<F> and C<G>.

  my $headlines = $dom->find('h1, h2, h3');

=item E[foo=bar][bar=baz]

An C<E> element whose attributes match all following attribute selectors.

  my $links = $dom->find('a[foo^=b][foo$=ar]');

=back

=head1 OPERATORS

L<Mojo::DOM58> overloads the following operators.

=head2 array

  my @nodes = @$dom;

Alias for L</"child_nodes">.

  # "<!-- Test -->"
  $dom->parse('<!-- Test --><b>123</b>')->[0];

=head2 bool

  my $bool = !!$dom;

Always true.

=head2 hash

  my %attrs = %$dom;

Alias for L</"attr">.

  # "test"
  $dom->parse('<div id="test">Test</div>')->at('div')->{id};

=head2 stringify

  my $str = "$dom";

Alias for L</"to_string">.

=head1 FUNCTIONS

L<Mojo::DOM58> implements the following functions, which can be imported
individually.

=head2 tag_to_html

  my $str = tag_to_html 'div', id => 'foo', 'safe content';

Generate HTML/XML tag and render it right away. This is a significantly faster
alternative to L</"new_tag"> for template systems that have to generate a lot
of tags.

=head1 METHODS

L<Mojo::DOM58> implements the following methods.

=head2 new

  my $dom = Mojo::DOM58->new;
  my $dom = Mojo::DOM58->new('<foo bar="baz">I ♥ Mojo::DOM58!</foo>');

Construct a new scalar-based L<Mojo::DOM58> object and L</"parse"> HTML/XML
fragment if necessary.

=head2 new_tag

  my $tag = Mojo::DOM58->new_tag('div');
  my $tag = $dom->new_tag('div');
  my $tag = $dom->new_tag('div', id => 'foo', hidden => undef);
  my $tag = $dom->new_tag('div', 'safe content');
  my $tag = $dom->new_tag('div', id => 'foo', 'safe content');
  my $tag = $dom->new_tag('div', data => {mojo => 'rocks'}, 'safe content');
  my $tag = $dom->new_tag('div', id => 'foo', sub { 'unsafe content' });

Construct a new L<Mojo::DOM58> object for an HTML/XML tag with or without
attributes and content. The C<data> attribute may contain a hash reference with
key/value pairs to generate attributes from.

  # "<br>"
  $dom->new_tag('br');

  # "<div></div>"
  $dom->new_tag('div');

  # "<div id="foo" hidden></div>"
  $dom->new_tag('div', id => 'foo', hidden => undef);

  # "<div>test &amp; 123</div>"
  $dom->new_tag('div', 'test & 123');

  # "<div id="foo">test &amp; 123</div>"
  $dom->new_tag('div', id => 'foo', 'test & 123');

  # "<div data-foo="1" data-bar="test">test &amp; 123</div>""
  $dom->new_tag('div', data => {foo => 1, Bar => 'test'}, 'test & 123');

  # "<div id="foo">test & 123</div>"
  $dom->new_tag('div', id => 'foo', sub { 'test & 123' });

  # "<div>Hello<b>Mojo!</b></div>"
  $dom->parse('<div>Hello</div>')->at('div')
    ->append_content($dom->new_tag('b', 'Mojo!'))->root;

=head2 all_text

  my $text = $dom->all_text;

Extract text content from all descendant nodes of this element. For HTML documents C<script> and C<style> elements are
excluded.

  # "foo\nbarbaz\n"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->at('div')->all_text;

=head2 ancestors

  my $collection = $dom->ancestors;
  my $collection = $dom->ancestors('div ~ p');

Find all ancestor elements of this node matching the CSS selector and return a
L<collection|/"COLLECTION METHODS"> containing these elements as L<Mojo::DOM58>
objects. All selectors listed in L</"SELECTORS"> are supported.

  # List tag names of ancestor elements
  say $dom->ancestors->map('tag')->join("\n");

=head2 append

  $dom = $dom->append('<p>I ♥ Mojo::DOM58!</p>');
  $dom = $dom->append(Mojo::DOM58->new);

Append HTML/XML fragment to this node (for all node types other than C<root>).

  # "<div><h1>Test</h1><h2>123</h2></div>"
  $dom->parse('<div><h1>Test</h1></div>')
    ->at('h1')->append('<h2>123</h2>')->root;

  # "<p>Test 123</p>"
  $dom->parse('<p>Test</p>')->at('p')
    ->child_nodes->first->append(' 123')->root;

=head2 append_content

  $dom = $dom->append_content('<p>I ♥ Mojo::DOM58!</p>');
  $dom = $dom->append_content(Mojo::DOM58->new);

Append HTML/XML fragment (for C<root> and C<tag> nodes) or raw content to this
node's content.

  # "<div><h1>Test123</h1></div>"
  $dom->parse('<div><h1>Test</h1></div>')
    ->at('h1')->append_content('123')->root;

  # "<!-- Test 123 --><br>"
  $dom->parse('<!-- Test --><br>')
    ->child_nodes->first->append_content('123 ')->root;

  # "<p>Test<i>123</i></p>"
  $dom->parse('<p>Test</p>')->at('p')->append_content('<i>123</i>')->root;

=head2 at

  my $result = $dom->at('div ~ p');
  my $result = $dom->at('svg|line', svg => 'http://www.w3.org/2000/svg');

Find first descendant element of this element matching the CSS selector and
return it as a L<Mojo::DOM58> object, or C<undef> if none could be found. All
selectors listed in L</"SELECTORS"> are supported.

  # Find first element with "svg" namespace definition
  my $namespace = $dom->at('[xmlns\:svg]')->{'xmlns:svg'};

Trailing key/value pairs can be used to declare xml namespace aliases.

  # "<rect />"
  $dom->parse('<svg xmlns="http://www.w3.org/2000/svg"><rect /></svg>')
    ->at('svg|rect', svg => 'http://www.w3.org/2000/svg');

=head2 attr

  my $hash = $dom->attr;
  my $foo  = $dom->attr('foo');
  $dom     = $dom->attr({foo => 'bar'});
  $dom     = $dom->attr(foo => 'bar');

This element's attributes.

  # Remove an attribute
  delete $dom->attr->{id};

  # Attribute without value
  $dom->attr(selected => undef);

  # List id attributes
  say $dom->find('*')->map(attr => 'id')->compact->join("\n");

=head2 child_nodes

  my $collection = $dom->child_nodes;

Return a L<collection|/"COLLECTION METHODS"> containing all child nodes of this
element as L<Mojo::DOM58> objects.

  # "<p><b>123</b></p>"
  $dom->parse('<p>Test<b>123</b></p>')->at('p')->child_nodes->first->remove;

  # "<!DOCTYPE html>"
  $dom->parse('<!DOCTYPE html><b>123</b>')->child_nodes->first;

  # " Test "
  $dom->parse('<b>123</b><!-- Test -->')->child_nodes->last->content;

=head2 children

  my $collection = $dom->children;
  my $collection = $dom->children('div ~ p');

Find all child elements of this element matching the CSS selector and return a
L<collection|/"COLLECTION METHODS"> containing these elements as L<Mojo::DOM58>
objects. All selectors listed in L</"SELECTORS"> are supported.

  # Show tag name of random child element
  say $dom->children->shuffle->first->tag;

=head2 content

  my $str = $dom->content;
  $dom    = $dom->content('<p>I ♥ Mojo::DOM58!</p>');
  $dom    = $dom->content(Mojo::DOM58->new);

Return this node's content or replace it with HTML/XML fragment (for C<root>
and C<tag> nodes) or raw content.

  # "<b>Test</b>"
  $dom->parse('<div><b>Test</b></div>')->at('div')->content;

  # "<div><h1>123</h1></div>"
  $dom->parse('<div><h1>Test</h1></div>')->at('h1')->content('123')->root;

  # "<p><i>123</i></p>"
  $dom->parse('<p>Test</p>')->at('p')->content('<i>123</i>')->root;

  # "<div><h1></h1></div>"
  $dom->parse('<div><h1>Test</h1></div>')->at('h1')->content('')->root;

  # " Test "
  $dom->parse('<!-- Test --><br>')->child_nodes->first->content;

  # "<div><!-- 123 -->456</div>"
  $dom->parse('<div><!-- Test -->456</div>')
    ->at('div')->child_nodes->first->content(' 123 ')->root;

=head2 descendant_nodes

  my $collection = $dom->descendant_nodes;

Return a L<collection|/"COLLECTION METHODS"> containing all descendant nodes of
this element as L<Mojo::DOM58> objects.

  # "<p><b>123</b></p>"
  $dom->parse('<p><!-- Test --><b>123<!-- 456 --></b></p>')
    ->descendant_nodes->grep(sub { $_->type eq 'comment' })
    ->map('remove')->first;

  # "<p><b>test</b>test</p>"
  $dom->parse('<p><b>123</b>456</p>')
    ->at('p')->descendant_nodes->grep(sub { $_->type eq 'text' })
    ->map(content => 'test')->first->root;

=head2 find

  my $collection = $dom->find('div ~ p');
  my $collection = $dom->find('svg|line', svg => 'http://www.w3.org/2000/svg');

Find all descendant elements of this element matching the CSS selector and
return a L<collection|/"COLLECTION METHODS"> containing these elements as
L<Mojo::DOM58> objects. All selectors listed in L</"SELECTORS"> are supported.

  # Find a specific element and extract information
  my $id = $dom->find('div')->[23]{id};

  # Extract information from multiple elements
  my @headers = $dom->find('h1, h2, h3')->map('text')->each;

  # Count all the different tags
  my $hash = $dom->find('*')->reduce(sub { $a->{$b->tag}++; $a }, {});

  # Find elements with a class that contains dots
  my @divs = $dom->find('div.foo\.bar')->each;

Trailing key/value pairs can be used to declare xml namespace aliases.

  # "<rect />"
  $dom->parse('<svg xmlns="http://www.w3.org/2000/svg"><rect /></svg>')
    ->find('svg|rect', svg => 'http://www.w3.org/2000/svg')->first;

=head2 following

  my $collection = $dom->following;
  my $collection = $dom->following('div ~ p');

Find all sibling elements after this node matching the CSS selector and return
a L<collection|/"COLLECTION METHODS"> containing these elements as
L<Mojo::DOM58> objects. All selectors listed in L</"SELECTORS"> are supported.

  # List tags of sibling elements after this node
  say $dom->following->map('tag')->join("\n");

=head2 following_nodes

  my $collection = $dom->following_nodes;

Return a L<collection|/"COLLECTION METHODS"> containing all sibling nodes after
this node as L<Mojo::DOM58> objects.

  # "C"
  $dom->parse('<p>A</p><!-- B -->C')->at('p')->following_nodes->last->content;

=head2 matches

  my $bool = $dom->matches('div ~ p');
  my $bool = $dom->matches('svg|line', svg => 'http://www.w3.org/2000/svg');

Check if this element matches the CSS selector. All selectors listed in
L</"SELECTORS"> are supported.

  # True
  $dom->parse('<p class="a">A</p>')->at('p')->matches('.a');
  $dom->parse('<p class="a">A</p>')->at('p')->matches('p[class]');

  # False
  $dom->parse('<p class="a">A</p>')->at('p')->matches('.b');
  $dom->parse('<p class="a">A</p>')->at('p')->matches('p[id]');

Trailing key/value pairs can be used to declare xml namespace aliases.

  # True
  $dom->parse('<svg xmlns="http://www.w3.org/2000/svg"><rect /></svg>')
    ->matches('svg|rect', svg => 'http://www.w3.org/2000/svg');

=head2 namespace

  my $namespace = $dom->namespace;

Find this element's namespace, or return C<undef> if none could be found.

  # "http://www.w3.org/2000/svg"
  Mojo::DOM58->new('<svg xmlns:svg="http://www.w3.org/2000/svg"><svg:circle>3.14</svg:circle></svg>')->at('svg\:circle')->namespace;

  # Find namespace for an element with namespace prefix
  my $namespace = $dom->at('svg > svg\:circle')->namespace;

  # Find namespace for an element that may or may not have a namespace prefix
  my $namespace = $dom->at('svg > circle')->namespace;

=head2 next

  my $sibling = $dom->next;

Return L<Mojo::DOM58> object for next sibling element, or C<undef> if there are
no more siblings.

  # "<h2>123</h2>"
  $dom->parse('<div><h1>Test</h1><h2>123</h2></div>')->at('h1')->next;

=head2 next_node

  my $sibling = $dom->next_node;

Return L<Mojo::DOM58> object for next sibling node, or C<undef> if there are no
more siblings.

  # "456"
  $dom->parse('<p><b>123</b><!-- Test -->456</p>')
    ->at('b')->next_node->next_node;

  # " Test "
  $dom->parse('<p><b>123</b><!-- Test -->456</p>')
    ->at('b')->next_node->content;

=head2 parent

  my $parent = $dom->parent;

Return L<Mojo::DOM58> object for parent of this node, or C<undef> if this node
has no parent.

  # "<b><i>Test</i></b>"
  $dom->parse('<p><b><i>Test</i></b></p>')->at('i')->parent;

=head2 parse

  $dom = $dom->parse('<foo bar="baz">I ♥ Mojo::DOM58!</foo>');

Parse HTML/XML fragment.

  # Parse XML
  my $dom = Mojo::DOM58->new->xml(1)->parse('<foo>I ♥ Mojo::DOM58!</foo>');

=head2 preceding

  my $collection = $dom->preceding;
  my $collection = $dom->preceding('div ~ p');

Find all sibling elements before this node matching the CSS selector and return
a L<collection|/"COLLECTION METHODS"> containing these elements as
L<Mojo::DOM58> objects. All selectors listed in L</"SELECTORS"> are supported.

  # List tags of sibling elements before this node
  say $dom->preceding->map('tag')->join("\n");

=head2 preceding_nodes

  my $collection = $dom->preceding_nodes;

Return a L<collection|/"COLLECTION METHODS"> containing all sibling nodes
before this node as L<Mojo::DOM58> objects.

  # "A"
  $dom->parse('A<!-- B --><p>C</p>')->at('p')->preceding_nodes->first->content;

=head2 prepend

  $dom = $dom->prepend('<p>I ♥ Mojo::DOM58!</p>');
  $dom = $dom->prepend(Mojo::DOM58->new);

Prepend HTML/XML fragment to this node (for all node types other than C<root>).

  # "<div><h1>Test</h1><h2>123</h2></div>"
  $dom->parse('<div><h2>123</h2></div>')
    ->at('h2')->prepend('<h1>Test</h1>')->root;

  # "<p>Test 123</p>"
  $dom->parse('<p>123</p>')
    ->at('p')->child_nodes->first->prepend('Test ')->root;

=head2 prepend_content

  $dom = $dom->prepend_content('<p>I ♥ Mojo::DOM58!</p>');
  $dom = $dom->prepend_content(Mojo::DOM58->new);

Prepend HTML/XML fragment (for C<root> and C<tag> nodes) or raw content to this
node's content.

  # "<div><h2>Test123</h2></div>"
  $dom->parse('<div><h2>123</h2></div>')
    ->at('h2')->prepend_content('Test')->root;

  # "<!-- Test 123 --><br>"
  $dom->parse('<!-- 123 --><br>')
    ->child_nodes->first->prepend_content(' Test')->root;

  # "<p><i>123</i>Test</p>"
  $dom->parse('<p>Test</p>')->at('p')->prepend_content('<i>123</i>')->root;

=head2 previous

  my $sibling = $dom->previous;

Return L<Mojo::DOM58> object for previous sibling element, or C<undef> if there
are no more siblings.

  # "<h1>Test</h1>"
  $dom->parse('<div><h1>Test</h1><h2>123</h2></div>')->at('h2')->previous;

=head2 previous_node

  my $sibling = $dom->previous_node;

Return L<Mojo::DOM58> object for previous sibling node, or C<undef> if there are
no more siblings.

  # "123"
  $dom->parse('<p>123<!-- Test --><b>456</b></p>')
    ->at('b')->previous_node->previous_node;

  # " Test "
  $dom->parse('<p>123<!-- Test --><b>456</b></p>')
    ->at('b')->previous_node->content;

=head2 remove

  my $parent = $dom->remove;

Remove this node and return L</"root"> (for C<root> nodes) or L</"parent">.

  # "<div></div>"
  $dom->parse('<div><h1>Test</h1></div>')->at('h1')->remove;

  # "<p><b>456</b></p>"
  $dom->parse('<p>123<b>456</b></p>')
    ->at('p')->child_nodes->first->remove->root;

=head2 replace

  my $parent = $dom->replace('<div>I ♥ Mojo::DOM58!</div>');
  my $parent = $dom->replace(Mojo::DOM58->new);

Replace this node with HTML/XML fragment and return L</"root"> (for C<root>
nodes) or L</"parent">.

  # "<div><h2>123</h2></div>"
  $dom->parse('<div><h1>Test</h1></div>')->at('h1')->replace('<h2>123</h2>');

  # "<p><b>123</b></p>"
  $dom->parse('<p>Test</p>')
    ->at('p')->child_nodes->[0]->replace('<b>123</b>')->root;

=head2 root

  my $root = $dom->root;

Return L<Mojo::DOM58> object for C<root> node.

=head2 selector

  my $selector = $dom->selector;

Get a unique CSS selector for this element.

  # "ul:nth-child(1) > li:nth-child(2)"
  $dom->parse('<ul><li>Test</li><li>123</li></ul>')->find('li')->last->selector;

  # "p:nth-child(1) > b:nth-child(1) > i:nth-child(1)"
  $dom->parse('<p><b><i>Test</i></b></p>')->at('i')->selector;

=head2 strip

  my $parent = $dom->strip;

Remove this element while preserving its content and return L</"parent">.

  # "<div>Test</div>"
  $dom->parse('<div><h1>Test</h1></div>')->at('h1')->strip;

=head2 tag

  my $tag = $dom->tag;
  $dom    = $dom->tag('div');

This element's tag name.

  # List tag names of child elements
  say $dom->children->map('tag')->join("\n");

=head2 tap

  $dom = $dom->tap(sub {...});

Equivalent to L<Mojo::Base/"tap">.

=head2 text

  my $text = $dom->text;

Extract text content from this element only (not including child elements).

  # "bar"
  $dom->parse("<div>foo<p>bar</p>baz</div>")->at('p')->text;

  # "foo\nbaz\n"
  $dom->parse("<div>foo\n<p>bar</p>baz\n</div>")->at('div')->text;

=head2 to_string

  my $str = $dom->to_string;

Render this node and its content to HTML/XML.

  # "<b>Test</b>"
  $dom->parse('<div><b>Test</b></div>')->at('div b')->to_string;

To extract text content from all descendant nodes, see L</"all_text">.

=head2 tree

  my $tree = $dom->tree;
  $dom     = $dom->tree(['root']);

Document Object Model. Note that this structure should only be used very
carefully since it is very dynamic.

=head2 type

  my $type = $dom->type;

This node's type, usually C<cdata>, C<comment>, C<doctype>, C<pi>, C<raw>,
C<root>, C<tag> or C<text>.

  # "cdata"
  $dom->parse('<![CDATA[Test]]>')->child_nodes->first->type;

  # "comment"
  $dom->parse('<!-- Test -->')->child_nodes->first->type;

  # "doctype"
  $dom->parse('<!DOCTYPE html>')->child_nodes->first->type;

  # "pi"
  $dom->parse('<?xml version="1.0"?>')->child_nodes->first->type;

  # "raw"
  $dom->parse('<title>Test</title>')->at('title')->child_nodes->first->type;

  # "root"
  $dom->parse('<p>Test</p>')->type;

  # "tag"
  $dom->parse('<p>Test</p>')->at('p')->type;

  # "text"
  $dom->parse('<p>Test</p>')->at('p')->child_nodes->first->type;

=head2 val

  my $value = $dom->val;

Extract value from form element (such as C<button>, C<input>, C<option>,
C<select> and C<textarea>), or return C<undef> if this element has no value. In
the case of C<select> with C<multiple> attribute, find C<option> elements with
C<selected> attribute and return an array reference with all values, or
C<undef> if none could be found.

  # "a"
  $dom->parse('<input name=test value=a>')->at('input')->val;

  # "b"
  $dom->parse('<textarea>b</textarea>')->at('textarea')->val;

  # "c"
  $dom->parse('<option value="c">Test</option>')->at('option')->val;

  # "d"
  $dom->parse('<select><option selected>d</option></select>')
    ->at('select')->val;

  # "e"
  $dom->parse('<select multiple><option selected>e</option></select>')
    ->at('select')->val->[0];

  # "on"
  $dom->parse('<input name=test type=checkbox>')->at('input')->val;

=head2 with_roles

  my $new_class = Mojo::DOM58->with_roles('Mojo::DOM58::Role::One');
  my $new_class = Mojo::DOM58->with_roles('+One', '+Two');
  $dom          = $dom->with_roles('+One', '+Two');

Equivalent to L<Mojo::Base/"with_roles">. Note that role support depends on
L<Role::Tiny> (2.000001+).

=head2 wrap

  $dom = $dom->wrap('<div></div>');
  $dom = $dom->wrap(Mojo::DOM58->new);

Wrap HTML/XML fragment around this node (for all node types other than C<root>),
placing it as the last child of the first innermost element.

  # "<p>123<b>Test</b></p>"
  $dom->parse('<b>Test</b>')->at('b')->wrap('<p>123</p>')->root;

  # "<div><p><b>Test</b></p>123</div>"
  $dom->parse('<b>Test</b>')->at('b')->wrap('<div><p></p>123</div>')->root;

  # "<p><b>Test</b></p><p>123</p>"
  $dom->parse('<b>Test</b>')->at('b')->wrap('<p></p><p>123</p>')->root;

  # "<p><b>Test</b></p>"
  $dom->parse('<p>Test</p>')->at('p')->child_nodes->first->wrap('<b>')->root;

=head2 wrap_content

  $dom = $dom->wrap_content('<div></div>');
  $dom = $dom->wrap_content(Mojo::DOM58->new);

Wrap HTML/XML fragment around this node's content (for C<root> and C<tag>
nodes), placing it as the last children of the first innermost element.

  # "<p><b>123Test</b></p>"
  $dom->parse('<p>Test<p>')->at('p')->wrap_content('<b>123</b>')->root;

  # "<p><b>Test</b></p><p>123</p>"
  $dom->parse('<b>Test</b>')->wrap_content('<p></p><p>123</p>');

=head2 xml

  my $bool = $dom->xml;
  $dom     = $dom->xml($bool);

Disable HTML semantics in parser and activate case-sensitivity, defaults to
auto detection based on XML declarations.

=head1 COLLECTION METHODS

Some L<Mojo::DOM58> methods return an array-based collection object based on
L<Mojo::Collection>, which can either be accessed directly as an array
reference, or with the following methods.

  # Chain methods
  $collection->map(sub { ucfirst })->shuffle->each(sub {
    my ($word, $num) = @_;
    say "$num: $word";
  });

  # Access array directly to manipulate collection
  $collection->[23] += 100;
  say for @$collection;

=head2 compact

  my $new = $collection->compact;

Create a new L<collection|/"COLLECTION METHODS"> with all elements that are
defined and not an empty string.

  # $collection contains (0, 1, undef, 2, '', 3)
  $collection->compact->join(', '); # "0, 1, 2, 3"

=head2 each

  my @elements = $collection->each;
  $collection  = $collection->each(sub {...});

Evaluate callback for each element in collection or return all elements as a
list if none has been provided. The element will be the first argument passed
to the callback and is also available as C<$_>.

  # Make a numbered list
  $collection->each(sub {
    my ($e, $num) = @_;
    say "$num: $e";
  });

=head2 first

  my $first = $collection->first;
  my $first = $collection->first(qr/foo/);
  my $first = $collection->first(sub {...});
  my $first = $collection->first($method);
  my $first = $collection->first($method, @args);

Evaluate regular expression/callback for, or call method on, each element in
collection and return the first one that matched the regular expression, or for
which the callback/method returned true. The element will be the first argument
passed to the callback and is also available as C<$_>.

  # Longer version
  my $first = $collection->first(sub { $_->$method(@args) });

  # Find first value that contains the word "mojo"
  my $interesting = $collection->first(qr/mojo/i);

  # Find first value that is greater than 5
  my $greater = $collection->first(sub { $_ > 5 });

=head2 flatten

  my $new = $collection->flatten;

Flatten nested collections/arrays recursively and create a new
L<collection|/"COLLECTION METHODS"> with all elements.

  # $collection contains (1, [2, [3, 4], 5, [6]], 7)
  $collection->flatten->join(', '); # "1, 2, 3, 4, 5, 6, 7"

=head2 grep

  my $new = $collection->grep(qr/foo/);
  my $new = $collection->grep(sub {...});
  my $new = $collection->grep($method);
  my $new = $collection->grep($method, @args);

Evaluate regular expression/callback for, or call method on, each element in
collection and create a new L<collection|/"COLLECTION METHODS"> with all
elements that matched the regular expression, or for which the callback/method
returned true. The element will be the first argument passed to the callback
and is also available as C<$_>.

  # Longer version
  my $new = $collection->grep(sub { $_->$method(@args) });

  # Find all values that contain the word "mojo"
  my $interesting = $collection->grep(qr/mojo/i);

  # Find all values that are greater than 5
  my $greater = $collection->grep(sub { $_ > 5 });

=head2 head

  my $new = $collection->head(4);
  my $new = $collection->head(-2);

Create a new L<collection|/"COLLECTION METHODS"> with up to the specified
number of elements from the beginning of the collection. A negative number will
count from the end.

  # $collection contains ('A', 'B', 'C', 'D', 'E')
  $collection->head(3)->join(' '); # "A B C"
  $collection->head(-3)->join(' '); # "A B"

=head2 join

  my $stream = $collection->join;
  my $stream = $collection->join("\n");

Turn collection into string.

  # Join all values with commas
  $collection->join(', ');

=head2 last

  my $last = $collection->last;

Return the last element in collection.

=head2 map

  my $new = $collection->map(sub {...});
  my $new = $collection->map($method);
  my $new = $collection->map($method, @args);

Evaluate callback for, or call method on, each element in collection and create
a new L<collection|/"COLLECTION METHODS"> from the results. The element will be
the first argument passed to the callback and is also available as C<$_>.

  # Longer version
  my $new = $collection->map(sub { $_->$method(@args) });

  # Append the word "mojo" to all values
  my $domified = $collection->map(sub { $_ . 'mojo' });

=head2 reduce

  my $result = $collection->reduce(sub {...});
  my $result = $collection->reduce(sub {...}, $initial);

Reduce elements in collection with callback, the first element will be used as
initial value if none has been provided.

  # Calculate the sum of all values
  my $sum = $collection->reduce(sub { $a + $b });

  # Count how often each value occurs in collection
  my $hash = $collection->reduce(sub { $a->{$b}++; $a }, {});

=head2 reverse

  my $new = $collection->reverse;

Create a new L<collection|/"COLLECTION METHODS"> with all elements in reverse
order.

=head2 slice

  my $new = $collection->slice(4 .. 7);

Create a new L<collection|/"COLLECTION METHODS"> with all selected elements.

  # $collection contains ('A', 'B', 'C', 'D', 'E')
  $collection->slice(1, 2, 4)->join(' '); # "B C E"

=head2 shuffle

  my $new = $collection->shuffle;

Create a new L<collection|/"COLLECTION METHODS"> with all elements in random
order.

=head2 size

  my $size = $collection->size;

Number of elements in collection.

=head2 sort

  my $new = $collection->sort;
  my $new = $collection->sort(sub {...});

Sort elements based on return value of callback and create a new
L<collection|/"COLLECTION METHODS"> from the results.

  # Sort values case-insensitive
  my $case_insensitive = $collection->sort(sub { uc($a) cmp uc($b) });

=head2 tail

  my $new = $collection->tail(4);
  my $new = $collection->tail(-2);

Create a new L<collection|/"COLLECTION METHODS"> with up to the specified
number of elements from the end of the collection. A negative number will count
from the beginning.

  # $collection contains ('A', 'B', 'C', 'D', 'E')
  $collection->tail(3)->join(' '); # "C D E"
  $collection->tail(-3)->join(' '); # "D E"

=head2 tap

  $collection = $collection->tap(sub {...});

Equivalent to L<Mojo::Base/"tap">.

=head2 to_array

  my $array = $collection->to_array;

Turn collection into array reference.

=head2 uniq

  my $new = $collection->uniq;
  my $new = $collection->uniq(sub {...});
  my $new = $collection->uniq($method);
  my $new = $collection->uniq($method, @args);

Create a new L<collection|/"COLLECTION METHODS"> without duplicate elements,
using the string representation of either the elements or the return value of
the callback/method to decide uniqueness. Note that C<undef> and empty string
are treated the same.

  # Longer version
  my $new = $collection->uniq(sub { $_->$method(@args) });

  # $collection contains ('foo', 'bar', 'bar', 'baz')
  $collection->uniq->join(' '); # "foo bar baz"

  # $collection contains ([1, 2], [2, 1], [3, 2])
  $collection->uniq(sub{ $_->[1] })->to_array; # "[[1, 2], [2, 1]]"

=head2 with_roles

  $collection = $collection->with_roles('Mojo::Collection::Role::One');

Equivalent to L<Mojo::Base/"with_roles">. Note that role support depends on
L<Role::Tiny> (2.000001+).

=head1 DEBUGGING

You can set the C<MOJO_DOM58_CSS_DEBUG> environment variable to get some advanced diagnostics information printed to
C<STDERR>.

  MOJO_DOM58_CSS_DEBUG=1

=head1 BUGS

Report issues related to the format of this distribution or Perl 5.8 support to
the public bugtracker. Any other issues should be reported directly to the
upstream L<Mojolicious> issue tracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

Code and tests adapted from L<Mojo::DOM>, a lightweight DOM parser by the L<Mojolicious> team.

=head1 CONTRIBUTORS

=over

=item Matt S Trout (mst)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2016 Sebastian Riedel and others.

Copyright (c) 2016 L</"AUTHOR"> and L</"CONTRIBUTORS"> for adaptation to standalone format.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::DOM>, L<HTML::TreeBuilder>, L<XML::LibXML>, L<XML::Twig>, L<XML::Smart>

=for Pod::Coverage TO_JSON

=cut
