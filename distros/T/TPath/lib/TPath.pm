package TPath;
$TPath::VERSION = '1.007';
# ABSTRACT: general purpose path languages for trees

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath - general purpose path languages for trees

=head1 VERSION

version 1.007

=head1 SYNOPSIS

  # we define our trees
  package MyTree;
  
  use overload '""' => sub {
      my $self     = shift;
      my $tag      = $self->{tag};
      my @children = @{ $self->{children} };
      return "<$tag/>" unless @children;
      local $" = '';
      "<$tag>@children</$tag>";
  };
  
  sub new {
      my ( $class, %opts ) = @_;
      die 'tag required' unless $opts{tag};
      bless { tag => $opts{tag}, children => $opts{children} // [] }, $class;
  }
  
  sub add {
      my ( $self, @children ) = @_;
      push @{ $self->{children} }, @children;
  }
  
  # teach TPath::Forester how to get the information it needs
  package MyForester;
  use Moose;
  use MooseX::MethodAttributes;    # needed for @tag attribute below
  with 'TPath::Forester';
  
  # implement required methods
  
  sub children {
      my ( $self, $n ) = @_;
      @{ $n->{children} };
  }
  
  sub tag {
      my ( $self, $n ) = @_;
      $n->{tag};
  }
  
  sub tag_at : Attr(tag) { # tags receive the selection context, not the bare node
      my ( $self, $context ) = @_;
      $context->n->{tag};
  }
  
  package main;
  
  # make the tree
  #      a
  #     /|\
  #    / | \
  #   b  c  \
  #  /\  |   d
  #  e f |  /|\
  #      h / | \
  #     /| i j  \
  #    l | | |\  \
  #      m n o p  \
  #     /|    /|\  \
  #    s t   u v w  k
  #                / \
  #               q   r
  #                  / \
  #                 x   y
  #                     |
  #                     z
  my %nodes = map { $_ => MyTree->new( tag => $_ ) } 'a' .. 'z';
  $nodes{a}->add( @nodes{qw(b c d)} );
  $nodes{b}->add( @nodes{qw(e f)} );
  $nodes{c}->add( $nodes{h} );
  $nodes{d}->add( @nodes{qw(i j k)} );
  $nodes{h}->add( @nodes{qw(l m)} );
  $nodes{i}->add( $nodes{n} );
  $nodes{j}->add( @nodes{qw(o p)} );
  $nodes{k}->add( @nodes{qw(q r)} );
  $nodes{m}->add( @nodes{qw(s t)} );
  $nodes{p}->add( @nodes{qw(u v w)} );
  $nodes{r}->add( @nodes{qw(x y)} );
  $nodes{y}->add( $nodes{z} );
  my $root = $nodes{a};
  
  # make our forester
  my $rhood = MyForester->new;
  
  # index our tree (not necessary, but efficient)
  my $index = $rhood->index($root);
  
  # try out some paths
  my @nodes = $rhood->path('//r')->select( $root, $index );
  print scalar @nodes, "\n";    # 1
  print $nodes[0], "\n";        # <r><x/><y><z/></y></r>
  print $_
    for $rhood->path('leaf::*[@tag > "o"]')->select( $root, $index )
    ;                           # <s/><t/><u/><v/><w/><q/><x/><z/>
  print "\n";
  print $_->{tag}
    for $rhood->path('//*[@tsize = 3]')->select( $root, $index );    # bm
  print "\n";
  @nodes = $rhood->path('/>~[bh-z]~')->select( $root, $index );
  print $_->{tag} for @nodes;                                        # bhijk
  print "\n";
  
  # we can map nodes back to their parents
  @nodes = $rhood->path('//*[parent::~[adr]~]')->select( $root, $index );
  print $_->{tag} for @nodes;                                        # bcdijkxy
  print "\n";

=head1 DESCRIPTION

TPath provides an xpath-like language for arbitrary trees. You implement a minimum of two
methods -- C<children> and C<tag> -- and then you can explore your trees via
concise, declarative paths.

In tpath, "attributes" are node attributes of any sort and are implemented as methods that 
return these attributes, or C<undef> if the attribute is undefined for the node.

The object in which the two required methods are implemented is a "forester" (L<TPath::Forester>),
something that understands your trees. In general, to use tpath you instantiate a forester and
then call the forester's methods.

Forester objects make use of an index (L<TPath::Index>), which caches information not present in, or
not cheaply extracted from, the nodes themselves. If no index is explicitly provided it is created, but one
can gain some efficiency by reusing an index when selecting paths from a tree. And one can use a forester's
C<index> method to produce a C<TPath::Index>.

The paths themselves are compiled into reusable L<TPath::Expression> objects that can be applied 
to multiple trees. One use's a forester's C<path> method to produce a C<TPath::Expression>.

=head1 ALGORITHM

TPath works by representing an expression as a pipeline of selectors and filters. Each pair of a
selector and some set of filters is called a "step". At each step one has a set of context nodes.
One applies the selectors to each context node, returning a candidate node set, and then one passes
these candidates through the filtering predicates. The remainder becomes the context node set
for the next step. If this is the last step, the surviving candidates are the nodes selected by the
expression. A node will only occur once among those returned and the order of their return will be
the order of their discovery. Search is depth-first pre-ordered -- parents returned before children.

=head2 CAVEAT

The tpath algorithm presupposes the tree it is used against is static, at least for the life of the
index it is using. If the tree is mutating, you must at least ensure that it does not mutate during
the functional life of any index.  The consequence of not doing so may be inaccurate queries.

=head1 SYNTAX

=head2 Sub-Paths

A tpath expression has one or more sub-paths.

=over 2

=item C<//a/b | preceding::d/*>

=back

Sub-paths are separated by the pipe symbol C<|> and optional space.

The nodes selected by a path is the union of the nodes selected by each sub-path in the order of
their discovery. The search is left-to-right and depth first. If a node and its descendants are both selected, the
node will be listed first.

=head2 Steps

=over 2

=item C<//a/b[0]/E<gt>c[@d]>

=item C<//aB</b[0]>/E<gt>c[@d]>

=item C<//a/b[0]B</E<gt>c[@d]>>

=back

Each step consists of a separator (optional on the first step), a tag selector, and optionally some
number of predicates.

=head2 Separators

=over 2

=item C<a/b/c/E<gt>d>

=item C<B</>aB</>b//c/E<gt>d>

=item C<B<//>a/bB<//>c/E<gt>d>

=item C<B</E<gt>>a/b//cB</E<gt>>d>

=back

=head3 null separator

=over 2

=item C<a/b/c/E<gt>d>

=back

The null separator is simply the absence of a separator and can only occur before the first step. 
It means "relative to the context node". Thus is it essentially the same as the file path formalism,
where C</a> means the file C<a> in the root directory and C<a> means the file C<a> in the current directory.

B<Note>, here and in the following discussion we speak of a "root" node, but in reality the node in
question is not the tree root but the node to which the expression is applied. This may be a bit confusing,
but it simplifies the interpretation of expressions. If you genuinely want to begin at the root node,
use the C<:root> selector, described below. Since in general one will apply an expression to a tree's
root node, in general this confusion of terminology is harmless. But know that if you pick a node at
random from a tree and apply an expression to it, this will become the "root" as far as the various
separator definitions here and below are concerned.

=head3 /

=over 2

=item C<B</>aB</>b//c/E<gt>d>

=back

The single slash separator means "search among the context node's children", or if it precedes
the first step it means that the context node is the root node.

=head3 // select among descendants

=over 2

=item C<B<//>a/bB<//>c/E<gt>d>

=back

The double slash separator means "search among the descendants of the context node" or, if the
context node is the root, "search among the root node and its descendants".

=head3 /> select closest

=over 2

=item C<B</E<gt>>a/b//cB</E<gt>>d>

=back

The C</E<gt>> separator means "search among the descendants of the context node (or the context node
and its descendants if the context node is root), but omit from consideration any node dominated by
a node matching the selector". Written out like this this may be confusing, but it is a surprisingly
useful separator. Consider the following tree

         a
        / \
       b   a
       |   | \
       a   b  a
       |      |
       b      b

The expression C</E<gt>b> when applied to the root node will select all the C<b> nodes B<except> the
leftmost leaf C<b>, which is screened from the root by its grandparent C<b> node. That is, going down
any path from the context node C</E<gt>b> will match the first node it finds matching the selector --
the matching node closest to the context node.

=head2 Selectors

Selectors select a candidate set for later filtering by predicates.

=head3 literal

=over 2

=item C<B<a>>

=back

A literal selector selects the nodes whose tag matches, in a tree-appropriate sense of "match",
a literal expression.

Any string may be used to represent a literal selector, but certain characters may have to be
escaped with a backslash. The expectation is that the literal will begin with a word character, _,
or C<$> and any subsequent character is either one of these characters, a number character or 
a hyphen or colon followed by one of these or a number character. The escape character, as usual, is a
backslash. Any unexpected character must be escaped. So

=over 2

=item C<a\\b>

=back

represents the literal C<a\b>.

There is also a quoting convention that one can use to avoid many escapes inside a tag name.

  /:"a tag name you otherwise would have to put a lot of escapes in"

See the Grammar section below for details.

=head3 ~a~ regex

=over 2

=item C<~a~>

=back

A regex selector selects the nodes whose tag matches a regular expression delimited by tildes. Within
the regular expression a tilde must be escaped, of course. A tilde within a regular expression is
represented as a pair of tildes. The backslash, on the other hand, behaves as it normally does within
a regular expression.

=head3 @a attribute

Any attribute may be used as a selector so long as it is preceded by something other than
the null separator -- in other words, C<@> cannot be the first character in a path. This is because 
attributes may take arguments and among other things these arguments can be both expressions and 
other attributes. If C<@foo> were a legitimate path expression it would be ambiguous how to compile 
C<@bar(@foo)>. Is the argument an attribute or a path with an attribute selector? You can produce
the effect of an attribute selector with the null separator, however, in two ways

=over 2

=item C<child::@foo>

=item C<./@foo>

=back

the second of these will be normalized in parsing to precisely what one would expect with a C<@foo>
path.

The attribute naming conventions are the same as those of tags with the exception that attributes are
always preceded by C<@>.

=head3 complement selectors

The C<^> character before a literal, regex, or attribute selector will convert it into a complement selector.

=over 2

=item C<//B<^>foo>

=item C<//B<^>~foo~>

=item C<//B<^>@foo>

=back

Complement selectors select nodes not selected by the unmodified selector: C<//^foo> will select any node
without the C<foo> tag, C<//~a~>, any node whose tag does not contain the C<a> character, and so forth.

=head3 * wildcard

The wildcard selector selects all the nodes on the relevant axis. The default axis is C<child>, so
C<//b/*> will select all the children of C<b> nodes.

=head3 case sensitivity

If you construct a forester with the C<case_insensitive> parameter set to true

  my $f = MyForester->new( case_insensitive => 1 );

the B<tag> selectors in all expressions compiled by this forester will be case insensitive. So then
C<//INPUT> will match C<INPUT> and C<input> and C<InPuT> and so forth. The same is true for C<//input> and
C<//~input~> and C<//^INPUT> etc. If your Perl version is 5.16 or higher, the native C<fc>
function will be used for case normalization. Otherwise, if L<Unicode::CaseFolding> is available, 
its C<fc> function will be used. If no C<fc> function is available, C<lc> will be used for case folding.

=head2 Axes

To illustrate the nodes on various axes I will using the following tree, showing which nodes
are selected from the tree relative the the C<d> node. Selected nodes will be in capital letters.

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=over 8

=item adjacent

  //d/adjacent::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b C     d     E f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

The C<adjacent> axis might be called the C<adjacent-sibling> axis. It selects
the nearest siblings of the context node passing the test. C<//foo/adjacent::p>
will select the immediately preceding and following C<p> siblings of C<foo> nodes.

=item ancestor

  //d/ancestor::*

         ROOT
          |
        __A__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item ancestor-or-self

  //d/ancestor-or-self::*

         ROOT
          |
        __A__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     D     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item child

  //d/child::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i J K L m n o
    |     |     |
    p     q     r

=item descendant

  //d/descendant::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i J K L m n o
    |     |     |
    p     Q     r

=item descendant-or-self

  //d/descendant-or-self::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     D     e f
   /|\   /|\   /|\
  g h i J K L m n o
    |     |     |
    p     Q     r

=item following

  //d/following::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     E F
   /|\   /|\   /|\
  g h i j k l M N O
    |     |     |
    p     q     R

=item following-sibling

  //d/following-sibling::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     E F
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item leaf

  //d/leaf::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i J k L m n o
    |     |     |
    p     Q     r

=item parent

  //d/parent::*

         root
          |
        __A__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item preceding

  //d/preceding::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  B C     d     e f
   /|\   /|\   /|\
  G H I j k l m n o
    |     |     |
    P     q     r

=item preceding-sibling

  //d/preceding-sibling::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  B C     d     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item previous

  //d/previous::*

         ROOT
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     d     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

The previous axis is a bit different from the others. It doesn't concern the
structure of the tree but the history of node selection. The root node is always
included because it is always the initial selection context.

By itself the previous axis is not terribly useful, as it is silly in general to
select a node, then other nodes, then backtrack. It is useful, however, when one
wants to compare properties of different nodes in the selection history. See also
the C<:p> selector, which selects the immediately preceding node in the selection
history.

=item self

  //d/self::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  b c     D     e f
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item sibling

  //d/sibling::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  B C     d     E F
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=item sibling-or-self

  //d/sibling-or-self::*

         root
          |
        __a__
       / /|\ \
      / / | \ \
     / /  |  \ \
    / /   |   \ \
   / /    |    \ \
  B C     D     E F
   /|\   /|\   /|\
  g h i j k l m n o
    |     |     |
    p     q     r

=back

=head2 Predicates

=over 2

=item C<//a/bB<[0]>/E<gt>c[@d][@e E<lt> 'string'][@f or @g]>

=item C<//a/b[0]/E<gt>B<c[@d]>[@e E<lt> 'string'][@f or @g]>

=item C<//a/b[0]/E<gt>c[@d]B<[@e E<lt> 'string']>[@f or @g]>

=item C<//a/b[0]/E<gt>c[@d][@e E<lt> 'string']B<[@f or @g]>>

=back

Predicates are the sub-expressions in square brackets after selectors. They represents
tests that filter the candidate nodes selected by the selectors. 

=head3 Index Predicates

  //foo/bar[0]

An index predicate simply selects the indexed item out of a list of candidates. By default,
the first index is 0, unlike in XML, so the expression above selects the first bar under every 
foo. This is configurable during the construction of your forester, however. If you
pass in the C<one_based> property

  my $f = MyForester->new( one_based => 1 );

The forester will use one-based indexing, so its index predicates will work identically to
index predicates in xpath. (This also affects the C<@index> and C<@pick> attributes. See below.)

The index rules are the same as those for Perl arrays: 0 is the first item; negative indices
count from the end, so -1 retrieves the last item. Negative indices behave the same regardless of
whether the C<one_based> property has been set to true.

=head4 outer versus inner index predicates

In general, an index indicates the location of a node among its siblings which have survived
and preceding filters. For example

  //*[0]

picks all nodes that are the first child of their parent (also the root, which has no parent).
This is distinct from C</descendant-or-self::*[0]>, which will simply pick the root.

  //a[0]

picks all nodes that are the first child of an C<a> node. This is distinct from C</descendant-or-self::a[0]>, 
where the only node returned will simply be the first node picked on this axis.

  //a[@foo][0]

picks all nodes that are the first child of an C<a> node having the property C<@foo>. This is
distinct from C</descendant-or-self::a[@foo][0]>, which will pick only the first C<a> node with
the C<@foo> property.

These predicates are all "inner" predicates. It is also possible to specify "outer" predicates, like so

  (//*)[0]
  (//a)[0]
  (//a[@foo])[0]

In this case, the index is for the collection of all nodes selected up to this point, not relative
to a node's similar siblings. So the first expression picks the first node which is the first
child of its parent; the second picks the first node anywhere that is the first child of an C<a>
node; the third picks the first node anywhere that is the first C<@foo> child node of an C<a> node.

Any predicate may be either inner or outer, but the distinction is most relevant to index predicates for
steps with the C<//> separator.

=head3 Path Predicates

  a[b]

A path predicate is true if the node set it selects starting at the context node is
not empty. Given the tree

    a
   / \
  b   a
  |   |
  a   b

the path C<//a[b]> would select only the two non-leaf C<a> nodes.

=head4 Attribute Predicates

  a[@leaf]

An attribute predicate is true if its context node bears the given attribute. (For the
definition of attributes, see below.) Given the tree

    a
   / \
  b   a
  |   |
  a   b

the path C<//a[@leaf]> would select only the leaf C<a> node.

=head3 Attribute Tests

Attribute tests are predicaters which compare two values. The values may be attributes, expressions, other attribute
tests, or literals, either strings or numbers. 

  //a[@b = 1]       # simple equality test
  //a[* % 2 == 0]   # mathematical expressions
  //a[@foo > :pi]   # comparison to a named constant 
  //a[@foo > "pi"]  # alphabetical sort order comparison

The name "attribute test" is actually a misnomer: originally one of the two items compared had to be an attribute.
Now any two values from the list above are acceptable. If both values are constant, the test is evaluated during
compilation. Analytically true tests are discarded and analytically false ones cause an error to be thrown.

=head4 math in attribute tests

  //a[ (@foo + 1) ** 2 > @bar ]
  //a[ :sqrt(@foo) == 1.414 ]

Basic mathematical expressions are acceptable in attribute tests. The standard precedence relations among operators
are preserved, the operators all have the same representation as in Perl, and one may group expressions with
parentheses to make precedence explicit.

There are two named constants, C<:pi> and C<:e>, the circle constant and the base of the natural logarithm. These are
preceded by colons to distinguish them from path expressions. The operators -- C<+>, C<->, C<*>, C</>, C<%>, and C<**> --
all may also be preceded by a colon when necessary to distinguish them from repetition characters or the wildcard character.
This will rarely be necessary, but consider

  //* [ a * /b = 3 ]

Without the colon, this is taken to be an assertion about the cardinality of the set of nodes selected by the expression
C<a*/b>. If one wants this to be interpreted as concerning the product of the cardinalities of two sets of nodes, one
should write it as

  //* [ a :* /b = 3 ]

The colon also B<must> precede the various unary mathematical expression tpath understands:

  :abs
  :acos
  :asin
  :atan
  :ceil
  :cos
  :exp
  :floor
  :int
  :log
  :log10
  :sin
  :sqrt
  :tan

These are all either the functions provided by Perl itself or those provided by the L<POSIX> module.

=head4 equality and inequality

  a[@b = 1]
  a[@b = "c"]
  a[@b = @c]
  a[@b == @c]
  a[@b != @c]
  ...

The equality and inequality attribute tests, as you would expect, determine whether the left
argument is equal to the right by some definition of equality. If one operator is a number
and the other a collection, it's equality of cardinality. If one is a string, it is whether 
their printed forms are identical. If they are both objects or collections, either referential or
semantic identity is measured. Referential identity means the collections or objects must be the
same individual -- must be stored at the same memory address. This is the meaning of the double
equals sign. The single equals sign designates semantic identity, meaning, in the case of collections,
that they are deeply equal -- the same values stored under the same indices or keys. If one of the items
compared is an object and it has an C<equals> method, this method is invoked as a semantic equality
test (this is the Java convention). Otherwise, referential identity (C<==>, which may be overloaded)
is required. Objects are not treated as containers. Finally, if an object is compared to a string, it will
be the stringification of the former that is compared to the latter using the c<eq> operator when semantic
identity is required.

The C<!=> comparator behaves as you would expect so long as one or the other of the two operands is either
a string or a number. That is, it is the negation of C<=> or C<==>. Otherwise, collections are converted to
cardinalities and objects to strings, with string comparison being used if either argument is an object. If
you wish the negation of C<=> or C<==> with collections or objects, you must negate the positive form:

  a[!(@b = @c)]
  a[!(@b == @c)]

=head4 ranking

  a[@b < 1]
  a[@b < "c"]
  a[@b < @c]
  a[@b > 1]
  a[@b <= 1]
  ...

The ranking operators require some partial order of the operands. If both evaluate to numbers or strings, the
respective orders of these are used. If one is a string, string sort order dominates. If both are collections,
numeric sorting by cardinality is used. Objects are sorted by string comparison.

=head4 matching

The matching operators look for character patterns within strings. They fall into two groups: the regex matchers
and the index matchers.

  a[@b =~ '(?<!c)d']  # regex matching
  a[@b !~ '(?<!c)d']
  a[@b =~ /(?<!c)d/]
  a[@b =~ :m{(?<!/)d}]
  a[@b =~ :m/ (?<!c) d /imsx]
  a[@b =~ @c]
  ...
  a[@b |= 'c']        # index matching
  a[@b =|= 'c']
  a[@b =| 'c']
  a[@b |= @c]
  ...

B<regex matching>

The two regex matching operators, C<=~> and C<!~>, function as you would expect: the right operand is stringified
and compiled into a regular expression and matched against the left operand. If the left operand is constant -- a
string or a number -- this regex compilation occurs at compile time. Otherwise, it must be performed for every match,
at some cost to efficiency.

Note that there are special quoting conventions for the right argument of the regex operator. You may use simple
forward slashes, but in that case one cannot use regex modifiers. Alternatively, you may prefix the expression
with C<:m>, in which case the qname quoting convention is followed and one may provide a modifier suffix. Escaping
within the delimiters is as one would expect for a regular expression, but note that you are writing the
expression as a string rather than a regex literal, so you may have to double-escape.

B<index matching>

Index matching uses the string index function, so it only finds whether one literal string occurs as a substring of
another -- the right as a substring of the left. There are three variants for the three most common uses of index
matching:

=over 2

=item C<|=> prefix

True if the left operand starts with the right operand.

=item C<=|=> infix (anywhere)

True if the right operand occurs anywhere in the left.

=item C<=|> suffix

True if the right operand ends the left operand.

=back

=head3 Boolean Predicates

Boolean predicates combine various terms -- attributes, attribute tests, or tpath expressions --
via boolean operators:

=over 8

=item C<!> or C<not>

True iff the attribute is undefined, the attribute test returns false, the expression returns
no nodes, or the boolean expression is false.

=item C<&> or C<and>

True iff all conjoined operands are true.

=item C<||> or C<or>

True iff any of the conjoined operands is true.

Note that boolean or is two pipe characters. This is to disambiguate the path expression
C<a|b> from the boolean expression C<a||b>.

=item C<;> or C<one>

True B<if one and only one of the conjoined operands is true>. The expression

  @a ; @b

behaves like ordinary exclusive or. But if more than two operands are conjoined
this way, the entire expression is a uniqueness test.

=item C<( ... )>

Groups the contained boolean operations. True iff they evaluate to true.

=back

The normal precedence rules of logical operators applies to these:

  () < ! < & < ; < ||

=head2 Attributes

  //foo[@bar]
  //foo[@bar(1, 'string', path, @attribute, @attribute = 'test')]

Attributes identify callbacks that evaluate a L<TPath::Context> to see whether the respective
attribute is defined for it. If the callback returns a defined value, the predicate is true
and the candidate is accepted; otherwise, it is rejected.

As the second example above demonstrates, attributes may take arguments and these arguments
may be numbers, strings, paths, other attributes, or attribute tests. Paths are
evaluated relative to the candidate node being tested, as are attributes and attribute tests.
A path argument is evaluated to the L<TPath::Context> objects selected by this path relative to the 
candidate node.

Attribute parameters are enclosed within parentheses. Within these parentheses, they are
delimited by commas. Space is optional around parameters.

For the standard attribute set available to all expressions, see L<TPath::Attributes::Standard>.
For the extended set that can be composed in, see L<TPath::Attributes::Extended>.

=head3 Ad Hoc Attributes

There are various ways one can add bespoke attributes but the easiest is to add them to an 
individual forester via the C<add_attribute> method:

  my $forester = MyForester->new;
  $forester->add_attribute( 'foo' => sub {
     my ( $self, $context, @params) = @_;
     ...
  });

Another methods is to define attributes as annotated methods of the forester

  sub foo :Attr {
  	 my ( $self, $context, @params) = @_;
  	 ...
  }

If this would cause a namespace collision or is not a possible method name, you can provide 
the attribute name as a parameter of the method attribute:

  sub foo :Attr(problem:name) {
  	 my ( $self, $context, @params) = @_;
  	 ...
  }

Defining attributes as annotated methods is particularly useful if you wish to
create an attribute library that you can mix into various foresters. In this case
you define the attributes within a role instead of the forester itself.

  package PimpedForester;
  use Moose;
  extends 'TPath::Forester';
  with qw(TheseAttributes ThoseAttributes YonderAttributes Etc);
  sub tag { ... }
  sub children { ... }

=head3 Auto-loaded Attributes

Some trees, like HTML and XML parse trees, may have ad hoc attributes. Foresters for this sort
of tree should override the default C<autoload_attribute> method. This method expects an
attribute name and an optional list of arguments and returns a code reference. The code reference
in turn, when applied to a context and a list of context-specific arguments, must return the value
of the given attribute in that context. For instance, the following implements HTML attribute 
autoloading providing these nodes have an C<attribute> method that returns the value of a particular
attribute at a given node, or C<undef> when the attribute is undefined:

  sub autoload_attribute {
      my ( $self, $name ) = @_;
      return sub {
          my ( $self, $ctx ) = @_;
          return $ctx->n->attribute($name);
      };
  }

With this one could write expressions such as C<//div[@:style =|= 'width']> which auto-load the C<style>
attribute. B<Note the expression syntax>: attributes whose names are preceded by an unescaped colon
are supplied by the C<autoload_attribute> method.

One could make this HTML implementation more efficient by memoizing C<autoload_attribute>. For HTML
attributes it doesn't make sense to further parameterize attribute generation -- all you need is the
name -- so any attribute arguments are ignored during auto-loading.

=head2 Variables

There are three special attributes among the standard attributes that facilitate
using variables in tpath expressions: C<@var>, C<@v>, and C<@clear_var>. The
first two are synonyms, so there are really only two functionally distinct
variable attributes. The first two allow one to set or check the value of a
particular variable. The last clears a variable, returning whatever value it
had before clearing. The variables themselves live in a hash belonging to a
particular expression.

One can use variables to obtain information from a selection other than a list
of nodes. For example,

  my $exp = $forester->path('/*[@v( "size", @tsize )][@v( "leaves", @size(leaf::*) )]');
  $exp->select($tree);
  say 'number of nodes in the tree: ' . $exp->vars->{size};
  say 'number of leaf nodes: ' . $exp->vars->{leaves};

One may also use variables to make later selections in an expression dependent
on earlier selections.

  my $exp = $forester->path('//foo[ @v( "bar", @quux ) ]//baz[ @quux = @v("bar") ]');

Finally, one may use variables to parameterize an expression:

  for my $fruit qw(apple orange kumquat quince) {
      $exp->vars->{fruit} = $fruit;
      my @harvest = $exp->select($tree);
      deliver( $recipients->{$fruit}, @harvest );
  }

=head2 Special Selectors

There are four special selectors B<that cannot occur with predicates> and may only be 
preceded by the C</> or null separators.

=head3 . : Select Self

This is an abbreviation for C<self::*>.

=head3 .. : Select Parent

This is an abbreviation for C<parent::*>.

=head3 :id(foo) : Select By Index

This selector selects the node, if any, with the given id. This same node can also be selected
by C<//*[@id = 'foo']> but this is much less efficient.

=head3 :root : Select Root

This expression selects the root of the tree. It doesn't make much sense except as the
first step in an expression.

=head3 :p : Select the Previously Selected Node

This expression selects the node from which the current node was selected. For example, C</a/b/:p>
will select the C<a> node selected before the C<b> node. How is this ever useful? Well, it lets one
write expressions like

  //a//b[@height = @at(/:p, 'depth')]

This selects all C<b> nodes descended from C<a> nodes where some C<a> node the C<b> node is descended
from has the same depth as the C<b> node's height.

One can iterate the C<:p> selector to move different distances up the selection path and one can impose
predicates on the selector to filter the selection.

  //a//b//c//d[@height = @at(/:p+, 'depth')]

See also the C<previous::> axis.

=head2 Grouping and Repetition

TPath expressions may contain sub-paths consisting of grouped alternates and steps or sub-paths
may be quantified as in regular expressions

=over 2

=item C<//aB<(/b|/c)>/d>

=item C<//aB<?>/bB<*>/cB<+>>

=item C<//aB<(/b/c)+>/d>

=item C<//aB<(/b/c){3}>/d>

=item C<//aB<{3,}>>

=item C<//aB<{0,3}>>

=item C<//aB<{,3}>>

=back

The last expression, C<{,3}>, one does not see in regular expressions. It is the short form
of C<{0,3}>.

Despite this similarity it should be remembered that tpath expression differ from regular 
expressions in that they always return all possible matches, not just the first match
discovered or, for those regular expression engines that provide longest token matching or
other optimality criteria, the optimal match. On the other hand, the first node selected
will correspond to the first match using greedy repetition. And if you have optimality 
criteria you are free to re-rank the nodes selected and pick the first node by this ranking.

=head2 Hiding Nodes

In some cases there may be nodes -- spaces, comments, hidden directories and files -- that you
want your expressions to treat as invisible. To do this you add invisibility tests to the forester
object that generates expressions.

  my $forester = MyForester->new;
  $forester->add_test( sub {
     my ($forester, $node, $index) = @_;
     ... # return true if the node should be invisible
  });

One can put this in the forester's C<BUILD> method to make them invisible to all instances of the
class.

=head2 Potentially Confusing Dissimilarities Between TPath and XPath

For most uses, where tpath and xpath provide similar functionality they will behave
identically. Where you may be led astray is in the semantics of separators beginning
paths.

  /foo/foo
  //foo//foo

In both tpath and xpath, when applied to the root of a tree the first expression will
select the root itself if this root has the tag C<foo> and the second will select all
C<foo> nodes, including the root if it bears this tag. This is notably different from the
behavior of the second step in each path. The second C</foo> will select a C<foo>
B<child> of the root node, not the root node itself, and the second C<//foo> will select
C<foo> descendants of other C<foo> nodes, not the nodes themselves.

Where the two formalisms may differ is in the nodes they return when these paths are applied
to some sub-node. In xpath, C</foo> always refers to the root node, provided this is a
C<foo> node. In tpath it always refers to the node the path is applied to, provided it is
a C<foo> node. In tpath, if you require that the first step
refer to the root node you must use the root selector C<:root>. If you also require that
this node bear the tag C<foo> you must combine the root selector with the C<self::> axis.

  :root/self::foo

This is verbose, but then this is not likely to be a common requirement.

The tpath semantics facilitate the implementation of repetition, which is absent from
xpath.

=head2 String Concatenation

Where you may use a string literal -- C<'foo'>, C<"foo">, C<q("fo'o")>, etc. --
you may also use a string concatenation. The string concatenation operator is
C<~>. The arguments it may separate are string literals, numbers, mathematical
expressions, attributes, or path expressions. Constants will be concatenated
during compilation, so

  //foo('a' ~ 1)

will compile to

  //foo('a1')

The spaces are optional.

=head2 Grammar

The actual L<Regexp::Grammars> parser which defines TPath expressions is in L<TPath::Grammar>. The crucial part, 
most likely, is the definition of the <name> rule which governs what you can put in tags and attribute names 
without escaping. The rule is

          (\\.|[\p{L}\$_])(?>[\p{L}\$\p{N}_]|[-.:](?=[\p{L}_\$\p{N}])|\\.)*+
          | <qname>

This means a tag or attribute name begins with a letter, the dollar sign, or an underscore, and is followed by
these characters or numbers, or dashes, dots, or colons followed by these characters. And at any time one can
violate this basic rule by escaping a character that would put one in violation with the backslash character, which
thus cannot itself appear except when escaped.

One can also use a quoted expression, with either single or double quotes. The usual escaping convention holds, so
"a\"a" would represent two a's with a " between them. However neither single nor double quotes may begin a path as
this would make certain expressions ambiguous -- is C<a[@b = 'c']> comparing C<@b> to a path or a literal?

Finally, one can "quote" the entire expression following the C<qname> convention, which is roughly:

          : [[:punct:]].+?[[:punct:]]

A quoted name begins with a colon followed by some delimiter character, which must be a POSIX punctuation mark. These
are the symbols

  <>[](){}/!"#$%&'*+,-.:;=?@^_`|~

Note that the backslash character is missing from that set. If the character after the colon is the first of one of 
the bracket pairs, the trailing delimiter must be the other member of the pair, so

  :<a>
  :[a]
  :(a)
  :{a}

are correct but

  :<a<

and so forth are bad. However,

  :>a>
  :]a]
  :)a)
  :}a}

are all fine, as are

  :;a;
  ::a:
  :-a-

and so forth. Within these delimiters the normal escaping convention holds: \ escapes the following character.

The C<qname> convention improves readability in some instances by allowing one to avoid escapes. Since the C<qname> convention 
commits you to 3 extra-name characters before any escapes, it is generally not advisable unless you otherwise would have 
to escape more than 3 characters or you feel that whatever escaping you would have to do would mar legibility. Double and
single quotes make particularly legible C<qname> delimiters if it comes to that. Compare

  file\ name\ with\ spaces
  :"file name with spaces"

One uses the same number of characters in each case but the second is clearly easier on the eye. In this case the colon
is necessary because " cannot begin a path expression.

=head3 Comments and Whitespace

Before or after most elements of tpath expressions one may put arbitrary whitespace or #-style comments.

  # a path made more complicated than necessary
  
  //a  # first look for a elements
  /*/* # find the grandchildren of these
  [0]  # select the first-born grandchildren
  [    # and log their foo properties
  @log( @foo )
  ]

There are some places where one cannot put whitespace or a comment: between a separator and a selector

  // a  # bad!

between an C<@> and an attribute name

  @ foo # bad!

and between a repetition suffix and the element repeated

  //a + # bad!

=head2 Escape Sequences in String Literals

All the places where one may use the C<\> escape character to protect a special character in
a string one may also use one of the escape sequences understood by tpath, which are
just those understood by JSON. These are

=over 4

=item \t

The tab character.

=item \n

The ASCII newline character -- decimal character 10 in the basic ASCII set. Note that this
isn't the magic newline character in Perl that adapts to the operating system it finds itself
on. This is just the 10th character in the ASCII set (excluding the null character).

=item \r

The ASCII carriage return character, decimal character 13.

=item \f

The ASCII form feed character.

=item \b

The backspace character.

=item \v

The vertical tab character. Why \v? Well, I figure it's important enough to somebody to be
included in the JSON spec, so it's here too. This is character 11 in ASCII's decimal set.

=back

=head1 HISTORY

I wrote tpath initially in Java (L<http://dfhoughton.org/treepath/>) because I wanted a more 
convenient way to select nodes from parse trees. I've re-written it in Perl because I figured
it might be handy and why not? Since I've been working on the Perl version I've added lots of features.
Eventually I'll back port these to the Java version, but I haven't yet.

=head1 SEE ALSO

L<Tree::XPathEngine> and L<Class::XPath> provide similar functionality, though
their aim is not to provide a generic tree path language but rather to provide
a means of adapting XPath, designed with XML in mind, to non-XML trees. I have
not actually used these modules, but if you are already familiar with XPath and
your node names and whatnot comport with those of XPath, than these may better
suit your needs.

If what you really want is to use XPath on XML in Perl, consider L<XML::XPath> or
L<XML::LibXML>. If speed is your concern and you are able to use the latter,
it's probably what you want.

L<TPath> is fast enough as pure Perl tree path libraries go, but it has Moose's
startup lag and its own conventions.

=head1 ACKNOWLEDGEMENTS

Thanks to Damian Conway for L<Regexp::Grammars>, which makes it pleasant to write complicated
parsers. Thanks to the Moose Cabal, who make it pleasant to write elaborate object oriented Perl.
Without the use of roles I don't think I would have tried this. Thanks to Jon Rubin, who made me
aware that tpath's index predicates weren't working like xpath's (since fixed). And thanks to my
wife Paula, who has heard a lot more about tpath than is useful to her.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
