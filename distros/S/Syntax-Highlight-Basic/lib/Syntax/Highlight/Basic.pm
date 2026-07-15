package Syntax::Highlight::Basic;

use 5.016;
use strict;
use warnings;

our $VERSION = '0.1.1';

use Syntax::Highlight::Basic::Parser;
use Syntax::Highlight::Basic::Output::Pygments;
use Syntax::Highlight::Basic::Output::HTML;
use Syntax::Highlight::Basic::Output::Ansi;

#===========================================================================
# Public OO Facade
#===========================================================================

sub new
{
    my ($class, %opts) = @_;

    my $self = {
        options => {
            syntax_dirs => $opts{syntax_dirs} || [],
            format      => $opts{format}      || 'html',
            wrap        => $opts{wrap}        || 0,
            css_class   => $opts{css_class},
            colors      => $opts{colors},
        },
    };

    bless $self, $class;
    return $self;
}

sub highlight
{
    my ($self, $code, $language, $opts) = @_;

    my $format    = $opts->{format} || $self->{options}{format};
    my $wrap      = exists $opts->{wrap} ? $opts->{wrap} : $self->{options}{wrap};
    my $css_class = exists $opts->{css_class} ? $opts->{css_class} : $self->{options}{css_class};
    my $colors    = exists $opts->{colors} ? $opts->{colors} : $self->{options}{colors};

    # Create parser
    my $parser = Syntax::Highlight::Basic::Parser->new(
        language    => $language,
        syntax_dirs => $self->{options}{syntax_dirs},
    );

    # Parse code into tokens
    my $tokens = $parser->parse($code);

    # Build output constructor args
    my %output_args;
    $output_args{wrap}      = $wrap if defined $wrap;
    $output_args{css_class} = $css_class if defined $css_class;
    $output_args{colors}    = $colors if defined $colors && ref $colors eq 'HASH';

    # Create output module based on format
    my $output;
    if (defined $format && $format eq 'pygments')
    {
        $output = Syntax::Highlight::Basic::Output::Pygments->new(%output_args);
    }
    elsif (defined $format && $format eq 'ansi')
    {
        $output = Syntax::Highlight::Basic::Output::Ansi->new(%output_args);
    }
    else
    {
        # Default to HTML (also catches 'html' and unknown formats)
        $output = Syntax::Highlight::Basic::Output::HTML->new(%output_args);
    }

    return $output->convert($tokens);
}

1;

__END__

=head1 NAME

Syntax::Highlight::Basic - Basic syntax highlighting for code

=head1 SYNOPSIS

    use Syntax::Highlight::Basic;

    my $shb = Syntax::Highlight::Basic->new(
        syntax_dirs => ['/path/to/custom/syntax'],
    );

    my $html = $shb->highlight($code, 'perl', { format => 'pygments' });

=head1 DESCRIPTION

Syntax::Highlight::Basic is a pure Perl library that provides basic syntax
highlighting for source code. It converts Vim syntax files into simplified
runtime data files, then uses those files to tokenize and classify code into
Vim-compatible highlight groups.

Output can be rendered as:

=over 4

=item * HTML with Pygments-compatible CSS class names

=item * HTML with inline color styles

=item * ANSI terminal color escape sequences

=back

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new Syntax::Highlight::Basic instance.

Options:

=over 4

=item C<syntax_dirs>

An array reference of directories to search for C<.shb> syntax data files.
User-supplied directories are searched before the module's built-in
C<share/syntax/> directory.

=back

=head1 METHODS

=head2 highlight($code, $language, \%opts)

Highlights the given source code.

Parameters:

=over 4

=item C<$code>

The source code string to highlight.

=item C<$language>

The programming language name (e.g., C<'perl'>, C<'python'>).  Pass C<undef>
to use the fallback tokenizer.

=item C<\%opts>

Optional hash reference with these keys:

=over 4

=item C<format>

Output format: C<'pygments'>, C<'html'>, or C<'ansi'>.

=item C<wrap>

If true, wrap the output in a container element (C<E<lt>preE<gt>E<lt>codeE<gt>>
for HTML, C<E<lt>div class="highlight"E<gt>> for Pygments).

=back

=back

Returns the highlighted string.

=head1 VERSION

0.1.0

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<Syntax::Highlight::Basic::Parser>,
L<Syntax::Highlight::Basic::Output::Pygments>,
L<Syntax::Highlight::Basic::Output::HTML>,
L<Syntax::Highlight::Basic::Output::Ansi>

=cut
