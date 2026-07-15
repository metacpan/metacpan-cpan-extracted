package Syntax::Highlight::Basic::Output::HTML;

use 5.016;
use strict;
use warnings;

#===========================================================================
# Default color palette (based on Pygments default theme)
#===========================================================================

my %DEFAULT_COLORS = (
    # Sub-groups
    'String'         => '#4070a0',
    'Character'      => '#4070a0',
    'Number'         => '#40a070',
    'Boolean'        => '#008000',
    'Float'          => '#40a070',
    'Function'       => '#3355cc',
    'Conditional'    => '#008000',
    'Repeat'         => '#008000',
    'Label'          => '#a0a000',
    'Operator'       => '#666666',
    'Keyword'        => '#008000',
    'Exception'      => '#008000',
    'Include'        => '#bc7a00',
    'Define'         => '#bc7a00',
    'Macro'          => '#bc7a00',
    'PreCondit'      => '#bc7a00',
    'StorageClass'   => '#008000',
    'Structure'      => '#008000',
    'Typedef'        => '#008000',
    'Tag'            => '#008000',
    'SpecialChar'    => '#bb6622',
    'Delimiter'      => '#666666',
    'SpecialComment' => '#cc2222',
    'Debug'          => '#cc2222',
    # Parent groups
    'Comment'        => '#60a0b0',
    'Constant'       => '#40a070',
    'Identifier'     => '#3355cc',
    'Statement'      => '#008000',
    'PreProc'        => '#bc7a00',
    'Type'           => '#902000',
    'Special'        => '#4070a0',
    'Underlined'     => '#000080',
    'Error'          => '#ff0000',
    'Todo'           => '#60a0b0',
);

#===========================================================================
# Groups that receive font-weight: bold in addition to color
#===========================================================================

my %BOLD_GROUPS = map { $_ => 1 } qw(
    Boolean Conditional Repeat Keyword Exception StorageClass Structure Typedef Tag
    Statement
);

#===========================================================================
# Constructor
#===========================================================================

sub new
{
    my ($class, %opts) = @_;

    my %colors = %DEFAULT_COLORS;
    if (defined $opts{colors} && ref $opts{colors} eq 'HASH')
    {
        while (my ($k, $v) = each %{ $opts{colors} })
        {
            $colors{$k} = $v;
        }
    }

    my $self = {
        wrap      => $opts{wrap} || 0,
        colors    => \%colors,
        css_class => $opts{css_class} || undef,
    };

    bless $self, $class;
    return $self;
}

#===========================================================================
# convert($parse_result) — render tokens as inline-styled HTML
#===========================================================================

sub convert
{
    my ($self, $parse_result) = @_;

    my $colors = $self->{colors};
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
                my $style = _build_style($token->{class}, $token->{sub_group}, $colors);
                if ($style)
                {
                    $line_html .= '<span style="' . $style . '">' . $escaped . '</span>';
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
        if (defined $css && length $css)
        {
            return '<pre class="' . $css . '"><code>' . $result . '</code></pre>';
        }
        return '<pre><code>' . $result . '</code></pre>';
    }

    return $result;
}

#===========================================================================
# _html_escape($text) — escape HTML entities
#===========================================================================

sub _html_escape
{
    my ($text) = @_;

    my $amp  = chr(38);
    my $lt   = chr(60);
    my $gt   = chr(62);
    my $quot = chr(34);

    $text =~ s/$amp/$amp . 'amp;'/ge;
    $text =~ s/$lt/$amp . 'lt;'/ge;
    $text =~ s/$gt/$amp . 'gt;'/ge;
    $text =~ s/$quot/$amp . 'quot;'/ge;

    return $text;
}

#===========================================================================
# _resolve_color($class, $sub_group, $colors) — resolve color for a token
#===========================================================================

sub _resolve_color
{
    my ($class, $sub_group, $colors) = @_;

    # Sub-group takes priority
    if (defined $sub_group && exists $colors->{$sub_group})
    {
        return $colors->{$sub_group};
    }

    # Fall back to parent group
    if (exists $colors->{$class})
    {
        return $colors->{$class};
    }

    return '';
}

#===========================================================================
# _build_style($class, $sub_group, $colors) — build inline style attribute
#===========================================================================

sub _build_style
{
    my ($class, $sub_group, $colors) = @_;

    my $color = _resolve_color($class, $sub_group, $colors);
    return '' unless $color;

    # Determine if this token should be bold
    my $group = defined $sub_group ? $sub_group : $class;
    if (exists $BOLD_GROUPS{$group})
    {
        return 'font-weight: bold; color: ' . $color;
    }

    return 'color: ' . $color;
}

1;

__END__

=head1 NAME

Syntax::Highlight::Basic::Output::HTML - Render highlighted code as HTML with inline color styles

=head1 SYNOPSIS

    use Syntax::Highlight::Basic::Parser;
    use Syntax::Highlight::Basic::Output::HTML;

    my $parser  = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $tokens  = $parser->parse('if ($x) { print "hello"; }');

    my $output  = Syntax::Highlight::Basic::Output::HTML->new(wrap => 1);
    my $html    = $output->convert($tokens);

    # $html contains:
    # <pre><code>
    # <span style="font-weight: bold; color: #008000">if</span> ...

=head1 DESCRIPTION

Syntax::Highlight::Basic::Output::HTML converts parser token output into
HTML with inline C<style> attributes.  Each non-whitespace token is wrapped
in a C<E<lt>span style="color: #RRGGBB"E<gt>> element using colors based
on the Pygments default theme.

Groups that are typically rendered in bold (keywords, statements, types)
also receive C<font-weight: bold> in their inline style.

All text content is HTML-escaped to prevent injection.

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new Output::HTML instance.

Options:

=over 4

=item C<wrap>

If true, the output is wrapped in:

  <pre><code>...CONTENT...</code></pre>

Default: C<0> (no wrapping).

=item C<colors>

A hash reference of group name to color overrides.  Keys are Vim group
names.  Values are CSS color strings (e.g., C<#ff0000>, C<rgb(255,0,0)>).

User-provided colors take precedence over the built-in defaults.

Valid group names (sub-groups take priority over parent groups):

Sub-groups: C<String>, C<Character>, C<Number>, C<Boolean>, C<Float>,
C<Function>, C<Conditional>, C<Repeat>, C<Label>, C<Operator>, C<Keyword>,
C<Exception>, C<Include>, C<Define>, C<Macro>, C<PreCondit>, C<StorageClass>,
C<Structure>, C<Typedef>, C<Tag>, C<SpecialChar>, C<Delimiter>,
C<SpecialComment>, C<Debug>

Parent groups: C<Comment>, C<Constant>, C<Identifier>, C<Statement>,
C<PreProc>, C<Type>, C<Special>, C<Underlined>, C<Error>, C<Todo>

Example:

    my $output = Syntax::Highlight::Basic::Output::HTML->new(
        wrap   => 1,
        colors => { Comment => '#888888', Keyword => '#0000ff' },
    );

=back

=head1 METHODS

=head2 convert($parse_result)

Converts parser token output to an HTML string.

Parameter C<$parse_result> is the array reference returned by
C<Syntax::Highlight::Basic::Parser::parse()>.

Returns an HTML string with C<E<lt>spanE<gt>> elements containing inline
C<style> attributes.

=head1 COLOR MAPPING

The following default colors are used for each Vim highlight group:

=over 4

=item C<String>, C<Character>, C<Special> → C<#4070a0>

=item C<Number>, C<Float>, C<Constant> → C<#40a070>

=item C<Boolean>, C<Conditional>, C<Repeat>, C<Keyword>, C<Exception>, C<StorageClass>, C<Structure>, C<Typedef>, C<Tag>, C<Statement> → C<#008000> (bold)

=item C<Function> → C<#06287e>

=item C<Label> → C<#a0a000>

=item C<Operator>, C<Delimiter> → C<#666666>

=item C<Include>, C<Define>, C<Macro>, C<PreCondit>, C<PreProc> → C<#bc7a00>

=item C<SpecialChar> → C<#bb6622>

=item C<SpecialComment>, C<Debug> → C<#cc2222>

=item C<Comment>, C<Todo> → C<#60a0b0>

=item C<Identifier> → C<#19177c>

=item C<Type> → C<#902000>

=item C<Underlined> → C<#000080>

=item C<Error> → C<#ff0000>

=back

=head1 VERSION

0.1.0

=head1 AUTHOR

Syntax::Highlight::Basic Contributors

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
