package Podlite;

our $VERSION = '2.00';
use warnings;
use strict;

use Filter::Util::Call ();
use Carp ();

our $WORK = 0;

my $IDENT            = qr{ (?> (?!\d)\w \w* )              }xms;
my $QUAL_IDENT       = qr{ $IDENT (?: :: $IDENT)*         }xms;

# A hyphen or apostrophe only before a letter...

my $NAME = qr{ [\p{Alphabetic}_] [\p{Alphabetic}\p{Nd}_]* (?: ['-] [\p{Alphabetic}_] [\p{Alphabetic}\p{Nd}_]* )* }xms;

# Perl 5.10 cannot load Unicode tables from inside a filter, so load them now...
my $TABLES = "\x{100}";
utf8::upgrade($TABLES);
$TABLES =~ $NAME;

my $MARKER = qr{ \A [ \t]* (?: __(?:DATA|END)__ | no [ \t]+ Podlite [ \t]* ; ) [ \t]* (?: \# .* )? \r? \n? \z }xms;

my %DIRECTIVE = map { $_ => 1 } qw( config set alias include boundary );

my %VERBATIM = map { $_ => 1 }
    qw( code input output formula markdown data data-table picture toc );

# Only words of the specification may start an indented directive...

my @SEMANTIC = qw(
    NAME AUTHOR VERSION SYNOPSIS DESCRIPTION USAGE INTERFACE METHOD SUBROUTINE
    OPTION DIAGNOSTIC ERROR WARNING DEPENDENCY BUG SEE-ALSO ACKNOWLEDGEMENT
    COPYRIGHT DISCLAIMER LICENCE LICENSE TITLE SECTION CHAPTER APPENDIX TOC
    INDEX FOREWORD SUMMARY
);
my %INDENTED = map { $_ => 1 } (
    qw( begin config set end for alias include boundary
        pod para code input output comment defn nested table row cell
        data data-table toc picture formula markdown item ),
    @SEMANTIC,
    map { _plurals($_) } @SEMANTIC,
);

sub _plurals {
    my ($word) = @_;
    return 'SYNOPSES' if $word eq 'SYNOPSIS';
    my @forms
        = $word =~ /[^AEIOU]Y\z/     ? substr( $word, 0, -1 ) . 'IES'
        : $word =~ /(?:X|S|SH|CH)\z/ ? $word . 'ES'
        :                              $word . 'S';
    push @forms, 'INDICES'    if $word eq 'INDEX';
    push @forms, 'APPENDICES' if $word eq 'APPENDIX';
    return @forms;
}

sub _may_indent {
    my ($word) = @_;
    return $INDENTED{$word} || $word =~ /\A(?:head|item)\d+\z/;
}

sub _columns {
    my ($space) = @_;
    my $col = 0;
    for my $ch ( split //, $space ) {
        $col += $ch eq "\t" ? 8 - $col % 8 : 1;
    }
    return $col;
}

# Recognition reads characters; output keeps the original bytes...

sub _chars {
    my ($line) = @_;
    my $text = $line;
    $text =~ s/\r?\n\z//;
    return $text if utf8::is_utf8($text);
    my $decoded = $text;
    unless ( utf8::decode($decoded) ) {
        $decoded = $text;
    }
    utf8::upgrade($decoded);
    return $decoded;
}

sub _new_scanner {
    my ( $file, $line ) = @_;
    return { file => $file, line => $line, stack => [], para => undef, data => [] };
}

sub _fail {
    my ( $scan, $message ) = @_;
    die "Podlite: $message\n";
}

sub _directive {
    my ( $chars, $margin ) = @_;
    $chars =~ /\A([ \t]*)=($NAME)(?=\h|\z)(.*)\z/s or return;
    my ( $space, $word, $rest ) = ( $1, $2, $3 );
    my $col = _columns($space);
    return if $col > $margin && !_may_indent($word);
    return { col => $col, word => $word, rest => $rest };
}

sub _typename {
    my ( $scan, $dir, $lineno ) = @_;
    my $config = $dir->{word} eq 'config' ? '(?:<>)?' : '';
    if ( $dir->{rest} =~ /\A\h+($NAME)$config(?=\h|\z)/ ) {
        $WORK += length $1;
        return $1;
    }
    _fail( $scan, "malformed =$dir->{word} directive at $scan->{file} line $lineno" );
}

# A tab that crosses the margin leaves spaces for the columns beyond it...

sub _unindent {
    my ( $line, $margin ) = @_;
    return $line unless $margin;
    my ( $col, $pos ) = ( 0, 0 );
    while ( $col < $margin && $pos < length $line ) {
        my $ch = substr $line, $pos, 1;
        last unless $ch eq ' ' || $ch eq "\t";
        $col += $ch eq "\t" ? 8 - $col % 8 : 1;
        $pos++;
    }
    return ( ' ' x ( $col > $margin ? $col - $margin : 0 ) ) . substr( $line, $pos );
}

sub _keep_data {
    my ( $scan, $body ) = @_;
    $WORK += length $body;
    push @{ $scan->{data} }, $body;
}

sub _end_para {
    my ($scan) = @_;
    my $para = $scan->{para} or return;
    _keep_data( $scan, $para->{body} ) if $para->{kind} eq 'data';
    $scan->{para} = undef;
}

sub _feed {
    my ( $scan, $line ) = @_;
    my $lineno = $scan->{line}++;
    my $chars  = _chars($line);
    $WORK += length $chars;
    my $eol   = $line =~ /\n\z/ ? "\n" : '';
    my $stack = $scan->{stack};
    my $top   = @$stack ? $stack->[-1] : undef;
    my $blank = $chars =~ /\A\h*\z/;

    if ( $top && $top->{verbatim} ) {
        my $dir = _directive( $chars, 1e9 );
        if (   $dir
            && $dir->{word} eq 'end'
            && $dir->{col} == $top->{margin}
            && $dir->{rest} =~ /\A\h+($NAME)(?=\h|\z)/
            && $1 eq $top->{name} )
        {
            $WORK += length $1;
            pop @$stack;
            _keep_data( $scan, $top->{body} ) if $top->{name} eq 'data';
        }
        elsif ( $top->{name} eq 'data' ) {
            $top->{body} .= _unindent( $line, $top->{margin} );
        }
        return $eol;
    }

    my $margin = $top ? $top->{margin} : 0;

    if ( my $para = $scan->{para} ) {
        if ($blank) {
            _end_para($scan);
            return $eol;
        }
        if ( $para->{kind} eq 'code' ) {
            my ($space) = $chars =~ /\A([ \t]*)/;
            return $eol if _columns($space) > $margin;
            $scan->{para} = undef;
            $scan->{line}--;
            return _feed( $scan, $line );
        }
        if (   ( $para->{kind} eq 'config' || $para->{opening} )
            && $chars =~ /\A([ \t]*)=(?:\h|\z)/
            && _columns($1) == $para->{col} )
        {
            return $eol;
        }
        $para->{opening} = 0;
        my $dir = _directive( $chars, $margin );
        if ( !$dir ) {
            if ( $para->{kind} eq 'config' ) {
                $scan->{para} = undef;
                return $top ? $eol : $line;
            }
            $para->{body} .= _unindent( $line, $para->{col} ) if $para->{kind} eq 'data';
            return $eol;
        }
        _end_para($scan);
    }

    return $top ? $eol : $line if $blank;

    my $dir = _directive( $chars, $margin );
    if ( !$dir ) {
        return $line unless $top;
        my ($space) = $chars =~ /\A([ \t]*)/;
        $scan->{para} = { kind => _columns($space) > $margin ? 'code' : 'text' };
        return $eol;
    }

    my $word = $dir->{word};
    if ( $word eq 'begin' ) {
        my $name = _typename( $scan, $dir, $lineno );
        push @$stack, {
            name     => $name,
            margin   => $dir->{col},
            line     => $lineno,
            verbatim => $VERBATIM{$name},
            body     => '',
        };
    }
    elsif ( $word eq 'end' ) {
        my $name = _typename( $scan, $dir, $lineno );
        if ( $top && $top->{name} eq $name ) {
            pop @$stack;
        }
        elsif ($top) {
            _fail( $scan, "=end $name at $scan->{file} line $lineno does not close =begin $top->{name} at line $top->{line}" );
        }
        else {
            _fail( $scan, "=end $name without =begin at $scan->{file} line $lineno" );
        }
    }
    elsif ( $word eq 'for' ) {
        my $name = _typename( $scan, $dir, $lineno );
        $scan->{para} = $name eq 'data'
            ? { kind => 'data', col => $dir->{col}, body => '', opening => 1 }
            : { kind => 'block' };
    }
    elsif ( $DIRECTIVE{$word} ) {
        _typename( $scan, $dir, $lineno ) if $word eq 'config';
        $scan->{para} = { kind => 'config', col => $dir->{col} };
    }
    elsif ( $word eq 'data' ) {
        my ($first) = $line =~ /\A[ \t]*=data[ \t](.*)\z/s;
        $scan->{para} = { kind => 'data', col => $dir->{col}, body => defined $first ? $first : '' };
    }
    else {
        $scan->{para} = { kind => 'block' };
    }
    return $eol;
}

sub _finish {
    my ($scan) = @_;
    _end_para($scan);
    my @open = reverse @{ $scan->{stack} } or return;
    _fail( $scan, join "\nPodlite: ",
        map { "unclosed =begin $_->{name} at $scan->{file} line $_->{line}" } @open );
}

sub _outside_blocks {
    my ($scan) = @_;
    return !@{ $scan->{stack} };
}

my ( @ACTIVE, %AREA );
my $AREAS = 0;

sub _end { my $area = delete $AREA{ $_[0] }; $area->{active} = 0 if $area }

# The require statements that led to the code being compiled now...
sub _units {
    my @units;
    for ( my $i = 1; my @frame = caller($i); $i++ ) {
        push @units, join "\0", @frame[ 1, 2, 6 ] if $frame[7];
    }
    return @units;
}

sub import {
    my ( $caller, $file, $line ) = caller;
    my @units = _units();
    my $depth = @units;
    my $unit  = join "\n", @units;

    # A unit whose compilation died never closes its area, hence the unit check...
    my $prev = $ACTIVE[$depth];
    return if $prev && $prev->{active} && $prev->{unit} eq $unit;
    my $id   = ++$AREAS;
    my $area = $ACTIVE[$depth] = $AREA{$id} = { active => 1, unit => $unit };

    my $scan = _new_scanner( $file, $line + 1 );
    my $done;

    Filter::Util::Call::filter_add( sub {
        if ($done) {
            _end($id);
            return 0;
        }
        $done = 1;

        my ( $perl, $marker ) = ('');
        while (1) {
            $_ = '';
            my $status = Filter::Util::Call::filter_read();
            return $status if $status < 0;
            last if $status == 0;
            if ( _outside_blocks($scan) && $_ =~ $MARKER ) {
                $marker = $_;
                last;
            }
            my $out = _feed( $scan, $_ );
            $WORK += length $out;
            $perl .= $out;
        }
        _finish($scan);

        my @DATA = @{ $scan->{data} };

        # Special newline handling required under Windows...
        if ( $^O =~ /MSWin/ ) {
            s{ \r\n }{\n}gxms for @DATA;
        }

        # Data of a module stays with its own packages...
        my %packages;
        $packages{$caller} = 1 if !$depth || $caller ne 'main';
        $packages{main}    = 1 if !$depth;
        $WORK += length $perl;
        while ( $perl =~ m{ \s* package \s+ ($QUAL_IDENT) }gxms ) {
            $packages{$1} = 1 if !$depth || $1 ne 'main';
        }

        # A handle reads bytes, so wide data goes through an encoding layer...
        local *DATA_glob;
        my $DATA_as_str = join q{}, @DATA;
        $WORK += length $DATA_as_str;
        *DATA_glob = \$DATA_as_str;
        *DATA_glob = \@DATA;
        my ( $backing, $layer ) = ( \$DATA_as_str, '<' );
        if ( $DATA_as_str =~ /[^\x00-\xFF]/ ) {
            my $bytes = $DATA_as_str;
            utf8::encode($bytes);
            $WORK += length $DATA_as_str;
            ( $backing, $layer ) = ( \$bytes, '<:encoding(UTF-8)' );
        }
        open *DATA_glob, $layer, $backing
            or Carp::croak("Can't set up *DATA handle ($!)");

        for my $package ( keys %packages ) {
            no strict 'refs';
            *{ $package . '::DATA' } = *DATA_glob;
        }

        # Perl reads no more source after the marker, so the area ends where its code does...
        if ( defined $marker ) {
            Filter::Util::Call::filter_del();
            $marker = ";BEGIN { Podlite::_end($id) } $marker";
            $WORK += length $marker;
            $perl .= $marker;
        }
        $_ = $perl;
        return length $perl ? 1 : 0;
    } );
}

sub unimport {
    my $area = $ACTIVE[ scalar _units() ];
    $area->{active} = 0 if $area;
}

1;

__END__

=head1 NAME

Podlite - Use Podlite markup language in Perl programs

=head1 VERSION

This document describes Podlite version 2.00, which follows the Podlite
specification 2.0

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

    =begin table :caption('System Requirements')
    Component    Minimum     Recommended
    CPU          2 GHz       4 GHz
    RAM          4 GB        16 GB
    =end table

Notification blocks (callouts):

    =begin nested :notice<warning> :caption<Important>
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

Data blocks, read back by the program:

    use Podlite;

    =begin data
    alpha
    beta
    =end data

    print for <DATA>;

=head1 DESCRIPTION

Podlite is a lightweight markup language with a simple, consistent underlying
document object model. It is designed to be a pure descriptive markup language
with no presentational components, focusing on simplicity and consistency.

This module preprocesses your Perl code from the point at which the module is
first used, stripping out any Podlite documentation while preserving line
numbering for accurate error reporting. Filtering stops at a C<__DATA__>,
C<__END__> or C<no Podlite;> line outside any block. A later C<use Podlite;>
starts it again.

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

These variables and the filehandle belong to the package that uses the module
and to every package declared in the filtered code. In the program itself they
also appear in C<main>. A module that uses Podlite keeps its data in its own
packages and does not touch the program's C<main::DATA>. A C<=data> block inside
a verbatim block, such as a code example, is not collected. A C<=data-table>
block is not collected either.

Markup that cannot be parsed is a compile-time error naming the file and the
line: an unclosed C<=begin>, an C<=end> without its C<=begin> or closing another
block, and a C<=begin>, C<=for> or C<=end> line with no valid block name, or with
something other than whitespace or the end of the line right after the name. See L</DIAGNOSTICS>.

=head2 General syntactic structure

Podlite documents are specified using directives, which are used to declare
configuration information and to delimit blocks of textual content. Every
directive starts with an equals sign (C<=>) as the first non-blank character of
a line.

Inside Perl code the filter recognizes an indented directive only when its word
is defined by the specification: the directives themselves (C<=begin>,
C<=end>, C<=for>, C<=config>, C<=set>, C<=alias>, C<=include>, C<=boundary>),
the standard block names such as C<=head2>, C<=item> or C<=code>, and the
semantic block names such as C<=SYNOPSIS>. An indented line such as C<=Foo>
stays Perl.

A block name is followed by one or more whitespace characters or by the end of
the line. A line such as C<=head1(x)> or C<< =Foo::Bar->new >> is not Podlite
markup and is left to Perl.

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

    =begin table :caption('Table of Contents')
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

    =for table :caption('Table of Contents')
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

Abbreviated blocks are introduced by an C<=> sign at the start of a line, which
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

=head3 Directives

Besides C<=begin>, C<=end> and C<=for>, the specification defines directives
that are not blocks. Each takes the rest of its line and any following lines
that start with C<=> and whitespace.

C<=config> sets attributes for every block of a type:

    =config head2 :numbered

C<=set> sets attributes for the next block only. Its values may span several
lines and contain markup codes:

    =set :caption('Product comparison') :id<table-1>
    =begin table
    Product    Price
    Basic      10
    =end table

C<=alias> defines a macro used with AE<lt>E<gt>:

    =alias PROGNAME Podlite

C<=include> inserts content from other sources. Since 2.0 it is a directive:

    =include file:./includes/chapter01.podlite

C<=boundary> marks a transition between major sections, such as chapters:

    =boundary :caption<Part Two>

=head2 Standard configuration options

Podlite predefines a small number of standard configuration options that can
be applied uniformly to built-in block types. These include:

=head3 :caption

Assigns a title to the given block, typically used for creating a table of
contents.

    =for table :caption('Performance Benchmarks')

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

Controls whether the block content is hidden until the reader opens it.
C<:folded> or C<:folded(1)> hides the content by default.
C<:!folded> or C<:folded(0)> shows it by default.

    =for table :folded :caption<Data>

On a heading the attribute covers the heading and all its lower-level content.
In non-interactive output the distinction may be shown by visual means, such
as sidebar placement or reduced emphasis.

=head3 :masked

Hides the block content when rendered but leaves the source unchanged. The
inline counterpart is GE<lt>E<gt>.

    =for para :masked
    The API token is sk-12345.

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

=item Tables (C<=table>, C<=row>, C<=cell>) - Simple and advanced formats, with defined recovery from malformed rows

=item Nesting blocks (C<=nested>) - For blockquotes and indented content

=item Comments (C<=comment>) - Documentation that won't be rendered

=item Data blocks (C<=data>) - Binary or text data sections

=item Data tables (C<=data-table>) - CSV and TSV data rendered as a table, from the block body, a file (C<:src>) or a C<=data> block, with C<:columns> and C<:rename> to pick and rename columns

=item Table of contents (C<=toc>) - Auto-generated TOC

=item Pictures (C<=picture>) - Image insertion

=item Formulas (C<=formula>) - Mathematical formulas

=item Markdown blocks (C<=markdown>) - Embedded Markdown

=item Notification blocks (C<=nested :notice>) - Callouts/admonitions

=item Semantic blocks (C<=SYNOPSIS>, C<=AUTHOR>, etc.) - Uppercase names

=back

C<=include> is no longer a block: since 2.0 it is a directive (see
L</Directives>).

=head2 Markup codes

Podlite supports inline formatting codes:

=over

=item BE<lt>E<gt> - Bold/basis/important text

=item IE<lt>E<gt> - Italic/important text

=item UE<lt>E<gt> - Underlined text

=item CE<lt>E<gt> - Code/verbatim inline text

=item LE<lt>E<gt> - Hyperlinks and cross-references, optionally with link attributes (C<:new>, C<:title>, C<:lang>, C<:download>)

=item WE<lt>E<gt> - Contextual backlinks, with the same link attributes

=item AE<lt>E<gt> - Replaced by the contents of an C<=alias> macro

=item GE<lt>E<gt> - Guarded text, concealed in rendered output (the inline form of C<:masked>)

=item SE<lt>E<gt> - Space characters preserved

=item XE<lt>E<gt> - Index entries

=item ZE<lt>E<gt> - Zero-width comment, never rendered

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

Link attributes follow the link, after a space:

    L<API Reference|https://api.example.com :new :title('Official documentation')>

=head2 Version 2.0 Features

Specification 2.0 adds:

=over

=item B<Fenced code attributes> - Podlite attributes after the language of a Markdown fence: C<```python :caption<Example>>

=item B<Link attributes> - C<:new>, C<:title>, C<:lang>, C<:download> on LE<lt>E<gt> and WE<lt>E<gt>

=item B<Table error recovery> - Defined handling of malformed C<=table> rows

=item B<Section boundaries> - The C<=boundary> directive

=item B<Content masking> - GE<lt>E<gt> code and C<:masked> attribute

=item B<Attribute assignment> - The C<=set> directive for the next block, with multiline values and markup

=item B<MIME parameters> - C<:mime-type('text/csv; header=present')>, where C<header=present|absent> marks a CSV or TSV header row

=item B<Data tables> - The C<=data-table> block with C<:src>, C<:columns>, C<:rename>

=back

Specification 2.0 also makes C<=include> a directive and refines C<:folded>. The
specification's examples use consistent attribute names and quote a string with
spaces, as in
C<:caption('Two words')>. The old form C<< :caption<Two words> >> is gone.

=head3 Introduced in 1.0

=over

=item B<Notification blocks> - Callouts/admonitions with C<:notice> attribute

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

    =begin table :caption('Performance Benchmarks')
    Operation      Time (ms)   Memory (MB)
    Parse          45          12
    Render         23          8
    Export         67          15
    =end table

=head2 Notification Block

    =begin nested :notice<warning> :caption('Important Note')
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

=head2 Embedded Data

    use Podlite;

    =begin data :key<sales> :mime-type('text/csv; header=present')
    quarter,revenue
    Q1,120
    =end data

    =set :caption('Revenue by quarter')
    =for data-table :src<data:sales>

    my ($header, @rows) = <DATA>;
    print "rows: ", scalar(@rows), "\n";

=head1 DIAGNOSTICS

=over

=item C<< Podlite: unclosed =begin %s at %s line %d >>

A C<=begin> block has no matching C<=end> before the end of the filtered code.
Every unclosed block is reported, innermost first.

=item C<< Podlite: =end %s without =begin at %s line %d >>

An C<=end> line closes no open block.

=item C<< Podlite: =end %s at %s line %d does not close =begin %s at line %d >>

An C<=end> line names a block other than the innermost open one.

=item C<< Podlite: malformed =%s directive at %s line %d >>

A C<=begin>, C<=for>, C<=end> or C<=config> line has no block name followed by
whitespace or the end of the line, as in C<< =begin code:lang<perl> >>.

=item C<< Can't set up *DATA handle (%s) >>

The filter found at least one C<=data> block, but was unable to create a
C<*DATA> filehandle in the caller's namespace (for the reason specified in the
parens).

=back

Each C<Podlite:> error stops compilation before any code after the
C<use Podlite;> line runs. Only code on that same line, such as a C<BEGIN>
block, may already have run.

=head1 CONFIGURATION AND ENVIRONMENT

Podlite requires no configuration files or environment variables.

=head1 DEPENDENCIES

Requires Perl 5.10.1 or later and the core modules C<Filter::Util::Call> and
C<Carp>.

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
C<$?DATA> object. They are accessible from the package that uses the module,
from C<main> in the program itself, and from every package declared with
C<package NAME> in the filtered code. The filter does not find packages declared
before C<use Podlite> unless one is current at that line, nor a C<package>
statement with a comment between C<package> and the name. A C<package> statement inside a Perl string
is found.

=item *

Where Perl opens its own C<DATA> handle for a C<__DATA__> or C<__END__> tail,
that handle takes over the shared C<*DATA> glob. C<$DATA> and C<@DATA> still
hold the Podlite data.

=item *

A file loaded with C<do> or C<require> whose code is in package C<main> gets no
data. Podlite treats such a file like a module and leaves the program's
C<main::DATA> alone. Declare a package in such a file. If a
file fails to compile and the same statement loads it again, the second load
is not filtered.

=item *

The filter reads lines and does not parse Perl. A line inside a heredoc or a
multiline string that looks like a directive is stripped. A line that consists
of C<__DATA__>, C<__END__> or C<no Podlite;> ends filtering at that point.

=item *

A line such as C<=head1:> at the start of a Perl statement has no whitespace
after the block name, so it is not Podlite markup. Perl reads it as the start
of its own POD and skips everything up to C<=cut> or the end of the file.

=item *

With indentation, an abbreviated block with a user-defined name is not
recognized, and neither is an upper-case name outside the semantic block list.
Without indentation both are recognized.

=item *

The C<:key> and C<:encoding> attributes of C<=data> are not interpreted.
GE<lt>E<gt>, C<:masked>, link attributes and fence attributes concern rendered
output, which this filter does not produce.

=item *

Parser modes (pod mode for C<.podlite> files, markdown mode for C<.md> files)
are not implemented in this source filter. You must explicitly use C<=begin>
blocks or other directives.

=back

=head1 BUGS

Please report any bugs  L<https://github.com/zag/p5-Podlite/issues>

=head1 SEE ALSO

=over

=item L<Podlite Specification 2.0|https://podlite.org/v2.0/specification> - Official specification in HTML

=item L<Podlite Specification 2.0 Source|https://github.com/podlite/podlite-specs/blob/v2.0.1/Specification.pod6> - Specification source code

=item L<Podlite Implementation|https://github.com/podlite/podlite> - Main Podlite implementation

=item L<Podlite Desktop|https://github.com/podlite/podlite-desktop> - Desktop viewer/editor

=item L<Podlite Web|https://github.com/podlite/podlite-web> - Publishing system

=item L<podlite.org|https://podlite.org> - Official website

=item L<Filter::Util::Call> - The module used for source filtering

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
