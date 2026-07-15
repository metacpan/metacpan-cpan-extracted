package Syntax::Highlight::Basic::Output::Pygments;

use 5.016;
use strict;
use warnings;

#===========================================================================
# Vim group/sub-group to Pygments CSS class mapping
#===========================================================================

my %PYGMENTS_CLASS = (
    # Sub-groups (take priority over parent groups)
    'String'         => 's',
    'Character'      => 'sc',
    'Number'         => 'm',
    'Boolean'        => 'kc',
    'Float'          => 'mf',
    'Function'       => 'nf',
    'Conditional'    => 'k',
    'Repeat'         => 'k',
    'Label'          => 'nl',
    'Operator'       => 'o',
    'Keyword'        => 'k',
    'Exception'      => 'k',
    'Include'        => 'cp',
    'Define'         => 'cp',
    'Macro'          => 'cp',
    'PreCondit'      => 'cp',
    'StorageClass'   => 'kd',
    'Structure'      => 'k',
    'Typedef'        => 'k',
    'Tag'            => 'nt',
    'SpecialChar'    => 'se',
    'Delimiter'      => 'p',
    'SpecialComment' => 'cs',
    'Debug'          => 'cs',
    # Parent groups (used when sub_group is undef)
    'Comment'        => 'c',
    'Constant'       => 'n',
    'Identifier'     => 'n',
    'Statement'      => 'k',
    'PreProc'        => 'cp',
    'Type'           => 'kt',
    'Special'        => 'p',
    'Underlined'     => 'ge',
    'Error'          => 'err',
    'Todo'           => 'c1',
);

#===========================================================================
# Constructor
#===========================================================================

sub new
{
    my ($class, %opts) = @_;

    my $self = {
        wrap      => $opts{wrap} || 0,
        css_class => $opts{css_class} || 'highlight',
    };

    bless $self, $class;
    return $self;
}

#===========================================================================
# convert($parse_result) — render tokens as Pygments-classed HTML
#===========================================================================

sub convert
{
    my ($self, $parse_result) = @_;

    my @lines;
    for my $line_tokens (@$parse_result)
    {
        my $line_html = '';
        for my $token (@$line_tokens)
        {
            my $escaped = _html_escape($token->{text});

            if ($token->{class} eq 'whitespace' || $token->{class} eq 'text')
            {
                $line_html .= $escaped;
            }
            else
            {
                my $css = _resolve_css_class($token->{class}, $token->{sub_group});
                if ($css)
                {
                    $line_html .= '<span class="' . $css . '">' . $escaped . '</span>';
                }
                else
                {
                    $line_html .= $escaped;
                }
            }
        }
        push @lines, $line_html;
    }

    my $result = join("\n", @lines);

    if ($self->{wrap})
    {
        my $css = $self->{css_class};
        return '<div class="' . $css . '"><pre><code>' . $result . '</code></pre></div>';
    }

    return $result;
}

#===========================================================================
# _html_escape($text) — escape HTML entities
#===========================================================================

sub _html_escape
{
    my ($text) = @_;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/"/&quot;/g;

    return $text;
}

#===========================================================================
# _resolve_css_class($class, $sub_group) — map Vim group to Pygments class
#===========================================================================

sub _resolve_css_class
{
    my ($class, $sub_group) = @_;

    # Sub-group takes priority
    if (defined $sub_group && exists $PYGMENTS_CLASS{$sub_group})
    {
        return $PYGMENTS_CLASS{$sub_group};
    }

    # Fall back to parent group
    if (exists $PYGMENTS_CLASS{$class})
    {
        return $PYGMENTS_CLASS{$class};
    }

    return '';
}

1;

__END__

=head1 NAME

Syntax::Highlight::Basic::Output::Pygments - Render highlighted code as HTML with Pygments CSS classes

=head1 SYNOPSIS

    use Syntax::Highlight::Basic::Parser;
    use Syntax::Highlight::Basic::Output::Pygments;

    my $parser  = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $tokens  = $parser->parse('if ($x) { print "hello"; }');

    my $output  = Syntax::Highlight::Basic::Output::Pygments->new(wrap => 1);
    my $html    = $output->convert($tokens);

    # $html contains:
    # <div class="highlight"><pre><code>
    # <span class="k">if</span> <span class="p">(</span>...

=head1 DESCRIPTION

Syntax::Highlight::Basic::Output::Pygments converts parser token output into
HTML with Pygments-compatible CSS class names.  Each non-whitespace token is
wrapped in a C<E<lt>span class="..."E<gt>> element using the standard
Pygments CSS class names.

This enables syntax-highlighted code to be styled by any Pygments-compatible
CSS theme.

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new Output::Pygments instance.

Options:

=over 4

=item C<wrap>

If true, the output is wrapped in:

  <div class="highlight"><pre><code>...CONTENT...</code></pre></div>

Default: C<0> (no wrapping).

=back

=head1 METHODS

=head2 convert($parse_result)

Converts parser token output to an HTML string.

Parameter C<$parse_result> is the array reference returned by
C<Syntax::Highlight::Basic::Parser::parse()>.

Returns an HTML string with C<E<lt>spanE<gt>> elements.

=head1 CSS CLASS MAPPING

The following Vim highlight groups are mapped to Pygments CSS classes:

=over 4

=item C<String> → C<s>

=item C<Character> → C<sc>

=item C<Number> → C<m>

=item C<Boolean> → C<kc>

=item C<Float> → C<mf>

=item C<Function> → C<nf>

=item C<Conditional>, C<Repeat>, C<Keyword>, C<Exception>, C<Structure>, C<Typedef> → C<k>

=item C<Label> → C<nl>

=item C<Operator> → C<o>

=item C<Include>, C<Define>, C<Macro>, C<PreCondit> → C<cp>

=item C<StorageClass> → C<kd>

=item C<Tag> → C<nt>

=item C<SpecialChar> → C<se>

=item C<Delimiter> → C<p>

=item C<SpecialComment>, C<Debug> → C<cs>

=item C<Comment> → C<c>

=item C<Constant>, C<Identifier> → C<n>

=item C<Statement> → C<k>

=item C<PreProc> → C<cp>

=item C<Type> → C<kt>

=item C<Special> → C<p>

=item C<Underlined> → C<ge>

=item C<Error> → C<err>

=item C<Todo> → C<c1>

=back

=head1 VERSION

0.1.0

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<Syntax::Highlight::Basic>,
L<Syntax::Highlight::Basic::Parser>,
L<Syntax::Highlight::Basic::Output::HTML>,
L<Syntax::Highlight::Basic::Output::Ansi>

=cut
