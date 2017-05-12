package Petal::Tiny;
$Petal::Tiny::VERSION = '1.16';
use warnings;
use strict;
use Carp;

# REX/Perl 1.0
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron.
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.
my $TextSE = "[^<]+";
my $UntilHyphen = "[^-]*-";
my $Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
my $CommentCE = "$Until2Hyphens>?";
my $UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
my $CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
my $S = "[ \\n\\t\\r]+";
my $NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
my $NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
my $Name = "(?:$NameStrt)(?:$NameChar)*";
my $QuoteSE = "\"[^\"]*\"|'[^']*'";
my $DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
my $MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
my $S1 = "[\\n\\r\\t ]";
my $UntilQMs = "[^?]*\\?+";
my $PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
my $DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
my $DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
my $DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
my $PI_CE = "$Name(?:$PI_Tail)?";
my $EndTagCE = "$Name(?:$S)?>?";
my $AttValSE = "\"[^<\"]*\"|'[^<']*'";
my $ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
my $ElemTagCE_Mod = "$S($Name)(?:$S)?=(?:$S)?($AttValSE)";
my $MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)";
my $XML_SPE = "$TextSE|$MarkupSPE";
# REX END - thank you Robert for this 26 line XML parser - awesome ...

my $ATTR_RE = qr /$ElemTagCE_Mod/;

my $DEFAULT_NS = 'petal';

sub new {
    my $class = shift;
    $class    = ref $class || $class;
    my $thing = shift;
    my $self  = bless {}, $class;
    if (defined $thing and $thing =~ /(\<|\n|\>)/) {
        $self->{xmldata} = $thing;
    }
    elsif (defined $thing) {
        open my $xmldatafile, "<", $thing or die "cannot read open $thing";
        $self->{xmldata} = join '', <$xmldatafile>;
        close $xmldatafile;
    }
    return $self;
}


sub process {
    my $self    = shift;
    my $context = { @_ };
    my $data    = $self->{xmldata};
    defined $data or return; # empty data, empty result.
    return $self->makeitso($self->xml2nodes($data), $context); # earl grey. hot.
}

sub xml2nodes {
    my ($self, $xml) = @_;

    my @flat = ( $xml =~ /$XML_SPE/og );
    my $top = { _kids => [], _ns => $DEFAULT_NS };
    my @nest = ( $top );
    for my $tag (@flat) {
        my $node = tag2node($tag, $nest[-1]{_ns}); # if ns is not explicitly set, inherit parent ns

        if ($node->{_close}) {
            my $open = pop @nest;
            confess "Too many close-tags! Last </$node->{_tag}>." if $open == $top;
            if (lc($node->{_tag}) ne lc($open->{_tag})) {
                my $in = "";
                $in .= $nest[$_]{_elem} for 1..$#nest;
                $in .= $open->{_elem};
                confess "Wrong close-tag '</$node->{_tag}>' following '$in'";
            }
        }
        else {
            push @{ $nest[-1]{_kids} }, $node;
            push @nest, $node unless ($node->{_simple} or $node->{_selfclose});
        }
    }
    confess "Unbalanced tree, more open than close nodes" if @nest > 1;

    my @nodes = @{ $top->{_kids} };

    return \@nodes;
}

sub makeitso {
    my ($self, $nodes, $context) = @_;

    return "" unless @$nodes;

    my @res;
    for my $node (@$nodes) {
        if ($node->{_simple}) {
            push @res, $self->_interpolate_dollar($context, $node->{_elem}, 'resolve_expression');
        }
        else {
            push @res, $self->makeitso_node($node, $context);
        }
    }

    return join "", @res;
}

sub _interpolate_dollar {
    my ($self, $context, $string, $method) = @_;

    if ($string =~ /\$/) {
        my $subst = sub {
            my $what = shift;
            my $res = $self->$method($what, $context);
            return $res if defined $res;
            carp "'$what' in \$-interpolation resolved to undef";
            return "";
        };

        $string =~ s/(?<!\$) \$\{  ( [^{}]+         ) \}  / $subst->($1) /xegi;
        $string =~ s/(?<!\$) \$\{? ( [a-z0-9-\/:_]+ ) \}? / $subst->($1) /xegi;
        $string =~ s/\$\$/\$/g;
    }
    return $string;
}

sub _deep_copy {
    my $node = shift;
    my %copy = %$node;
    my @kids;
    for my $kid (@{ $node->{_kids} }) {
        push @kids, _deep_copy($kid);
    }
    $copy{_kids} = \@kids;
    return \%copy;
}

sub makeitso_node {
    my ($self, $node, $context) = @_;

    my $TAL = $node->{_ns};

    my $STOP_RECURSE = 0;
    
    if ($node->{_has_tal}) {
        $node->{_change} = 1;

        if (defined( my $stuff = delete $node->{"$TAL:on-error"} )) {
            my $nodeCopy = { %$node };
            my $res = eval { $self->makeitso_node($node, $context); };
            if ($@) {
                for my $k (keys %$nodeCopy) { delete $nodeCopy->{$k} if $k =~ /^$TAL:/ }
                delete $nodeCopy->{_selfclose};
                $nodeCopy->{_contents} = $self->resolve_expression($stuff, $context);
                return node2txt($nodeCopy);
            }
            return $res;
        }

        $context = { %$context };

        if (defined( my $stuff = delete $node->{"$TAL:define"} )) {
            for my $def (split /;(?!;)/, $stuff) {
                my ($symbol, $expression) = split ' ', $def, 2;
                $context->{$symbol} = $self->resolve_expression($expression, $context);
            }
        }

        if (defined( my $stuff = delete $node->{"$TAL:condition"} )) {
            for my $cond (split /;(?!;)/, $stuff) {
                return '' unless $self->resolve_expression($cond, $context);
            }
        }

        if (defined( my $stuff = delete $node->{"$TAL:repeat"} )) {
            my @loops = split /;(?!;)/, $stuff;
            my $count = 0;
            return join "", $self->_do_repeat(\$count, 1, \@loops, $node, $context);
        }

        if (defined( my $stuff = delete $node->{"$TAL:content"} )) {
            my $res = $self->resolve_expression($stuff, $context);
            $node->{_contents} = defined $res ? $res : "";
            delete $node->{_selfclose};

            # set the stop recurse flag so that if content contains $foo and $bar,
            # those aren't interpolated as variables.
            $STOP_RECURSE = 1;
        }

        if (defined( my $stuff = delete $node->{"$TAL:replace"} )) {
            my $res = $self->resolve_expression($stuff, $context);
            return defined $res ? $res : '';
        }

        if (defined( my $stuff = delete $node->{"$TAL:attributes"} )) {
            for my $att (split /;(?!;)/, $stuff) {
                my ($symbol, $expression) = split ' ', $att, 2;
                my $add = ($symbol =~ s/^\+//);
                my $new = $self->resolve_expression($expression, $context);
                if (defined $new) {
                    if ($add) {
                        my $old = $node->{$symbol};
                        $old = "" unless defined $old;
                        $new = $old . $new;
                    }
                    $node->{$symbol} = $new;
                }
                else {
                    delete $node->{$symbol} unless $add;
                }
            }
        }

        if (defined(my $stuff = delete $node->{"$TAL:omit-tag"})) {
            if ($stuff eq '' or $self->resolve_expression($stuff, $context)) {
                return $node->{_contents} if $STOP_RECURSE;
                return $self->makeitso($node->{_kids}, $context);
            }
        }
    }

    unless ($STOP_RECURSE) {
        $node->{_contents} = $self->makeitso($node->{_kids}, $context);
    }
    return node2txt($node);
}

sub _do_repeat {
    my ($self, $count, $last, $loops_ref, $node, $context) = @_;
    my @loops = @$loops_ref;
    my $stuff = shift @loops;
    my ($symbol, $expression) = split ' ', $stuff, 2;
    my $array  = $self->resolve_expression($expression, $context);
    $array = [ $array ] unless ref $array; # we don't judge
    my @result;
    foreach my $idx (0 .. $#$array) {
        my $item = $array->[$idx];
        $context->{$symbol} = $item;
        if (@loops) {
            push @result, $self->_do_repeat($count, $last && $idx == $#$array, \@loops, $node, $context);
        }
        else {
            $$count++;
            $context->{repeat} = {};
            $context->{repeat}->{index}  = $$count;
            $context->{repeat}->{number} = $$count;
            $context->{repeat}->{even}   = $$count%2 ? 0 : 1;
            $context->{repeat}->{odd}    = $$count%2 ? 1 : 0;
            $context->{repeat}->{start}  = $$count == 1 ? 1 : 0;
            $context->{repeat}->{end}    = $last && $idx == $#$array ? 1 : 0;
            $context->{repeat}->{inner}  = $context->{repeat}->{start} || $context->{repeat}->{end} ? 0 : 1;

            push @result, $self->makeitso_node(_deep_copy($node), $context);
        }
    }
    return @result;
}


sub resolve_expression {
    my ($self, $expr, $context) = @_;

    $expr = "" unless defined $expr;
    $expr =~ s/[\n\r]/ /g;
    $expr =~ s/^\s+//;
    $expr =~ s/\s+$//;

    $expr =~ s/([;\$])\1/$1/g;
    $expr eq 'nothing' and return undef;
    $expr =~ s/^fresh\s+//;
    my $structure = ($expr =~ s/^structure\s+//);
    my $resolved = $self->resolve($expr, $context);
    return $structure ? $resolved : xmlencode($resolved);
}

sub reftype {
    my ($self, $obj) = @_;
    return ref $obj;
}

sub resolve {
    my ($self, $expr, $context) = @_;
    $expr =~ /:(?!pattern)/ and do { # XXX what is :pattern?
        my ($mod, $expr) = split /:(?!pattern)\s*/, $expr, 2;
        my $meth = $self->can("modifier_$mod");
        return $self->$meth($expr, $context) if $meth;
        confess "unknown modifier $mod";
    };
    return $expr if $expr =~ s/^--//;

    my ($what, @args) = split ' ', $expr;
    defined $what or return;

    my (@path)   = split /\//, $what;
    my @resolved;
    my $obj      = $context;
    @args        = map { $self->resolve($_, $context) } @args;
    while (@path) {
        my $attribute_or_method = shift @path;
        push @resolved, $attribute_or_method;
        my $resolved = join '/', @resolved;
        $obj or confess "cannot fetch $what, because $resolved is undefined";
        my $reftype = $self->reftype($obj);
        $reftype or confess "cannot fetch $what, because $resolved is not a reference";

        if ($reftype eq 'ARRAY') {
            $obj = $obj->[$attribute_or_method];
        }
        elsif ($reftype eq 'HASH') {
            $obj = $obj->{$attribute_or_method};
        }
        elsif ($obj->can($attribute_or_method)) {
            if (@path) {
                $obj = $obj->$attribute_or_method();
            }
            else {
                $obj = $obj->$attribute_or_method(@args);
                @args = ();
            }
        }

        # now, check if what we found was a code-ref
        $reftype = $self->reftype($obj);
        if ($reftype eq 'CODE') {
            if (@path) {
                $obj = $obj->();
            }
            else {
                $obj = $obj->(@args);
                @args = ();
            }
        }

        # if we're done with @path and there's a single arg, use it to look up in array/hash
        if (not @path and @args == 1) {
            $reftype = $self->reftype($obj);

            if ($reftype eq 'ARRAY') {
                $obj = $obj->[ $args[0] ];
                last;
            }
            elsif ($reftype eq 'HASH') {
                $obj = $obj->{ $args[0] };
                last;
            }
        }

        not @path and @args and confess "cannot resolve expression $expr";
    }
    return $obj;
}


sub modifier_true {
    my ($self, $expr, $context) = @_;
    my $arg  = $self->resolve($expr, $context);
    ref $arg and $self->reftype($arg) eq 'ARRAY' and return scalar @$arg;
    return $arg ? 1 : 0;
}


sub modifier_false {
    my $self = shift;
    return not $self->modifier_true(@_);
}


sub modifier_string {
    my ($self, $string, $context) = @_;
    $string = $self->_interpolate_dollar($context, $string, 'resolve');
    return $string;
}


sub node2txt {
    my $node  = shift;

    return $node unless ref $node eq 'HASH'; # handle textnodes introduced in makeitso_node
    return $node->{_elem} if $node->{_simple};

    delete $node->{_ns};
    delete $node->{_has_tal};
    delete $node->{_kids};

    my $change   = delete $node->{_change};
    my $elem     = delete $node->{_elem};
    my $tag      = delete $node->{_tag};
    my $close    = delete $node->{_selfclose};
    my $quotes   = delete $node->{_quotes};
    my $contents = delete $node->{_contents};
    my $att      = join ' ', map { my $q = $quotes->{$_} || '"'; qq|$_=$q$node->{$_}$q| } keys %$node;

    if ($close) {
        return $change ? ($att ? "<$tag $att />" : "<$tag />") : $elem;
    }

    my $start = $change ? ($att ? "<$tag $att>" : "<$tag>") : $elem;
    my $end   = "</$tag>";

    $contents = "" unless defined $contents;

    return $start . $contents . $end;
}

sub tag2node {
    my ($elem, $ns) = @_;

    if (my ($has_close,     $tag) = $elem =~ m, \A < ( /? ) ( [A-Za-z0-9] [A-Za-z0-9_:-]* ) ,x and
        my ($has_self_close     ) = $elem =~ m, ( /? ) > \z ,x)
    {
        return { _tag => $tag, _close => 1 } if $has_close; # don't waste any time on </...> nodes, they're just for book-keeping

        my %node          = extract_attributes($elem);
        $node{_ns}      ||= $ns;

        $node{_has_tal}   = exists $node{_ns_prefix}{ $node{_ns} };
        $node{_tag}       = $tag;
        $node{_selfclose} = $has_self_close;
        $node{_elem}      = $elem;
        $node{_kids}      = [];

        delete $node{_ns_prefix};

        return \%node;
    }

    return {
        _elem => $elem,
        _simple => 1,
    };
}

sub extract_attributes {
    my $tag = shift;

    my %attr = $tag =~ /$ATTR_RE/og;

    my (%quotes, %prefix);

    foreach my $key (keys %attr) {
        $attr{$key} =~ s/^(['"])(.*?)\1$/$2/;
        my $q = $1 || '"';

        if ($key =~ /^(.*?):/) {
            if ($1 eq 'xmlns' && $attr{$key} eq 'http://purl.org/petal/1.0/') {
                delete $attr{$key};
                $key           =~ s/^xmlns\://;
                $attr{_ns}     = $key;
                $attr{_change} = 1;
                next;
            }
            $prefix{$1} = 1;
        }
        $quotes{$key} = $q;
    }

    $attr{_quotes} = \%quotes;
    $attr{_ns_prefix} = \%prefix;

    %attr;
}

my %_encode_dict = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
);

sub xmlencode {
    my $string = shift;
    return $string if !$string or ref $string;
    $string =~ s/([&<>"'])/$_encode_dict{$1}/g;
    return $string;
}


1;


__END__

=head1 NAME

Petal::Tiny - super light TAL for Perl!


=head1 SYNOPSIS

in your Perl code:

  use Petal::Tiny;
  my $template = Petal::Tiny->new('foo.xhtml');
  print $template->process(bar => 'BAZ');


in foo.xhtml

  <html xmlns:tal="http://purl.org/petal/1.0/">
    <body tal:content="bar">Dummy Content</body>
  </html>


and you get something like:

  <html>
    <body>BAZ</body>
  </html>


=head1 SUMMARY

Almost 10 years ago now at the time of this writing, I wrote L<Petal>, an XML
based templating engine that is able to process any kind of XML, XHTML and
HTML. Although I no longer maintain it, I have still used it until today.

L<Petal> is kind of the swiss army knife of the XML templating. It supports
pluggable parsers. Pluggable generators. XML to perl compilation. Disk and
memory caches. Definable charset encoding and decoding. XML or XHTML entity
encoding. I18N. etc. etc.

I wanted something that had most of the really cools feature of L<Petal>, but
that was small and didn't have any dependancies.

Hence, after a couple of days of coding, L<Petal::Tiny> was born. It's still
L<Petal>, but is weighting around 500 lines of code, is completely
self-contained in one .pm file, and doesn't need anything else than Perl.

This POD hence steals a lot of its documentation and explains the differences
between the two modules.


=head1 NAMESPACE

Although this is not mandatory, Petal templates should include use the namespace
L<http://purl.org/petal/1.0/>. Example:

    <html xml:lang="en"
          lang="en"
          xmlns="http://www.w3.org/1999/xhtml"
          xmlns:tal="http://purl.org/petal/1.0/">

      Blah blah blah...
      Content of the file
      More blah blah...
    </html>

If you do not specify the namespace, Petal will by default try to use the
C<petal:> prefix. However, in all the examples of this POD we'll use the
C<tal:> prefix to avoid too much typing.


=head1 KICKSTART

Let's say you have the following Perl code:

    use Petal::Tiny;
    my $template = Petal::Tiny->new ('/my/templates/foo.xml');
    print $template->process ( my_var => some_object() );

some_object() is a subroutine that returns some kind of object, may it be a
scalar, object, array referebce or hash reference. Let's see what we can do...


=head2 Version 1: WYSIWYG friendly prototype.

Using TAL you can do:

    This is the variable 'my_var' :
    <span tal:replace="my_var/hello_world">Hola, Mundo!</span>

Now you can open your template in any WYSIWYG tool (mozilla composer,
frontpage, dreamweaver, adobe golive...) and work with less risk of damaging
your petal commands.


=head2 Version 2: Object-oriented version

Let's now say that C<my_var> is actually an object with a method hello_world()
that returns I<Hello World>. To output the same result, your line, which was:

    <span tal:replace="my_var/hello_world">Hola, Mundo!</span>

Would need to be... EXACTLY the same. Petal lets you access hashes and objects
in an entirely transparent way and tries to automagically do The Right Thing
for you.

This high level of polymorphism means that in most cases you can maintain your
code, swap hashes for objects, and not change a single line of your template
code.


=head2 Version 3: Personalizable

Now let's say that your method hello_world() can take an optional
argument so that C<$some_object-E<gt>hello_world ('Jack')> returns I<Hello Jack>.

You would write:

    <span
        tal:define="var_jack string:Jack"
        tal:replace="my_var/hello_world var_jack">Hola, Mundo!</span>

Optionally, you can directly pass strings (so long as they don't contain
spaces) using two dashes, a la GNU command-line option:

    <span tal:replace="my_var/hello_world --Jack">Hola, Mundo!</span>

TRAP#1: With L<Petal>, You could write:

    <span tal:replace="my_var/hello_world 'Jack'">Hola, Mundo!</span>

This syntax is NOT supported by L<Petal::Tiny>. It's a drag to code, looks ugly
in your templates, and I never used this feature. Thus I dropped it.

TRAP#2: Just like with L<Petal>, you can NOT write nested expressions such as:

    ${my_var/hello_world ${my_var/current_user}}


=head2 Version 4: Internationalized

UNSUPPORTED. Either switch to Petal or write a separate module which handles
this.


=head1 OPTIONS

When you create a L<Petal> template object you can specify plethoras of options
controling file pathes, input parsers / output generators, pluggable encoding
mechanism, language options, etc. etc. Looking back at it I found it totally
over-engineered.

With L<Petal::Tiny> you pass a single argument, which is either a file name or
XML data, and that's it. If the stuff which you pass contains < or a new line,
it's considered XML data. Otherwise it's treated as a file name.


=head1 TAL syntax

Go read L<https://github.com/zopefoundation/zpt-docs>
(http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL> is
dead). L<Petal::Tiny> tries to comply with the TAL spec a lot more
than L<Petal> did.

Currently it implements all operations, i.e. define, condition, repeat,
content, replace, attributes, omit-tag and even on-error (which allows for much
nicer error reporting and exception handling than L<Petal>).

But it also tries to remain true to the "Petal Spirit", hence things like
directly interpolating variables still work, so instead of having to type
things such as:

    <!-- fully TAL compliant version -->
    <p>Checkout amount: <span petal:content="self/basket/total">TOTAL</span> USD</p>

You can still write:

    <!-- BAM! Petal way. Much easier, especially for quick prototyping. -->
    <p>Checkout amount: $self/basket/total USD</p>

TRAP: Don't forget that the default prefix is C<petal:> NOT C<tal:>, until you
set the petal namespace in your HTML or XML document as follows:

    <html xmlns:tal="http://purl.org/petal/1.0/">

=head2 Modifications to TAL

=head3 '+' in attributes

tal:attributes always overrides the content of an attribute, but
occasionally you want to concatenate the new string to the existing
string. Prefixing the attribute name with '+' allows you do to this:

 <div class="foo " tal:attributes="+class bar"/>

outputs

 <div class="foo bar"/>

With +, if the expression returns undef the exisiting attribute is
left unchanged. Without +, it's still deleted.

=head3 Nested loops in repeat

tal:repeat understands semicolon-separated loop-variables to nest loops within same tag, e.g.:

  some_keys => [ "foo", "bar" ],
  some_hash => {
    foo => [ "fooval1", "fooval2" ],
    bar => "barval",
  }

  <span tal:repeat="key some_keys; val some_hash key" tal:replace="structure string:${key}=${val}&"/>

will evaluate to

  foo=fooval1&foo=fooval2&bar=barval&

=head1 METAL macros

UNSUPPORTED.


=head1 EXPRESSIONS AND MODIFIERS

Just like L<Petal>, L<Petal::Tiny> has the ability to bind template variables
to the following Perl datatypes: scalars, lists, hash, arrays and objects. The
article describes the syntax which is used to access these from Petal
templates.

In the following examples, we'll assume that the template is used as follows:

  my $hashref = some_complex_data_structure();
  my $template = Petal::Tiny->new('foo.xml');
  print $template->process ( $hashref );

Then we will show how the Petal Expression Syntax maps to the Perl way of
accessing these values.


=head2 accessing scalar values

Perl expression

  $hashref->{'some_value'};

Petal expression

  some_value

Example

  <!--? Replaces Hello, World with the contents of
        $hashref->{'some_value'}
  -->
  <span tal:replace="some_value">Hello, World</span>


=head2 accessing hashes & arrays

Perl expression

  $hashref->{'some_hash'}->{'a_key'};

Petal expression

  some_hash/a_key

Example

  <!--? Replaces Hello, World with the contents
        of $hashref->{'some_hash'}->{'a_key'}
  -->
  <span tal:replace="some_hash/a_key">Hello, World</span>

Petal expression

  some_hash a_variable

Example

  <!--? Replaces Hello, World with the contents
        of $hashref->{'some_hash'}->{'a_key'}
  -->
  <span tal:define="a_variable --a_key" tal:replace="some_hash a_variable">Hello, World</span>

Perl expression

  $hashref->{'some_array'}->[12]

Petal expression

  some_array/12

Example

  <!--? Replaces Hello, World with the contents
       of $hashref->{'some_array'}->[12]
  -->
  <span tal:replace="some_array/12">Hello, World</span>

Petal expression

  some_array a_variable

Example

  <!--? Replaces Hello, World with the contents
        of $hashref->{'some_array'}->[12]
  -->
  <span tal:define="a_variable 12" tal:replace="some_array a_variable">Hello, World</span>

Note: You're more likely to want to loop through arrays:

  <!--? Loops trough the array and displays each values -->
  <ul tal:condition="some_array">
    <li tal:repeat="value some_array"
        tal:content="value">Hello, World</li>
  </ul>

If you want to loop through a hash, supply both the hash, as well as its relevant keys in $hashref, e.g.:

  some_keys => [ "foo", "bar" ],
  some_hash => {
    foo => "fooval",
    bar => "barval",
  }

  <input type="text" tal:repeat="a_key some_keys" tal:attributes="name a_key; value some_hash a_key" />

which will generate the HTML

  <input type="text" name="foo" value="fooval" />
  <input type="text" name="bar" value="barval" />

=head2 calling anonymous functions

If $hashref->{'some_function'} = sub { ... }.

Perl expressions

  1. $hashref->{'some_function'}->();
  2. $hashref->{'some_function'}->('foo', 'bar');
  3. $hashref->{'some_function'}->($hashref->{'some_variable'});

L<Petal::Tiny expressions>

  1. some_object/some_function
  2. some_object/some_function --foo --bar
  3. some_object/some_function some_variable

TRAP: If the last item in the path is a function or method which
returns a function, it is the path-member who gets the argument-list;
there's no way to predict the future and giving the argument-list to
the function.

=head2 accessing object methods

Perl expressions

  1. $hashref->{'some_object'}->some_method();
  2. $hashref->{'some_object'}->some_method ('foo', 'bar');
  3. $hashref->{'some_object'}->some_method ($hashref->{'some_variable'});

L<Petal::Tiny expressions>

  1. some_object/some_method
  2. some_object/some_method --foo --bar
  3. some_object/some_method some_variable

WARNING! The below expressions which work in L<Petal> are UNSUPPORTED by this
module!

  2a. some_object/some_method 'foo' 'bar'
  2b. some_object/some_method "foo" "bar"


=head2 composing

Petal lets you traverse any data structure, i.e.

Perl expression

  $hashref->{'some_object'}
          ->some_method()
          ->{'key2'}
          ->{'some_function'}->()
          ->some_other_method ( 'foo', $hash->{bar} );

Petal expression

  some_object/some_method/key2/some_function/some_other_method --foo bar


=head2 true:EXPRESSION

  If EXPRESSION returns an array reference
    If this array reference has at least one element
      Returns TRUE
    Else
      Returns FALSE

  Else
    If EXPRESSION returns a TRUE value (according to Perl 'trueness')
      Returns TRUE
    Else
      Returns FALSE

the C<true:> modifiers should always be used when doing Petal conditions.


=head2 false:EXPRESSION

I'm pretty sure you can work this one out by yourself :-)


=head2 set:variable_name EXPRESSION

UNSUPPORTED.


=head2 string:STRING_EXPRESSION

The C<string:> modifier lets you interpolate petal expressions within a string
and returns the value.

  string:Welcome $user/real_name, it is $date!

Alternatively, you could write:

  string:Welcome ${user/real_name}, it is ${date}!

The advantage of using curly brackets is that it lets you interpolate
expressions which invoke methods with parameters, i.e.

  string:The current CGI 'action' param is: ${cgi/param --action}

And IMHO, they make your interpolated variables stand out a lot more in your
templates, so I advise you to use them.


=head2 writing your own modifiers

Just go and pollute the Petal::Tiny namespace:

  sub Petal::Tiny::modifier_uppercase {
      my $self    = shift;
      my $string  = shift;
      my $context = shift;
      return uc ($self->resolve($expression, $context));
  }

Please remember that you need to prefix your modifier name with
'Petal::Tiny::modifier_', thus if you need to create a modifier "SPONGYBOB:",
you define Petal::Tiny::modifier_SPONGYBOB.

Alternatively add your modifiers to a subclass of Petal::Tiny, and
instantiate that class instead of Petal::Tiny.

=head1 Expression keywords


=head2 XML encoding / structure keyword

By default Petal will encode C<&>, C<<>, C<>> and C<"> to C<&amp;>, C<&lt;>,
C<&gt> and C<&quot;> respectively. However sometimes you might want to display
an expression which is already encoded, in which case you can use the
C<structure> keyword.

  structure my/encoded/variable

Note that this is a language I<keyword>, not a modifier. It does not use a
trailing colon.


=head2 Petal::Hash caching and fresh keyword

UNSUPPORTED. L<Petal::Tiny> does no caching.


=head2 TOY FUNCTIONS (For debugging or if you're curious)

UNSUPPORTED. Besides, you will find thatL <Petal::Tiny> error reporting and
handling is a lot better than L<Petal>'s, leading to less debugging
requirement. So long as you feed L<Petal::Tiny> with valid XML, you'll be fine.


=head2 UGLY SYNTAX

UNSUPPORTED. See L<Petal::Deprecated>.


=head2 Performance considerations

The cycle of a L<Petal> template is the following:

    1. Read the source XML template
    2. $INPUT (XML or HTML) throws XML events from the source file
    3. $OUTPUT (XML or HTML) uses these XML events to canonicalize the template
    4. Petal::CodeGenerator turns the canonical template into Perl code
    5. Petal::Cache::Disk caches the Perl code on disk
    6. Petal turns the perl code into a subroutine
    7. Petal::Cache::Memory caches the subroutine in memory
    8. Petal executes the subroutine
    9. (optional) Petal internationalizes the resulting output.

If you are under a persistent environement a la mod_perl, subsequent calls to
the same template will be reduced to step 8 until the source template changes.

The cycle of a L<Petal::Tiny> template is the following:

    1. Read the source XML template
    2. Tokenize it using a big regex
    3. Recursively process the tokens

Benchmarking a simple piece of basic XML shows that Petal is much faster when
running its caches, but much slower otherwise:

 Benchmark: timing 1000 iterations of Petal (disk cache), Petal (memory cache), Petal (no cache), Petal::Tiny...
 Petal (disk cache):  3 wallclock secs ( 2.50 usr +  0.10 sys =  2.60 CPU) @ 384.62/s (n=1000)
 Petal (memory cache):  2 wallclock secs ( 1.76 usr +  0.05 sys =  1.81 CPU) @ 552.49/s (n=1000)
 Petal (no cache): 18 wallclock secs (17.85 usr +  0.09 sys = 17.94 CPU) @ 55.74/s (n=1000)
 Petal::Tiny:  6 wallclock secs ( 6.57 usr +  0.04 sys =  6.61 CPU) @ 151.29/s (n=1000)



=head1 EXPORTS

None.

=head1 BUGS

If you find any, please drop me an email or pull request on github. Patches are always welcome.

=head1 SOURCE AVAILABILITY

This source is on Github:

    https://github.com/lbalker/petal-tiny

=head1 AUTHOR

Current maintainer 1.05+: Lars Balker lars@balker.dk

Original author: Jean-Michel Hiver - jhiver (at) gmail (dot) com

=head1 SEE ALSO

L<Petal>, L<Template::TAL>, L<Mojolicious::Plugin::PetalTinyRenderer>

=head1 LICENSE

This module free software and is distributed under the same license as Perl
itself. Use it at your own risk.
