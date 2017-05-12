package Pod::Cats;

use warnings;
use strict;
use 5.010;

use Pod::Cats::Parser::MGC;
use List::Util qw(min max);
use Carp;
use String::Util qw/crunch/;

=head1 NAME

Pod::Cats - The POD-like markup language written for podcats.in

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

POD is an expressive markup language - like Perl is an expressive programming
language - and for a plain text file format there is little finer. Pod::Cats is
an extension of the POD semantics that adds more syntax and more flexibility to
the language.

Pod::Cats is designed to be extended and doesn't implement any default
commands or entities.

=head1 SYNTAX

Pod::Cats syntax borrows ideas from POD and adds its own.

A paragraph is any block of text delimited by blank lines (whitespace ignored).
This is the same as POD, and basically allows you to use hard word wrapping in
your markup without having to join them all together for output later.

There are three command paragraphs, which are defined by their first character.
This character must be in the first column; whitespace at the start of a
paragraph is syntactically relevant.

=over 4

=item C<=COMMAND CONTENT>
X<command>

A line beginning with the C<=> symbol denotes a single I<command>. Usually this
will be some sort of header, perhaps the equivalent of a C<< <hr> >>, something
like that. It is roughly equivalent to the self-closing tag in XML. B<CONTENT>
is just text that may or may not be present. The relationship of B<CONTENT> to
the B<COMMAND> is for you to define, as is the meaning of B<COMMAND>.

When a C<=COMMAND> block is completed, it is passed to L</handle_command>.

=item C<+NAME CONTENT>
X<begin>

A line beginning with C<+> opens a named block; its name is B<NAME>. Similar to
C<=COMMAND>, the B<CONTENT> is arbitrary, and its relationship to the B<NAME> of
the block is up to you.

When this is encountered you are invited to L</handle_begin>.

=item C<-NAME>
X<end>

A line beginning with C<-> is the end of the named block previously started.
These must match in reverse order to the C<+> block with the matching B<NAME> -
basically the same as XML's <NAME></NAME> pairs. It is passed to L</handle_end>,
and unlike the other two command paragraphs it accepts no content.

=back

Then there are two types of text paragraph, for which the text is not
syntactically relevant but whitespace still is:

=over 4

=item Verbatim paragraphs

A line whose first character is whitespace is considered verbatim. No removal of
whitespace is done to the rest of the paragraph if the first character is
whitespace; all your text is repeated verbatim, hence the name

The verbatim paragraph continues until the first non-verbatim paragraph is
encountered. A blank line is no longer considered to end the paragraph.
Therefore, two verbatim paragraphs can only be separated by a non-verbatim
paragraph with non-whitespace content. The special formatting code C<< ZZ<><> >>
can be used on its own to separate them with zero-width content.

All lines in the verbatim paragraph will have their leading whitespace removed.
This is done intelligently: the I<minimum> amount of leading whitespace found on
any line is removed from all lines. This allows you to indent other lines (even
the first one) relative to the syntactic whitespace that defines the verbatim
paragraph without your indentation being parsed out.

L</Entities> are not parsed in verbatim paragraphs, as expected.

When a verbatim paragraph has been collated, it is passed to L</handle_verbatim>.

=item Paragraphs

Everything that doesn't get caught by one of the above rules is deemed to be a
plain text paragraph. As with all paragraphs, a single line break is removed by
the parser and a blank line causes the paragraph to be processed. It is passed
to L</handle_paragraph>.

=back

And finally the inline formatting markup, entities.

=over

=item C<< XZ<><> >>
X<entity> X<entities>

An entity is defined as a capital letter followed by a delimiter that is
repeated n times, then any amount of text up to a matching quantity of a
balanced delimiter.

In normal POD the only delimiter is C<< < >>, so entities have the format C<<
XZ<><> >>; except that the opening delimiter may be duplicated as long as the
closing delimiter matches, allowing you to put the delimiter itself inside the
entity: C<<< XZ<><<>> >>>; in Pod::Cats you can use any delimiter, removing the
requirement to duplicate it at all: C<< C[ XZ<><> ] >>.

Once an entity has begun, nested entities are only considered if the delimiters
are the same as those used for the outer entity: C<< B[ I[bold-italic] ] >>;
C<< B[IZ<><bold>] >>.

Apart from the special entity C<< ZZ<><> >>, the letter used for the entity has
no inherent meaning to Pod::Cats. The parsed entity is provided to
L</handle_entity>. C<< ZZ<><> >> retains its meaning from POD, which is to be a
zero-width 'divider' to break up things that would otherwise be considered
syntax. You are not given C<< ZZ<><> >> to handle, and C<< ZZ<><> >> itself will
produce undef if it is the only content to an element. A paragraph comprising solely
C<< ZZ<><> >> will never generate a parsed paragraph; it will be skipped.

=back

=head1 METHODS

=cut

our $VERSION = '0.08';

=head2 new

Create a new parser. Options are provided as a hashref, but there is currently
only one:

=over

=item delimiters

A string containing delimiters to use. Bracketed delimiters will be balanced;
other delimiters will simply be used as-is. This echoes the delimiter philosophy
of Perl syntax such as regexes and C<q{}>. The string should be all the possible
delimiters, listed once each, and only the opening brackets of balanced pairs.

The default is C<< '<' >>, same as POD.

=back

=cut

sub new {
    my $class = shift;
    my $opts = shift || {};
    my $self = bless $opts, $class; # FIXME

    return $self;
}

=head2 parse

Parses a string containing whatever Pod::Cats code you have.

=cut

sub parse {
    my ($self, $string) = @_;

    return $self->parse_lines(split /\n/, $string);
}

=head2 parse_file

Opens the file given by filename and reads it all in and then parses that.

=cut

sub parse_file {
    my ($self, $filename) = @_;

    carp "File not found: " . $filename unless -e $filename;

    open my $fh, "<", $filename;
    chomp(my @lines = <$fh>);
    close $fh;

    return $self->parse_lines(@lines);
}

=head2 parse_lines

L</parse> and L</parse_file> both come here, which just takes the markup text
as an array of lines and parses them. This is where the logic happens. It is
exposed publicly so you can parse an array of your own if you want.

=cut

sub parse_lines {
    my ($self, @lines) = @_;

    my $result = "";
    $self->_new_buffer;

    # Special lines are:
    #  - a blank line. An exception is between verbatim paragraphs, so we will
    #    simply re-merge verbatim paras later on
    #  - A line starting with =, + or -. Command paragraph. Process the previous
    #    buffer and start a new one with this.
    #  - Anything else continues the previous buffer, or starts a normal paragraph

    my $line_num = @lines;
    shift @lines while $lines[0] !~ /\S/; # shift off leading blank lines!

    # Adjust for lines we removed.
    $line_num = $line_num - @lines;

    my $original_warn = $SIG{__WARN__} || sub { warn $_[0] };
    local $SIG{__WARN__} = sub {
        my $warning = shift;
        $warning =~ s/at .+/at line $line_num/;
        $original_warn->($warning);
    };

    for my $line (@lines) {
        $line_num++;

        for ($line) {
            if (/^\s*$/) {
                $self->_handle_blank_line;
            }
            elsif (/^([=+-])/) {
                my $type = $1;
                my $buftype = {
                    '+' => 'begin',
                    '-' => 'end',
                    '=' => 'command',
                }->{$type};

                # First word is command name; rest is buffer.
                my ($command, $buffer) = $line =~ /^\Q$type\E(\w+)\s*(.*)$/;

                $self->_handle_command_line($buftype, $command);
                $self->_buffer($buffer);
            }
            elsif (/^\s+\S/) {
                $self->_handle_verbatim_line($line);
            }
            else {
                $self->_handle_normal_line($line);
            }
        }
    }

    $self->_end_of_line;
}

sub _buffer {
    my $self = shift;
    push @{ $self->{buffer} }, @_;
}

sub _new_buffer {
    my $self = shift;
    # The buffer type goes in the first element, and its
    # contents, if any, in the rest.
    $self->{buffer} = [];
}

sub _end_previous_buffer {
    my $self = shift;
    return unless $self->_buftype;

    if ($self->_buftype eq 'verbatim') {
        warn "Verbatim paragraph ended without blank line"
            if $self->{buffer}->[-1] =~ /\S/;

        $self->_process_buffer;
        return
    }

    warn $self->_buftype . " ended without blank line";
    $self->_process_buffer;

    return 0;
}

sub _handle_blank_line {
    my $self = shift;
    return unless $self->_buftype;

    # Handle a verbatim buffer when a different buffer starts, or we run out of
    # lines.
    if ($self->_buftype eq 'verbatim') {
        $self->_buffer('');
        return;
    }

    $self->_process_buffer;
}

sub _handle_command_line {
    my $self = shift;
    my $type = shift;
    my $command = shift;

    $self->_end_previous_buffer;

    $self->_buffer($type, $command);
}

# Verbatim lines just get buffered until something else happens.
sub _handle_verbatim_line {
    my $self = shift;

    if ($self->_buftype ne 'verbatim') {
        $self->_end_previous_buffer;
        $self->_buffer('verbatim');
    }
    $self->_buffer(@_);
}

sub _handle_normal_line {
    my $self = shift;
    my $line = shift;

    # Nothing special, continue previous buffer or start a paragraph.
    if ($self->_buftype eq 'verbatim') {
        $self->_end_previous_buffer;
    }

    if (not $self->_buftype) {
        $self->_buffer('paragraph');
    }

    $self->_buffer($line);
}

sub _buftype {
    my $self = shift;
    if (@{ $self->{buffer} }) {
        return $self->{buffer}->[0];
    }
    return '';
}

sub _end_of_line {
    my $self = shift;
    $self->_process_buffer;
}

sub _process_buffer {
    my $self = shift;

    return '' unless $self->_buftype;

    my @buffer = @{$self->{buffer}};

    for (shift @buffer) {
        if($_ eq 'paragraph') {
            # concatenate the lines and normalise whitespace.
            my $para = crunch(join " ", @buffer);
            $self->handle_paragraph($self->_process_entities($para));
            $self->_new_buffer;
        }
        elsif($_ eq 'verbatim') {
            # There will have been a warning if this is not the empty string
            pop @buffer if $buffer[-1] eq '';

            # find the lowest level of indentation in this buffer and strip it
            # Avoid zeroes from blank lines in between
            my $indent_level = min map { /^(\s*)/; length $1 || () } @buffer;
            s/^\s{$indent_level}// for @buffer;

            my $para = join "\n", @buffer;
            $self->handle_verbatim($para);
        }
        elsif($_ eq 'command' || $_ eq 'begin') {
            my $type = shift @buffer;
            my $content = crunch(join " ", @buffer);
            $self->${\"handle_$_"}($type, $self->_process_entities($content));
        }
        elsif($_ eq 'end') {
            $self->handle_end($buffer[0]);
        }
    }

    $self->_new_buffer;
}

=head2 handle_verbatim

The verbatim paragraph as it was in the code, except with the minimum amount of
whitespace stripped from each line as described in L<Verbatim paragraphs|/verbatim>.
Passed in as a single string with line breaks preserved.

Do whatever you want. Default is to return the string straight back atcha.

=cut

sub handle_verbatim {
    shift;
    shift;
}

=head2 handle_entity

Passed the letter of the L<entity|/entity> as the first argument and its content
as the rest of @_. The content will alternate between plain text and the return
value of this function for any nested entities inside this one.

For this reason you should return a scalar from this method, be it text or a
ref. The default is to concatenate @_, thus replacing entities with their
contents.

Note that this method is the only one whose return value is of relevance to the
parser, since what you return from this will appear in another handler,
depending on what type of paragraph the entity is in.

You will never get the C<< ZZ<><> >> entity.

=cut

sub handle_entity {
    shift; shift;
    join ' ', map $_ // '', @_;
}

# preprocess paragraph before giving it to the user. handle_entity is called
# from the parser itself.
sub _process_entities {
    my ($self, $para) = @_;

    # 1. replace POD-like Z<...> with user-defined functions.
    # Z itself is the only actual exception to that.
    $self->{parser} ||= Pod::Cats::Parser::MGC->new(
        object => $self,
        delimiters => $self->{delimiters} // '<'
    );

    my $parsed = $self->{parser}->from_string( $para );

    # Single return of undef was Z<>
    return defined $parsed->[0] || @$parsed > 1 ? @$parsed : ();
}

=head2 handle_paragraph

The paragraph is split into sections that alternate between plain text and the
return values of L<handle_entity|/handle_entity> as described above. These
sections are arrayed in @_. Note that the paragraph could start with an entity.

By default it returns @_ concatenated, since the default behaviour of
L<handle_entity|/handle_entity> is to remove the formatting but keep the
contents.

=cut

sub handle_paragraph {
    shift; join ' ', map $_ // '', @_;
}

=head2 handle_command

When a L<command|/command> is encountered it comes here. The first argument is
the B<COMMAND> (from B<=COMMAND>); the rest of the arguments follow the rules of
L<paragraphs|handle_paragraph> and alternate between plain text and parsed
entities.

By default it returns @_ concatenated, same as paragraphs.

=cut

sub handle_command {
    shift; shift; join ' ', map $_ // '', @_;
}

=head2 handle_begin

This is handled the same as L<handle_command|/handle_command>, except it is
called when a L<begin|/begin> command is encountered. The same rules apply.

=cut

sub handle_begin {
    shift; shift; join ' ', map $_ // '', @_;
}

=head2 handle_end

The counterpart to the begin handler. This is called when the L</end> paragraph
is encountered. The parser will already have discovered whether your begins and
ends are not balanced so you don't need to worry about that.

Note that there is no content for an end paragraph so the only argument this
gets is the command name.

=cut

sub handle_end { }

=head1 TODO

=over

=item The document is parsed into DOM, then events are fired SAX-like.
Preferable to fire the events and build the DOM from that.

=item Currently the matching of begin/end commands is a bit naive.

=item Line numbers of errors are not yet reported.

=back

=head1 AUTHOR

Altreus, C<< <altreus at perl.org> >>

=head1 BUGS

Bug reports to github please: http://github.com/Altreus/Pod-Cats/issues

=head1 SUPPORT

You are reading the only documentation for this module.

For more help, give me a holler on irc.freenode.com #perl

=head1 ACKNOWLEDGEMENTS

Paul Evans (LeoNerd) basically wrote Parser::MGC because I was whining about not
being able to parse these entity delimiters with any of the token parsers I
could find; and then he wrote a POD example that I only had to tweak in order to
do so. So a lot of the credit should go to him!

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Altreus.

This module is released under the MIT licence.

=cut

1;
