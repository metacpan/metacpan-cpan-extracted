package Syntax::Highlight::Basic::Output::Ansi;

use 5.016;
use strict;
use warnings;

#===========================================================================
# ANSI 256-color palette (approximating Pygments default theme)
#===========================================================================

my %ANSI_COLORS = (
    # Sub-groups
    'String'         => { color => 67,  bold => 0 },    # blue-ish
    'Character'      => { color => 67,  bold => 0 },
    'Number'         => { color => 71,  bold => 0 },    # green-ish
    'Boolean'        => { color => 28,  bold => 1 },    # green bold
    'Float'          => { color => 71,  bold => 0 },
    'Function'       => { color => 33,  bold => 0 },    # light blue
    'Conditional'    => { color => 28,  bold => 1 },    # green bold
    'Repeat'         => { color => 28,  bold => 1 },
    'Label'          => { color => 136, bold => 0 },    # olive
    'Operator'       => { color => 102, bold => 0 },    # gray
    'Keyword'        => { color => 28,  bold => 1 },
    'Exception'      => { color => 28,  bold => 1 },
    'Include'        => { color => 130, bold => 0 },    # brown
    'Define'         => { color => 130, bold => 0 },
    'Macro'          => { color => 130, bold => 0 },
    'PreCondit'      => { color => 130, bold => 0 },
    'StorageClass'   => { color => 28,  bold => 1 },
    'Structure'      => { color => 28,  bold => 1 },
    'Typedef'        => { color => 28,  bold => 1 },
    'Tag'            => { color => 28,  bold => 1 },
    'SpecialChar'    => { color => 130, bold => 1 },    # brown bold
    'Delimiter'      => { color => 102, bold => 0 },
    'SpecialComment' => { color => 160, bold => 1 },    # red bold
    'Debug'          => { color => 160, bold => 1 },
    # Parent groups
    'Comment'        => { color => 73,  bold => 0 },    # teal
    'Constant'       => { color => 71,  bold => 0 },
    'Identifier'     => { color => 33,  bold => 0 },    # light blue
    'Statement'      => { color => 28,  bold => 1 },
    'PreProc'        => { color => 130, bold => 0 },
    'Type'           => { color => 88,  bold => 0 },    # dark red
    'Special'        => { color => 67,  bold => 0 },
    'Underlined'     => { color => 4,   bold => 0 },    # blue
    'Error'          => { color => 196, bold => 0 },    # bright red
    'Todo'           => { color => 73,  bold => 0 },
);

#===========================================================================
# Constructor
#===========================================================================

sub new
{
    my ($class, %opts) = @_;

    my %colors = %ANSI_COLORS;
    if (defined $opts{colors} && ref $opts{colors} eq 'HASH')
    {
        while (my ($k, $v) = each %{ $opts{colors} })
        {
            $colors{$k} = $v;
        }
    }

    my $self = {
        colors => \%colors,
    };

    bless $self, $class;
    return $self;
}

#===========================================================================
# convert($parse_result) — render tokens with ANSI escape codes
#===========================================================================

sub convert
{
    my ($self, $parse_result) = @_;

    my $colors = $self->{colors};
    my @lines;

    for my $line_tokens (@$parse_result)
    {
        my $line_str = '';
        for my $token (@$line_tokens)
        {
            if ($token->{class} eq 'whitespace' || $token->{class} eq 'text')
            {
                $line_str .= $token->{text};
            }
            else
            {
                my $entry = _resolve_ansi_color($token->{class}, $token->{sub_group}, $colors);
                if ($entry)
                {
                    if ($entry->{bold})
                    {
                        $line_str .= "\e[1;38;5;" . $entry->{color} . "m"
                            . $token->{text} . "\e[0m";
                    }
                    else
                    {
                        $line_str .= "\e[38;5;" . $entry->{color} . "m"
                            . $token->{text} . "\e[0m";
                    }
                }
                else
                {
                    $line_str .= $token->{text};
                }
            }
        }
        push @lines, $line_str;
    }

    return join("\n", @lines);
}

#===========================================================================
# _resolve_ansi_color($class, $sub_group, $colors) — resolve ANSI color entry
#===========================================================================

sub _resolve_ansi_color
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

    return undef;
}

1;

__END__

=head1 NAME

Syntax::Highlight::Basic::Output::Ansi - Render highlighted code with ANSI terminal colors

=head1 SYNOPSIS

    use Syntax::Highlight::Basic::Parser;
    use Syntax::Highlight::Basic::Output::Ansi;

    my $parser  = Syntax::Highlight::Basic::Parser->new(language => 'perl');
    my $tokens  = $parser->parse('if ($x) { print "hello"; }');

    my $output  = Syntax::Highlight::Basic::Output::Ansi->new();
    my $string  = $output->convert($tokens);

    print $string;  # outputs ANSI-colored text to terminal

=head1 DESCRIPTION

Syntax::Highlight::Basic::Output::Ansi converts parser token output into
a string with embedded ANSI 256-color escape codes.  Each non-whitespace
token is wrapped in C<\e[38;5;NNNm> ... C<\e[0m> sequences.

Bold groups (keywords, statements, types) use C<\e[1;38;5;NNNm> to
combine bold with color.

No HTML escaping is needed since the output is intended for terminal
display.

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new Output::Ansi instance.

Options:

=over 4

=item C<colors>

A hash reference of group name to color entry overrides.  Keys are Vim
group names.  Values are hash references with two fields:

=over 4

=item C<color> — ANSI 256-color index (0–255)

=item C<bold> — 1 for bold, 0 for normal weight

=back

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

    my $output = Syntax::Highlight::Basic::Output::Ansi->new(
        colors => {
            Comment => { color => 245, bold => 0 },
            Keyword => { color => 33,  bold => 1 },
        },
    );

=back

=head1 METHODS

=head2 convert($parse_result)

Converts parser token output to an ANSI-colored string.

Parameter C<$parse_result> is the array reference returned by
C<Syntax::Highlight::Basic::Parser::parse()>.

Returns a string with embedded ANSI escape codes suitable for terminal
display.

=head1 COLOR MAPPING

The following default ANSI 256-color indices are used:

=over 4

=item C<String>, C<Character>, C<Special> → 67 (blue-ish)

=item C<Number>, C<Float>, C<Constant> → 71 (green-ish)

=item C<Boolean>, C<Conditional>, C<Repeat>, C<Keyword>, C<Exception>, C<StorageClass>, C<Structure>, C<Typedef>, C<Tag>, C<Statement> → 28 bold (green bold)

=item C<Function> → 33 (light blue)

=item C<Label> → 136 (olive)

=item C<Operator>, C<Delimiter> → 102 (gray)

=item C<Include>, C<Define>, C<Macro>, C<PreCondit>, C<PreProc> → 130 (brown)

=item C<SpecialChar> → 130 bold (brown bold)

=item C<SpecialComment>, C<Debug> → 160 bold (red bold)

=item C<Comment>, C<Todo> → 73 (teal)

=item C<Identifier> → 33 (light blue)

=item C<Type> → 88 (dark red)

=item C<Underlined> → 4 (blue)

=item C<Error> → 196 (bright red)

=back

=head1 VERSION

0.1.0

=head1 AUTHOR

Syntax::Highlight::Basic Contributors

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
