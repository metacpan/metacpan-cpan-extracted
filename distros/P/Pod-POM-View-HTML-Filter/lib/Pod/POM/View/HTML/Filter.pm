package Pod::POM::View::HTML::Filter;
use Pod::POM::View::HTML;
our @ISA = qw( Pod::POM::View::HTML );

use warnings;
use strict;
use Carp;

our $VERSION = '0.09';

my  %filter;
our %builtin = (
    default => {
        code => sub {
            my $s = shift;
            $s =~ s/&/&amp;/g;
            $s =~ s/</&lt;/g;
            $s =~ s/>/&gt;/g;
            $s;
        },
        verbatim => 1,
    },
    perl_tidy => {
        code     => \&perl_tidy_filter,
        requires => [qw( Perl::Tidy )],
        verbatim => 1,
        alias    => [qw( perl )],
    },
    perl_ppi => {
        code     => \&perl_ppi_filter,
        requires => [qw( PPI PPI::HTML )],
        verbatim => 1,
        alias    => [qw( ppi )],
    },
    html => {
        code     => \&html_filter,
        requires => [qw( Syntax::Highlight::HTML )],
        verbatim => 1,
    },
    shell => {
        code     => \&shell_filter,
        requires => [qw( Syntax::Highlight::Shell )],
        verbatim => 1,
    },
    kate => {
        code     => \&kate_filter,
        requires => [qw( Syntax::Highlight::Engine::Kate )],
        verbatim => 1,
    },
    wiki => {
        code     => \&wiki_filter,
        requires => [qw( Text::WikiFormat )],
        verbatim => 0,
    },
    wikimedia => {
        code     => \&wikimedia_filter,
        requires => [qw( Text::MediawikiFormat )],
        verbatim => 0,
    },
);

# automatically register built-in handlers
my $INIT = 1;
Pod::POM::View::HTML::Filter->add( %builtin );
$INIT = 0;

#
# Specific methods
#
sub new {
    my $class = shift;
    return $class->SUPER::new(
        auto_unindent => 1,
        @_,
        filter => {},    # instance filters
        FILTER => [],    # stack maintaining info for filters
    );
}

sub add {
    my ($self, %args) = @_;
    my $filter = $self->__filter();

    for my $lang ( keys %args ) {
        my $nok = 0;
        if( exists $args{$lang}{requires} ) {
            for ( @{ $args{$lang}{requires} } ) {
                eval "require $_;";
                if ($@) {
                    $nok++;
                    carp "$lang\: pre-requisite $_ could not be loaded"
                      unless $INIT;    # don't warn for built-ins
                }
            }
        }
        croak "$lang: no code parameter given"
          unless exists $args{$lang}{code};

        if ( !$nok ) {
            $filter->{$lang} = $args{$lang};
            if ( $args{$lang}{alias} ) {
                $filter->{$_} = $args{$lang} for @{ $args{$lang}{alias} };
            }
        }
    }
}

sub delete {
    my ( $self, $lang ) = @_;
    my $filter = $self->__filter();
    my $old = $self->_filter()->{$lang};
    $filter->{$lang} = undef;
    return $old;
}

# return a hashref of current filters for the class|instance
sub _filter {
    my ($self) = @_;
    my $filter =
        ref $self
        && UNIVERSAL::isa( $self, 'Pod::POM::View::HTML::Filter' )
        ? { %filter, %{ $self->{filter} } }
        : \%filter;
    $filter->{$_} || delete $filter->{$_} for keys %$filter;
    return $filter;
}

# return the real inner filter list for the class|instance
sub __filter {
    my ($self) = @_;
    return
        ref $self
        && UNIVERSAL::isa( $self, 'Pod::POM::View::HTML::Filter' )
        ? $self->{filter}
        : \%filter;
}

sub know {
    my ($self, $lang) = @_;
    return exists $self->_filter()->{$lang};
}

sub filters { keys %{ $_[0]->_filter() }; }

#
# overridden Pod::POM::View::HTML methods
#
sub view_for {
    my ($self, $for)    = @_;
    my $format = $for->format;
    my $filter = $self->_filter();

    return $for->text() . "\n\n" if $format =~ /^html\b/;

    if ( $format =~ /^filter\b/ ) {
        my $args   = (split '=', $format, 2)[1];
        return '' unless defined $args; # silently skip

        my $text = $for->text;
        my $verbatim = 0;

        # select the filters and options
        my @langs;
        for my $lang (split /\|/, $args) {
            ( $lang, my $opts ) = ( split( ':', $lang, 2 ), '' );
            $opts =~ y/:/ /;
            $lang = exists $filter->{$lang} ? $lang : 'default';
            push @langs, [ $lang, $opts ];
            $verbatim++ if $filter->{$lang}{verbatim};
        }

        # cancel filtering if one filter is missing
        @langs = ( grep { $_->[0] eq 'default' } @langs )
            ? ( [ 'default', '' ] )
            : @langs;

        # process the text
        $text = $filter->{ $_->[0] }{code}->( $text, $_->[1] ) for @langs;

        return $verbatim ? "<pre>$text</pre>\n" : "$text\n";
    }

    # fall-through
    return '';
}

sub view_begin {
    my ($self, $begin)  = @_;
    my ($format, $args) = split(' ', $begin->format(), 2);
    my $filter = $self->_filter();

    if ( $format eq 'html' ) {
        return $self->SUPER::view_begin( $begin );
    }
    elsif( $format eq 'filter' ) {
        my @filters = map { s/^\s*|\s*$//g; $_ } split /\|/, $args;

        # fetch the text and verbatim blocks in the begin section
        # and remember the type of each block
        my $verbatim = 0;
        my $prev = '';
        my $text = '';
        for my $item ( @{ $begin->content } ) {
            $text .= ($prev ? "\n\n" :'') . $item->text();
            $prev = 1;
            $verbatim++ if $item->type eq 'verbatim';
        }

        # a block is verbatim only if all subblocks are verbatim
        $verbatim = 0 if $verbatim != @{ $begin->content };

        # select the filters and options
        my @langs;
        for my $f (@filters) {
            my ( $lang, $opts ) = split( ' ', $f, 2 );
            $lang = exists $filter->{$lang} ? $lang : 'default';
            push @langs, [ $lang, $opts ];
            $verbatim++ if $filter->{$lang}{verbatim};
        }

        # cancel filtering if one filter is missing
        @langs = ( grep { $_->[0] eq 'default' } @langs )
            ? ( [ 'default', '' ] )
            : @langs;

        # process the text
        ( my $indent, $text ) = _unindent($text)
            if $self->{auto_unindent};
        $text = $filter->{ $_->[0] }{code}->( $text, $_->[1] ) for @langs;
        $text =~ s/^(?=.+)/$indent/gm
            if $self->{auto_unindent};

        # the enclosing tags depend on the block and the last filter
        return $verbatim ? "<pre>$text</pre>\n" : "$text\n";
    }

    # fall-through
    return '';
}

#
# utility functions
#

# a simple filter output cleanup routine
sub _cleanup {
    local $_ = shift;
    s!\A<pre>\n?|\n?</pre>\n\z!!gm; # remove <pre></pre>
    $_;
}

sub _unindent {
    my $str = shift;
    my $indent;
    while ( $str =~ /^( *)\S/gmc ) {
        $indent =
              !defined $indent             ? $1
            : length($1) < length($indent) ? $1
            :                                $indent;
    }
    $indent ||= '';
    $str =~ s/^$indent//gm;
    return ( $indent, $str );
}

#
# builtin filters
#

# a cache for multiple parsers with the same options
my %filter_parser;

# Perl highlighting, thanks to Perl::Tidy
sub perl_tidy_filter {
    my ($code, $opts) = ( shift, shift || "" );
    my $output = "";

    # Perl::Tidy 20031021 uses Getopt::Long and expects the default config
    # this is a workaround (a patch was sent to Perl::Tidy's author)
    my $glc = Getopt::Long::Configure();
    Getopt::Long::ConfigDefaults();

    Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$output,
        argv        => "-html -pre -nopod2html " . $opts,
        stderr      => '-',
        errorfile   => '-',
    );
    $output = _cleanup( $output ); # remove <pre></pre>

    # put back Getopt::Long previous configuration, if needed
    Getopt::Long::Configure( $glc );

    return $output;
}

# Perl highlighting, thanks to PPI::HTML
sub perl_ppi_filter {
    my ($code, $opts) = ( shift, shift || '');

    # PPI::HTML options
    my %ppi_opt = map { !/=/ && s/$/=1/ ; split /=/, $_, 2 } split / /, $opts;

    # create PPI::HTML syntax highlighter
    my $highlighter = $filter_parser{ppi}{$opts} ||= PPI::HTML->new(%ppi_opt);

    # highlight the code and clean up the resulting HTML
    my $pretty = $highlighter->html(\$code);
    $pretty =~ s/<br>$//gsm;

    return $pretty;
}

# HTML highlighting thanks to Syntax::Highlight::HTML
sub html_filter {
    my ($code, $opts) = ( shift, shift || "" );

    my $parser = $filter_parser{html}{$opts}
      ||= Syntax::Highlight::HTML->new( map { (split /=/) } split ' ', $opts );
    return _cleanup( $parser->parse($code) );
}

# Shell highlighting thanks to Syntax::Highlight::Shell
sub shell_filter {
    my ($code, $opts) = ( shift, shift || "" );

    my $parser = $filter_parser{shell}{$opts}
      ||= Syntax::Highlight::Shell->new( map { (split /=/) } split ' ', $opts );
    return _cleanup( $parser->parse($code) );
}

# Kate highligthing thanks to Syntax::Highlight::Engine::Kate
sub kate_filter {
    my ($code, $opts) = @_;
    my ($lang) = split ' ', $opts || ''; 

    my $parser = $filter_parser{kate}{$lang}
      ||= Syntax::Highlight::Engine::Kate->new(
        language => $lang,
        substitutions => {
            '<' => '&lt;',
            '>' => '&gt;',
            '&' => '&amp;',
        },
        format_table => {
            Alert        => [ '<span class="k-alert">',        '</span>' ],
            BaseN        => [ '<span class="k-basen">',        '</span>' ],
            BString      => [ '<span class="k-bstring">',      '</span>' ],
            Char         => [ '<span class="k-char">',         '</span>' ],
            Comment      => [ '<span class="k-comment">',      '</span>' ],
            DataType     => [ '<span class="k-datatype">',     '</span>' ],
            DecVal       => [ '<span class="k-decval">',       '</span>' ],
            Error        => [ '<span class="k-error">',        '</span>' ],
            Float        => [ '<span class="k-float">',        '</span>' ],
            Function     => [ '<span class="k-function">',     '</span>' ],
            IString      => [ '<span class="k-istring">',      '</span>' ],
            Keyword      => [ '<span class="k-keyword">',      '</span>' ],
            Normal       => [ '',                              '' ],
            Operator     => [ '<span class="k-operator">',     '</span>' ],
            Others       => [ '<span class="k-others">',       '</span>' ],
            RegionMarker => [ '<span class="k-regionmarker">', '</span>' ],
            Reserved     => [ '<span class="k-reserved">',     '</span>' ],
            String       => [ '<span class="k-string">',       '</span>' ],
            Variable     => [ '<span class="k-variable">',     '</span>' ],
            Warning      => [ '<span class="k-warning">',      '</span>' ],
        },
    );

    return $parser->highlightText($code);
}

sub wiki_filter {
    my ($code, $opts) = (shift, shift || '');
    return Text::WikiFormat::format( $code , {},
        { map { ( split /=/ ) } split ' ', $opts } );
}

sub wikimedia_filter {
    my ($code, $opts) = (shift, shift || '');
    return Text::MediawikiFormat::format( $code , {},
        { map { ( split /=/ ) } split ' ', $opts } );
}

1;

__END__

=head1 NAME

Pod::POM::View::HTML::Filter - Use filters on sections of your pod documents

=cut

=head1 SYNOPSIS

In your POD:

    Some coloured Perl code:

    =begin filter perl

        # now in full colour!
        $A++;

    =end filter

    =for filter=perl $A++; # this works too

    This should read C<bar bar bar>:

    =begin filter foo

    bar foo bar

    =end filter

In your code:

    my $view = Pod::POM::View::HTML::Filter->new;
    $view->add(
        foo => {
            code => sub { my $s = shift; $s =~ s/foo/bar/gm; $s },
            # other options are available
        }
    );

    my $pom = Pod::POM->parse_file( '/my/pod/file' );
    $pom->present($view);

=begin html

<style type="text/css">
<!--
/* HTML colouring styles */
.h-decl { color: #336699; font-style: italic; }   /* doctype declaration  */
.h-pi   { color: #336699;                     }   /* process instruction  */
.h-com  { color: #338833; font-style: italic; }   /* comment              */
.h-ab   { color: #000000; font-weight: bold;  }   /* angles as tag delim. */
.h-tag  { color: #993399; font-weight: bold;  }   /* tag name             */
.h-attr { color: #000000; font-weight: bold;  }   /* attribute name       */
.h-attv { color: #333399;                     }   /* attribute value      */
.h-ent  { color: #cc3333;                     }   /* entity               */
.h-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */

/* Perl colouring styles */
.c  { color: #228B22;} /* comment */
.cm { color: #000000;} /* comma */
.co { color: #000000;} /* colon */
.h  { color: #CD5555; font-weight:bold;} /* here-doc-target */
.hh { color: #CD5555; font-style:italic;} /* here-doc-text */
.i  { color: #00688B;} /* identifier */
.j  { color: #CD5555; font-weight:bold;} /* label */
.k  { color: #8B008B; font-weight:bold;} /* keyword */
.m  { color: #FF0000; font-weight:bold;} /* subroutine */
.n  { color: #B452CD;} /* numeric */
.p  { color: #000000;} /* paren */
.pd { color: #228B22; font-style:italic;} /* pod-text */
.pu { color: #000000;} /* punctuation */
.q  { color: #CD5555;} /* quote */
.s  { color: #000000;} /* structure */
.sc { color: #000000;} /* semicolon */
.v  { color: #B452CD;} /* v-string */
.w  { color: #000000;} /* bareword */
-->
</style>

<p>The resulting HTML will look like this (modulo the stylesheet):</p>

<pre>    <span class="c"># now in full colour!</span>
    <span class="i">$A</span>++<span class="sc">;</span></pre>
<pre><span class="i">$A</span>++<span class="sc">;</span> <span class="c"># this works too</span></pre>
<p>This should read <code>bar bar bar</code>:</p>
<p>bar bar bar</p>

=end html

=head1 DESCRIPTION

This module is a subclass of C<Pod::POM::View::HTML> that support the
C<filter> extension. This can be used in C<=begin> / C<=end> and
C<=for> pod blocks.

Please note that since the view maintains an internal state, only
an instance of the view can be used to present the POM object.
Either use:

    my $view = Pod::POM::View::HTML::Filter->new;
    $pom->present( $view );

or

    $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;
    $pom->present;

Even though the module was specifically designed
for use with C<Perl::Tidy>, you can write your own filters quite
easily (see L<Writing your own filters>).

=head1 FILTERING POD?

The whole idea of this module is to take advantage of all the syntax
colouring modules that exist (actually, C<Perl::Tidy> was my first target)
to produce colourful code examples in a POD document (after conversion
to HTML).

Filters can be used in two different POD constructs:

=over 4

=item C<=begin filter I<filter>>

The data in the C<=begin filter> ... C<=end filter> region is passed to
the filter and the result is output in place in the document.

The general form of a C<=begin filter> block is as follow:

    =begin filter lang optionstring

    # some text to process with filter "lang"

    =end filter

The optionstring is trimed for whitespace and passed as a single string
to the filter routine which must perform its own parsing.

=item C<=for filter=I<filter>>

C<=for> filters work just like C<=begin>/C=<end> filters, except that
a single paragraph is the target.

The general form of a C<=for filter> block is as follow:

    =for filter=lang:option1:option2
    # some code in language lang

The option string sent to the filter C<lang> would be C<option1 option2>
(colons are replaced with spaces).

=back

=head2 Options

Some filters may accept options that alter their behaviour.
Options are separated by whitespace, and appear after the name of the
filter. For example, the following code will be rendered in colour and
with line numbers:

    =begin filter perl -nnn

        $a = 123;
        $b = 3;
        print $a * $b;     # prints 369
        print $a x $b;     # prints 123123123

    =end filter

C<=for> filters can also accept options, but the syntax is less clear.
(This is because C<=for> expects the I<formatname> to match C<\S+>.)

The syntax is the following:

    =for filter=html:nnn=1
         <center><img src="camel.png" />
         A camel</center>

In summary, options are separated by space for C<=begin> blocks and by
colons for C<=for> paragraphs.

The options and their paramater depend on the filter, but they cannot contain
the pipe (C<|>) or colon (C<:>) character, for obvious reasons.

=head2 Pipes

Having filter to modify a block of text is usefule, but what's more useful
(and fun) than a filter? Answer: a stack of filters piped together!

Take the imaginary filters C<foo> (which does a simple C<s/foo/bar/g>)
and C<bang> (which does an even simpler C<tr/r/!/>). The following block

    =begin filter foo|bar

    foo bar baz

    =end

will become C<ba! ba! baz>.

And naturally, 

    =for filter=bar|foo
    foo bar baz

will return C<bar ba! baz>.

=head2 A note on verbatim and text blocks

B<Note:> The fact that I mention I<verbatim> and I<paragraph> in
this section is due to an old bug in C<Pod::POM>, which parses the
content of C<begin>/C<end> sections as the usual POD paragraph
and verbatim blocks. This is a bug in C<Pod::POM>, around which
C<Pod::POM::View::HTML::Filter> tries to work around.

As from version 0.06, C<Pod::POM::View::HTML::Filter> gets to the
original text contained in the C<=begin> / C<=end> block (it was
easier than I thought, actually) and put that string throught all
the filters.

If any filter in the stack is defined as C<verbatim>, or if C<Pod::POM>
detect any block in the C<=begin> / C<=end> block as verbatim, then
the output will be produced between C<< <pre> >> and C<< </pre> >> tags.
Otherwise, no special tags will be added (his is left to the formatter).

=head2 Examples

An example of the power of pipes can be seen in the following example.
Take a bit of Perl code to colour:

    =begin filter perl

        "hot cross buns" =~ /cross/;
        print "Matched: <$`> $& <$'>\n";    # Matched: <hot > cross < buns>
        print "Left:    <$`>\n";            # Left:    <hot >
        print "Match:   <$&>\n";            # Match:   <cross>
        print "Right:   <$'>\n";            # Right:   < buns>

    =end

This will produce the following HTML code:

    <pre>    <span class="q">&quot;hot cross buns&quot;</span> =~ <span class="q">/cross/</span><span class="sc">;</span>
         <span class="k">print</span> <span class="q">&quot;Matched: &lt;$`&gt; $&amp; &lt;$'&gt;\n&quot;</span><span class="sc">;</span>    <span class="c"># Matched: &lt;hot &gt; cross &lt; buns&gt;</span>
         <span class="k">print</span> <span class="q">&quot;Left:    &lt;$`&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Left:    &lt;hot &gt;</span>
         <span class="k">print</span> <span class="q">&quot;Match:   &lt;$&amp;&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Match:   &lt;cross&gt;</span>
         <span class="k">print</span> <span class="q">&quot;Right:   &lt;$'&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Right:   &lt; buns&gt;</span></pre>

=begin html

<p>Which your browser will render as:</p>

<pre>    <span class="q">&quot;hot cross buns&quot;</span> =~ <span class="q">/cross/</span><span class="sc">;</span>
    <span class="k">print</span> <span class="q">&quot;Matched: &lt;$`&gt; $&amp; &lt;$'&gt;\n&quot;</span><span class="sc">;</span>    <span class="c"># Matched: &lt;hot &gt; cross &lt; buns&gt;</span>
    <span class="k">print</span> <span class="q">&quot;Left:    &lt;$`&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Left:    &lt;hot &gt;</span>
    <span class="k">print</span> <span class="q">&quot;Match:   &lt;$&amp;&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Match:   &lt;cross&gt;</span>
    <span class="k">print</span> <span class="q">&quot;Right:   &lt;$'&gt;\n&quot;</span><span class="sc">;</span>            <span class="c"># Right:   &lt; buns&gt;</span></pre>

=end html

Now if you want to colour and number the HTML code produced, it's as simple
as tackling the C<html> on top of the C<perl> filter:

    =begin filter perl | html nnn=1

        "hot cross buns" =~ /cross/;
        print "Matched: <$`> $& <$'>\n";    # Matched: <hot > cross < buns>
        print "Left:    <$`>\n";            # Left:    <hot >
        print "Match:   <$&>\n";            # Match:   <cross>
        print "Right:   <$'>\n";            # Right:   < buns>

    =end

Which produces the rather unreadable piece of HTML:

    <pre><span class="h-lno">  1</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>hot cross buns<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> =~ <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span>/cross/<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
    <span class="h-lno">  2</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Matched: <span class="h-ent">&amp;lt;</span>$`<span class="h-ent">&amp;gt;</span> $<span class="h-ent">&amp;amp;</span> <span class="h-ent">&amp;lt;</span>$'<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>    <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Matched: <span class="h-ent">&amp;lt;</span>hot <span class="h-ent">&amp;gt;</span> cross <span class="h-ent">&amp;lt;</span> buns<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
    <span class="h-lno">  3</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Left:    <span class="h-ent">&amp;lt;</span>$`<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Left:    <span class="h-ent">&amp;lt;</span>hot <span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
    <span class="h-lno">  4</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Match:   <span class="h-ent">&amp;lt;</span>$<span class="h-ent">&amp;amp;</span><span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Match:   <span class="h-ent">&amp;lt;</span>cross<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
    <span class="h-lno">  5</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Right:   <span class="h-ent">&amp;lt;</span>$'<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Right:   <span class="h-ent">&amp;lt;</span> buns<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span></pre>

=begin html

<p>But your your browser will render it as:</p>


<pre><span class="h-lno">  1</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>hot cross buns<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> =~ <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span>/cross/<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
<span class="h-lno">  2</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Matched: <span class="h-ent">&amp;lt;</span>$`<span class="h-ent">&amp;gt;</span> $<span class="h-ent">&amp;amp;</span> <span class="h-ent">&amp;lt;</span>$'<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>    <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Matched: <span class="h-ent">&amp;lt;</span>hot <span class="h-ent">&amp;gt;</span> cross <span class="h-ent">&amp;lt;</span> buns<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
<span class="h-lno">  3</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Left:    <span class="h-ent">&amp;lt;</span>$`<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Left:    <span class="h-ent">&amp;lt;</span>hot <span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
<span class="h-lno">  4</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Match:   <span class="h-ent">&amp;lt;</span>$<span class="h-ent">&amp;amp;</span><span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Match:   <span class="h-ent">&amp;lt;</span>cross<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>
<span class="h-lno">  5</span>     <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"k</span>"<span class="h-ab">&gt;</span>print<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span> <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"q</span>"<span class="h-ab">&gt;</span><span class="h-ent">&amp;quot;</span>Right:   <span class="h-ent">&amp;lt;</span>$'<span class="h-ent">&amp;gt;</span>\n<span class="h-ent">&amp;quot;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"sc</span>"<span class="h-ab">&gt;</span>;<span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span>            <span class="h-ab">&lt;</span><span class="h-tag">span</span> <span class="h-attr">class</span>=<span class="h-attv">"c</span>"<span class="h-ab">&gt;</span># Right:   <span class="h-ent">&amp;lt;</span> buns<span class="h-ent">&amp;gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">span</span><span class="h-ab">&gt;</span></pre>

=end html

=head2 Caveats

There were a few things to keep in mind when mixing verbatim and text paragraphs
in a C<=begin> block. These problems do not exist any more as from version
0.06.

=over 4

=item Text paragraphs are not processed for POD escapes any more

Because the C<=begin> / C<=end> block is now processed as a single
string of text, the following block:

    =begin filter html

    B<foo>

    =end

will not be transformed into C< <b>foo</b> > before being passed to the
filters, but will produce the expected:

    <pre>B<span class="h-ab">&lt;</span><span class="h-tag">foo</span><span class="h-ab">&gt;</span></pre>

=begin html

<p>This will be rendered by your web browser as:</p>

    <pre>B<span class="h-ab">&lt;</span><span class="h-tag">foo</span><span class="h-ab">&gt;</span></pre>

=end html

And the same text in a verbatim block

    =begin filter html
    
        B<foo>

    =end

will produce the same results.

    <pre>    B<span class="h-ab">&lt;</span><span class="h-tag">foo</span><span class="h-ab">&gt;</span></pre>

=begin html

<p>Which a web browser will render as:</p>

    <pre>    B<span class="h-ab">&lt;</span><span class="h-tag">foo</span><span class="h-ab">&gt;</span></pre>

=end html

Which looks quite the same, doesn't it?

=item Separate paragraphs aren't filtered separately any more

As seen in L<A note on verbatim and text blocks>, the filter now processes
the begin block as a single string of text. So, if you have a filter
that replace each C<*> character with an auto-incremented number in
square brackets, like this:

    $view->add(
        notes => {
            code => sub {
                my ( $text, $opt ) = @_;
                my $n = $opt =~ /(\d+)/ ? $1 : 1;
                $text =~ s/\*/'[' . $n++ . ']'/ge;
                $text;
              }
        }
    );

And you try to process the following block:

    =begin filter notes 2
    
    TIMTOWDI*, but your library should DWIM* when possible.
    
    You can't always claims that PICNIC*, can you?
    
    =end filter

You'll get the expected result (contrary to previous versions):

    <p>TIMTOWDI[2], but your library should DWIM[3] when possible.
    
    You can't always claims that PICNIC[4], can you?</p>

The filter was really called only once, starting at C<2>, just like requested.

Future versions of C<Pod::POM::View::HTML::Filter> I<may> support
C<init>, C<begin> and C<end> callbacks to run filter initialisation and
clean up code.

=back

=head1 METHODS

=head2 Public methods

The following methods are available:

=over 4

=item C<< add( lang => { I<options> }, ... ) >>

Add support for one or more languages. Options are passed in a hash
reference.

The required C<code> option is a reference to the filter routine. The
filter must take a string as its only argument and return the formatted
HTML string (coloured accordingly to the language grammar, hopefully).

Available options are:

    Name       Type       Content
    ----       ----       -------

    code       CODEREF    filter implementation

    verbatim   BOOLEAN    if true, force the full content of the
                          =begin/=end block to be passed verbatim
                          to the filter

    requires   ARRAYREF   list of required modules for this filter

Note that C<add()> is both a class and an instance method.

When used as a class method, the new language is immediately available
for all future and existing instances.

When used as an instance method, the new language is only available for
the instance itself.

=item C<delete( $lang )>

Remove the given language from the list of class or instance filters.
The deleted filter is returned by this method.

C<delete()> is both a class and an instance method, just like C<add()>.

=item C<filters()>

Return the list of languages supported.

=item C<know( I<$lang> )>

Return true if the view knows how to handle language C<$lang>.

=back

=head2 Overloaded methods

The following C<Pod::POM::View::HTML> methods are overridden in
C<Pod::POM::View::HTML::Filter>:

=over 4

=item C<new()>

The overloaded constructor initialises some internal structures.
This means that you'll have to use a instance of the class as a
view for your C<Pod::POM> object. Therefore you must use C<new>.

    $Pod::POM::DEFAULT_VIEW = 'Pod::POM::View::HTML::Filter'; # WRONG
    $pom->present( 'Pod::POM::View::HTML::Filter' );          # WRONG

    # this is CORRECT
    $Pod::POM::DEFAULT_VIEW = Pod::POM::View::HTML::Filter->new;

    # this is also CORRECT
    my $view = Pod::POM::View::HTML::Filter->new;
    $pom->present( $view );

The only option at this time is C<auto_unindent>, which is enabled by
default. This option remove leading indentation from all verbatim blocks
within the begin blocks, and put it back after highlighting.

=item C<view_begin()>

=item C<view_for()>

These are the methods that support the C<filter> format.

=back

=head1 FILTERS

=head2 Built-in filters

C<Pod::POM::View::HTML::Filter> is shipped with a few built-in filters.

The name for the filter is obtained by removing C<_filter> from the
names listed below (except for C<default>):

=over 4

=item default

This filter is called when the required filter is not known by
C<Pod::POM::View::HTML::Filter>. It does nothing more than normal POD
processing (POD escapes for text paragraphs and C<< <pre> >> for
verbatim paragraphs.

You can use the C<delete()> method to remove a filter and therefore
make it behave like C<default>.

=item perl_tidy_filter

This filter does Perl syntax highlighting with a lot of help from
C<Perl::Tidy>.

It accepts options to C<Perl::Tidy>, such as C<-nnn> to number lines of
code. Check C<Perl::Tidy>'s documentation for more information about
those options.

=item perl_ppi_filter

This filter does Perl syntax highlighting using C<PPI::HTML>, which is 
itself based on the incredible C<PPI>.

It accepts the same options as C<PPI::HTML>, which at this time solely 
consist of C<line_numbers> to, as one may guess, add line numbers to the 
output. 

=item html_filter

This filter does HTML syntax highlighting with the help of
C<Syntax::Highlight::HTML>.

The filter supports C<Syntax::Highlight::HTML> options:

    =begin filter html nnn=1

    <p>The lines of the HTML code will be numbered.</p>
    <p>This is line 2.</p>

    =end filter

See C<Syntax::Highlight::HTML> for the list of supported options.

=item shell_filter

This filter does shell script syntax highlighting with the help of
C<Syntax::Highlight::Shell>.

The filter supports C<Syntax::Highlight::Shell> options:

    =begin filter shell nnn=1

        #!/bin/sh
        echo "This is a foo test" | sed -e 's/foo/shell/'

    =end filter

See C<Syntax::Highlight::Shell> for the list of supported options.

=item kate_filter

This filter support syntax highlighting for numerous languages
with the help of C<Syntax::Highlight::Engine::Kate>.

The filter supports C<Syntax::Highlight::Engine::Kate> languages as options:

     =begin filter kate Diff
     
         Index: lib/Pod/POM/View/HTML/Filter.pm
         ===================================================================
         --- lib/Pod/POM/View/HTML/Filter.pm     (revision 99)
         +++ lib/Pod/POM/View/HTML/Filter.pm     (working copy)
         @@ -27,6 +27,11 @@
                  requires => [qw( Syntax::Highlight::Shell )],
                  verbatim => 1,
              },
         +    kate => {
         +        code     => \&kate_filter,
         +        requires => [qw( Syntax::Highlight::Engine::Kate )],
         +        verbatim => 1,
         +    },
          );
          
          my $HTML_PROTECT = 0;
     
     =end filter

Check the C<Syntax::Highlight::Engine::Kate> documentation for the full
list of supported languages. Please note that some of them aren't well
supported yet (by C<Syntax::Highlight::Engine::Kate>), so the output
may not be what you expect.

Here is a list of languages we have successfully tested with
C<Syntax::Highlight::Engine::Kate> version 0.02:
C<C>, C<Diff>, C<Fortran>, C<JavaScript>, C<LDIF>, C<SQL>.

=item wiki_filter

This filter converts the wiki format parsed by C<Text::WikiFormat>
in HTML.

The supported options are: C<prefix>, C<extended>, C<implicit_links>,
C<absolute_links>. The option and value are separated by a C<=> character,
as in the example below:

    =begin filter wiki extended=1

    [link|title]

    =end

=item wikimedia_filter

This filter converts the wiki format parsed by C<Text::MediawikiFormat>
in HTML.

The supported options are: C<prefix>, C<extended>, C<implicit_links>,
C<absolute_links> and C<process_html>. The option and value are separated
by a C<=> character.

=back

=head2 Writing your own filters

Write a filter is quite easy: a filter is a subroutine that takes two
arguments (text to parse and option string) and returns the filtered
string.

The filter is added to C<Pod::POM::View::HTML::Filter>'s internal filter
list with the C<add()> method:

    $view->add(
        foo => {
            code     => \&foo_filter,
            requires => [],
        }
    );

When presenting the following piece of pod,

    =begin filter foo bar baz

    Some text to filter.

    =end filter

the C<foo_filter()> routine will be called with two arguments, like this:

    foo_filter( "Some text to filter.", "bar baz" );

If you have a complex set of options, your routine will have to parse 
the option string by itself.

Please note that in a C<=for> construct, whitespace in the option string
must be replaced with colons:

    =for filter=foo:bar:baz Some text to filter.

The C<foo_filter()> routine will be called with the same two arguments
as before.

=head1 BUILT-IN FILTERS CSS STYLES

Each filter uses its own CSS classes, so that one can define their
favourite colours in a custom CSS file.

=head2 C<perl> filter

C<Perl::Tidy>'s HTML code looks like:

    <span class="i">$A</span>++<span class="sc">;</span>

Here are the classes used by C<Perl::Tidy>:

    n        numeric
    p        paren
    q        quote
    s        structure
    c        comment
    v        v-string
    cm       comma
    w        bareword
    co       colon
    pu       punctuation
    i        identifier
    j        label
    h        here-doc-target
    hh       here-doc-text
    k        keyword
    sc       semicolon
    m        subroutine
    pd       pod-text

=head2 C<ppi> filter

C<PPI::HTML> uses the following CSS classes: 

    comment            
    double             
    heredoc_content    
    interpolate        
    keyword            for language keywords (my, use
    line_number        
    number             
    operator           for language operators
    pragma             for pragmatas (strict, warnings)
    single             
    structure          for syntaxic symbols
    substitute         
    symbol             
    word               for module, function and method names
    words              
    match              

=head2 C<html> filter

C<Syntax::Highlight::HTML> makes use of the following classes:

    h-decl   declaration    # declaration <!DOCTYPE ...>
    h-pi     process        # process instruction <?xml ...?>
    h-com    comment        # comment <!-- ... -->
    h-ab     angle_bracket  # the characters '<' and '>' as tag delimiters
    h-tag    tag_name       # the tag name of an element
    h-attr   attr_name      # the attribute name
    h-attv   attr_value     # the attribute value
    h-ent    entity         # any entities: &eacute; &#171;

=head2 C<shell> filter

C<Syntax::Highlight::Shell> makes use of the following classes:

    s-key                   # shell keywords (like if, for, while, do...)
    s-blt                   # the builtins commands
    s-cmd                   # the external commands
    s-arg                   # the command arguments
    s-mta                   # shell metacharacters (|, >, \, &)
    s-quo                   # the single (') and double (") quotes
    s-var                   # expanded variables: $VARIABLE
    s-avr                   # assigned variables: VARIABLE=value
    s-val                   # shell values (inside quotes)
    s-cmt                   # shell comments

=head2 C<kate> filter

Output formatted with C<Syntax::Highlight::Engine::Kate> makes use
of the following classes:

    k-alert                 # Alert
    k-basen                 # BaseN
    k-bstring               # BString
    k-char                  # Char
    k-comment               # Comment
    k-datatype              # DataType
    k-decval                # DecVal
    k-error                 # Error
    k-float                 # Float
    k-function              # Function
    k-istring               # IString
    k-keyword               # Keyword
    k-normal                # Normal
    k-operator              # Operator
    k-others                # Others
    k-regionmarker          # RegionMarker
    k-reserved              # Reserved
    k-string                # String
    k-variable              # Variable
    k-warning               # Warning

=head1 HISTORY

The goal behind this module was to produce nice looking HTML pages from the
articles the French Perl Mongers are writing for the French magazine
GNU/Linux Magazine France (L<http://www.linuxmag-france.org/>).

The resulting web pages can be seen at
L<http://articles.mongueurs.net/magazines/>.

=head1 AUTHOR

Philippe "BooK" Bruhat, C<< <book@cpan.org> >>

=head1 THANKS

Many thanks to Sébastien Aperghis-Tramoni (Maddingue), who helped
debugging the module and wrote C<Syntax::Highlight::HTML> and
C<Syntax::Highlight::Shell> so that I could ship PPVHF with more than
one filter. He also pointed me to C<Syntax::Highlight::Engine::Kate>,
which led me to clean up PPVHF before adding support for SHEK.

Perl code examples where borrowed in Amelia,
aka I<Programming Perl, 3rd edition>.

=head1 TODO

There are a few other syntax highlighting modules on CPAN, which I should
try to add support for in C<Pod::POM::View::HTML::Filter>:

=over 4

=item *

C<Syntax::Highlight::Universal>

=item *

C<Syntax::Highlight::Mason>

=item *

C<Syntax::Highlight::Perl> (seems old)

=item *

C<Syntax::Highlight::Perl::Improved>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pod-pom-view-html-filter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Philippe "BooK" Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

