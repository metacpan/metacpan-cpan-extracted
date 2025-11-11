package Podlite;

our $VERSION = '1.00';
use warnings;
use strict;
use re 'eval';

use Filter::Simple;

my $IDENT            = qr{ (?> [^\W\d] \w* )              }xms;
my $QUAL_IDENT       = qr{ $IDENT (?: :: $IDENT)*         }xms;
my $TO_EOL           = qr{ (?> [^\n]* ) (?:\Z|\n)         }xms;
my $HWS              = qr{ (?> [^\S\n]+ )                 }xms;
my $OHWS             = qr{ (?> [^\S\n]* )                 }xms;
my $BLANK_LINE       = qr{ ^ $OHWS $ | (?= ^ = | \s* \z)  }xms;
my $DIRECTIVE        = qr{ config }xms;
my $OPT_EXTRA_CONFIG = qr{ (?> (?: ^ = $HWS $TO_EOL)* )   }xms;


# Recursive matcher for =DATA sections...

my $DATA_PAT = qr{
    ^ = 
    (?:
        begin $HWS data $TO_EOL
        $OPT_EXTRA_CONFIG
            (.*?)
        ^ =end $HWS data
    |
        for $HWS data $TO_EOL
        $OPT_EXTRA_CONFIG
            (.*?)
        $BLANK_LINE
    |
        data \s
            (.*?)
        $BLANK_LINE
    )
}xms;


# Recursive matcher for all other Podlite sections...

use vars '$type';
my $PODLITE_PAT; $PODLITE_PAT = qr{
    ^ =
    (?:
        begin $HWS ($IDENT) (?{ local $type = $^N}) $TO_EOL
        $OPT_EXTRA_CONFIG
            (?: ^ (??{$PODLITE_PAT}) | . )*?
        ^ =end $HWS (??{$type}) $TO_EOL
    |
        for $HWS $TO_EOL
        $OPT_EXTRA_CONFIG
            .*?
        $BLANK_LINE
    |
        $DIRECTIVE $HWS $TO_EOL
        $OPT_EXTRA_CONFIG
    |
        (?! end) $IDENT $TO_EOL
            .*?
        $BLANK_LINE
    )
}xms;

FILTER {
    my @DATA;

    # Extract DATA sections, deleting them but preserving line numbering...
    s{ ($DATA_PAT) }{
        my ($data_block, $contents) = ($1,$+);

        # Special newline handling required under Windows...
        if ($^O =~ /MSWin/) {
            $contents =~ s{ \r\n }{\n}gxms;
        }

        # Save the data...
        push @DATA, $contents;

        # Delete it from the source code, but leave the newlines...
        $data_block =~ tr[\n\0-\377][\n]d;

        $data_block;
    }gxmse;

    # Collect all declared package names...
    my %packages = (main=>1);
    s{ (\s* package \s+ ($QUAL_IDENT)) }{
        my ($package_decl, $package_name) = ($1,$2);
        $packages{$package_name} = 1;
        $package_decl;
    }gxmse;

    # Delete all other Podlite sections, preserving newlines...
    { no warnings;
      s{ ($PODLITE_PAT) }{ my $text = $1; $text =~ tr[\n\0-\377][\n]d; $text; }gxmse;
    }

    # Consolidate data and open a filehandle to it...
    local *DATA_glob;
    my $DATA_as_str = join q{}, @DATA;
    *DATA_glob = \$DATA_as_str;
    *DATA_glob = \@DATA;
    open *DATA_glob, '<', \$DATA_as_str
        or require Carp
        and croak( "Can't set up *DATA handle ($!)" );

    # Alias each package's *DATA, @DATA, and $DATA...
    for my $package (keys %packages) {
        no strict 'refs'; 
        *{$package.'::DATA'} = *DATA_glob;
    }
}

__END__

=head1 NAME

Podlite - Use Podlite markup language in Perl programs

=head1 VERSION

This document describes Podlite version 1.00

=head1 SYNOPSIS

    use Podlite;

    =comment
    This is a Podlite comment block

    =head1 Head title
    =para
    Some text of paragraph

Delimited style, paragraph style, or abbreviated style of blocks:

    =begin para :nested
    Podlite is a lightweight markup language with a simple,
    consistent underlying document object model.
    =end para

    =for para :nested
    Podlite is a lightweight markup language.

    =para
    Podlite is a lightweight markup language.

Unordered lists:

    =item FreeBSD
    =item Linux
    =item Windows
    =item MacOS

Definition lists:

    =defn XML
    Extensible Markup Language
    =defn HTML
    Hyper Text Markup Language

Task lists with checkboxes:

    =item [x] Completed task
    =item [ ] Pending task

Tables with captions:

    =begin table :caption<System Requirements>
    Component    Minimum     Recommended
    CPU          2 GHz       4 GHz
    RAM          4 GB        16 GB
    =end table

Notification blocks (callouts):

    =begin nested :notify<warning> :caption<Important>
    This feature is experimental and may change.
    =end nested

Markdown blocks:

    =begin markdown
    # Documentation

    Mix **markdown** formatting with Podlite!

    - Bullet points
    - **Bold** and *italic*
    - Code blocks with ```perl syntax```
    =end markdown

=head1 DESCRIPTION

Podlite is a lightweight markup language with a simple, consistent underlying
document object model. It is designed to be a pure descriptive markup language
with no presentational components, focusing on simplicity and consistency.

This module preprocesses your Perl code from the point at which the module is
first used, stripping out any Podlite documentation while preserving line
numbering for accurate error reporting.

This means that, so long as your program starts with:

    use Podlite;

you can document it using the Podlite markup notation and it will still
run correctly under the Perl interpreter.

In addition, the module detects any C<=data> sections in the stripped
documentation and makes them available to your program in three ways:

=over

=item *

As a single concatenated string, in the C<$DATA> package variable

=item *

As a sequence of strings (one per C<=data> block) in the C<@DATA> package
variable

=item *

As a single concatenated input stream in the C<*DATA> filehandle.

=back

=head2 General syntactic structure

Podlite documents are specified using directives, which are used to declare
configuration information and to delimit blocks of textual content. Every
directive starts with an equals sign (C<=>) in the first column.

The content of a document is specified within one or more blocks. Every Podlite
block may be declared in any of three equivalent forms: delimited style,
paragraph style, or abbreviated style.

=head3 Delimited blocks

The general syntax is:

    =begin BLOCK_TYPE  OPTIONAL CONFIG INFO
    =                  OPTIONAL EXTRA CONFIG INFO
    BLOCK CONTENTS
    =end BLOCK_TYPE

For example:

    =begin table :caption<Table of Contents>
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57
    =end table

    =begin Name :required
    =            :width(50)
    The applicant's full name
    =end Name

    =begin Contact :optional
    The applicant's contact details
    =end Contact

=head3 Paragraph blocks

Paragraph blocks are introduced by a C<=for> marker and terminated by the next
Podlite directive or the first blank line (which is not considered to be part
of the block's contents). The C<=for> marker is followed by the name of the
block and optional configuration information. The general syntax is:

    =for BLOCK_TYPE  OPTIONAL CONFIG INFO
    =                OPTIONAL EXTRA CONFIG INFO
    BLOCK DATA

For example:

    =for table :caption<Table of Contents>
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57

    =for Name :required
    =          :width(50)
    The applicant's full name

    =for Contact :optional
    The applicant's contact details

=head3 Abbreviated blocks

Abbreviated blocks are introduced by an C<=> sign in the first column, which
is followed immediately by the typename of the block. The rest of the line is
treated as block data, rather than as configuration. The content terminates at
the next Podlite directive or the first blank line (which is not part of the
block data). The general syntax is:

    =BLOCK_TYPE  BLOCK DATA
    MORE BLOCK DATA

For example:

    =table
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57

    =Name     The applicant's full name
    =Contact  The applicant's contact details

Note that abbreviated blocks cannot specify configuration information. If
configuration is required, use a C<=for> or C<=begin>/C<=end> instead.

=head3 Block equivalence

The three block specifications (delimited, paragraph, and abbreviated) are
treated identically by the underlying documentation model, so you can use
whichever form is most convenient for a particular documentation task.

For example, although Headings shows only:

    =head1 Top Level Heading

this automatically implies that you could also write that block as:

    =for head1
    Top Level Heading

or:

    =begin head1
    Top Level Heading
    =end head1

=head2 Standard configuration options

Podlite predefines a small number of standard configuration options that can
be applied uniformly to built-in block types. These include:

=head3 :caption

Assigns a title to the given block, typically used for creating a table of
contents.

    =for table :caption<Performance Benchmarks>

=head3 :id

Enables explicit definition of identifiers for blocks, used for linking
purposes.

    =for head1 :id<introduction>
    Introduction

=head3 :nested

Specifies that the block is to be nested within its current context. Can take
integer values for multiple nesting levels.

    =begin para :nested(3)
    "We're going deep, deep, deep undercover!"
    =end para

Use C<:nested(0)> or C<:!nested> to defeat implicit nesting.

=head3 :numbered

Specifies that the block is to be numbered. The most common use is to create
numbered headings and ordered lists, but it can be applied to any block.

    =for head1 :numbered
    The Problem

Shorthand: If first word is a single C<#>, it's removed and treated as
C<:numbered>:

    =head1 # The Problem

=head3 :checked

Adds checkbox to block (for task lists). Use C<:!checked> for unchecked.

    =for item :checked
    Buy groceries

Shorthand: C<[x]> for checked, C<[ ]> for unchecked:

    =item [x] Buy groceries
    =item [ ] Clean garage

=head3 :folded

Specifies if block is foldable and default state (collapsed/expanded).

    =for table :folded :caption<Data>

C<:!folded> or C<:folded(0)> = expanded by default.
C<:folded> or C<:folded(1)> = collapsed by default.

=head3 :lang

Specifies programming language for code blocks (for syntax highlighting).

    =begin code :lang<raku>
    sub demo { say 'Hello'; }
    =end code

Common values: C<cpp>, C<css>, C<html>, C<java>, C<javascript>, C<python>,
C<raku>, C<perl>

=head3 :allow

Lists markup codes recognized within VE<lt>E<gt> codes (typically in code blocks).

    =begin code :allow<B R E>
    sub demo {
        B<say> 'Hello R<name>';
    }
    =end code

=head2 Block types

Podlite supports many block types including:

=over

=item Headings (C<=head1>, C<=head2>, etc.) - Unlimited nesting levels

=item Paragraphs (C<=para>) - Formatted text with whitespace squeezed

=item Code blocks (C<=code>) - Pre-formatted source code

=item Lists (C<=item>, C<=item1>, C<=item2>, etc.) - Multi-level lists

=item Definition lists (C<=defn>) - Term and definition pairs

=item Tables (C<=table>, C<=row>, C<=cell>) - Simple and advanced formats

=item Nesting blocks (C<=nested>) - For blockquotes and indented content

=item Comments (C<=comment>) - Documentation that won't be rendered

=item Data blocks (C<=data>) - Binary or text data sections

=item Include blocks (C<=include>) - Content reuse from other files

=item Table of contents (C<=toc>) - Auto-generated TOC

=item Pictures (C<=picture>) - Image insertion

=item Formulas (C<=formula>) - Mathematical formulas

=item Markdown blocks (C<=markdown>) - Embedded Markdown

=item Notification blocks (C<=nested :notify>) - Callouts/admonitions

=item Semantic blocks (C<=SYNOPSIS>, C<=AUTHOR>, etc.) - Uppercase names

=back

=head2 Markup codes

Podlite supports inline formatting codes:

=over

=item BE<lt>E<gt> - Bold/basis/important text

=item IE<lt>E<gt> - Italic/important text

=item UE<lt>E<gt> - Underlined text

=item CE<lt>E<gt> - Code/verbatim inline text

=item LE<lt>E<gt> - Hyperlinks and cross-references

=item EE<lt>E<gt> - Entities and emoji

=item NE<lt>E<gt> - Footnotes and annotations

=item DE<lt>E<gt> - Definitions (for inline glossary)

=item VE<lt>E<gt> - Verbatim text (no processing)

=item KE<lt>E<gt> - Keyboard input

=item TE<lt>E<gt> - Terminal output

=item RE<lt>E<gt> - Replaceable text/metasyntax

=item HE<lt>E<gt> - Superscript (High text)

=item JE<lt>E<gt> - Subscript (Junior text)

=item OE<lt>E<gt> - Overstrike/strikethrough

=item PE<lt>E<gt> - Pictures (inline images)

=item FE<lt>E<gt> - Formulas (inline math)

=item ME<lt>E<gt> - Custom markup codes

=back

=head2 Version 1.0 Features

Podlite 1.0 includes many advanced features:

=over

=item B<Notification blocks> - Callouts/admonitions with C<:notify> attribute

=item B<Table of contents> - C<=toc> block with selectors

=item B<Include blocks> - C<=include> for content reuse

=item B<Picture insertion> - C<=picture> and PE<lt>E<gt> code

=item B<Mathematical formulas> - C<=formula> and FE<lt>E<gt> code

=item B<Markdown support> - C<=markdown> blocks for embedding GitHub-flavored Markdown syntax within Podlite documents

=item B<Task lists> - C<:checked> attribute and C<[x]>/C<[ ]> syntax

=item B<Advanced tables> - C<=row>/C<=cell> with colspan/rowspan

=item B<Custom blocks> - Named semantic blocks

=item B<Embedded data> - C<=data> blocks with MIME types and encoding

=item B<Folding support> - C<:folded> attribute for collapsible content

=item B<Selectors> - Pattern-based block filtering from multiple sources

=back

=head1 INTERFACE

None. You C<use> the module and it takes care of everything.

=head1 EXAMPLES

=head2 Basic Documentation

    use Podlite;

    sub calculate {
        my ($x, $y) = @_;
        return $x + $y;
    }

    =head1 FUNCTIONS

    =head2 calculate

    =para
    Adds two numbers together.

    =begin code :lang<perl>
    my $result = calculate(5, 3);  # Returns 8
    =end code

=head2 Task List

    =head1 TODO

    =item [x] Implement basic functionality
    =item [x] Write documentation
    =item [ ] Add test suite
    =item [ ] Publish to CPAN

=head2 Table with Caption

    =begin table :caption<Performance Benchmarks>
    Operation      Time (ms)   Memory (MB)
    Parse          45          12
    Render         23          8
    Export         67          15
    =end table

=head2 Notification Block

    =begin nested :notify<warning> :caption<Important Note>
    This feature is experimental and may change in future releases.
    =end nested

=head2 Markdown Block

    use Podlite;

    my $config = {
        title => "My Project",
        version => "1.0"
    };

    =begin markdown
    # Documentation

    You can mix **markdown** and *Podlite* markup!

    ## Features

    - Easy to read
    - Easy to write
    - Works seamlessly with Perl code

    Code example:
    ```perl
    my $x = 1 + 1;
    ```
    =end markdown

    print "Config: $config->{title} v$config->{version}\n";

=head1 DIAGNOSTICS

=over

=item C<< Can't set up *DATA handle (%s) >>

The filter found at least one C<=data> block, but was unable to create a
C<*DATA> filehandle in the caller's namespace (for the reason specified in the
parens).

=back

=head1 CONFIGURATION AND ENVIRONMENT

Podlite requires no configuration files or environment variables.

=head1 DEPENDENCIES

Requires the standard module C<Filter::Simple>.

=head1 LIMITATIONS

Unlike full Podlite parsers:

=over

=item *

This module does not make every Podlite block available to the surrounding
program, only the C<=data> blocks. This is to avoid unacceptably slow
compilation speed that would result from attempting to fully parse the entire
embedded Podlite markup.

=item *

The contents of C<=data> blocks appear in the global variables C<$DATA> and
C<@DATA>, and the global C<*DATA> filehandle, rather than in a special
C<$?DATA> object. These variables and filehandle are accessible from C<main>
and in every other package that is explicitly declared in the file.

=item *

Parser modes (pod mode for C<.podlite> files, markdown mode for C<.md> files)
are not implemented in this source filter. You must explicitly use C<=begin>
blocks or other directives.

=back

=head1 BUGS

Please report any bugs  L<https://github.com/zag/p5-Podlite/issues>

=head1 SEE ALSO

=over

=item L<Podlite Specification|https://podlite.org/specification> - Official specification in HTML

=item L<Podlite Specification Source|https://github.com/podlite/podlite-specs> - Specification source code

=item L<Podlite Implementation|https://github.com/podlite/podlite> - Main Podlite implementation

=item L<Podlite Desktop|https://github.com/podlite/podlite-desktop> - Desktop viewer/editor

=item L<Podlite Web|https://github.com/podlite/podlite-web> - Publishing system

=item L<podlite.org|https://podlite.org> - Official website

=item L<Filter::Simple> - The module used for source filtering

=back

=head1 AUTHOR

Aliaksandr Zahatski, C<< <zag at cpan.org> >>

=head1 CREDITS

Damian Conway - for inspiration and source filter techniques

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2025 by Aliaksandr Zahatski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl you may have available.

=head1 DISCLAIMER OF STABILITY

This module will attempt to track any future changes to the Podlite
specification. Hence its features and the Podlite syntax it recognizes may
change in future releases.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
