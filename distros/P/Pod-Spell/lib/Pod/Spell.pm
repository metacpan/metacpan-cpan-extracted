package Pod::Spell;
use 5.008;
use strict;
use warnings;

our $VERSION = '1.23';

sub new {
    my ( $class, %args ) = @_;

    my $no_wide_chars = delete $args{no_wide_chars};
    my $debug = exists $args{debug} ? delete $args{debug} : $ENV{PERL_POD_SPELL_DEBUG};

    my $stopwords = $args{stopwords} || do {
        require Pod::Wordlist;
        Pod::Wordlist->new(
            _is_debug => $debug,
            no_wide_chars => $no_wide_chars
        )
    };

    my $parser = Pod::Spell::_Processor->new;
    $parser->stopwords($stopwords);
    $parser->_is_debug($debug);
    $parser->output_fh(\*STDOUT);

    my %self = (
        processor => $parser,
        stopwords => $stopwords,
        debug => $debug,
    );

    bless \%self, $class
}

sub _is_debug { (shift)->{debug} ? 1 : 0; }

sub stopwords { (shift)->{stopwords} }

sub parse_from_file {
    shift->{processor}->parse_from_file(@_)
}

sub parse_from_filehandle {
    shift->{processor}->parse_from_file(@_)
}

package # Hide from indexing
    Pod::Spell::_Processor;
use parent 'Pod::Simple';

use Text::Wrap ();

__PACKAGE__->_accessorize(qw(
    stopwords
    _is_debug
));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->accept_targets('stopwords');
    return $self;
}

my %track_elements = (
    for       => 1,
    Verbatim  => 1,
    L         => 1,
    C         => 1,
    F         => 1,
);

sub _handle_element_start { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ($self, $element_name, $attr) = @_;
    $self->{buffer} = ''
        if !defined $self->{buffer};

    if ($track_elements{$element_name}) {
        push @{ $self->{in_element} }, [ $element_name, $attr ];
    }
}

sub _handle_text { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ($self, $text) = @_;

    my $in = $self->{in_element};
    if ($in && @$in) {
        my ($element_name, $attr) = @{$in->[-1]};
        ## no critic (ControlStructures::ProhibitCascadingIfElse)
        if ($element_name eq 'for' && $attr->{target_matching} eq 'stopwords') {
            # this will match both for/begin and stopwords/:stopwords

            print "Stopword para: <$text>\n"
                if $self->_is_debug;
            $self->stopwords->learn_stopwords($text);
            return;
        }
        # totally ignore verbatim sections
        elsif ($element_name eq 'Verbatim') {
            return;
        }
        elsif ($element_name eq 'L') {
            return
                if $attr->{'content-implicit'};
        }
        elsif ($element_name eq 'C' || $element_name eq 'F') {
            # maintain word boundaries
            my $pre = $text =~ s{\A\s+}{} ? ' ' : '';
            my $post = $text =~ s{\s+\z}{} ? ' ' : '';
            # if _ is joined with text before or after, it will be treated as
            # a Perl token and the entire word ignored
            $text = $pre . (length $text ? '_' : '') . $post;
        }
    }

    $self->{buffer} .= $text;
}

sub _handle_element_end { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ($self, $element_name) = @_;

    my $in = $self->{in_element};
    if ($in && @$in && $in->[-1][0] eq $element_name) {
        pop @$in;
    }

    return
        if $element_name !~ m{\A(?:Para|head\d|item-.*|over-block)\z};

    my $buffer = delete $self->{buffer};
    if (!defined $buffer || !length $buffer) {
        return;
    }

    my $fh = $self->output_fh;

    my $out = $self->stopwords->strip_stopwords($buffer);

    # maintain exact output of older Pod::Parser based implementation
    print { $fh } "\n"
        if $element_name ne 'Para';

    return
        if !length $out;

    local $Text::Wrap::huge = 'overflow'; ## no critic ( Variables::ProhibitPackageVars )
    print { $fh } Text::Wrap::wrap( '', '', $out ) . "\n\n";
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Sean M. Burke Caleb Cushing Olivier Mengué PODs virtE<ugrave> qux

=head1 NAME

Pod::Spell - a formatter for spellchecking Pod

=head1 VERSION

version 1.23

=head1 SYNOPSIS

    use Pod::Spell;
    Pod::Spell->new->parse_from_file( 'File.pm' );

    Pod::Spell->new->parse_from_filehandle( $infile, $outfile );

Also look at L<podspell>

    % perl -MPod::Spell -e "Pod::Spell->new->parse_from_file(shift)" Thing.pm |spell |fmt

...or instead of piping to spell or C<ispell>, use C<< >temp.txt >>, and open
F<temp.txt> in your word processor for spell-checking.

=head1 DESCRIPTION

Pod::Spell is a Pod formatter whose output is good for
spellchecking.  Pod::Spell is rather like L<Pod::Text>, except that
it doesn't put much effort into actual formatting, and it suppresses things
that look like Perl symbols or Perl jargon (so that your spellchecking
program won't complain about mystery words like "C<$thing>"
or "C<Foo::Bar>" or "hashref").

This class works by filtering out words that look like Perl or any
form of computerese (like "C<$thing>" or "C<< N>7 >>" or
"C<@{$foo}{'bar','baz'}>", anything in CE<lt>...E<gt> or FE<lt>...E<gt>
codes, anything in verbatim paragraphs (code blocks), and anything
in the stopword list.  The default stopword list for a document starts
out from the stopword list defined by L<Pod::Wordlist>,
and can be supplemented (on a per-document basis) by having
C<"=for stopwords"> / C<"=for :stopwords"> region(s) in a document.

=head1 METHODS

=head2 new

    Pod::Spell->new(%options)

Creates a new Pod::Spell instance. Accepts several options:

=over 4

=item debug

When set to a true value, will output debugging messages about how the Pod
is being processed.

Defaults to false.

=item stopwords

Can be specified to use an alternate wordlist instance.

Defaults to a new Pod::Wordlist instance.

=item no_wide_chars

Will be passed to Pod::Wordlist when creating a new instance. Causes all words
with characters outside the Latin-1 range to be stripped from the output.

=back

=head2 stopwords

    $self->stopwords->isa('Pod::WordList'); # true

=head2 parse_from_filehandle($in_fh,$out_fh)

This method takes an input filehandle (which is assumed to already be
opened for reading) and reads the entire input stream looking for blocks
(paragraphs) of POD documentation to be processed. If no first argument
is given the default input filehandle C<STDIN> is used.

The C<$in_fh> parameter may be any object that provides a B<getline()>
method to retrieve a single line of input text (hence, an appropriate
wrapper object could be used to parse PODs from a single string or an
array of strings).

=head2 parse_from_file($filename,$outfile)

This method takes a filename and does the following:

=over 2

=item *

opens the input and output files for reading
(creating the appropriate filehandles)

=item *

invokes the B<parse_from_filehandle()> method passing it the
corresponding input and output filehandles.

=item *

closes the input and output files.

=back

If the special input filename "", "-" or "<&STDIN" is given then the STDIN
filehandle is used for input (and no open or close is performed). If no
input filename is specified then "-" is implied. Filehandle references,
or objects that support the regular IO operations (like C<E<lt>$fhE<gt>>
or C<$fh-<Egt>getline>) are also accepted; the handles must already be
opened.

If a second argument is given then it should be the name of the desired
output file. If the special output filename "-" or ">&STDOUT" is given
then the STDOUT filehandle is used for output (and no open or close is
performed). If the special output filename ">&STDERR" is given then the
STDERR filehandle is used for output (and no open or close is
performed). If no output filehandle is currently in use and no output
filename is specified, then "-" is implied.
Alternatively, filehandle references or objects that support the regular
IO operations (like C<print>, e.g. L<IO::String>) are also accepted;
the object must already be opened.

=head1 ENCODINGS

If your Pod is encoded in something other than Latin-1, it should declare
an encoding using the L<< perlpod/C<=encoding I<encodingname>> >> directive.

=head1 ADDING STOPWORDS

You can add stopwords on a per-document basis with
C<"=for stopwords"> / C<"=for :stopwords"> regions, like so:

    =for stopwords  plok Pringe zorch   snik !qux
    foo bar baz quux quuux

This adds every word in that paragraph after "stopwords" to the
stopword list, effective for the rest of the document.  In such a
list, words are whitespace-separated.  (The amount of whitespace
doesn't matter, as long as there's no blank lines in the middle
of the paragraph.)  Plural forms are added automatically using
L<Lingua::EN::Inflect>. Words beginning with "!" are
I<deleted> from the stopword list -- so "!qux" deletes "qux" from the
stopword list, if it was in there in the first place.  Note that if
a stopword is all-lowercase, then it means that it's okay in I<any>
case; but if the word has any capital letters, then it means that
it's okay I<only> with I<that> case.  So a Wordlist entry of "perl"
would permit "perl", "Perl", and (less interestingly) "PERL", "pERL",
"PerL", et cetera.  However, a Wordlist entry of "Perl" catches
only "Perl", not "perl".  So if you wanted to make sure you said
only "Perl", never "perl", you could add this to the top of your
document:

    =for stopwords !perl Perl

Then all instances of the word "Perl" would be weeded out of the
Pod::Spell-formatted version of your document, but any instances of
the word "perl" would be left in (unless they were in a CE<lt>...> or
FE<lt>...> style).

You can have several "=for stopwords" regions in your document.  You
can even express them like so:

    =begin stopwords

    plok Pringe zorch

    snik !qux

    foo bar
    baz quux quuux

    =end stopwords

If you want to use EE<lt>...> sequences in a "stopwords" region, you
have to use ":stopwords", as here:

    =for :stopwords
    virtE<ugrave>

...meaning that you're adding a stopword of "virtE<ugrave>".  If
you left the ":" out, that would mean you were adding a stopword of
"virtEE<lt>ugrave>" (with a literal E, a literal <, etc), which
will have no effect, since  any occurrences of virtEE<lt>ugrave>
don't look like a normal human-language word anyway, and so would
be screened out before the stopword list is consulted anyway.

=head1 CAVEATS

=head2 finding stopwords defined with C<=for>

Pod::Spell makes a single pass over the POD.  Stopwords
must be added B<before> they show up in the POD.

=head1 HINT

If you feed output of Pod::Spell into your word processor and run a
spell-check, make sure you're I<not> also running a grammar-check -- because
Pod::Spell drops words that it thinks are Perl symbols, jargon, or
stopwords, this means you'll have ungrammatical sentences, what with
words being missing and all.  And you don't need a grammar checker
to tell you that.

=head1 SEE ALSO

=over 4

=item * L<Pod::Wordlist>

=item * L<Pod::Simple>

=item * L<podchecker> also known as L<Pod::Checker>

=item * L<perlpod>, L<perlpodspec>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Spell> or by email
to L<bug-Pod-Spell@rt.cpan.org|mailto:bug-Pod-Spell@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords David Golden Graham Knop Kent Fredric Mohammad S Anwar Olivier Mengué Paulo Custodio

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Paulo Custodio <pauloscustodio@gmail.com>

=back

=head1 AUTHORS

=over 4

=item *

Sean M. Burke <sburke@cpan.org>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Olivier Mengué.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
