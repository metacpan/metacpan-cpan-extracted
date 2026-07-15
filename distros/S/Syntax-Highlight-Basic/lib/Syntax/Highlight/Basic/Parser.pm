package Syntax::Highlight::Basic::Parser;

use 5.016;
use strict;
use warnings;

use File::ShareDir qw(dist_dir);
use File::Basename qw(dirname);
use File::Spec;

#===========================================================================
# Vim sub-group to parent group mapping
#===========================================================================

my %SUB_GROUP_PARENT = (
    String         => 'Constant',
    Character      => 'Constant',
    Number         => 'Constant',
    Boolean        => 'Constant',
    Float          => 'Constant',
    Function       => 'Identifier',
    Conditional    => 'Statement',
    Repeat         => 'Statement',
    Label          => 'Statement',
    Operator       => 'Statement',
    Keyword        => 'Statement',
    Exception      => 'Statement',
    Include        => 'PreProc',
    Define         => 'PreProc',
    Macro          => 'PreProc',
    PreCondit      => 'PreProc',
    StorageClass   => 'Type',
    Structure      => 'Type',
    Typedef        => 'Type',
    Tag            => 'Special',
    SpecialChar    => 'Special',
    Delimiter      => 'Special',
    SpecialComment => 'Special',
    Debug          => 'Special',
);

my %PARENT_GROUPS = map { $_ => 1 } qw(
    Comment Constant Identifier Statement PreProc Type Special
    Underlined Ignore Error Todo
);

#===========================================================================
# Fallback tokenizer rules
#===========================================================================

my @FALLBACK_REGIONS = (
    { class => 'Constant', sub_group => 'String', start => '"', end => '"', escape => '\\' },
    { class => 'Constant', sub_group => 'String', start => "'", end => "'", escape => '\\' },
);

my @FALLBACK_MATCHES = (
    { class => 'Constant', sub_group => 'Number',
      pattern => qr/\b(?:0x[0-9a-fA-F]+|0b[01]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b/ },
    { class => 'Special', sub_group => 'Delimiter',
      pattern => qr/[{}()\[\];,.<>+\-*\/=!&|^~?:%]+/ },
);

#===========================================================================
# Constructor
#===========================================================================

sub new
{
    my ($class, %opts) = @_;

    my $self = {
        language    => $opts{language},
        syntax_dirs => $opts{syntax_dirs} || [],
        keywords    => {},
        matches     => [],
        regions     => [],
        case_fold   => 0,
        fallback    => 0,
    };

    bless $self, $class;

    # Resolve language name via Pygments mapping if needed
    my $lang = $self->{language};
    if (defined $lang)
    {
        $lang = _resolve_pygments_name($lang);
    }

    # Find and load the .shb file
    my $shb_file = _find_shb_file($lang, $self->{syntax_dirs});
    if ($shb_file)
    {
        _load_shb_file($self, $shb_file);
    }
    else
    {
        $self->{fallback} = 1;
        $self->{regions} = \@FALLBACK_REGIONS;
        $self->{matches} = \@FALLBACK_MATCHES;
    }

    return $self;
}

#===========================================================================
# parse($code) — tokenize source code
#===========================================================================

sub parse
{
    my ($self, $code) = @_;

    my @lines = split /\n/, $code, -1;
    my $result = [];
    my $current_region = undef;

    for my $line (@lines)
    {
        my $tokens = [];
        my $pos    = 0;
        my $len    = length($line);

        while ($pos < $len)
        {
            my $remaining = substr($line, $pos);

            # If we are inside a multi-line region, look for the end
            if (defined $current_region)
            {
                my $end_pos = _find_region_end($remaining, $current_region);
                if (defined $end_pos)
                {
                    my $end_len = length($current_region->{end});
                    my $text    = substr($remaining, 0, $end_pos + $end_len);
                    push @$tokens, {
                        class     => $current_region->{class},
                        sub_group => $current_region->{sub_group},
                        text      => $text,
                    };
                    $pos            += $end_pos + $end_len;
                    $current_region  = undef;
                }
                else
                {
                    push @$tokens, {
                        class     => $current_region->{class},
                        sub_group => $current_region->{sub_group},
                        text      => $remaining,
                    };
                    $pos = $len;
                }
                next;
            }

            # Match whitespace
            if ($remaining =~ /^(\s+)/)
            {
                push @$tokens, { class => 'whitespace', sub_group => undef, text => $1 };
                $pos += length($1);
                next;
            }

            # Try to find the best match
            my $best = _find_best_match($self, $remaining, $line, $pos);

            if (defined $best)
            {
                push @$tokens, {
                    class     => $best->{class},
                    sub_group => $best->{sub_group},
                    text      => $best->{text},
                };
                $pos += length($best->{text});

                if ($best->{open_region})
                {
                    $current_region = $best->{open_region};
                }
            }
            else
            {
                # No match — consume one character
                push @$tokens, { class => 'text', sub_group => undef, text => substr($remaining, 0, 1) };
                $pos += 1;
            }
        }

        $tokens = _merge_text_tokens($tokens);
        push @$result, $tokens;
    }

    return $result;
}

#===========================================================================
# _find_best_match — find the best token match at the current position
#===========================================================================

sub _find_best_match
{
    my ($self, $remaining, $line, $pos) = @_;

    my $best       = undef;
    my $best_len   = 0;
    my $best_prio  = 0;    # 3 = region, 2 = match, 1 = keyword

    # Try region starts (priority 3)
    for my $region (@{$self->{regions}})
    {
        my $start = $region->{start};
        if (substr($remaining, 0, length($start)) eq $start)
        {
            my $after_start = substr($remaining, length($start));
            my $end_pos     = _find_region_end($after_start, $region);

            if (defined $end_pos)
            {
                my $end_len = length($region->{end});
                my $text    = $start . substr($after_start, 0, $end_pos + $end_len);
                my $len     = length($text);
                if ($len > $best_len || ($len == $best_len && 3 > $best_prio))
                {
                    $best      = { class => $region->{class}, sub_group => $region->{sub_group}, text => $text, open_region => undef };
                    $best_len  = $len;
                    $best_prio = 3;
                }
            }
            else
            {
                # Region spans to end of line
                my $len = length($remaining);
                if ($len > $best_len || ($len == $best_len && 3 > $best_prio))
                {
                    $best      = { class => $region->{class}, sub_group => $region->{sub_group}, text => $remaining, open_region => $region };
                    $best_len  = $len;
                    $best_prio = 3;
                }
            }
        }
    }

    # Try match patterns (priority 2)
    for my $match (@{$self->{matches}})
    {
        if ($remaining =~ /^($match->{pattern})/)
        {
            my $text = $1;
            my $len  = length($text);
            if ($len > $best_len || ($len == $best_len && 2 > $best_prio))
            {
                $best      = { class => $match->{class}, sub_group => $match->{sub_group}, text => $text, open_region => undef };
                $best_len  = $len;
                $best_prio = 2;
            }
        }
    }

    # Try keyword matching (priority 1)
    # Must be a whole word — check word boundaries before and after
    my $at_word_start = ($pos == 0 || substr($line, $pos - 1, 1) !~ /\w/);
    if ($at_word_start && $remaining =~ /^(\w+)(?:\W|\z)/)
    {
        my $word = $1;
        my $lookup = $self->{case_fold} ? lc($word) : $word;
        for my $parent (keys %{$self->{keywords}}) {
            for my $sub (keys %{$self->{keywords}{$parent}}) {
                if (exists $self->{keywords}{$parent}{$sub}{$lookup})
                {
                    my $len = length($word);
                    if ($len > $best_len || ($len == $best_len && 1 > $best_prio))
                    {
                        $best      = { class => $parent, sub_group => ($sub eq '_' ? undef : $sub), text => $word, open_region => undef };
                        $best_len  = $len;
                        $best_prio = 1;
                    }
                }
            }
        }
    }

    return $best;
}

#===========================================================================
# _find_region_end — find the end delimiter in a string, respecting escapes
#===========================================================================

sub _find_region_end
{
    my ($str, $region) = @_;

    my $end    = $region->{end};
    my $escape = $region->{escape};
    my $end_len = length($end);
    my $pos     = 0;

    while ($pos <= length($str) - $end_len)
    {
        if (defined $escape)
        {
            # Check for escape character
            if (substr($str, $pos, 1) eq $escape)
            {
                $pos += 2;    # skip escape + next char
                next;
            }
        }

        if (substr($str, $pos, $end_len) eq $end)
        {
            return $pos;
        }
        $pos++;
    }

    return undef;
}

#===========================================================================
# _merge_text_tokens — merge consecutive 'text' tokens
#===========================================================================

sub _merge_text_tokens
{
    my ($tokens) = @_;

    my @merged;
    for my $token (@$tokens)
    {
        if (@merged && $merged[-1]{class} eq 'text' && $token->{class} eq 'text')
        {
            $merged[-1]{text} .= $token->{text};
        }
        else
        {
            push @merged, $token;
        }
    }

    return \@merged;
}

#===========================================================================
# _load_shb_file — parse a .shb file and populate the parser data structures
#===========================================================================

sub _load_shb_file
{
    my ($self, $path) = @_;

    open(my $fh, '<', $path) or die "Cannot open $path: $!";

    my $section = undef;
    my $keywords = {};
    my @matches;
    my @regions;

    while (my $line = <$fh>)
    {
        chomp $line;
        $line =~ s/\s+$//;

        # Skip comments and blank lines
        next if $line =~ /^\s*#/;
        next if $line =~ /^\s*$/;

        # Header lines
        if ($line =~ /^language:\s*(.+)/i)
        {
            next;
        }
        if ($line =~ /^extensions:\s*(.+)/i)
        {
            next;
        }
        if ($line =~ /^case:\s*ignore/i)
        {
            $self->{case_fold} = 1;
            next;
        }

        # Section headers
        if ($line =~ /^\[keyword:(.+)\]/i)
        {
            $section = { type => 'keyword', group => $1 };
            next;
        }
        if ($line =~ /^\[match:(.+)\]/i)
        {
            $section = { type => 'match', group => $1 };
            next;
        }
        if ($line =~ /^\[region:(.+)\]/i)
        {
            $section = { type => 'region', group => $1 };
            next;
        }

        # Section content
        if (defined $section)
        {
            if ($section->{type} eq 'keyword')
            {
                my @words = split /\s+/, $line;
                my ($parent, $sub) = _resolve_group($section->{group});
                $sub //= '_';
                for my $word (@words)
                {
                    next unless length($word);
                    my $key = $self->{case_fold} ? lc($word) : $word;
                    $keywords->{$parent}{$sub}{$key} = 1;
                }
            }
            elsif ($section->{type} eq 'match')
            {
                if ($line =~ /^pattern:\s*(.+)/i)
                {
                    my $pattern = $1;
                    my $flags   = $self->{case_fold} ? 'i' : '';
                    my $compiled;
                    if ($flags)
                    {
                        $compiled = eval { qr/(?$flags:$pattern)/ };
                    }
                    else
                    {
                        $compiled = eval { qr/$pattern/ };
                    }
                    if ($compiled)
                    {
                        my ($parent, $sub) = _resolve_group($section->{group});
                        push @matches, { class => $parent, sub_group => $sub, pattern => $compiled };
                    }
                }
            }
            elsif ($section->{type} eq 'region')
            {
                if ($line =~ /^start:\s*(.+)/i)
                {
                    $section->{start} = $1;
                }
                elsif ($line =~ /^end:\s*(.+)/i)
                {
                    $section->{end} = $1;
                }
                elsif ($line =~ /^escape:\s*(.+)/i)
                {
                    $section->{escape} = $1;
                }

                # If we have both start and end, add the region
                if (defined $section->{start} && defined $section->{end})
                {
                    my ($parent, $sub) = _resolve_group($section->{group});
                    push @regions, {
                        class     => $parent,
                        sub_group => $sub,
                        start     => $section->{start},
                        end       => $section->{end},
                        escape    => $section->{escape},
                    };
                    # Reset for next region in same section
                    delete $section->{start};
                    delete $section->{end};
                    delete $section->{escape};
                }
            }
        }
    }
    close $fh;

    $self->{keywords} = $keywords;
    $self->{matches}  = \@matches;
    $self->{regions}  = \@regions;
}

#===========================================================================
# _find_shb_file — locate a .shb file for the given language
#===========================================================================

sub _find_shb_file
{
    my ($language, $syntax_dirs) = @_;

    return undef unless defined $language;

    my $filename = lc($language) . '.shb';

    # Search user-supplied directories first
    for my $dir (@$syntax_dirs)
    {
        my $path = File::Spec->catfile($dir, $filename);
        return $path if -f $path;
    }

    # Search built-in share directory via File::ShareDir
    my $found;
    eval {
        my $share_dir = dist_dir('Syntax-Highlight-Basic');
        my $path = File::Spec->catfile($share_dir, 'syntax', $filename);
        $found = $path if -f $path;
    };
    return $found if defined $found;

    # Development fallback: search relative to this file
    my $dev_dir = _find_dev_share_dir();
    if ($dev_dir)
    {
        my $path = File::Spec->catfile($dev_dir, $filename);
        return $path if -f $path;
    }

    return undef;
}

#===========================================================================
# _find_dev_share_dir — find share/syntax/ during development
#===========================================================================

sub _find_dev_share_dir
{
    my $dir = dirname(__FILE__);
    for (1 .. 6)
    {
        my $share = File::Spec->catdir($dir, 'share', 'syntax');
        return $share if -d $share;
        $dir = dirname($dir);
    }
    return undef;
}

#===========================================================================
# _resolve_group — resolve a Vim group name to (parent, sub_group)
#===========================================================================

sub _resolve_group
{
    my ($group_name) = @_;

    # Check if it's a known sub-group
    if (exists $SUB_GROUP_PARENT{$group_name})
    {
        return ($SUB_GROUP_PARENT{$group_name}, $group_name);
    }

    # Check if it's a known parent group
    if (exists $PARENT_GROUPS{$group_name})
    {
        return ($group_name, undef);
    }

    # Unknown — treat as a parent group
    return ($group_name, undef);
}

#===========================================================================
# _resolve_pygments_name — resolve Pygments alias to Vim language name
#===========================================================================

my $_pygments_map = undef;

sub _resolve_pygments_name
{
    my ($name) = @_;

    return $name unless defined $name;

    my $lc_name = lc($name);

    # Load the mapping table lazily
    if (!defined $_pygments_map)
    {
        $_pygments_map = {};
        my $map_file = _find_pygments_map();
        if ($map_file && open(my $fh, '<', $map_file))
        {
            while (my $line = <$fh>)
            {
                chomp $line;
                $line =~ s/\s+$//;
                next if $line =~ /^\s*#/;
                next if $line =~ /^\s*$/;
                my ($alias, $vim_name) = split /\s+/, $line, 2;
                next unless $alias && $vim_name;
                $_pygments_map->{lc($alias)} = lc($vim_name);
            }
            close $fh;
        }
    }

    return $_pygments_map->{$lc_name} || $name;
}

#===========================================================================
# _find_pygments_map — locate the pygments-languages.txt file
#===========================================================================

sub _find_pygments_map
{
    # Search built-in share directory via File::ShareDir
    my $found;
    eval {
        my $share_dir = dist_dir('Syntax-Highlight-Basic');
        my $path = File::Spec->catfile($share_dir, 'pygments-languages.txt');
        $found = $path if -f $path;
    };
    return $found if defined $found;

    # Development fallback
    my $dir = dirname(__FILE__);
    for (1 .. 6)
    {
        my $path = File::Spec->catdir($dir, 'share', 'pygments-languages.txt');
        return $path if -f $path;
        $dir = dirname($dir);
    }

    return undef;
}

1;

__END__

=head1 NAME

Syntax::Highlight::Basic::Parser - Tokenize source code for syntax highlighting

=head1 SYNOPSIS

    use Syntax::Highlight::Basic::Parser;

    my $parser = Syntax::Highlight::Basic::Parser->new(
        language    => 'perl',
        syntax_dirs => ['/path/to/custom/syntax'],
    );

    my $tokens = $parser->parse("if (\$x) {\n    print \"hello\";\n}");

    # $tokens is an arrayref of arrayrefs of token hashes:
    # [
    #     [ { class => 'Statement', sub_group => 'Conditional', text => 'if' },
    #       { class => 'whitespace', sub_group => undef, text => ' ' },
    #       ... ],
    #     [ ... ],
    # ]

=head1 DESCRIPTION

Syntax::Highlight::Basic::Parser reads C<.shb> syntax data files and tokenizes
source code into an array of arrays of token hashes. Each token contains the
matched text, its Vim highlight group classification, and an optional sub-group.

The parser supports:

=over 4

=item * Keyword matching (exact word matches with word boundaries)

=item * Regex pattern matching (single-line patterns)

=item * Multi-line region matching (strings, block comments)

=item * Fallback tokenizer for unrecognized languages

=back

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new Parser instance.

Options:

=over 4

=item C<language>

The programming language name (e.g., C<'perl'>, C<'python'>).  The parser
searches for a corresponding C<.shb> file.  Pygments-compatible aliases
are resolved via the built-in mapping table.

=item C<syntax_dirs>

An array reference of additional directories to search for C<.shb> files.
User-supplied directories are searched before the module's built-in
C<share/syntax/> directory.

=back

=head1 METHODS

=head2 parse($code)

Tokenizes the given source code string.

Returns an array reference of array references.  Each inner array corresponds
to one line of input and contains token hash references:

    { class => 'Statement', sub_group => 'Keyword', text => 'if' }

Special class values:

=over 4

=item C<'whitespace'> — spaces and tabs

=item C<'text'> — unrecognized text

=back

=head1 SYNTAX FILES

See C<docs/syntax-format.md> for the complete C<.shb> file format reference.

=head1 VERSION

0.1.0

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SYNTAX FILES

Syntax definitions are stored in C<.shb> files.  The module ships with
definitions for many languages in its C<share/syntax/> directory.  Users
can add custom definitions by creating their own C<.shb> files and
passing the directory via the C<syntax_dirs> option.

For a complete reference on the C<.shb> file format, see
L<docs/syntax-format.md> in the distribution.

=head1 SEE ALSO

L<Syntax::Highlight::Basic>,
L<Syntax::Highlight::Basic::Output::Pygments>,
L<Syntax::Highlight::Basic::Output::HTML>,
L<Syntax::Highlight::Basic::Output::Ansi>

=cut
