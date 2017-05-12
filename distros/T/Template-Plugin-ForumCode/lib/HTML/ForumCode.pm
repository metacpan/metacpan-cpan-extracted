package HTML::ForumCode;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use version; our $VERSION = qv('0.0.5')->numify;

use Template::Plugin::HTML;

sub new {
    my ($class, @args) = @_;

    my $new_obj = bless {}, (ref($class)||$class);
    $new_obj->init;

    return $new_obj;
}

sub init {
    my $self = shift;

    # simple [x][/x] --> <x></x> tags
    $self->{simple_tags} = [qw{
        b
        u
        i
    }];
    # replacements; e.g. __x__ --> <u>x</u>
    $self->{replacements} = [
        {   from => '__',       to => 'u'   },
        {   from => '\*\*',     to => 'b'   },
    ];

    return;
}

sub forumcode {
    my ($self, $text) = @_;

    # if we don't have any text, we don't have to do any work
    if (not defined $text) {
        return q{};
    }

    # first of all ESCAPE EVERYTHING!
    $text = Template::Plugin::HTML->escape($text);

    # turn newlines into <br /> tags
    $self->_preserve_newlines(\$text );

    $self->_simple_tags     ( \$text );
    $self->_replacements    ( \$text );
    $self->_colouring       ( \$text );
    $self->_lists           ( \$text );
    $self->_url_links       ( \$text );
    $self->_images          ( \$text );
    $self->_styled_block    ( \$text );
    $self->_quoted_block    ( \$text );
    
    return $text;
}

sub _preserve_newlines {
    my ($self, $textref) = @_;

    $$textref =~ s{\n}{<br />}xmsg;
}

sub _simple_tags {
    my ($self, $textref) = @_;

    # deal with acceptable [x]...[/x] markup
    foreach my $tag (@{ $self->{simple_tags} }) {
        # we should be able to combine these two into one
        #$$textref =~ s{\[$tag\]}{<$tag>}g;
        #$$textref =~ s{\[/$tag\]}{</$tag>}g;
        $$textref =~ s{
            \[($tag)\]
            (.+?)
            \[/$tag\]
        }
        {<$1>$2</$1>}xmsg;
    }
}

sub _replacements {
    my ($self, $textref) = @_;

    # now deal with replacements
    foreach my $tag (@{ $self->{replacements} }) {
        $$textref =~ s{
            $tag->{from}
            (.+?)
            $tag->{from}
        }
        {<$tag->{to}>$1</$tag->{to}>}gx;
    }
}

sub _url_links {
    my ($self, $textref) = @_;

    # deal with links with no text-label
    $$textref =~ s{\[url\](.+?)\[/url\]}
        {<a href="$1">$1</a>}xmsg;
    # deal with links with a text-label
    $$textref =~ s{
        \[url           # start of url tag
        \s+             # need some whitespace
        name=&quot;     # name="
        (.+?)           # the name
        &quot;          # closing "
        \s*             # optional whitespace
        \]              # close the opening tag
        (.+?)           # the url
        \[/url\]        # close the URL tag
    }
    {<a href="$2">$1</a>}xmsg;
    # bbcode / explosm style urls
    $$textref =~ s{
        \[URL=&quot;    # opening url tag
        (.+?)           # the url
        &quot;\]        # close-opening tag
        (.+?)           # link name/text/label
        \[/URL]         # closing tag
    }
    {<a href="$1">$2</a>}ximsg;
}

sub _images {
    my ($self, $textref) = @_;

    # deal with image tags
    $$textref =~ s{
        \[img           # opening img tag
        (.*?)           # optional parameters
        \]              # close-opening tag
        (.+?)           # image URL
        \[/img\]        # closing img tag
    }
    #{<img src="$2"$1 />}ximsg;
    {&_image_tag_with_attr($2,$1)}ximsge;
}

sub _image_tag_with_attr {
    my ($uri, $attr_match) = @_;

    # no annoying image attributes to worry about
    if (q{} eq $attr_match) {
        return qq{<img src="$uri" />};
    }
    # deal with annoying image attributes
    else {
        $attr_match =~ s{
            (\w+)
            =
            &quot;
            (\w+?)
            &quot;
        }
        {$1="$2"}xmsg;
        return qq{<img src="$uri"$attr_match />};
    }
}

sub _colouring {
    my ($self, $textref) = @_;

    # deal with colouring
    $$textref =~ s{
        \[(colou?r)
        =
        (
              red | orange | yellow | green | blue
            | black | white
            | \#[0-9a-fA-F]{3}
            | \#[0-9a-fA-F]{6}
        )
        \]
        (.+?)
        \[/\1\]
    }
    {<span style="color: $2">$3</span>}ixmsg;
}

sub _lists {
    my ($self, $textref) = @_;

    $$textref =~ s{
        \[list\]
        (?:
            \s*
            (?:
                <br\s*?/>
            )?
            \s*
        )
        (.+?)
        \[/list\]
        [\s]*
        (?:
            <br\s*?/>
        )?
    }
    {_list_elements($1)}xmsge;
}

sub _list_elements {
    my ($text) = @_;

    # ordered lists
    if (
        $text =~ s{
            \[\*\]
            \s*
            (.+?)
            <br\s*?/>
            \s*
        }
        {<li>$1</li>}xmsg
    ) {
        return qq{<ul>$text</ul>};
    }

    # ordered lists
    if (
        $text =~ s{
            \[1\]
            \s*
            (.+?)
            <br\s*?/>
            \s*
        }
        {<li>$1</li>}xmsg
    ) {
        return qq{<ol>$text</ol>};
    }


    # otherwise, just return what we were given
    return $text;
}

sub _styled_block {
    my ($self, $textref) = @_;

    $$textref =~ s{
        \[(code|pre|quote)\]
        (.+?)
        \[/\1\]
    }
    {<div class="forumcode_$1">$2</div>}xmsg;
}

# this deals with the extended case of [quote] where we have the quoting=
# attribute
sub _quoted_block {
    my ($self, $textref) = @_;

    $$textref =~ s{
        \[
            (quote)
            \s+
            quoting=
            &quot;
            (.+?)
            &quot;
        \]
        (.+?)
        \[/\1\]
    }
    {<div class="forumcode_$1"><div class="forumcode_quoting">Quoting $2:</div>$3</div>}xmsg;
}

1;
__END__
vim: ts=8 sts=4 et sw=4 sr sta

=pod

=head1 NAME

HTML::ForumCode - BBCode-esque forum markup

=head1 SYNOPSIS

Usage in a perl module:

  use HTML::ForumCode;

  my $tt_forum  = HTML::ForumCode->new();
  my $formatted = $tt_forum->forumcode($text);

Standard usage in a Template Toolkit file:

  # load the TT module
  [% USE ForumCode %]

  # ForumCodify some text
  [% ForumCode.forumcode('[b]bold[/u] [u]underlined[/u] [i]italic[/i]') %]
  [% ForumCode.forumcode('**bold** __underlined__') %]

=head1 DESCRIPTION

This module implements ForumCode, a simple markup language inspired by the
likes of BBCode.

ForumCode allows end-users (of a web-site) limited access to a set of HTML
markup through a HTML-esque syntax.

This module works by using L<Template::Plugin::HTML> to escape all HTML
entities and markup. It then performs a series of transformations to convert
ForumCode markup into the appropriate HTML markup.

=head1 MARKUP

HTML::ForumCode plugin will perform the following transformations:

=over 4

=item B<[b]>...B<[/b]> or B<**>...B<**>

Make the text between the markers I<bold>.

=item B<[u]>...B<[/u]> or B<__>...B<___>

Make the text between the markers I<underlined>.
  
=item B<[i]>...B<[/i]>

Make the text between the markers I<italicised>.

=item B<[url]>http://...B<[/url]> or B<[url="http://..."]>LinkTextB<[/url]>

Make the text between the markers into a I<HTML link>. If you
would like to give the link a name, use the following format:

S<[url B<name="...">]http://...[/url]>

=item B<[img]>http://...B<[/img]>

Insert an I<image>, specified by the URL between the markers.

You may also include extra attributes such as title=, alt=, etc. Research the
HTML E<lt>imgE<gt> tag  for the full list of attributes.

  e.g.
   [img title='Powered by Catalyst' width='50']http://.../images/button.png[/img]

=item B<[colour=I<code>]>...B<[/colour]>

Make a block of text appear in the I<colour> specified by I<code>.

I<code> can be any of the named colours: red, orange, yellow, green, blue, black, white.

I<code> may also be a #RGB value in either the #XYZ or #XXYYZZ format.

For the sake of international relations C<< [color=I<code>]...[/color] >> may also be used.

  e.g. red text
   [colour=red]Red Text[/colour]
   [colour=#ff0000]Red Text[/colour]

=item B<[list]>...B<[/list]>

Create an ordered or unordered list of items. To create an I<unordered list> use B<[*]> to
mark the start of each list item. To create an I<ordered list> use B<[1]> to mark the start
of each list item.

  e.g. an unordered list
   [list]
   [*]apple
   [*]orange
   [*]banana
   [/list]

  e.g. an ordered list
   [list]
   [1]first
   [1]second
   [1]third
   [/list]

=item B<[code]>...B<[/code]>

Marks a block of text with the CSS I<forumcode_code> class.
How this displays is dependant on the CSS definitions in your application
templates.

  /* Example CSS */

  .forumcode_code {
    font-family:        monospace;
    border:             1px solid #333;
    font-size:          95%;
    margin:             15px 20px 15px 20px;
    padding:            6px;
    width:              85%;
    overflow:           auto;
    white-space:        pre;

    color:              #ff0;
    background-color:   #333;
    border:             1px solid #666;
  }

=item B<[pre]>...B<[/pre]>

Marks a block of text with the CSS I<forumcode_pre> class.
How this displays is dependant on the CSS definitions in your application
templates.

  /* Example CSS */

  .forumcode_pre {
    background-color:   transparent;
    font-family:        monospace;
    font-size:          95%;
    border:             1px dashed #333;
    margin:             15px 20px 15px 20px;
    padding:            6px;
    width:              85%;
    overflow:           auto;
    white-space:        pre;
  }

=item B<[quote]>...B<[/quote]>

Marks a block of text with the CSS I<forumcode_pre> class.
How this displays is dependant on the CSS definitions in your application
templates.

You may specify the name of ther person you are quoting using the following
addition to the markup:

S<[quote B<quoting="...">]Lorem ipsum ...[/quote]>

The quoted text will be prefixed with B<Quoting Name:>.
This extra output will be wrapped in with the CSS I<forumcode_quoting> class.

  /* Example CSS */

  .forumcode_quote {
    background-color:   #eee;
    font-family:        monospace;
    font-style:         italic;
    border:             1px dotted #333;
    font-size:          95%;
    margin:             15px 20px 15px 20px;
    padding:            6px;
    width:              85%;
    overflow:           auto;
  }

  .forumcode_quoting {
    font-weight:        bold;
    margin-bottom:      3px;
  }

=back

=head1 PUBLIC METHODS

=head2 new

Create a new instance of the plugin for TT usage

=head2 forumcode

The transformation function

=head1 PRIVATE METHODS

=head2 init

Called during the object set-up to initialise the object with the required
information and voodoo.

=head1 SEE ALSO

L<Template::Plugin::ForumCode>,
L<Template::Plugin::HTML>,
L<Template::Toolkit>,
L<HTML::ForumCode::Cookbook>

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
