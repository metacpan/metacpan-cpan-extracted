SYNOPSIS
========

        use Regexp::Common qw( Markdown );

        while( <> )
        {
            my $pos = pos( $_ );
            /\G$RE{Markdown}{Header}/gmc   and  print "Found a header at pos $pos\n";
            /\G$RE{Markdown}{Bold}/gmc     and  print "Found bold text at pos $pos\n";
        }

VERSION
=======

        v0.1.5

DESCRIPTION
===========

This module provides Markdown regular expressions as set out by its
original author [John
Gruber](https://daringfireball.net/projects/markdown/syntax){.perl-module}

There are different types of patterns: vanilla and extended. To get the
extended regular expressions, use the `-extended` switch.

You can use each regular expression by using their respective names:
*Bold*, *Blockquote*, *CodeBlock*, *CodeLine*, *CodeSpan*, *Em*,
*HtmlOpen*, *HtmlClose*, *HtmlEmpty*, *Header*, *HeaderLine*, *Image*,
*ImageRef*, *Line*, *Link*, *LinkAuto*, *LinkDefinition*, *LinkRef*,
*List*

Almost all of the regular expressions use named capture. See [\"%+\" in
perlvar](https://metacpan.org/pod/perlvar#%+){.perl-module} for more
information on named capture.

For example:

        if( $text =~ /$RE{Markdown}{LinkAuto}/ )
        {
            print( "Found https url \"$+{link_https}\"\n" ) if( $+{link_https} );
            print( "Found file url \"$+{link_file}\"\n" ) if( $+{link_file} );
            print( "Found ftp url \"$+{link_ftp}\"\n" ) if( $+{link_ftp} );
            print( "Found e-mail address \"$+{link_mailto}\"\n" ) if( $+{link_mailto} );
            print( "Found Found phone number \"$+{link_tel}\"\n" ) if( $+{link_tel} );
            my $url = URI->new( $+{link_https} );
        }

As a general rule, Markdown rule requires that the text being parsed be
de-tabbed, i.e. with its tabs converted into 4 spaces. Those regular
expressions reflect this principle.

STANDARD MARKDOWN
=================

`$RE{Markdown}`
---------------

This returns a pattern that recognises any of the supported vanilla
Markdown formatting. If you pass the `-extended` parameter, some will be
added and some of those regular expressions will be replaced by their
extended ones, such as *ExtAbbr*, *ExtCodeBlock*, *ExtLink*,
*ExtAttributes*

Blockquote
----------

        $RE{Markdown}{Blockquote}

For example:

        > foo
        >
        > > bar
        >
        > foo

You can see example of this regular expression along with test units
here: <https://regex101.com/r/TdKq0K/1/tests>

The capture names are:

bquote\_all

:   The entire capture of the blockquote.

bquote\_other

:   The inner content of the blockquote.

You can see also
[Markdown::Parser::Blockquote](https://metacpan.org/pod/Markdown::Parser::Blockquote){.perl-module}

Bold
----

        $RE{Markdown}{Bold}

For example:

        **This is a text in bold.**

        __And so is this.__

You can see example of this regular expression along with test units
here: <https://regex101.com/r/Jp2Kos/3>

The capture names are:

bold\_all

:   The entire capture of the text in bold including the enclosing
    marker, which can be either `**` or `__`

bold\_text

:   The text within the markers.

bold\_type

:   The marker type used to highlight the text. This can be either `**`
    or `__`

You can see also
[Markdown::Parser::Bold](https://metacpan.org/pod/Markdown::Parser::Bold){.perl-module}

Code Block
----------

        $RE{Markdown}{CodeBlock}

For example:

        ```
        Some text

            Indented code block sample code
        ```

You can see example of this regular expression along with test units
here: <https://regex101.com/r/M6W99K/7>

The capture names are:

code\_all

:   The entire capture of the code block, including the enclosing
    markers, such as ```` ``` ````

code\_content

:   The content of the code enclosed within the 2 markers.

code\_start

:   The enclosing marker used to mark the code. Typically ```` ``` ````.

code\_trailing\_new\_line

:   The possible trailing new lines. This is used to detect if any were
    captured in order to put them back in the parsed text for the next
    markdown, since the last new lines of a markdown are alos the first
    new lines of the next ones and new lines are used to delimit
    markdowns.

You can see also
[Markdown::Parser::Code](https://metacpan.org/pod/Markdown::Parser::Code){.perl-module}

Code Line
---------

        $RE{Markdown}{CodeLine}

For example:

            the lines in this block  
            all contain trailing spaces  

You can see example of this regular expression along with test units
here: <https://regex101.com/r/toEboU/3>

The capture names are:

code\_after

:   This contains the data that follows the code block.

code\_all

:   The entire capture of the code lines.

code\_content

:   The content of the code.

code\_prefix

:   This contains the leading spaces used to mark the code as code.

You can see also
[Markdown::Parser::Code](https://metacpan.org/pod/Markdown::Parser::Code){.perl-module}

Code Span
---------

        $RE{Markdown}{CodeSpan}

For example:

        This is some `inline code`

You can see example of this regular expression along with test units
here: <https://regex101.com/r/C2Vl9M/1/tests>

The capture names are:

code\_all

:   The entire capture of the code lines.

code\_start

:   Contains the marker that delimit the inline code. The delimiter is
    `` ` ``

code\_content

:   The content of the code.

You can see also
[Markdown::Parser::Code](https://metacpan.org/pod/Markdown::Parser::Code){.perl-module}

Emphasis
--------

        $RE{Markdown}{Em}

For example:

        This routine parameter is _test_

You can see example of this regular expression along with test units
here: <https://regex101.com/r/eDb6RN/5>

You can see also
[Markdown::Parser::Emphasis](https://metacpan.org/pod/Markdown::Parser::Emphasis){.perl-module}

Header
------

        $RE{Markdown}{Header}

For example:

        ### This is a H3 Header

        ### And so is this one ###

You can see example of this regular expression along with test units
here: <https://regex101.com/r/9uQwBk/4>

The capture names are:

header\_all

:   The entire capture of the code lines.

header\_content

:   The text that is enclosed in the header marker.

header\_level

:   This contains all the dashes that precedes the text. The number of
    dash indicates the level of the header. Thus, you could do something
    like this:

            length( $+{header_level} );

You can see also
[Markdown::Parser::Header](https://metacpan.org/pod/Markdown::Parser::Header){.perl-module}

Header Line
-----------

        $RE{Markdown}{HeaderLine}

For example:

        This is an H1 header
        ====================

        And this is a H2
        -----------

You can see example of this regular expression along with test units
here: <https://regex101.com/r/sQLEqz/3>

The capture names are:

header\_all

:   The entire capture of the code lines.

header\_content

:   The text that is enclosed in the header marker.

header\_type

:   This contains the marker line used to mark the line above as header.

    A line using `=` is a header of level 1, while a line using `-` is a
    header of level 2.

You can see also
[Markdown::Parser::Header](https://metacpan.org/pod/Markdown::Parser::Header){.perl-module}

HTML
----

        $RE{Markdown}{Html}

For example:

        <div>
            foo
        </div>

You can see example of this regular expression along with test units
here: <https://regex101.com/r/SH8ki3/4>

The capture names are:

html\_all

:   The entire capture of the html block.

html\_comment

:   If this html block is a comment, this will contain the data within
    the comment.

html\_content

:   The inner content between the opning and closing tag. This could be
    more html block or some text.

    This capture will not be available obviously for html tags that are
    \"empty\" by nature, such as `<hr /`\>

tag\_attributes

:   The attributes of the opening tag, if any. For example:

            <div title="Start" class="center large" id="extra_stuff">
                <span title="Brand name">MyWorld</span>
            </div>

    Here, the attributes will be:

            title="Start" class="center large" id="extra_stuff"

tag\_close

:   The closing tag, including enclosing brackets.

tag\_name

:   This contains the name of the first html tag encountered, i.e. the
    one that starts the html block. For example:

            <div>
                <span title="Brand name">MyWorld</span>
            </div>

    Here the tag name will be `div`

You can see also
[Markdown::Parser::HTML](https://metacpan.org/pod/Markdown::Parser::HTML){.perl-module}

Image
-----

        $RE{Markdown}{Image}

For example:

        ![Alt text](/path/to/img.jpg)

or

        ![Alt text](/path/to/img.jpg "Optional title")

or, with reference:

        ![alt text][foo]

You can see example of this regular expression along with test units
here: <https://regex101.com/r/z0yH2F/10>

The capture names are:

img\_all

:   The entire capture of the markdown, such as:

            ![Alt text](/path/to/img.jpg)

img\_alt

:   The alternative tet to be displayed for this image. This is
    mandatory as per markdown, so it is guaranteed to be available.

img\_id

:   If the image, is an image reference, this will contain the reference
    id. When an image id is provided, there is no url and no title,
    because the image reference provides those information.

img\_title

:   This is the title of the image, which may not exist, since it is
    optional in markdown. The title is surrounded by single or double
    quote that are captured in *img\_title\_container*

img\_url

:   This is the url of the image.

You can see also
[Markdown::Parser::Image](https://metacpan.org/pod/Markdown::Parser::Image){.perl-module}

Line
----

        $RE{Markdown}{Line}

For example:

        ---

or

        - - -

or

        ***

or

        * * *

or

        ___

or

        _ _ _


        $text =~ s{$RE{Markdown}{Line}}
        {
            # processing
        }gexm;

Note that this regular expression uses multiline switch and not the
single line `/s` switch since a markdown horizontal line does not span
multiple lines.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/Vlew4X/2>

The capture names are:

line\_all

:   The entire capture of the horizontal line.

line\_type

:   This contains the marker used to set the line. Valid markers are
    `*`, `-`, or `_`

See also [Markdown original author reference for horizontal
line](https://daringfireball.net/projects/markdown/syntax#hr){.perl-module}

You can see also
[Markdown::Parser::Line](https://metacpan.org/pod/Markdown::Parser::Line){.perl-module}

Line Break
----------

        $RE{Markdown}{LineBreak}

For example:

        Mignonne, allons voir si la rose  
        Qui ce matin avait déclose  
        Sa robe de pourpre au soleil,  
        A point perdu cette vesprée,  
        Les plis de sa robe pourprée,  
        Et son teint au vôtre pareil.

To ensure arbitrary line breaks, each line ends with 2 spaces and 1 line
break. This should become:

        Mignonne, allons voir si la rose<br />
        Qui ce matin avait déclose<br />
        Sa robe de pourpre au soleil,<br />
        A point perdu cette vesprée,<br />
        Les plis de sa robe pourprée,<br />
        Et son teint au vôtre pareil.

P.S.: If you\'re wondering, this is an extract from
[Ronsard](https://en.wikipedia.org/wiki/Pierre_de_Ronsard){.perl-module}.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/6VG46H/1/>

There is only one capture name: `br_all`. This is basically used like
this:

        if( $text =~ /\G$RE{Markdown}{LineBreak}/ )
        {
            print( "Found a line break\n" );
        }

Or

        $text =~ s/$RE{Markdown}{LineBreak}/<br \/>\n/gs;

You can see also
[Markdown::Parser::NewLine](https://metacpan.org/pod/Markdown::Parser::NewLine){.perl-module}

The capture name is:

br\_all

:   The entire capture of the line break.

Link
----

        $RE{Markdown}{Link}

For example:

        [Inline link](https://www.example.com "title")

or

        [Inline link](/some/path "title")

or, without title

        [Inline link](/some/path)

or with a reference id:

        [reference link][refid]

        [refid]: /path/to/something (Title)

or, using the link text as the id for the reference:

        [My Example][]

        [My Example]: https://example.com (Great Example)

You can see example of this regular expression along with test units
here: <https://regex101.com/r/sGsOIv/10>

The capture names are:

link\_all

:   The entire capture of the link.

link\_title\_container

:   If there is a link title, this contains the single or double quote
    enclosing it.

link\_id

:   The link reference id. For example here `1` is the id.

            [Reference link 1 with parens][1]

link\_name

:   The link text

link\_title

:   The link title, if any.

link\_url

:   The link url, if any

You can see also
[Markdown::Parser::Link](https://metacpan.org/pod/Markdown::Parser::Link){.perl-module}
and
[Regexp::Common::URI](https://metacpan.org/pod/Regexp::Common::URI){.perl-module}

Link Auto
---------

        $RE{Markdown}{LinkAuto}

Supports, http, https, ftp, newsgroup, local file, e-mail address or
phone numbers

For example:

        <https://www.example.com>

would become:

        <a href="https://www.example.com">https://www.example.com</a>

An e-mail such as:

        <!#$%&'*+-/=?^_`.{|}~@example.com>

would become:

        <a href="mailto:!#$%&'*+-/=?^_`.{|}~@example.com>!#$%&'*+-/=?^_`.{|}~@example.com</a>

Other possible and valid e-mail addresses:

        <"abc@def"@example.com>

        <jsmith@[192.0.2.1]>

A file link:

        <file:///Volume/User/john/Document/form.rtf>

A newsgroup link:

        <news:alt.fr.perl>

A ftp uri:

        <ftp://ftp.example.com/plop/>

Phone numbers:

        <+81-90-1234-5678>

        <tel:+81-90-1234-5678>

You can see example of this regular expression along with test units
here: <https://regex101.com/r/bAUu1E/3/tests>

The capture names are:

link\_all

:   The entire capture of the link.

link\_file

:   A local file url, such as:
    `ile:///Volume/User/john/Document/form.rtf`

link\_ftp

:   Contains an ftp url

link\_http

:   Contains an http url

link\_https

:   Contains an https url

link\_mailto

:   An e-mail address with or without the `mailto:` prefix.

link\_news

:   A newsgroup link url, such as `news:alt.fr.perl`

link\_tel

:   Contains a telephone url according to the [rfc
    3966](https://tools.ietf.org/search/rfc3966){.perl-module}

link\_url

:   Contains the link uri, which contains one of *link\_file*,
    *link\_ftp*, *link\_http*, *link\_https*, *link\_mailto*,
    *link\_news* or *link\_tel*

You can see also
[Markdown::Parser::Link](https://metacpan.org/pod/Markdown::Parser::Link){.perl-module}

Link Definition
---------------

        $RE{Markdown}{LinkDefinition}

For example:

        [1]: /url/  "Title"

        [refid]: /path/to/something (Title)

Extra care has been implemented to avoid link definition from being
confused with footnotes:

        [^block]:
                Paragraph.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/edg2F7/3>

The capture names are:

link\_all

:   The entire capture of the link.

link\_id

:   The link id

link\_title

:   The link title

link\_title\_container

:   The character used to enclose the title, if any. This is either `"`
    or `'`

link\_url

:   The link url

You can see also
[Markdown::Parser::LinkDefinition](https://metacpan.org/pod/Markdown::Parser::LinkDefinition){.perl-module}

Link Reference
--------------

        $RE{Markdown}{LinkRef}

Example:

        Foo [bar] [1].

        Foo [bar][1].

        Foo [bar]
        [1].

        [Foo][]

        [1]: /url/  "Title"
        [Foo]: https://www.example.com

You can see example of this regular expression along with test units
here: <https://regex101.com/r/QmyfnH/1/tests>

The capture names are:

link\_all

:   The entire capture of the link.

link\_id

:   The link reference id. For example here `1` is the id.

            [Reference link 1 with parens][1]

link\_name

:   The link text

See also the [reference on links by Markdown original
author](https://daringfireball.net/projects/markdown/syntax#link){.perl-module}

You can see also
[Markdown::Parser::Link](https://metacpan.org/pod/Markdown::Parser::Link){.perl-module}

List
----

        $RE{Markdown}{List}

For example, an unordered list:

        *   asterisk 1

        *   asterisk 2

        *   asterisk 3

or, an ordered list:

        1. One item

        1. Second item

        1. Third item

You can see example of this regular expression along with test units
here: <https://regex101.com/r/RfhRVg/5>

The capture names are:

list\_after

:   The data that follows the list.

list\_all

:   The entire capture of the markdown.

list\_content

:   The content of the list.

list\_prefix

:   Contains the first list marker possible preceded by some space. A
    list marker is `*`, or `+`, or `-` or a digit with a dot such as
    `1.`

list\_type\_any

:   Contains the list marker such as `*`, or `+`, or `-` or a digit with
    a dot such as `1.`

    This is included in the *list\_prefix* named capture.

list\_type\_any2

:   Sale as *list\_type\_any*, but matches the following item if any. If
    there is no matching item, then an end of string is expected.

list\_type\_ordered

:   Contains a digit followed by a dot if the list is an ordered one.

list\_type\_ordered2

:   Same as *list\_type\_ordered*, but for the following list item, if
    any.

list\_type\_unordered\_minus

:   Contains the marker of a minus `-` value if the list marker uses a
    minus sign.

list\_type\_unordered\_minus2

:   Same as *list\_type\_unordered\_minus*, but for the following list
    item, if any.

list\_type\_unordered\_plus

:   Contains the marker of a plus `+` value if the list marker uses a
    plus sign.

list\_type\_unordered\_plus2

:   Same as *list\_type\_unordered\_plus*, but for the following list
    item, if any.

list\_type\_unordered\_star

:   Contains the marker of a star `*` value if the list marker uses a
    star.

list\_type\_unordered\_star2

:   Same as *list\_type\_unordered\_star*, but for the following list
    item, if any.

You can see also
[Markdown::Parser::List](https://metacpan.org/pod/Markdown::Parser::List){.perl-module}

List First Level
----------------

        $RE{Markdown}{ListFirstLevel}

This regular expression is used for top level list, as opposed to the
nth level pattern that is used for sub list. Both will match lists
within list, but the processing under markdown is different whether the
list is a top level one or an sub one.

You can see also
[Markdown::Parser::List](https://metacpan.org/pod/Markdown::Parser::List){.perl-module}

List Nth Level
--------------

        $RE{Markdown}{ListNthLevel}

Regular expression to process list within list.

You can see also
[Markdown::Parser::List](https://metacpan.org/pod/Markdown::Parser::List){.perl-module}

List Item
---------

        $RE{Markdown}{ListItem}

You can see example of this regular expression along with test units
here: <https://regex101.com/r/bulBCP/1/tests>

The capture names are:

li\_all

:   The entire capture of the markdown.

li\_content

:   Contains the data contained in this list item

li\_lead\_line

:   The optional leding line breaks

li\_lead\_space

:   The optional leading spaces or tabs. This is used to check that
    following items belong to the same list level

list\_type\_any

:   This contains the list type marker, which can be `*`, `+`, `-` or a
    digit with a dot such as `1.`

list\_type\_any2

:   Sale as *list\_type\_any*, but matches the following item if any. If
    there is no matching item, then an end of string is expected.

list\_type\_ordered

:   This contains a true value if the list marker contains a digit
    followed by a dot, such as `1.`

list\_type\_ordered2

:   Same as *list\_type\_ordered*, but for the following list item, if
    any.

list\_type\_unordered\_minus

:   This contains a true value if the list marker is a minus sign, i.e.
    `-`

list\_type\_unordered\_minus2

:   Same as *list\_type\_unordered\_minus*, but for the following list
    item, if any.

list\_type\_unordered\_plus

:   This contains a true value if the list marker is a plus sign, i.e.
    `+`

list\_type\_unordered\_plus2

:   Same as *list\_type\_unordered\_plus*, but for the following list
    item, if any.

list\_type\_unordered\_star

:   This contains a true value if the list marker is a star, i.e. `*`

list\_type\_unordered\_star2

:   Same as *list\_type\_unordered\_star*, but for the following list
    item, if any.

You can see also
[Markdown::Parser::ListItem](https://metacpan.org/pod/Markdown::Parser::ListItem){.perl-module}

Paragraph
---------

        $RE{Markdown}{Paragraph}

For example:

        The quick brown fox
        jumps over the lazy dog

        Lorem Ipsum

        > Why am I matching?
        1. Nonononono!
        * Aaaagh!
        # Stahhhp!

This regular expression would capture the whole block up until \"Lorem
Ipsum\", but will be careful not to catch other markdown element after
that. Thus, anything after \"Lorem Ipsum\" would not be caught because
this is a blockquote.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/0B3gR4/5>

The capture names are:

para\_all

:   The entire capture of the paragraph.

para\_content

:   Content of the paragraph

para\_prefix

:   Any leading space (up to 3)

You can see also
[Markdown::Parser::Paragraph](https://metacpan.org/pod/Markdown::Parser::Paragraph){.perl-module}

EXTENDED MARKDOWN
=================

Abbreviation
------------

        $RE{Markdown}{ExtAbbr}

For example:

        Some discussion about HTML, SGML and HTML4.

        *[HTML4]: Hyper Text Markup Language version 4
        *[HTML]: Hyper Text Markup Language
        *[SGML]: Standard Generalized Markup Language

You can see example of this regular expression along with test units
here: <https://regex101.com/r/ztM2Pw/2/tests>

The capture names are:

abbr\_all

:   The entire capture of the abbreviation.

abbr\_name

:   Contains the abbreviation. For example `HTML`

abbr\_value

:   Contains the abbreviation value. For example
    `Hyper Text Markup Language`

You can see also
[Markdown::Parser::Abbr](https://metacpan.org/pod/Markdown::Parser::Abbr){.perl-module}

Attributes
----------

        $RE{Markdown}{ExtAttributes}

For example, an header with attribute `.cl.class#id7`

        ### Header  {.cl.class#id7 }

Checkbox
--------

        $RE{Markdown}{ExtCheckbox}

[Introduced by
Github](https://github.github.com/gfm/#task-list-items-extension-){.perl-module},
this markdown extension captures checkboxes whether checked or
unchecked.

For example:

        - [ ] foo
        - [x] bar

would become:

<div>    <ul>
        <li><input disabled="" type="checkbox"> foo</li>
        <li><input checked="" disabled="" type="checkbox"> bar</li>
    </ul>
</div>

Those checkboxes can be placed anywhere, not just in a list.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/ezMwsv/2/>

The capture names are:

check\_all

:   The entire capture of the checkbox.

check\_content

:   The value inside the square brackets, which is either a blank, or
    the letter `X` in either lower or upper case.

You can see also
[Markdown::Parser::Checkbox](https://metacpan.org/pod/Markdown::Parser::Checkbox){.perl-module}

Code Block
----------

        $RE{Markdown}{ExtCodeBlock}

This is the same as conventional blocks with backticks, except the
extended version uses tilde characters.

For example:

        ~~~
        <div>
        ~~~

You can see example of this regular expression along with test units
here: <https://regex101.com/r/Y9lPAz/9>

The capture names are:

code\_all

:   The entire capture of the code.

code\_attr

:   The class and/or id attributes for this code. This is something
    like:

            `````` .html {#codeid}
            </div>
            ``````

    Here, *code\_class* would contain `#codeid`

code\_class

:   The class of code. For example:

            ``````html {#codeid}
            </div>
            ``````

    Here the code class would be `html`

code\_content

:   The code data enclosed within the code markers (backticks or tilde)

code\_start

:   Contains the code delimiter, which is either a series of backticks
    `` ` `` or tilde `~`

You can see also
[Markdown::Parser::Code](https://metacpan.org/pod/Markdown::Parser::Code){.perl-module}

Footnotes
---------

        $RE{Markdown}{ExtFootnote}

This looks like this:

        [^1]: Content for fifth footnote.
        [^2]: Content for sixth footnote spaning on 
            three lines, with some span-level markup like
            _emphasis_, a [link][].

A reference to those footnotes could be:

        Some paragraph with a footnote[^1], and another[^2].

The *footnote\_id* reference can be anything as long as it is unique.

You can see also
[Markdown::Parser::Footnote](https://metacpan.org/pod/Markdown::Parser::Footnote){.perl-module}

### Inline Footnotes

For consistency with links, footnotes can be added inline, like this:

        I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.

Inline notes will work even without the identifier. For example:

        I met Jack [^](Co-founder of Angels, Inc) at the meet-up.

However, in compliance with pandoc footnotes style, inline footnotes can
also be added like this:

        Here is an inline note.^[Inlines notes are easier to write, since
        you don't have to pick an identifier and move down to type the
        note.]

You can see example of this regular expression along with test units
here: <https://regex101.com/r/WuB1FR/2/>

The capture names are:

footnote\_all

:   The entire capture of the footnote.

footnote\_id

:   The footnote id which must be unique and will be referenced in text.

footnote\_text

:   The footnote text

You can see also
[Markdown::Parser::Footnote](https://metacpan.org/pod/Markdown::Parser::Footnote){.perl-module}

Footnote Reference
------------------

        $RE{Markdown}{ExtFootnoteReference}

This regular expression matches 3 types of footnote references:

1 Conventional

:   An id is specified referring to a footnote that provide details.

            Here's a simple footnote,[^1]

            [^1]: This is the first footnote.

2 Inline

:       I met Jack [^jack](Co-founder of Angels, Inc) at the meet-up.

    Inline footnotes without any id, i.e. auto-generated id. For
    example:

            I met Jack [^](Co-founder of Angels, Inc) at the meet-up.

3 Inline auto-generated, pandoc style

:       Here is an inline note.^[Inlines notes are easier to write, since
            you don't have to pick an identifier and move down to type the
            note.]

    See [pandoc
    manual](https://pandoc.org/MANUAL.html#footnotes){.perl-module} for
    more information

You can see example of this regular expression along with test units
here: <https://regex101.com/r/3eO7rJ/1/>

The capture names are:

footnote\_all

:   The entire capture of the footnote reference.

footnote\_id

:   The footnote id which must be unique and must match a footnote
    declared anywhere in the document and not necessarily before. For
    example:

            Here's a simple footnote,[^1]

            [^1]: This is the first footnote.

    **1** here is the id fo the footnote.

    If it is not provided, then an id will be auto-generated, but a
    footnote text is then required.

footnote\_text

:   The footnote text is optional if an id is provided. If an id is not
    provided, the fotnote text is guaranteed to have some value.

You can see also
[Markdown::Parser::FootnoteReference](https://metacpan.org/pod/Markdown::Parser::FootnoteReference){.perl-module}

Header
------

        $RE{Markdown}{ExtHeader}

This extends regular header with attributes.

For example:

        ### Header  {.cl.class#id7 }

You can see example of this regular expression along with test units
here: <https://regex101.com/r/GyzbR2/3>

The capture names are:

header\_all

:   The entire capture of the code lines.

header\_attr

:   Contains the extended attribute set. For example:

            {.class#id}

header\_content

:   The text that is enclosed in the header marker.

header\_level

:   This contains all the dashes that precedes the text. The number of
    dash indicates the level of the header. Thus, you could do something
    like this:

            length( $+{header_level} );

You can see also
[Markdown::Parser::Header](https://metacpan.org/pod/Markdown::Parser::Header){.perl-module}

Header Line
-----------

        $RE{Markdown}{ExtHeaderLine}

Same as header line, but with attributes.

For example:

        Header  {#id5.cl.class}
        ======

You can see example of this regular expression along with test units
here: <https://regex101.com/r/berfAR/3>

The capture names are:

header\_all

:   The entire capture of the code lines.

header\_attr

:   Contains the extended attribute set. For example:

            {.class#id}

header\_content

:   The text that is enclosed in the header marker.

header\_type

:   This contains the marker line used to mark the line above as header.

    A line using `=` is a header of level 1, while a line using `-` is a
    header of level 2.

You can see also
[Markdown::Parser::Header](https://metacpan.org/pod/Markdown::Parser::Header){.perl-module}

HTML Markdown
-------------

        $RE{Markdown}{ExtHtmlMarkdown}

This is markdown embedded in html using the html tag attribute
`markdown="1"`

For example:

        <div>
            <div markdown="1">

            This is a code block however:

                </div>

            Funny isn't it? Here is a code span: `</div>`.

            </div>
        </div>

This would capture the following as markdown data:

        This is a code block however:

            </div>

        Funny isn't it? Here is a code span: `</div>`.

And since `</div`\> is indented, it would be treated as a line of code
rather than html. The second `</div`\> snce it is surrounded by
backticks.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/M6KCjp/3>

The capture names are:

content

:   Contains the markdown data enclosed.

div\_close

:   Contains the closing tag.

div\_open

:   Contains the entire opening tag.

    For example, in:

            <table>
            <tr><td markdown="1">test _emphasis_ (span)</td></tr>
            </table>

    this would match:

            <td markdown="1">

leading\_space

:   Contains any leading space before the start of the tag containing
    the markdown data.

html\_markdown\_all

:   Contains the entire block of data captured

mark\_pat1

:   This contains the data captured in pattern type 1, which matches
    on-line html and multiline ones.

    For example:

            <abbr markdown="1" title="`second backtick!">SB</abbr>

    or

            <div>
                <div markdown="1">

                This is a code block however:

                    </div>

                Funny isn't it? Here is a code span: `</div>`.

                </div>
            </div>

mark\_pat2

:   This contains the data captured in pattern type 2, which matches
    html markdown

    For example:

            <table>
            <tr><td markdown="1">test _emphasis_ (span)</td></tr>
            </table>

quote

:   Contains the type of quote used in:

            <table>
            <tr><td markdown="1">test _emphasis_ (span)</td></tr>
            </table>

    This would be `"`

tag\_name

:   This contains the tag name that contains the markdown data.

Image
-----

        $RE{Markdown}{ExtImage}

Same as regular image, but with attributes.

For example:

        This is an ![inline image](/img "title"){.class #inline-img}.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/xetHV1/4>

The capture names are:

img\_all

:   The entire capture of the markdown, such as:

            ![Alt text](/path/to/img.jpg)

img\_alt

:   The alternative tet to be displayed for this image. This is
    mandatory as per markdown, so it is guaranteed to be available.

img\_attr

:   Contains the extended attribute set. For example:

            {.class#id}

img\_id

:   If the image, is an image reference, this will contain the reference
    id. When an image id is provided, there is no url and no title,
    because the image reference provides those information.

img\_title

:   This is the title of the image, which may not exist, since it is
    optional in markdown. The title is surrounded by single or double
    quote that are captured in *img\_title\_container*

img\_url

:   This is the url of the image.

You can see also
[Markdown::Parser::Image](https://metacpan.org/pod/Markdown::Parser::Image){.perl-module}

Insertion
---------

        $RE{Markdown}{ExtInsertion}

This is an extension to the original Markdown.

For example:

        Tickets for the event are ~~€5~~ ++€10++

Which would become:

        Tickets for the event are <del>€5</del> <ins>€10</ins>

With `€5` being stroken through and `€10` being highlighted as being
added. The actual representation depends on the web browser of course.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/IZw4YU/1/>

The capture names are:

ins\_all

:   The entire capture of the insertion.

ins\_content

:   The content of the text being inserted. In the example above, this
    would be `€10`

You can see also
[Markdown::Parser::Insertion](https://metacpan.org/pod/Markdown::Parser::Insertion){.perl-module}
and [Mozilla explanation of the
tag](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ins){.perl-module}

Katex Math Expression
---------------------

        $RE{Markdown}{ExtKatex}

This is used to capture [Katex math
expression](https://katex.org/docs/autorender.html){.perl-module}.

It supports the following delimiters:

1.  open delimiter: \$\$

    close delimiter: \$\$

2.  open delimiter: \$\$

    close delimiter: \$\$

3.  open delimiter: \\\[

    close delimiter: \\\]

4.  open delimiter: \\(

    close delimiter: \\)

For example:

        $$
        \Gamma(z) = \int_0^\infty t^{z-1}e^{-t}dt\,.
        $$

or

        Other node \[ displaymath \frac{1}{2} \]

It does not matter whether the expression is in its own block (first
example) or inline (second example)

You can see a demo [here](https://katex.org/#demo){.perl-module}.

By default, it supports all 4 delimiters mentioned above, but if you
have some expression in your doc that may conflict, such as:

        LD_PRELOAD=libusb-driver.so $0.bin $*

Then, you can chose which delimiter to activate by calling the regular
expression like this:

        $RE{Markdown}{ExtKatex}{-delimiter => '$$,$$,\[,\],\(,\)'}

As you can see you can pass the argument `-delimiter` and providing a
comma delimited series of opening en closing delimiters. In the above
example:

        $$,$$ # open, close
        \[,\] # open, close
        \(,\) # open, close

I would gladly allow for an array reference to be provided, but the
[Regexp::Common](https://metacpan.org/pod/Regexp::Common){.perl-module}
api does not make that possible.

Since [Katex]{.perl-module} only recognises those delimiters, you can
only choose among those.

Also, in the above example, I used single quotes because of enclosed
dolar sign. Of course, if you prefer to use double quote, then you need
to escape the dollar signs.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/43OuNT/3/>

The capture names are:

katex\_all

:   The entire capture of the math expression, including its delimiters,
    typically `$$`.

katex\_close

:   Contains the closing delimiter, such as `$$`, `$`, `\]` or `\)`

katex\_content

:   The content of the math expression, i.e. without the surrounding
    delimiters

katex\_open

:   Contains the opening delimiter, such as `$$`, `$`, `\[` or `\(`

Link
----

        $RE{Markdown}{ExtLink}

Same as regular links, but with attributes.

For example:

        This is an [inline link](/url "title"){.class #inline-link}.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/7mLssJ/7>

The capture names are:

link\_all

:   The entire capture of the link.

link\_attr

:   Contains the extended attribute set. For example:

            {.class#id}

    *link\_all* would contain `.class#id`

link\_title\_container

:   If there is a link title, this contains the single or double quote
    enclosing it.

link\_id

:   The link reference id. For example here `1` is the id.

            [Reference link 1 with parens][1]

link\_name

:   The link text

link\_title

:   The link title, if any.

link\_url

:   The link url, if any

You can see also
[Markdown::Parser::Link](https://metacpan.org/pod/Markdown::Parser::Link){.perl-module}

Link Definition
---------------

        $RE{Markdown}{ExtLinkDefinition}

Same as regular link definition, but with attributes

For example:

        [refid]: /path/to/something (Title) { .class #ref data-key=val }

You can see example of this regular expression along with test units
here: <https://regex101.com/r/hVfXCe/3>

The capture names are:

link\_all

:   The entire capture of the link.

link\_attr

:   Contains the extended attribute set. For example:

            {.class#id}

link\_id

:   The link id

link\_title

:   The link title

link\_title\_container

:   The character used to enclose the title, if any. This is either `"`
    or `'`

link\_url

:   The link url

You can see also
[Markdown::Parser::LinkDefinition](https://metacpan.org/pod/Markdown::Parser::LinkDefinition){.perl-module}

Strikethrough
-------------

        $RE{Markdown}{ExtStrikeThrough}

This is an extension brought by [Git Flavoured
Markdown](https://github.github.com/gfm/#strikethrough-extension-){.perl-module}.

For example:

        ~~Hi~~ Hello, world!

You can see example of this regular expression along with test units
here: <https://regex101.com/r/4Z3h4F/1/>

The capture names are:

strike\_all

:   The entire capture of the strikethrough.

strike\_content

:   The content of the text being stroken through. In the example above,
    this would be `Hi`

You can see also
[Markdown::Parser::StrikeThrough](https://metacpan.org/pod/Markdown::Parser::StrikeThrough){.perl-module}
and [Git Flavoured
Markdown](https://github.github.com/gfm/#strikethrough-extension-){.perl-module}

Subscript
---------

        $RE{Markdown}{ExtSubscript}

For example:

        log~10~100 is 2.

would set `10` as a subscript by the software using this regular
expression.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/gF6wVe/2>

The capture names are:

sub\_all

:   The entire capture of the subscript.

sub\_text

:   Contains the text of the subscript

See also:
[Markdown::Parser::Subscript](https://metacpan.org/pod/Markdown::Parser::Subscript){.perl-module},
[Pandoc
manual](https://pandoc.org/MANUAL.html#superscripts-and-subscripts){.perl-module}

Superscript
-----------

        $RE{Markdown}{ExtSuperscript}

For example:

        2^10^ is 1024.

would set `10` in superscript by the software using this regular
expression.

You can see example of this regular expression along with test units
here: <https://regex101.com/r/yAcNcX/1>

The capture names are:

sup\_all

:   The entire capture of the superscript.

sup\_text

:   Contains the text of the superscript

See also:
[Markdown::Parser::Superscript](https://metacpan.org/pod/Markdown::Parser::Superscript){.perl-module},
[Pandoc
manual](https://pandoc.org/MANUAL.html#superscripts-and-subscripts){.perl-module},
<https://facelessuser.github.io/pymdown-extensions/extensions/caret/>

Table
-----

        $RE{Markdown}{ExtTable}

This is an extensive regular expression to capture all kinds of tables,
including with caption on top or bottom.

For example:

You can see example of this regular expression along with test units
here: <https://regex101.com/r/01XCqB/12>

The capture names are:

table

:   The entire capture of the table.

table\_after

:   Contains the data that follows the table.

table\_caption

:   Contains the table caption if set. A table caption, in markdown can
    be position before or after the table.

    If you use [\"%-\" in
    perlvar](https://metacpan.org/pod/perlvar#%-){.perl-module} then
    `$-{table_caption}-`\[0\]\> will give you the table caption if it
    was set at the top of the table, and `$-{table_caption}-`\[1\]\>
    will give you the table caption if it was set at the bottom of the
    table.

table\_headers

:   Contains the entire header rows

table\_header1

:   Contains the first row of the header. This is contained within the
    capture name *table\_headers*

table\_header2

:   Contains the second row, if any, of the header. This is contained
    within the capture name *table\_headers*

    A second is optional and there can be only two rows in the headers
    as per standards.

table\_header\_sep

:   Contain the separator line between the table header and the table
    body.

table\_rows

:   Contains the table body rows

Table format is taken from [David E. Wheeler
RFC](https://justatheory.com/2009/02/markdown-table-rfc/){.perl-module}

You can see also
[Markdown::Parser::Table](https://metacpan.org/pod/Markdown::Parser::Table){.perl-module}

SEE ALSO
========

[Regexp::Common](https://metacpan.org/pod/Regexp::Common){.perl-module}
for a general description of how to use this interface.

[Markdown::Parser](https://metacpan.org/pod/Markdown::Parser){.perl-module}
for a Markdown parser using this module.

CHANGES & CONTRIBUTIONS
=======================

Feel free to reach out to the author for possible corrections,
improvements, or suggestions.

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55fae57be300)"}\>

CREDITS
=======

Credits to [Michel
Fortin](https://michelf.ca/projects/php-markdown){.perl-module} and
[John
Gruber](http://six.pairlist.net/pipermail/markdown-discuss/2006-June/000079.html){.perl-module}
for their test units.

Credits to Firas Dib for his online [regular expression test
tool](https://regex101.com){.perl-module}.

COPYRIGHT & LICENSE
===================

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
