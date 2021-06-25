package Pod::PseudoPod::DOM::Role::LaTeX;
# ABSTRACT: an LaTeX formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;
use File::Basename;

requires 'type';
has 'tables',            is => 'rw', default => sub { {} };
has 'filename',          is => 'ro', default => '';
has 'emit_environments', is => 'ro', default => sub { {} };

sub accept_targets { 'latex' }

sub add_table
{
    my ($self, $table) = @_;

    # TeX includes are RELATIVE
    my $filename       = basename($self->filename);
    my $tables         = $self->tables;
    my $count          = keys %$tables;
    (my $id            = $filename)
                       =~ s/\.(\w+)$/'_table' . $count . '.tex'/e;

    $tables->{$id} = $table;
    return $id;
}

sub emit
{
    my $self = shift;
    my $type = $self->type;
    my $emit = 'emit_' . $type;

    $self->$emit( @_ );
}

sub emit_document
{
    my $self = shift;
    return $self->emit_kids( document => $self );
}

sub emit_kids
{
    my $self = shift;
    join '', map { $_->emit( @_ ) } @{ $self->children }
}

sub emit_header
{
    my $self     = shift;
    my $level    = $self->level;
    my $text     = $self->emit_kids;
    my $suppress = $text =~ s/^\*// ? '*' : '';
    my $anchor   = $self->anchor ? $self->anchor->emit_anchor : '';

    return qq|\\chapter${suppress}{$text}\n\n$anchor| if $level == 0;

    my $subs = 'sub' x ($level - 1);

    return qq|\\${subs}section${suppress}{$text}\n\n$anchor|;
}

sub emit_plaintext
{
    my ($self, %args) = @_;
    my $content       = defined $self->content ? $self->content : '';

    if (my $encode = $args{encode})
    {
        my $method = 'encode_' . $encode;
        return $self->$method( $content, %args );
    }

    return $self->encode_text( $content, %args );
}

sub encode_none { return $_[1] }

sub encode_split
{
    my ($self, $content, %args) = @_;
    my $target                  = $args{target};
    return join $args{joiner},
        map { $self->encode_text( $_ ) } split /\Q$target\E/, $content;
}

sub encode_index_anchor
{
    my ($self, $text) = @_;

    $text =~ s/"/""/g;
    $text = $self->escape_characters( $text );
    $text =~ s/([!|@])/"$1/g;

    return $text;
}

sub encode_label_text
{
    my ($self, $text) = @_;
    $text =~ s/[^\w:]/-/g;

    return $text;
}

sub encode_verbatim_text
{
    my ($self, $text) = @_;

    $text = $self->escape_characters( $text );
    $text =~ s/--/-\\mbox{}-/g;

    return $text;
}

sub encode_text
{
    my ($self, $text) = @_;

    $text = $self->escape_characters( $text );
    $text =~ s/(\\textbackslash)/\$$1\$/g;    # add unescaped dollars

    # use the right beginning quotes
    $text =~ s/(^|\s)"/$1``/g;

    # and the right ending quotes
    $text =~ s/"(\W|$)/''$1/g;

    # fix the ellipses
    $text =~ s/\.{3}\s*/\\ldots /g;

    # fix the ligatures
    $text =~ s/f([fil])/f\\mbox{}$1/g unless $self->{keep_ligatures};

    # fix emdashes
    $text =~ s/\s--\s/---/g;

    # suggest hyphenation points for module names
    $text =~ s/::/::\\-/g;

    return $text;
}

sub escape_characters
{
    my ($self, $text) = @_;

    # Escape LaTeX-specific characters
    $text =~ s/([{}])/\\$1/g;
    $text =~ s/\\(?![{}])/\\textbackslash{}/g;        # backslashes are special
    $text =~ s/([#\$&%_])/\\$1/g;
    $text =~ s/(\^)/\\char94{}/g;             # carets are special
    $text =~ s/</\\textless{}/g;
    $text =~ s/>/\\textgreater{}/g;
    $text =~ s/~/\\textasciitilde{}/g;
    $text =~ s/'/\\textquotesingle{}/g;

    return $text;
}

sub emit_literal
{
    my $self = shift;

    if (my $title = $self->title)
    {
        my $target = $title->emit_kids( encode => 'none' );
        return join "\n\n",
            map
            {
                $_->emit_kids(
                    encode => 'split', target => $target, joiner => "\\\\\n"
                )
            } @{ $self->children };
    }

    return qq||
         . join( "\\\\\n", map { $_->emit_kids( @_ ) } @{ $self->children } )
         . qq|\n|;
}

sub emit_anchor
{
    my $self = shift;
    return '\\label{' . $self->emit_kids( encode => 'label_text' ) . qq|}\n\n|;
}

sub emit_italics
{
    my $self = shift;
    return '\\emph{' . $self->emit_kids( @_ ) . '}';
}

sub emit_number_item
{
    my $self   = shift;
    my $marker = $self->marker;
    my $number = $marker ? qq| number="$marker"| : '';
    return "\\item " . $self->emit_kids( @_ ) . "\n\n";
}

sub emit_text_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return qq|\\item[]\n| unless @$kids;

    my $first = (shift @$kids)->emit;
    my $prelude = $first =~ /\D/
                ?  q|\\item[] | . $first
                : qq|\\item[$first]|;

    return $prelude . "\n\n" . join( '', map { $_->emit } @$kids );
}

sub emit_bullet_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return qq|\\item\n| unless @$kids;

    return q|\\item | . join( '', map { $_->emit } @$kids ) . qq|\n\n|;
}

sub emit_code
{
    my ($self, %args) = @_;
    my $kids          = $self->emit_kids( encode => 'verbatim_text' );
    my $tag           = '\\texttt{' . $kids . '}';

    $args{encode}     ||= '';
    return $tag unless $args{encode} =~ /^index_/;
    return $kids . '@' . $tag;
}

sub emit_footnote
{
    my $self = shift;
    return '\\footnote{' . $self->emit_kids( @_ ) . '}';
}

sub emit_url
{
    my $self = shift;
    return q|\\url{| . $self->emit_kids( encode => 'verbatim_text' ) . '}';
}

sub emit_link
{
    my $self = shift;
    return qq|\\ppodxref{| . $self->emit_kids( encode => 'label_text' ). q|}|;
}

sub emit_superscript
{
    my $self = shift;
    return '$^{' . $self->emit_kids( @_ ) . '}$';
}

sub emit_subscript
{
    my $self = shift;
    return '$_{' . $self->emit_kids( @_ ) . '}$';
}

sub emit_bold
{
    my $self = shift;
    return '\\textbf{' . $self->emit_kids( @_ ) . '}';
}

sub emit_file
{
    my $self = shift;
    return '\\emph{' . $self->emit_kids( @_ ) . '}';
}

sub emit_paragraph
{
    my $self             = shift;
    my $has_visible_text = grep { $_->type ne 'index' } @{ $self->children };
    return $self->emit_kids( @_ ) . ( $has_visible_text ? "\n\n" : '' );
}

use constant { BEFORE => 0, AFTER => 1 };
my $escapes = "commandchars=\\\\\\{\\}";

my %parent_items =
(
    text_list      => [ qq|\\begin{description}\n\n|,
                        qq|\\end{description}|                          ],
    bullet_list    => [ qq|\\begin{itemize}\n\n|,
                        qq|\\end{itemize}|                              ],
    number_list    => [ qq|\\begin{enumerate}\n\n|,
                        qq|\\end{enumerate}|                            ],
     map { $_ => [ qq|\\begin{$_}\n|, qq|\\end{$_}\n\n| ] }
         qw( epigraph blockquote )
);

while (my ($tag, $values) = each %parent_items)
{
    my $sub = sub
    {
        my $self = shift;
        return $values->[BEFORE]
             . $self->emit_kids( @_ )
             . $values->[AFTER] . "\n\n";
    };

    do { no strict 'refs'; *{ 'emit_' . $tag } = $sub };
}

sub emit_programlisting
{
    my $self = shift;

    # should be only a single Verbatim; may need to fix with hoisting
    my $kid  = $self->children->[0];

    return qq|\\begin{CodeListing}\n|
         . $kid->emit_kids( encode => 'verbatim_text' )
         . qq|\n\\end{CodeListing}\n|;
}

sub emit_verbatim
{
    my $self = shift;
    return qq|\\begin{Verbatim}[$escapes]\n|
         . $self->emit_kids( encode => 'verbatim_text' )
         . qq|\n\\end{Verbatim}\n|;
}

sub emit_screen
{
    my $self = shift;
    # should be only a single Verbatim; may need to fix with hoisting
    my $kid  = $self->children->[0];

    return qq|\\begin{Screen}\n|
         . $kid->emit_kids( encode => 'verbatim_text' )
         . qq|\n\\end{Screen}\n|;
}

my %characters = (
    acute    => sub { qq|\\'| . shift },
    grave    => sub { qq|\\`| . shift },
    uml      => sub { qq|\\"| . shift },
    cedilla  => sub { '\c{'   . shift . '}' }, # cedilla
    opy      => sub { '\copyright' },          # copy
    dash     => sub { '---' },                 # mdash
    lusmn    => sub { '\pm' },                 # plusmn
    mp       => sub { '\&' },                  # amp
    rademark => sub { '\texttrademark' }
);

sub emit_character
{
    my $self    = shift;

    my $content = eval { $self->emit_kids( @_ ) };
    return unless defined $content;

    if (my ($char, $class) = $content =~ /(\w)(\w+)/)
    {
        return $characters{$class}->($char) if exists $characters{$class};
    }

    return Pod::Escapes::e2char( $content );
}

sub emit_index
{
    my $self = shift;

    my $content;
    for my $kid (@{ $self->children })
    {
        if ($kid->type eq 'plaintext')
        {
            my $kid_content = $kid->emit( encode => 'index_anchor' );
            $kid_content    =~ s/\s*;\s*/!/g;
            $content       .= $kid_content;
        }
        else
        {
            $content .= $kid->emit( encode => 'index_anchor' );
        }
    }

    $content =~ s/^\s+|\s+$//g;

    return '\\index{' . $content . '}';
}

sub emit_latex
{
    my $self = shift;
    return $self->emit_kids( encode => 'none' ) . "\n";
}

sub emit_block
{
    my $self   = shift;
    my $title  = $self->title ? $self->title->emit_kids( encode => 'text' ) :'';
    my $target = $self->target;

    if (my $environment = $self->emit_environments->{$target})
    {
        $target = $environment;
    }
    elsif (my $meth = $self->can( 'emit_' . $target))
    {
        return $self->$meth( @_ );
    }

    return $self->make_basic_block( $self->target, $title, @_ );
}

sub make_basic_block
{
    my ($self, $target, $title, @rest) = @_;

    $title = defined $title ? qq|[$title]| : '';

    return qq|\\begin{$target}$title\{\n|
         . $self->emit_kids( @rest )
         . qq|}\\end{$target}\n|;
}

sub encode_E_contents {}

sub emit_sidebar
{
    my $self  = shift;
    my $title = $self->title;
    my $env   = $self->emit_environments;

    return $self->make_basic_block( $env->{sidebar}, $title, @_ )
        if exists $env->{sidebar};

    if ($title)
    {
        $title = <<END_TITLE;
\\begin{center}
\\large{\\bfseries{$title}}
\\end{center}
END_TITLE
    }
    else
    {
        $title = '';
    }

    return <<END_HEADER . $self->emit_kids( @_ ) . <<END_FOOTER;
\\begin{figure}[H]
\\begin{center}
\\begin{Sbox}
\\begin{minipage}{\\linewidth}
$title
END_HEADER
\\end{minipage}
\\end{Sbox}
\\framebox{\\TheSbox}
\\end{center}
\\end{figure}
END_FOOTER

}

sub emit_table
{
    my ($self, %args) = @_;
    my $title         = $self->title
                      ? $self->title->emit_kids( encode => 'text' )
                      : '';
    my $num_cols      = $self->num_cols;
    my $width         = 1.0 / $num_cols;
    my $cols          = join ' | ', map { 'X' } 1 .. $num_cols;

    my $document      = $args{document};
    my $caption       = length $title
                      ? "\\caption{" . $title . "}\n"
                      : '';

    my $start = "\\begin{longtable}{| $cols |}\n";
    my $end   = "$caption\\end{longtable}\n";
    my $id    = $document->add_table( $start . $self->emit_kids( @_ ) . $end );

    return <<TABLE_REFERENCE;
\\begin{center}
\\LTXtable{\\linewidth}{$id}
\\end{center}
TABLE_REFERENCE
}

sub emit_headrow
{
    my $self = shift;
    my $row  = $self->emit_row;
    $row =~ s{(\\hline\n)$}{\\endhead$1}s;
    return "\\hline\n\\rowcolor[gray]{.9}\n$row";
}

sub emit_row
{
    my $self     = shift;
    my $contents = join ' & ', map { $_->emit } @{ $self->children };
    return $contents . "\\\\\\hline\n";
}

sub emit_cell
{
    my $self = shift;
    my @contents;

    for my $child (@{ $self->children })
    {
        my $contents = $child->emit( @_ );
        $contents =~ s/\n+$//g;
        next unless $contents =~ /\S/;
        push @contents, $contents;
    }

    return join '\\newline\\newline ', @contents;
}

sub emit_figure
{
    my $self    = shift;
    my $caption = $self->caption;
    $caption    = defined $caption
                ? '\\caption{' . $self->encode_text( $caption ) . "}\n"
                : '';

    my $anchor  = $self->anchor;
    $anchor     = defined $anchor ? $anchor->emit : '';

    my $file    = $self->file->emit_kids( encode => 'none' );

    return <<END_FIGURE;
\\begin{figure}[H]
\\centering
\\includegraphics[width=\\linewidth]{$file}
$caption$anchor\\end{figure}
END_FIGURE
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::Role::LaTeX - an LaTeX formatter role for PseudoPod DOM trees

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
