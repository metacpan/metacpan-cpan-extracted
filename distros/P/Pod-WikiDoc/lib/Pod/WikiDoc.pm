package Pod::WikiDoc;
use strict;
use warnings;
# ABSTRACT: Generate Pod from inline wiki style text

our $VERSION = '0.21';

use 5.006;
use Carp;
use IO::String 1.06;
use Scalar::Util 1.02 qw( blessed );
use Pod::WikiDoc::Parser;

#--------------------------------------------------------------------------#
# PREAMBLE DOCUMENTATION
#--------------------------------------------------------------------------#

#pod =begin wikidoc
#pod
#pod = SYNOPSIS
#pod
#pod In a source file, Pod format-block style:
#pod     =begin wikidoc
#pod
#pod     = POD FORMAT-BLOCK STYLE
#pod
#pod     Write documentation with *bold*, ~italic~ or {code}
#pod     markup.  Create a link to [Pod::WikiDoc].
#pod     Substitute for user-defined %%KEYWORD%%.
#pod
#pod         Indent for verbatim paragraphs
#pod
#pod     * bullet
#pod     * point
#pod     * list
#pod
#pod     0 sequentially
#pod     0 numbered
#pod     0 list
#pod
#pod     =end wikidoc
#pod
#pod In a source file, wikidoc comment-block style:
#pod     ### = WIKIDOC COMMENT-BLOCK STYLE
#pod     ###
#pod     ### Optionally, [Pod::WikiDoc] can extract from
#pod     ### specially-marked comment blocks
#pod
#pod Generate Pod from wikidoc, programmatically:
#pod     use Pod::WikiDoc;
#pod     my $parser = Pod::WikiDoc->new( {
#pod         comment_blocks => 1,
#pod         keywords => { KEYWORD => "foo" },
#pod     } );
#pod     $parser->filter(
#pod         { input => "my_module.pm", output => "my_module.pod" }
#pod     );
#pod
#pod Generate Pod from wikidoc, via command line:
#pod     $ wikidoc -c my_module.pm my_module.pod
#pod
#pod = DESCRIPTION
#pod
#pod Pod works well, but writing it can be time-consuming and tedious.  For example,
#pod commonly used layouts like lists require numerous lines of text to make just
#pod a couple of simple points.  An alternative approach is to write documentation
#pod in a wiki-text shorthand (referred to here as ~wikidoc~) and use Pod::WikiDoc
#pod to extract it and convert it into its corresponding Pod as a separate {.pod}
#pod file.
#pod
#pod Documentation written in wikidoc may be embedded in Pod format blocks, or,
#pod optionally, in specially marked comment blocks.  Wikidoc uses simple text-based
#pod markup like wiki websites to indicate formatting and links.  (See
#pod [/WIKIDOC MARKUP], below.)
#pod
#pod Pod::WikiDoc processes text files (or text strings) by extracting both
#pod existing Pod and wikidoc, converting the wikidoc to Pod, and then writing
#pod the combined document back to a file or standard output.
#pod
#pod Summary of major features of Pod::WikiDoc:
#pod
#pod * Extracts and converts wikidoc from Pod format blocks or special
#pod wikidoc comment blocks
#pod * Extracts and preserves existing Pod
#pod * Provides bold, italic, code, and link markup
#pod * Substitutes user-defined keywords
#pod * Automatically converts special symbols in wikidoc to their
#pod Pod escape equivalents, e.g. \E\<lt\>, \E\<gt\>
#pod * Preserves other Pod escape sequences, e.g. \E\<euro\>
#pod
#pod In addition, Pod::WikiDoc provides a command-line utility, [wikidoc],
#pod to simplify wikidoc translation.
#pod
#pod See the [Pod::WikiDoc::Cookbook] for more detailed usage examples,
#pod including how to automate {.pod} generation when using [Module::Build].
#pod
#pod = INTERFACE
#pod
#pod =end wikidoc
#pod
#pod =cut

#--------------------------------------------------------------------------#
# PUBLIC METHODS
#--------------------------------------------------------------------------#

#pod =begin wikidoc
#pod
#pod == {new}
#pod
#pod     $parser = Pod::WikiDoc->new( \%args );
#pod
#pod Constructor for a new Pod::WikiDoc object.  It takes a single, optional
#pod argument: a hash reference with the following optional keys:
#pod
#pod * {comment_blocks}: if true, Pod::WikiDoc will scan for wikidoc in comment
#pod blocks.  Default is false.
#pod * {comment_prefix_length}: the number of leading sharp (#) symbols to
#pod denote a comment block.  Default is 3.
#pod * {keywords}: a hash reference with keywords and values for keyword
#pod substitution
#pod
#pod =end wikidoc
#pod
#pod =cut

my %default_args = (
    comment_blocks         => 0,
    comment_prefix_length  => 3,
    keywords               => {},
);

sub new {
    my ( $class, $args ) = @_;

    croak "Error: Class method new() can't be called on an object"
        if ref $class;

    croak "Error: Argument to new() must be a hash reference"
        if $args && ref $args ne 'HASH';

    my $self = { %default_args };

    # pick up any specified arguments;
    for my $key ( keys %default_args ) {
        if ( exists $args->{$key} ) {
            $self->{$key} = $args->{$key};
        }
    }

    # load up a parser
    $self->{parser} = Pod::WikiDoc::Parser->new();

    return bless $self, $class;
}

#pod =begin wikidoc
#pod
#pod == {convert}
#pod
#pod     my $pod_text = $parser->convert( $input_text );
#pod
#pod Given a string with valid Pod and/or wikidoc markup, filter/translate it to
#pod Pod.  This is really just a wrapper around {filter} for working with
#pod strings rather than files, and provides similar behavior, including adding
#pod a 'Generated by' header.
#pod
#pod =end wikidoc
#pod
#pod =cut

sub convert {
    my ($self, $input_string) = @_;

    croak "Error: Argument to convert() must be a scalar"
        if ( ref \$input_string ne 'SCALAR' );

    my $input_fh = IO::String->new( $input_string );
    my $output_fh = IO::String->new();
    _filter_podfile( $self, $input_fh, $output_fh );

    return ${ $output_fh->string_ref() };
}

#pod =begin wikidoc
#pod
#pod == {filter}
#pod
#pod     $parser->filter( \%args );
#pod
#pod Filters from an input file for Pod and wikidoc, translating it to Pod
#pod and writing it to an output file.  The output file will be prefixed with
#pod a 'Generated by' comment with the version of Pod::WikiDoc and timestamp,
#pod as required by [perlpodspec].
#pod
#pod {filter} takes a single, optional argument: a hash reference with
#pod the following optional keys:
#pod
#pod * {input}: a filename or filehandle to read from. Defaults to STDIN.
#pod * {output}: a filename or filehandle to write to.  If given a filename
#pod and the file already exists, it will be clobbered. Defaults to STDOUT.
#pod
#pod =end wikidoc
#pod
#pod =cut

sub filter {
    my ( $self, $args_ref ) = @_;

    croak "Error: Argument to filter() must be a hash reference"
        if defined $args_ref && ref($args_ref) ne 'HASH';
    # setup input
    my $input_fh;
    if ( ! $args_ref->{input} ) {
        $input_fh = \*STDIN;
    }
    elsif ( ( blessed $args_ref->{input} && $args_ref->{input}->isa('GLOB') )
         || ( ref $args_ref->{input}  eq 'GLOB' )
         || ( ref \$args_ref->{input} eq 'GLOB' ) ) {
        # filehandle or equivalent
        $input_fh = $args_ref->{input};
    }
    elsif ( ref \$args_ref->{input} eq 'SCALAR' ) {
        # filename
        open( $input_fh, "<", $args_ref->{input} )
            or croak "Error: Couldn't open input file '$args_ref->{input}': $!";
    }
    else {
        croak "Error: 'input' parameter for filter() must be a filename or filehandle"
    }

    # setup output
    my $output_fh;
    if ( ! $args_ref->{output} ) {
        $output_fh = \*STDOUT;
    }
    elsif ( ( blessed $args_ref->{output} && $args_ref->{output}->isa('GLOB') )
         || ( ref $args_ref->{output}  eq 'GLOB' )
         || ( ref \$args_ref->{output} eq 'GLOB' ) ) {
        # filehandle or equivalent
        $output_fh = $args_ref->{output};
    }
    elsif ( ref \$args_ref->{output} eq 'SCALAR' ) {
        # filename
        open( $output_fh, ">", $args_ref->{output} )
            or croak "Error: Couldn't open output file '$args_ref->{output}': $!";
    }
    else {
        croak "Error: 'output' parameter for filter() must be a filename or filehandle"
    }

    _filter_podfile( $self, $input_fh, $output_fh );
    return;
}

#pod =begin wikidoc
#pod
#pod == {format}
#pod
#pod     my $pod_text = $parser->format( $wiki_text );
#pod
#pod Given a string with valid Pod and/or wikidoc markup, filter/translate it to
#pod Pod. Unlike {convert}, no 'Generated by' comment is added.  This
#pod function is used internally by Pod::WikiDoc, but is being made available
#pod as a public method for users who want more granular control of the
#pod translation process or who want to convert wikidoc to Pod for other
#pod creative purposes using the Pod::WikiDoc engine.
#pod
#pod =end wikidoc
#pod
#pod =cut

sub format { ## no critic
    my ($self, $wikitext) = @_;

    croak "Error: Argument to format() must be a scalar"
        if ( ref \$wikitext ne 'SCALAR' );

    my $wiki_tree  = $self->{parser}->WikiDoc( $wikitext ) ;
    for my $node ( @$wiki_tree ) {
        undef $node if ! ref $node;
    }

    return _wiki2pod( $wiki_tree, $self->{keywords} );
}

#--------------------------------------------------------------------------#
# PRIVATE METHODS
#--------------------------------------------------------------------------#

#--------------------------------------------------------------------------#
# _comment_block_regex
#
# construct a regex dynamically for the right comment prefix
#--------------------------------------------------------------------------#

sub _comment_block_regex {
    my ( $self ) = @_;
    my $length = $self->{comment_prefix_length};
    return qr/\A#{$length}(?:\s(.*))?\z/ms;
}

#--------------------------------------------------------------------------#
# _input_iterator
#
# return an iterator that streams a filehandle. Action arguments:
#     'peek' -- lookahead at the next line without consuming it
#     'next' and 'drop' -- synonyms to consume and return the next line
#--------------------------------------------------------------------------#

sub _input_iterator {
    my ($self, $fh) = @_;
    my @head;
    return sub {
        my ($action) = @_;
        if ($action eq 'peek') {
            push @head, scalar <$fh> unless @head;
            return $head[0];
        }
        elsif ( $action eq 'drop' || $action eq 'next' ) {
            return shift @head if @head;
            return scalar <$fh>;
        }
        else {
            croak "Unrecognized iterator action '$action'\n";
        }
    }
}

#--------------------------------------------------------------------------#
# _exhaust_iterator
#
# needed to help abort processing
#--------------------------------------------------------------------------#

sub _exhaust_iterator {
    my ($self, $iter) = @_;
    1 while $iter->();
    return;
}

#--------------------------------------------------------------------------#
# _output_iterator
#
# returns an output "iterator" that streams to a filehandle.  Inputs
# are array refs of the form [ $FORMAT, @LINES ].  Format 'pod' is
# printed to the filehandle immediately.  Format 'wikidoc' is accumulated
# until the next 'pod' then converted to wikidoc and printed to the file
# handle
#--------------------------------------------------------------------------#

sub _output_iterator {
    my ($self, $fh) = @_;
    my @wikidoc;
    return sub {
        my ($chunk) = @_;
        if ($chunk eq 'flush') {
            print {$fh} $self->format( join(q{}, splice(@wikidoc,0) ) )
                if @wikidoc;
            return;
        }
        return unless ref($chunk) eq 'ARRAY';
        my ($format, @lines) = grep { defined $_ } @$chunk;
        if ( $format eq 'wikidoc' ) {
            push @wikidoc, @lines;
        }
        elsif ( $format eq 'pod' ) {
            print {$fh} $self->format( join(q{}, splice(@wikidoc,0) ) )
                if @wikidoc;
            print {$fh} @lines;
        }
        return;
    }
}

#--------------------------------------------------------------------------#
# _filter_podfile()
#
# extract Pod from input and pass through to output, converting any wikidoc
# markup to Pod in the process
#--------------------------------------------------------------------------#

my $BLANK_LINE = qr{\A \s* \z}xms;
my $NON_BLANK_LINE = qr{\A \s* \S }xms;
my $FORMAT_LABEL = qr{:? [-a-zA-Z0-9_]+}xms;
my $POD_CMD = qr{\A =[a-zA-Z]+}xms;
my $BEGIN = qr{\A =begin \s+ ($FORMAT_LABEL)  \s* \z}xms;
my $END   = qr{\A =end   \s+ ($FORMAT_LABEL)  \s* \z}xms;
my $FOR   = qr{\A =for   \s+ ($FORMAT_LABEL)  [ \t]* (.*) \z}xms;
my $POD   = qr{\A =pod                          \s* \z}xms;
my $CUT   = qr{\A =cut                          \s* \z}xms;

sub _filter_podfile {
    my ($self, $input_fh, $output_fh) = @_;

    # open output with tag and Pod marker
    print $output_fh
          "# Generated by Pod::WikiDoc version $Pod::WikiDoc::VERSION\n\n";
    print $output_fh "=pod\n\n";

    # setup iterators
    my $in_iter = $self->_input_iterator( $input_fh );
    my $out_iter = $self->_output_iterator( $output_fh );

    # starting filter mode is code
    $self->_filter_code( $in_iter, $out_iter );
    $out_iter->('flush');

    return;
}

#--------------------------------------------------------------------------#
# _filter_code
#
# we need a "cutting" flag -- if we got here from a =cut, then we return to
# caller ( pod or format ) when we see pod. Otherwise we're just starting
# and need to start a new pod filter when we see pod
#
# perlpodspec says starting Pod with =cut is an error and that we
# *must* halt parsing and *should* issue a warning. Here we might be
# far down the call stack and don't want to just return where the caller
# might continue processing.  To avoid this, we exhaust the input first.
#--------------------------------------------------------------------------#

sub _filter_code {
    my ($self, $in_iter, $out_iter, $cutting) = @_;
    my $CBLOCK = _comment_block_regex($self);
    CODE: while ( defined( my $peek = $in_iter->('peek') ) ) {
        $peek =~ $CBLOCK && do {
            $self->_filter_cblock( $in_iter, $out_iter );
            next CODE;
        };
        $peek =~ $CUT && do {
            warn "Can't start Pod with '$peek'\n";
            $self->_exhaust_iterator( $in_iter );
            last CODE;
        };
        $peek =~ $POD_CMD && do {
            last CODE if $cutting;
            $self->_filter_pod( $in_iter, $out_iter );
            next CODE;
        };
        do { $in_iter->('drop') };
    }
    return;
}

#--------------------------------------------------------------------------#
# _filter_pod
#
# Pass through lines to the output iterators, but flag wikidoc lines
# differently so that they can be converted on output
#
# If we find an =end that is out of order, perlpodspec says we *must* warn
# and *may* halt.  Instead of halting, we return to the caller in the
# hopes that an earlier format might match this =end.
#--------------------------------------------------------------------------#

sub _filter_pod {
    my ($self, $in_iter, $out_iter) = @_;
    my @format = (); # no format to start
    # process the pod block -- recursing as necessary
    LINE: while ( defined( my $peek = $in_iter->('peek') ) ) {
        $peek =~ $POD && do {
            $in_iter->('drop');
            next LINE;
        };
        $peek =~ $CUT && do {
            $in_iter->('drop');
            $self->_filter_code( $in_iter, $out_iter, 1 );
            next LINE;
        };
        $peek =~ $FOR && do {
            $self->_filter_for( $in_iter, $out_iter );
            next LINE;
        };
        $peek =~ $END && do {
            if ( ! @format ) {
                warn "Error: '$peek' doesn't match any '=begin $1'\n";
                $in_iter->('drop');
                next LINE;
            }
            elsif ( $format[-1] ne $1 ) {
                warn "Error: '$peek' doesn't match '=begin $format[-1]'\n";
                pop @format; # try an earlier format
                redo LINE;
            }
            elsif ( $format[-1] eq 'wikidoc' ) {
                pop @format;
                $in_iter->('drop');
                next LINE;
            }
            else {
                pop @format;
                # and let it fall through to the output iterator
            }
        };
        $peek =~ $BEGIN && do {
            if ( $1 eq 'wikidoc' ) {
                push @format, 'wikidoc';
                $in_iter->('drop');
                next LINE;
            }
            else {
                push @format, $1;
                # and let it fall through to the output iterator
            }
        };
        do {
            my $out_type =
                ( @format && $format[-1] eq 'wikidoc' ) ? 'wikidoc' : 'pod' ;
            $out_iter->( [ $out_type, $in_iter->('next') ] )
        };
    }
    return;
}

#--------------------------------------------------------------------------#
# _filter_for
#--------------------------------------------------------------------------#

sub _filter_for {
    my ($self, $in_iter, $out_iter) = @_;
    my $for_line = $in_iter->('next');
    my ($format, $rest) = $for_line =~ $FOR;
    $rest ||= "\n";

    my @lines = ( $format eq 'wikidoc' ? $rest : $for_line );

    LINE: while ( defined( my $peek = $in_iter->('peek') ) ) {
        $peek =~ $BLANK_LINE && do {
            last LINE;
        };
        do {
            push @lines, $in_iter->('next');
        };
    }
    if ($format eq 'wikidoc' ) {
        $in_iter->('drop'); # wikidoc will append \n
    }
    else {
        push @lines, $in_iter->('next');
    }
    my $out_type =  $format eq 'wikidoc' ? 'wikidoc' : 'pod' ;
    $out_iter->( [ $out_type, @lines ] );
    return;
}

#--------------------------------------------------------------------------#
# _filter_cblock
#--------------------------------------------------------------------------#

sub _filter_cblock {
    my ($self, $in_iter, $out_iter) = @_;
    my @lines = ($1 ? $1 : "\n"); ## no critic
    $in_iter->('next');
    my $CBLOCK = _comment_block_regex($self);
    LINE: while ( defined( my $peek = $in_iter->('peek') ) ) {
        last LINE if $peek !~ $CBLOCK;
        push @lines, ($1 ? $1 : "\n");
        $in_iter->('next');
    }
    $out_iter->( [ 'wikidoc', @lines ] ) if $self->{comment_blocks};
    return;
}


#--------------------------------------------------------------------------#
# Translation functions and tables
#--------------------------------------------------------------------------#

#--------------------------------------------------------------------------#
# Tables for formatting
#--------------------------------------------------------------------------#

# Used in closure for counting numbered lists
my $numbered_bullet;

# Text to print at start of entity from parse tree, or a subroutine
# to generate the text programmatically
my %opening_of = (
    Paragraph           =>  q{},
    Unordered_List      =>  "=over\n\n",
    Ordered_List        =>  sub { $numbered_bullet = 1; return "=over\n\n" },
    Preformat           =>  q{},
    Header              =>  sub {
                                my $node = shift;
                                my $level = $node->{level} > 4
                                    ? 4 : $node->{level};
                                return "=head$level "
                            },
    Bullet_Item         =>  "=item *\n\n",
    Numbered_Item       =>  sub {
                                return  "=item " . $numbered_bullet++
                                        . ".\n\n"
                            },
    Indented_Line       =>  q{ },
    Plain_Line          =>  q{},
    Empty_Line          =>  q{ },
    Parens              =>  "(",
    RegularText         =>  q{},
    EscapedChar         =>  q{},
    WhiteSpace          =>  q{},
    InlineCode          =>  "C<<< ",
    BoldText            =>  'B<',
    ItalicText          =>  'I<',
    KeyWord             =>  q{},
    LinkContent         =>  'L<',
    LinkLabel           =>  q{},
    LinkTarget          =>  q{},
);

# Text to print at end of entity from parse tree, or a subroutine
# to generate the text programmatically
my %closing_of = (
    Paragraph           =>  "\n",
    Unordered_List      =>  "=back\n\n",
    Ordered_List        =>  "=back\n\n",
    Preformat           =>  "\n",
    Header              =>  "\n\n",
    Bullet_Item         =>  "\n\n",
    Numbered_Item       =>  "\n\n",
    Indented_Line       =>  "\n",
    Plain_Line          =>  "\n",
    Empty_Line          =>  "\n",
    Parens              =>  ")",
    RegularText         =>  q{},
    EscapedChar         =>  q{},
    WhiteSpace          =>  q{},
    InlineCode          =>  " >>>",
    BoldText            =>  ">",
    ItalicText          =>  ">",
    KeyWord             =>  q{},
    LinkContent         =>  q{>},
    LinkLabel           =>  q{|},
    LinkTarget          =>  q{},
);

# Subroutine to handle actual raw content from different node types
# from the parse tree
my %content_handler_for = (
    RegularText         =>  \&_escape_pod,
    Empty_Line          =>  sub { q{} },
    KeyWord             =>  \&_keyword_expansion,
);

# Table of character to E<> code conversion
my %escape_code_for = (
    q{>} =>  "E<gt>",
    q{<} =>  "E<lt>",
    q{|} =>  "E<verbar>",
    q{/} =>  "E<sol>",
);

# List of characters that need conversion
my $specials = join q{}, keys %escape_code_for;

#--------------------------------------------------------------------------#
# _escape_pod()
#
# After removing backslash escapes from a text string, translates characters
# that must be escaped in Pod <, >, |, and / to their Pod E<> code equivalents
#
#--------------------------------------------------------------------------#

sub _escape_pod {

    my $node = shift;

    my $input_text  = $node->{content};

    # remove backslash escaping
    $input_text =~ s{ \\(.) }
                    {$1}gxms;

    # replace special symbols with corresponding escape code
    $input_text =~ s{ ( [$specials] ) }
                    {$escape_code_for{$1}}gxms;

    return $input_text;
}

#--------------------------------------------------------------------------#
# _keyword_expansion
#
# Given a keyword, return the corresponding value from the keywords
# hash or the keyword itself
#--------------------------------------------------------------------------#

sub _keyword_expansion {
    my ($node, $keywords) = @_;
    my $key = $node->{content};
    my $value = $keywords->{$key};
    return defined $value ? $value : q{%%} . $key . q{%%} ;
}


#--------------------------------------------------------------------------#
# _translate_wikidoc()
#
# given an array of wikidoc lines, joins them and runs them through
# the formatter
#--------------------------------------------------------------------------#

sub _translate_wikidoc {
    my ( $self, $wikidoc_ref ) = @_;
    return $self->format( join q{}, @$wikidoc_ref );
}

#--------------------------------------------------------------------------#
# _wiki2pod()
#
# recursive function that walks a Pod::WikiDoc::Parser tree and generates
# a string with the corresponding Pod
#--------------------------------------------------------------------------#

sub _wiki2pod {
    my ($nodelist, $keywords, $insert_space) = @_;
    my $result = q{};
    for my $node ( @$nodelist ) {
        # XXX print "$node\n" if ref $node ne 'HASH';
        my $opening = $opening_of{ $node->{type} };
        my $closing = $closing_of{ $node->{type} };

        $result .= ref $opening eq 'CODE' ? $opening->($node) : $opening;
        if ( ref $node->{content} eq 'ARRAY' ) {
            $result .= _wiki2pod(
                $node->{content},
                $keywords,
                $node->{type} eq 'Preformat' ? 1 : 0
            );
        }
        else {
            my $handler = $content_handler_for{ $node->{type} };
            $result .= defined $handler
                     ? $handler->( $node, $keywords ) : $node->{content}
            ;
        }
        $result .= ref $closing eq 'CODE' ? $closing->($node) : $closing;
    }
    return $result;
}

1; #this line is important and will help the module return a true value

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::WikiDoc - Generate Pod from inline wiki style text

=head1 VERSION

version 0.21

=head1 SYNOPSIS

In a source file, Pod format-block style:

     =begin wikidoc
 
     = POD FORMAT-BLOCK STYLE
 
     Write documentation with *bold*, ~italic~ or {code}
     markup.  Create a link to [Pod::WikiDoc].
     Substitute for user-defined %%KEYWORD%%.
 
         Indent for verbatim paragraphs
 
     * bullet
     * point
     * list
 
     0 sequentially
     0 numbered
     0 list
 
     =end wikidoc

In a source file, wikidoc comment-block style:

     ### = WIKIDOC COMMENT-BLOCK STYLE
     ###
     ### Optionally, [Pod::WikiDoc] can extract from
     ### specially-marked comment blocks

Generate Pod from wikidoc, programmatically:

     use Pod::WikiDoc;
     my $parser = Pod::WikiDoc->new( {
         comment_blocks => 1,
         keywords => { KEYWORD => "foo" },
     } );
     $parser->filter(
         { input => "my_module.pm", output => "my_module.pod" }
     );

Generate Pod from wikidoc, via command line:

     $ wikidoc -c my_module.pm my_module.pod

=head1 DESCRIPTION

Pod works well, but writing it can be time-consuming and tedious.  For example,
commonly used layouts like lists require numerous lines of text to make just
a couple of simple points.  An alternative approach is to write documentation
in a wiki-text shorthand (referred to here as I<wikidoc>) and use Pod::WikiDoc
to extract it and convert it into its corresponding Pod as a separate C<<< .pod >>>
file.

Documentation written in wikidoc may be embedded in Pod format blocks, or,
optionally, in specially marked comment blocks.  Wikidoc uses simple text-based
markup like wiki websites to indicate formatting and links.  (See
L</WIKIDOC MARKUP>, below.)

Pod::WikiDoc processes text files (or text strings) by extracting both
existing Pod and wikidoc, converting the wikidoc to Pod, and then writing
the combined document back to a file or standard output.

Summary of major features of Pod::WikiDoc:

=over

=item *

Extracts and converts wikidoc from Pod format blocks or special
wikidoc comment blocks

=item *

Extracts and preserves existing Pod

=item *

Provides bold, italic, code, and link markup

=item *

Substitutes user-defined keywords

=item *

Automatically converts special symbols in wikidoc to their
Pod escape equivalents, e.g. EE<lt>ltE<gt>, EE<lt>gtE<gt>

=item *

Preserves other Pod escape sequences, e.g. EE<lt>euroE<gt>

=back

In addition, Pod::WikiDoc provides a command-line utility, L<wikidoc>,
to simplify wikidoc translation.

See the L<Pod::WikiDoc::Cookbook> for more detailed usage examples,
including how to automate C<<< .pod >>> generation when using L<Module::Build>.

=head1 INTERFACE

=head2 C<<< new >>>

     $parser = Pod::WikiDoc->new( \%args );

Constructor for a new Pod::WikiDoc object.  It takes a single, optional
argument: a hash reference with the following optional keys:

=over

=item *

C<<< comment_blocks >>>: if true, Pod::WikiDoc will scan for wikidoc in comment
blocks.  Default is false.

=item *

C<<< comment_prefix_length >>>: the number of leading sharp (#) symbols to
denote a comment block.  Default is 3.

=item *

C<<< keywords >>>: a hash reference with keywords and values for keyword
substitution

=back

=head2 C<<< convert >>>

     my $pod_text = $parser->convert( $input_text );

Given a string with valid Pod andE<sol>or wikidoc markup, filterE<sol>translate it to
Pod.  This is really just a wrapper around C<<< filter >>> for working with
strings rather than files, and provides similar behavior, including adding
a 'Generated by' header.

=head2 C<<< filter >>>

     $parser->filter( \%args );

Filters from an input file for Pod and wikidoc, translating it to Pod
and writing it to an output file.  The output file will be prefixed with
a 'Generated by' comment with the version of Pod::WikiDoc and timestamp,
as required by L<perlpodspec>.

C<<< filter >>> takes a single, optional argument: a hash reference with
the following optional keys:

=over

=item *

C<<< input >>>: a filename or filehandle to read from. Defaults to STDIN.

=item *

C<<< output >>>: a filename or filehandle to write to.  If given a filename
and the file already exists, it will be clobbered. Defaults to STDOUT.

=back

=head2 C<<< format >>>

     my $pod_text = $parser->format( $wiki_text );

Given a string with valid Pod andE<sol>or wikidoc markup, filterE<sol>translate it to
Pod. Unlike C<<< convert >>>, no 'Generated by' comment is added.  This
function is used internally by Pod::WikiDoc, but is being made available
as a public method for users who want more granular control of the
translation process or who want to convert wikidoc to Pod for other
creative purposes using the Pod::WikiDoc engine.

=head1 WIKIDOC MARKUP

Pod::WikiDoc uses a wiki-style text markup, called wikidoc.  It is heavily
influenced by L<Kwiki>.  Like other wiki markup, it has both block and
inline elements, which map directly to their Pod equivalents.

Block elements include:

=over

=item *

Headers

=item *

Verbatim text

=item *

Bullet lists

=item *

Numbered lists

=item *

Ordinary paragraphs

=back

Block elements should be separated by a blank line (though Pod::WikiDoc
will do the right thing in many cases if you don't).

Inline elements include:

=over

=item *

Bold

=item *

Italic

=item *

Code

=item *

Link

=item *

Escape code

=item *

Keywords

=back

All text except that found in verbatim text, code markup or keywords is
transformed to convert special Pod characters to Pod escape code markup:
EE<lt>ltE<gt>, EE<lt>gtE<gt>, EE<lt>solE<gt>, EE<lt>verbarE<gt>.  Inline markup can be escaped with
a backslash (\).  Including a literal backslash requires a double-backslash
(\\).

=head2 Headers

Headers are indicated with one or more equals signs followed by whitespace in
the first column.  The number of equals signs indicates the level of the
header (the maximum is four).  Headers can not span multiple lines.

     = header level 1
 
     == header level 2

=head2 Verbatim text

Verbatim text is indicated with leading whitespace in each line of text,
just as with Pod.

     #<--- first column
 
         sub verbatim {}

=head2 Bullet lists

Bullet lists are indicated with an asterisk in the first column followed by
whitespace.  Bullet lists can span multiple lines.  Lines after the first
should not have an asterisk or be indented.

     * First item in the list
     * Second item in the list
     on multiple lines
     * Third item in the list

=head2 Numbered lists

Numbered lists work just like numbered lists, but with a leading 0 followed
by whitespace.

     0 First item in the list
     0 Second item in the list
     on multiple lines
     0 Third item in the list

=head2 Ordinary paragraphs

Ordinary paragraphs consist of one or more lines of text that do not match
the criteria of other blocks.  Paragraphs are terminated with a empty line.

     This is an ordinary paragraph that
     spans multiple lines.

=head2 Bold markup

Bold text is indicated by bracketing with asterisks.  Bold markup must
begin at a whitespace boundary, the start of a line, or the inside of
other markup.

     This shows *bold* text.

=head2 Italic markup

Italic text is indicated by bracketing with tildes.  Italic markup must
begin at a whitespace boundary, the start of a line, or the inside of
other markup.

     This shows ~italic~ text.

=head2 Code markup

Code (monospaced) text is indicated by bracketing with matched braces.  Code
markup must begin at a whitespace boundary, the start of a line, or the inside
of other markup.  Brackets should nest properly with code.

     This shows {code} text.  It can surround text
     with brackets like this: { $data{ $id } }

=head2 Link markup

Link text is indicated by bracketing with square brackets.  As with Pod, link
text may include a vertical bar to separate display text from the link itself.
Link markup must begin at a whitespace boundary, the start of a line, or the
inside of other markup.

     This is an ordinary [Pod::WikiDoc] link.
     This is a [way to ~markup~ links|Pod::WikiDoc] with display text
     Hypertext links look like this: [http://www.google.com/]

=head2 Escape code markup

Pod-style escape text is passed through as normal to support international
or other unusual characters.

     This is the euro symbol: E<euro>

=head2 Keyword markup

Text surrounded by double-percent signs is treated as a keyword for expansion.
The entire expression will be replaced with the value of the keyword from the
hash provided when the parser is created with C<<< new() >>>.  If the keyword is
unknown or the value is undefined, the keyword will be passed through
unchanged.

     This is version %%VERSION%%

=head1 DIAGNOSTICS

=over

=item *

C<<< Error: Argument to convert() must be a scalar >>>

=item *

C<<< Error: Argument to filter() must be a hash reference >>>

=item *

C<<< Error: Argument to format() must be a scalar >>>

=item *

C<<< Error: Argument to new() must be a hash reference >>>

=item *

C<<< Error: Class method new() can't be called on an object >>>

=item *

C<<< Error: Couldn't open input file 'FILENAME' >>>

=item *

C<<< Error: Couldn't open output file 'FILENAME' >>>

=item *

C<<< Error: 'input' parameter for filter() must be a filename or filehandle >>>

=item *

C<<< Error: 'output' parameter for filter() must be a filename or filehandle >>>

=back

=head1 INCOMPATIBILITIES

=over

=item *

Default prefix length for wikidoc comment-blocks conflicts with
L<Smart::Comments>.  Change the C<<< comment_prefix_length >>> argument to C<<< new >>> in
Pod::WikiDoc or the level of 'smartness' in L<Smart::Comments> to avoid the
conflict.

=back

=over

=item *

Module::Build before 0.28 does not look in external C<<< .pod >>> files
to generate a C<<< README >>> with the C<<< create_readme >>> option or to find a module
abstract.  Set the abstract manually in the C<<< Build.PL >>> file with the
C<<< dist_abstract >>> option.

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/pod-wikidoc/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/pod-wikidoc>

  git clone https://github.com/dagolden/pod-wikidoc.git

=head1 AUTHOR

David A Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords James E Keenan

James E Keenan <jkeenan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by David A Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
