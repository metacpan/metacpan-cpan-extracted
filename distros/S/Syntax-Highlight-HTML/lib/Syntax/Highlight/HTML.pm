package Syntax::Highlight::HTML;
use strict;
use HTML::Parser;

{ no strict;
  $VERSION = '0.04';
  @ISA = qw(HTML::Parser);
}

=head1 NAME

Syntax::Highlight::HTML - Highlight HTML syntax

=head1 VERSION

Version 0.04

=cut

my %classes = (
    declaration   => 'h-decl',  # declaration <!DOCTYPE ...>
    process       => 'h-pi',    # process instruction <?xml ...?>
    comment       => 'h-com',   # comment <!-- ... -->
    angle_bracket => 'h-ab',    # the characters '<' and '>' as tag delimiters
    tag_name      => 'h-tag',   # the tag name of an element
    attr_name     => 'h-attr',  # the attribute name
    attr_value    => 'h-attv',  # the attribute value
    entity        => 'h-ent',   # any entities: &eacute; &#171;
    line_number   => 'h-lno',   # line number
);

my %defaults = (
    pre     => 1, # add <pre>...</pre> around the result? (default: yes)
    nnn     => 0, # add line numbers (default: no)
);

=head1 SYNOPSIS

    use Syntax::Highlight::HTML;

    my $highlighter = new Syntax::Highlight::HTML;
    $output = $highlighter->parse($html);

If C<$html> contains the following HTML fragment: 

    <!-- a description list -->
    <dl compact="compact">
      <dt>some word</dt>
      <dd>the description of the word. Plus some <a href="/definitions/other_word"
      >reference</a> towards another definition. </dd>
    </dl>

then the resulting HTML contained in C<$output> will render like this: 

=begin html

<style type="text/css">
<!--
.h-decl { color: #336699; font-style: italic; }   /* doctype declaration  */
.h-pi   { color: #336699;                     }   /* process instruction  */
.h-com  { color: #338833; font-style: italic; }   /* comment              */
.h-ab   { color: #000000; font-weight: bold;  }   /* angles as tag delim. */
.h-tag  { color: #993399; font-weight: bold;  }   /* tag name             */
.h-attr { color: #000000; font-weight: bold;  }   /* attribute name       */
.h-attv { color: #333399;                     }   /* attribute value      */
.h-ent  { color: #cc3333;                     }   /* entity               */
.h-lno  { color: #aaaaaa; background: #f7f7f7;}   /* line numbers         */
-->
</style>

<pre>
    <span class="h-com">&lt;!-- a description list --&gt;</span>
    <span class="h-ab">&lt;</span><span class="h-tag">dl</span> <span class="h-attr">compact</span>=<span class="h-attv">"compact</span>"<span class="h-ab">&gt;</span>
      <span class="h-ab">&lt;</span><span class="h-tag">dt</span><span class="h-ab">&gt;</span>some word<span class="h-ab">&lt;/</span><span class="h-tag">dt</span><span class="h-ab">&gt;</span>
      <span class="h-ab">&lt;</span><span class="h-tag">dd</span><span class="h-ab">&gt;</span>the description of the word. Plus some <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/definitions/other_word</span>"
      <span class="h-ab">&gt;</span>reference<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span> towards another definition. <span class="h-ab">&lt;/</span><span class="h-tag">dd</span><span class="h-ab">&gt;</span>
    <span class="h-ab">&lt;/</span><span class="h-tag">dl</span><span class="h-ab">&gt;</span>
</pre>

=end html

=head1 DESCRIPTION

This module is designed to take raw HTML input and highlight it (using a CSS 
stylesheet, see L<"Notes"> for the classes). The returned HTML code is ready 
for inclusion in a web page. 

It is intented to be used as an highlighting filter, and as such does not reformat 
or reindent the original HTML code. 

=head1 METHODS

=over 4

=item new()

The constructor. Returns a C<Syntax::Highlight::HTML> object, which derives from 
C<HTML::Parser>. As such, any C<HTML::parser> method can be called on this object 
(that is, expect for C<parse()> which is overloaded here). 

B<Options>

=over 4

=item *

C<nnn> - Activate line numbering. Default value: 0 (disabled). 

=item *

C<pre> - Surround result by C<< <pre>...</pre> >> tags. Default value: 1 (enabled). 

=back

B<Example>

To avoid surrounding the result by the C<< <pre>...</pre> >> tags:

    my $highlighter = Syntax::Highlight::HTML->new(pre => 0);

=cut

sub new {
    my $self = __PACKAGE__->SUPER::new(
        # API version
        api_version      => 3, 

        # Options
        case_sensitive   => 1, 
        attr_encoded     => 1, 

        # Handlers
        declaration_h    => [ \&_highlight_tag,  'self, event, tagname, attr, text' ], 
        process_h        => [ \&_highlight_tag,  'self, event, tagname, attr, text' ], 
        comment_h        => [ \&_highlight_tag,  'self, event, tagname, attr, text' ], 
        start_h          => [ \&_highlight_tag,  'self, event, tagname, attr, text' ], 
        end_h            => [ \&_highlight_tag,  'self, event, tagname, attr, text' ], 
        text_h           => [ \&_highlight_text, 'self, text' ], 
        default_h        => [ \&_highlight_text, 'self, text' ], 
    );
    
    my $class = ref $_[0] || $_[0]; shift;
    bless $self, $class;
    
    $self->{options} = { %defaults };
    
    my %args = @_;
    for my $arg (keys %defaults) {
        $self->{options}{$arg} = $args{$arg} if defined $args{$arg}
    }
    
    $self->{output} = '';
    
    return $self
}

=item parse()

Parse the HTML code given in argument and returns the highlighted HTML code, 
ready for inclusion in a web page. 

B<Example>

    $highlighter->parse("<p>Hello, world.</p>");

=cut

sub parse {
    my $self = shift;
    
    ## parse the HTML fragment
    $self->{output} = '';
    $self->SUPER::parse($_[0]);
    $self->eof;
    
    ## add line numbering?
    if($self->{options}{nnn}) {
        my $i = 1;
        $self->{output} =~ s|^|<span class="$classes{line_number}">@{[sprintf '%3d', $i++]}</span> |gm;
    }
    
    ## add <pre>...</pre>?
    $self->{output} = "<pre>\n" . $self->{output} . "</pre>\n" if $self->{options}{pre};
    
    return $self->{output}
}

=back

=head2 Internals Methods

The following methods are for internal use only. 

=over 4

=item _highlight_tag()

C<HTML::Parser> tags handler: highlights a tag. 

=cut

sub _highlight_tag {
    my $self = shift;
    my $event = shift;
    my $tagname = shift;
    my $attr = shift;
    
    $_[0] =~ s|&([^;]+;)|<span class="$classes{entity}">&amp;$1</span>|g;
    
    if($event eq 'declaration' or $event eq 'process' or $event eq 'comment') {
        $_[0] =~ s/</&lt;/g;
        $_[0] =~ s/>/&gt;/g;
        $self->{output} .= qq|<span class="$classes{$event}">| . $_[0] . '</span>'
    
    } else {
        $_[0] =~ s|^<$tagname|<<span class="$classes{tag_name}">$tagname</span>|;
        $_[0] =~ s|^</$tagname|</<span class="$classes{tag_name}">$tagname</span>|;
        $_[0] =~ s|^<(/?)|<span class="$classes{angle_bracket}">&lt;$1</span>|;
        $_[0] =~ s|(/?)>$|<span class="$classes{angle_bracket}">$1&gt;</span>|;
        
        for my $attr_name (keys %$attr) {
            next if $attr_name eq '/';
            $_[0] =~ s{$attr_name=(["'])\Q$$attr{$attr_name}\E\1}
            {<span class="$classes{attr_name}">$attr_name</span>=<span class="$classes{attr_value}">$1$$attr{$attr_name}</span>$1}
        }
        
        $self->{output} .= $_[0];
    }
}

=item _highlight_text()

C<HTML::Parser> text handler: highlights text. 

=cut

sub _highlight_text {
    my $self = shift;
    $_[0] =~ s|&([^;]+;)|<span class="$classes{entity}">&amp;$1</span>|g;
    $self->{output} .= $_[0];
}

=back

=head1 NOTES

The resulting HTML uses CSS to colourize the syntax. Here are the classes 
that you can define in your stylesheet. 

=over 4

=item *

C<.h-decl> - for a markup declaration; in a HTML document, the only 
markup declaration is the C<DOCTYPE>, like: 
C<< <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"> >>

=item *

C<.h-pi> - for a process instruction like C<< <?html ...> >>
or C<< <?xml ...?> >>

=item *

C<.h-com> - for a comment, C<< <!-- ... --> >>

=item *

C<.h-ab> - for the characters C<< '<' >> and C<< '>' >> as tag delimiters

=item *

C<.h-tag> - for the tag name of an element

=item *

C<.h-attr> - for the attribute name

=item *

C<.h-attv> - for the attribute value

=item *

C<.h-ent> - for any entities: C<&eacute;> C<&#171;>

=item *

C<.h-lno> - for the line numbers

=back

An example stylesheet can be found in F<eg/html-syntax.css>.

=head1 EXAMPLE

Here is an example of generated HTML output. It was generated with the 
script F<eg/highlight.pl>. 

The following HTML fragment (which is the beginning of 
L<http://search.cpan.org/~saper/>)

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
    <html>
     <head>
      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
      <link rel="stylesheet" href="/s/style.css" type="text/css">
      <title>search.cpan.org: S&#233;bastien Aperghis-Tramoni</title>
     </head>
     <body id="cpansearch">
    <center><div class="logo"><a href="/"><img src="/s/img/cpan_banner.png" alt="CPAN"></a></div></center>
    <div class="menubar">
     <a href="/">Home</a>
    &middot; <a href="/author/">Authors</a>
    &middot; <a href="/recent">Recent</a>
    &middot; <a href="/news">News</a>
    &middot; <a href="/mirror">Mirrors</a>
    &middot; <a href="/faq.html">FAQ</a>
    &middot; <a href="/feedback">Feedback</a>
    </div>
    <form method="get" action="/search" name="f" class="searchbox">
    <input type="text" name="query" value="" size="35">
    <br>in <select name="mode">
     <option value="all">All</option>
     <option value="module" >Modules</option>
     <option value="dist" >Distributions</option>
     <option value="author" >Authors</option>
    </select>&nbsp;<input type="submit" value="CPAN Search">
    </form>

will be rendered like this (using the CSS stylesheet F<eg/html-syntax.css>): 

=begin html

<pre>
<span class="h-lno">  1</span> <span class="h-decl">&lt;!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"&gt;</span>
<span class="h-lno">  2</span> <span class="h-ab">&lt;</span><span class="h-tag">html</span><span class="h-ab">&gt;</span>
<span class="h-lno">  3</span>  <span class="h-ab">&lt;</span><span class="h-tag">head</span><span class="h-ab">&gt;</span>
<span class="h-lno">  4</span>   <span class="h-ab">&lt;</span><span class="h-tag">meta</span> <span class="h-attr">http-equiv</span>=<span class="h-attv">"Content-Type</span>" <span class="h-attr">content</span>=<span class="h-attv">"text/html; charset=iso-8859-1</span>"<span class="h-ab">&gt;</span>
<span class="h-lno">  5</span>   <span class="h-ab">&lt;</span><span class="h-tag">link</span> <span class="h-attr">rel</span>=<span class="h-attv">"stylesheet</span>" <span class="h-attr">href</span>=<span class="h-attv">"/s/style.css</span>" <span class="h-attr">type</span>=<span class="h-attv">"text/css</span>"<span class="h-ab">&gt;</span>
<span class="h-lno">  6</span>   <span class="h-ab">&lt;</span><span class="h-tag">title</span><span class="h-ab">&gt;</span>search.cpan.org: S<span class="h-ent">&amp;#233;</span>bastien Aperghis-Tramoni<span class="h-ab">&lt;/</span><span class="h-tag">title</span><span class="h-ab">&gt;</span>
<span class="h-lno">  7</span>  <span class="h-ab">&lt;/</span><span class="h-tag">head</span><span class="h-ab">&gt;</span>
<span class="h-lno">  8</span>  <span class="h-ab">&lt;</span><span class="h-tag">body</span> <span class="h-attr">id</span>=<span class="h-attv">"cpansearch</span>"<span class="h-ab">&gt;</span>
<span class="h-lno">  9</span> <span class="h-ab">&lt;</span><span class="h-tag">center</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">div</span> <span class="h-attr">class</span>=<span class="h-attv">"logo</span>"<span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/</span>"<span class="h-ab">&gt;</span><span class="h-ab">&lt;</span><span class="h-tag">img</span> <span class="h-attr">src</span>=<span class="h-attv">"/s/img/cpan_banner.png</span>" <span class="h-attr">alt</span>=<span class="h-attv">"CPAN</span>"<span class="h-ab">&gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">div</span><span class="h-ab">&gt;</span><span class="h-ab">&lt;/</span><span class="h-tag">center</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 10</span> <span class="h-ab">&lt;</span><span class="h-tag">div</span> <span class="h-attr">class</span>=<span class="h-attv">"menubar</span>"<span class="h-ab">&gt;</span>
<span class="h-lno"> 11</span>  <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/</span>"<span class="h-ab">&gt;</span>Home<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 12</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/author/</span>"<span class="h-ab">&gt;</span>Authors<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 13</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/recent</span>"<span class="h-ab">&gt;</span>Recent<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 14</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/news</span>"<span class="h-ab">&gt;</span>News<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 15</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/mirror</span>"<span class="h-ab">&gt;</span>Mirrors<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 16</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/faq.html</span>"<span class="h-ab">&gt;</span>FAQ<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 17</span> <span class="h-ent">&amp;middot;</span> <span class="h-ab">&lt;</span><span class="h-tag">a</span> <span class="h-attr">href</span>=<span class="h-attv">"/feedback</span>"<span class="h-ab">&gt;</span>Feedback<span class="h-ab">&lt;/</span><span class="h-tag">a</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 18</span> <span class="h-ab">&lt;/</span><span class="h-tag">div</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 19</span> <span class="h-ab">&lt;</span><span class="h-tag">form</span> <span class="h-attr">method</span>=<span class="h-attv">"get</span>" <span class="h-attr">action</span>=<span class="h-attv">"/search</span>" <span class="h-attr">name</span>=<span class="h-attv">"f</span>" <span class="h-attr">class</span>=<span class="h-attv">"searchbox</span>"<span class="h-ab">&gt;</span>
<span class="h-lno"> 20</span> <span class="h-ab">&lt;</span><span class="h-tag">input</span> <span class="h-attr">type</span>=<span class="h-attv">"text</span>" <span class="h-attr">name</span>=<span class="h-attv">"query</span>" <span class="h-attr">value</span>=<span class="h-attv">"</span>" <span class="h-attr">size</span>=<span class="h-attv">"35</span>"<span class="h-ab">&gt;</span>
<span class="h-lno"> 21</span> <span class="h-ab">&lt;</span><span class="h-tag">br</span><span class="h-ab">&gt;</span>in <span class="h-ab">&lt;</span><span class="h-tag">select</span> <span class="h-attr">name</span>=<span class="h-attv">"mode</span>"<span class="h-ab">&gt;</span>
<span class="h-lno"> 22</span>  <span class="h-ab">&lt;</span><span class="h-tag">option</span> <span class="h-attr">value</span>=<span class="h-attv">"all</span>"<span class="h-ab">&gt;</span>All<span class="h-ab">&lt;/</span><span class="h-tag">option</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 23</span>  <span class="h-ab">&lt;</span><span class="h-tag">option</span> <span class="h-attr">value</span>=<span class="h-attv">"module</span>" <span class="h-ab">&gt;</span>Modules<span class="h-ab">&lt;/</span><span class="h-tag">option</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 24</span>  <span class="h-ab">&lt;</span><span class="h-tag">option</span> <span class="h-attr">value</span>=<span class="h-attv">"dist</span>" <span class="h-ab">&gt;</span>Distributions<span class="h-ab">&lt;/</span><span class="h-tag">option</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 25</span>  <span class="h-ab">&lt;</span><span class="h-tag">option</span> <span class="h-attr">value</span>=<span class="h-attv">"author</span>" <span class="h-ab">&gt;</span>Authors<span class="h-ab">&lt;/</span><span class="h-tag">option</span><span class="h-ab">&gt;</span>
<span class="h-lno"> 26</span> <span class="h-ab">&lt;/</span><span class="h-tag">select</span><span class="h-ab">&gt;</span><span class="h-ent">&amp;nbsp;</span><span class="h-ab">&lt;</span><span class="h-tag">input</span> <span class="h-attr">type</span>=<span class="h-attv">"submit</span>" <span class="h-attr">value</span>=<span class="h-attv">"CPAN Search</span>"<span class="h-ab">&gt;</span>
<span class="h-lno"> 27</span> <span class="h-ab">&lt;/</span><span class="h-tag">form</span><span class="h-ab">&gt;</span>
</pre>

=end html

=head1 CAVEATS

C<Syntax::Highlight::HTML> relies on C<HTML::Parser> for parsing the HTML 
and therefore suffers from the same limitations. 

=head1 SEE ALSO

L<HTML::Parser>

=head1 AUTHORS

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-syntax-highlight-html@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Highlight-HTML>. 
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (C)2004 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Syntax::Highlight::HTML
