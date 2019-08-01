package Pod::PseudoPod::LaTeX;
$Pod::PseudoPod::LaTeX::VERSION = '1.20190729';
use Pod::PseudoPod 0.16;

use base 'Pod::PseudoPod';
use 5.008006;

use strict;
use warnings;



sub new
{
    my ( $class, %args ) = @_;
    my $self             = $class->SUPER::new(%args);

    $self->{keep_ligatures}  = exists($args{keep_ligatures})  ? $args{keep_ligatures}  : 0;
    $self->{captions_below} = exists($args{captions_below}) ? $args{captions_below} : 0;
    $self->{full}           = exists($args{full})           ? $args{full}           : 0;

    # These have their contents parsed
    $self->accept_targets_as_text(
        qw( sidebar blockquote programlisting screen figure table
            PASM PIR PIR_FRAGMENT PASM_FRAGMENT PIR_FRAGMENT_INVALID )
    );

    # These do not. Content is not touched.
    $self->accept_target('latex');

    $self->{scratch} ||= '';
    $self->{stack}     = [];
    $self->{labels}    = { screen => 'Program output' };

    return $self;
}

sub emit_environments
{
    my ( $self, %env ) = @_;
    for ( keys %env )
    {
        $self->{emit_environment}->{$_} = $env{$_};
    }
}

sub start_Document
{
    my $self = shift;
    if ($self->{full}) {
        $self->{scratch} .= "\\documentclass[12pt,a4paper]{book}\n"
                         .  "\\usepackage{fancyvrb}\n"
                         .  "\\usepackage{url}\n"
                         .  "\\usepackage{titleref}\n"
                         .  "\\usepackage[T1]{fontenc}\n"
                         .  "\\usepackage{textcomp}\n"
                         .  "\\begin{document}\n";
    }
}

sub end_Document
{
    my $self = shift;
    $self->{scratch} .= "\\end{document}\n" if $self->{full};
    $self->emit();
}

sub emit
{
    my $self = shift;
    return unless defined $self->{scratch};
    print { $self->{output_fh} } delete $self->{scratch};
}

sub handle_text
{
    my ( $self, $text ) = @_;
    $self->{scratch} .= $self->encode_text($text);
}

sub encode_text
{
    my ( $self, $text ) = @_;

    my $resolve = 1;
    eval {
        no warnings 'uninitialized';
        if (exists($self->{curr_open}[-1][-1]{'~resolve'}) &&
            $self->{curr_open}[-1][-1]{'~resolve'} == 0)
          {
              $resolve = 0;
          }
    };
    return $text unless $resolve;

    return $self->encode_verbatim_text($text) if $self->{flags}{in_verbatim};
    return $text if $self->{flags}{in_xref};
    return $text if $self->{flags}{in_figure};

    # Escape LaTeX-specific characters
    $text =~ s/\\/\\backslash/g;          # backslashes are special
    $text =~ s/([#\$&%_{}])/\\$1/g;
    $text =~ s/(\^)/\\char94{}/g;         # carets are special
    $text =~ s/</\\textless{}/g;
    $text =~ s/>/\\textgreater{}/g;

    $text =~ s/(\\backslash)/\$$1\$/g;    # add unescaped dollars

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

    # fix tildes
    $text =~ s/~/\$\\sim\$/g;

    # suggest hyphenation points for module names
    $text =~ s/::/::\\-/g;

    return $text;
}

# in verbatim mode, some things still need escaping - otherwise markup
# wouldn't work when the codes_in_verbatim option is enabled.
sub encode_verbatim_text {
    my ($self, $text) = @_;

    $text =~ s/([{}])/\\$1/g;
    $text =~ s/\\(?![{}])/\\textbackslash{}/g;

    return $text;
}

sub start_head0
{
    my $self = shift;
    $self->{scratch} .= '\\chapter{';
}

sub end_head0
{
    my $self = shift;
    $self->{scratch} .= "}\n\n";
    $self->emit();
}

sub end_Para
{
    my $self = shift;
    $self->{scratch} .= "\n\n";
    $self->emit();
}

BEGIN
{
    for my $level ( 1 .. 5 )
    {
        my $prefix = '\\' . ( 'sub' x ( $level - 1 ) ) . 'section*{';
        my $start_sub = sub {
            my $self = shift;
            $self->{scratch} .= $prefix;
        };

        my $end_sub = sub {
            my $self = shift;
            $self->{scratch} .= "}\n\n";
            $self->emit();
        };

        no strict 'refs';
        *{ 'start_head' . $level } = $start_sub;
        *{ 'end_head'   . $level } = $end_sub;
    }
}

sub start_E
{
    my $self = shift;
    push @{ $self->{stack} }, delete $self->{scratch};
    $self->{scratch} = '';
}

my %characters = (
    acute   => sub { qq|\\'| . shift },
    grave   => sub { qq|\\`| . shift },
    uml     => sub { qq|\\"| . shift },
    cedilla => sub { '\c{c}' },              # ccedilla
    opy     => sub { '\copyright' },         # copy
    dash    => sub { '---' },                # mdash
    lusmn   => sub { '\ensuremath{\pm}' },   # plusmn
    mp      => sub { '\&' },                 # amp
);

sub end_E
{
    my $self = shift;
    my $clean_entity;

    # XXX - error checking here
    my $entity = delete $self->{scratch};
    $entity =~ /(\w)(\w+)/;

    if ( exists $characters{$2} )
    {
        $clean_entity = $characters{$2}->($1);
    }
    elsif ( $clean_entity = Pod::Escapes::e2char($entity) )
    {
    }
    else
    {
        die "Unrecognized character '$entity'\n";
    }

    $self->{scratch}  = pop @{ $self->{stack} };
    $self->{scratch} .= $clean_entity;
}

sub _treat_Es { }

sub start_X
{
    my $self = shift;
    push @{ $self->{stack} }, delete $self->{scratch};
    $self->{scratch} = '';
}

sub end_X
{
    my $self       = shift;
    my $terms_text = delete $self->{scratch};
	my @terms;
	for my $t (split ',', $terms_text) {
		$t =~ s/^\s+|\s+$//g;
		$t =~ s/"/""/g;
		$t =~ s/([!|@])/"$1/g;
		push @terms, $t;
	}
    {
        no warnings 'uninitialized';
        $self->{scratch}  = pop(@{ $self->{stack} })
          . '\\index{' . join('!', @terms) . '}';
    }
}

sub start_Z
{
    my $self = shift;
    push @{ $self->{stack} }, delete $self->{scratch};
    $self->{scratch} = '';
    $self->{flags}{in_xref}++;
}

sub end_Z
{
    my $self       = shift;
    my $clean_xref = delete $self->{scratch};

    # sanitize crossreference names
    $clean_xref =~ s/[^\w:]/-/g;

    {
        no warnings 'uninitialized';
        $self->{scratch}  = pop( @{ $self->{stack} } )
          . '\\label{' . $clean_xref . '}';
    }
    $self->{flags}{in_xref}--;
}

sub start_A
{
    my $self = shift;
    push @{ $self->{stack} }, delete $self->{scratch};

    $self->{scratch} = '';
    $self->{flags}{in_xref}++;
}

sub end_A
{
    my $self       = shift;
    my $clean_xref = delete $self->{scratch};

    # sanitize crossreference names
    $clean_xref      =~ s/[^\w:]/-/g;
    $self->{scratch} = pop @{ $self->{stack} };

    # Figures have a different xref format
    if ( $clean_xref =~ /^fig:/ )
    {
        $self->{scratch} .= 'Figure \\ref{' . $clean_xref . '} ';
    }
    # Tables have a different xref format
    elsif ( $clean_xref =~ /^table:/ )
    {
        $self->{scratch} .= 'Table \\ref{' . $clean_xref . '} ';
    }
    else
    {
        $self->{scratch} .= '\\emph{\\titleref{' . $clean_xref . '}}';
    }

    $self->{scratch} .= ' on page~'
                     .  '\\pageref{' . $clean_xref . '}';

    $self->{flags}{in_xref}--;
}

sub start_F
{
    my $self = shift;

    if ( $self->{flags}{in_figure} )
    {
        push @{ $self->{stack} }, delete $self->{scratch};
        $self->{scratch} = '';
    }
    else
    {
        $self->{scratch} .= '\\emph{';
    }
}

sub end_F
{
    my $self = shift;

    if ( $self->{flags}{in_figure} )
    {
        my $raw_filename = delete $self->{scratch};
        $self->{scratch} = pop @{ $self->{stack} };

        # extract bare image filename
        $raw_filename =~ /(\w+)\.\w+$/;
        $self->{scratch} .= "\n\\includegraphics{" . $1 . '}';
    }
    else
    {
        $self->{scratch} .= '}';
    }
}

sub start_for
{
    my ( $self, $flags ) = @_;

    if ($flags->{target} =~ /^latex$/i) { # support latex, LaTeX, et al
        $self->{scratch} .= "\n\n";
    } elsif (exists($flags->{'~really'}) &&
             $flags->{'~really'} eq "=begin" &&
             exists($self->{emit_environment}{$flags->{target}})) {
        my $title = "";
        $title = "{".$flags->{title}."}" if exists $flags->{title};
        $self->{scratch} .= sprintf("\n\\begin{%s}%s\n",
                                    $self->{emit_environment}{$flags->{target}},
                                    $title);
    }
}

sub end_for
{
    my ( $self, $flags ) = @_;

    if ($flags->{target} =~ /^latex$/i) { # support latex, LaTeX, et al
        $self->{scratch} .= "\n\n";
        $self->emit;
    } elsif (exists($self->{emit_environment}{$flags->{target}})) {
        $self->{scratch} .= sprintf("\\end{%s}\n\n",
                                    $self->{emit_environment}{$flags->{target}});
        $self->emit;
    }
}

sub start_Verbatim
{
    my $self = shift;

    my $verb_options = "commandchars=\\\\\\{\\}";
    eval {
        no warnings 'uninitialized';
        if ($self->{curr_open}[-1][-1]{target} eq 'screen') {
            my $label = $self->{curr_open}[-1][-1]{title} || $self->{labels}{screen};
            $verb_options .= ",frame=single,label=$label";
        }
    };

    $self->{scratch} .= "\\vspace{-6pt}\n"
                     .  "\\scriptsize\n"
                     .  "\\begin{Verbatim}[$verb_options]\n";
    $self->{flags}{in_verbatim}++;
}

sub end_Verbatim
{
    my $self = shift;

    $self->{scratch} .= "\n\\end{Verbatim}\n"
                     .  "\\vspace{-6pt}\n";

    #    $self->{scratch} .= "\\addtolength{\\parskip}{5pt}\n";
    $self->{scratch} .= "\\normalsize\n";
    $self->{flags}{in_verbatim}--;
    $self->emit();
}

sub end_screen
{
    my $self = shift;
    $self->{scratch} .= "\n\\end{Verbatim}\n"
                     .  "\\vspace{-6pt}\n";

    #    $self->{scratch} .= "\\addtolength{\\parskip}{5pt}\n";
    $self->{scratch} .= "\\normalsize\n";
    $self->{flags}{in_verbatim}--;
    $self->emit();
}

sub start_figure
{
    my ( $self, $flags ) = @_;

    $self->{scratch} .= "\\begin{figure}[!h]\n";

    $self->{_dangling_title} = undef; # just in case; Do not think it is worth a stack.
    if ( $flags->{title} ) {
        if ($self->{captions_below}) {
            $self->{_dangling_title} = $flags->{title};
        }
        else {
            my $title = $self->encode_text( $flags->{title} );
            $title    =~ s/^graphic\s*//;
            $self->{scratch} .= "\\caption{" . $title . "}\n";
        }
    }

    $self->{scratch} .= "\\begin{center}\n";
    $self->{flags}{in_figure}++;
}

sub end_figure
{
    my $self = shift;
    $self->{scratch} .= "\\end{center}\n";

    if ($self->{captions_below} && $self->{_dangling_title})
    {
        my $title = $self->encode_text( $self->{_dangling_title} );
        $title    =~ s/^graphic\s*//;
        $self->{scratch} .= "\\caption{" . $title . "}\n";
        $self->{_dangling_title} = undef; # clear it
    }

    $self->{scratch} .= "\\end{figure}\n";
    $self->{flags}{in_figure}--;
    $self->emit();
}

sub start_table
{
    my ( $self, $flags) = @_;

    # Open the table
    $self->{scratch} .= "\\begin{table}[!h]\n";

    $self->{_dangling_title} = undef; # just in case; Do not think it is worth a stack.
    if ( $flags->{title} )
    {
        if ($self->{captions_below}) {
            $self->{_dangling_title} = $flags->{title};
        }
        else {
            my $title = $self->encode_text( $flags->{title} );
            $title    =~ s/^graphic\s*//;
            $self->{scratch} .= "\\caption{" . $title . "}\n";
        }
    }
    $self->{scratch} .= "\\begin{center}\n";

    $self->{flags}{in_table}++;
    delete $self->{table_rows};
}

sub end_table
{
    my $self = shift;

    # Format the table body
    my $column_count  = @{ $self->{table_rows}[0] };
    my $format_spec   = '|' . ( 'l|' x $column_count );

    # first row is gray
    $self->{scratch} .= "\\begin{tabular}{$format_spec}\n"
                     .  "\\hline\n"
                     .  "\\rowcolor[gray]{.9}\n";

    # Format each row
    my $row;
    for $row ( @{ $self->{table_rows} } )
    {
        $self->{scratch} .= join( ' & ', @$row )
                         . "\\\\ \\hline\n";
    }

    # Close the table
    $self->{scratch} .= "\\end{tabular}\n"
                     .  "\\end{center}\n";


    if ($self->{captions_below} && $self->{_dangling_title})
    {
        my $title = $self->encode_text( $self->{_dangling_title} );
        $title    =~ s/^graphic\s*//;
        $self->{scratch} .= "\\caption{" . $title . "}\n";
        $self->{_dangling_title} = undef; # clear it
    }

    $self->{scratch}.= "\\end{table}\n";

    $self->{flags}{in_table}--;
    delete $self->{table_rows};

    $self->emit();
}

sub start_headrow
{
    my $self = shift;
    $self->{in_headrow}++;
}

sub start_bodyrows
{
    my $self = shift;
    $self->{in_headrow}--;
}

sub start_row
{
    my $self = shift;
    delete $self->{table_current_row};
}

sub end_row
{
    my $self = shift;
    push @{ $self->{table_rows} }, $self->{table_current_row};
    delete $self->{table_current_row};
}

sub start_cell
{
    my $self = shift;
    push @{ $self->{stack} }, delete $self->{scratch};
    $self->{scratch} = '';
}

sub end_cell
{
    my $self          = shift;
    my $cell_contents = delete $self->{scratch};

    if ( $self->{in_headrow} )
    {
        $cell_contents = '\\textbf{\\textsf{' . $cell_contents . '}}';
    }

    push @{ $self->{table_current_row} }, $cell_contents;
    $self->{scratch} = pop @{ $self->{stack} };
}

BEGIN
{
    for my $listtype (
        [qw( bullet itemize     )], [qw( number enumerate   )],
        [qw( text   description )], [qw( block  description )],
        )
    {

        my $start_sub = sub {
            my $self = shift;
            $self->{scratch} .= "\\vspace{-5pt}\n"
                             .  "\n\\begin{$listtype->[1]}\n\n"
                             .  "\\setlength{\\topsep}{0pt}\n"
                             .  "\\setlength{\\itemsep}{0pt}\n";

            #            $self->{scratch} .= "\\setlength{\\parskip}{0pt}\n";
            #            $self->{scratch} .= "\\setlength{\\parsep}{0pt}\n";
        };

        my $end_sub = sub {
            my $self = shift;
            $self->{scratch} .= "\\end{$listtype->[1]}\n\n"
                             .  "\\vspace{-5pt}\n";
            $self->emit();
        };

        no strict 'refs';
        *{ 'start_over_' . $listtype->[0] } = $start_sub;
        *{ 'end_over_'   . $listtype->[0] } = $end_sub;
    }
}

sub start_item_bullet
{
    my $self = shift;
    $self->{scratch} .= '\item ';
}

sub start_item_number
{
    my ( $self, $flags ) = @_;

    #    $self->{scratch}  .= "\\item[$flags->{number}] ";
    $self->{scratch} .= "\\item ";    # LaTeX will auto-number
}

sub start_item_text
{
    my $self = shift;
    $self->{scratch} .= '\item[] ';
}

sub start_sidebar
{
    my ( $self, $flags ) = @_;

    my $title;
    $title = $self->encode_text( $flags->{title} ) if $flags->{title};

    if ( $self->{emit_environment}->{sidebar} )
    {
    $self->{scratch} .= "\\begin{" . $self->{emit_environment}->{sidebar} . "}";
    $self->{scratch} .= "[$title]" if $title;
    $self->{scratch} .= "\n";
    }
    else
    {
        $self->{scratch} .= "\\begin{figure}[!h]\n"
                         .  "\\begin{center}\n"
                         .  "\\framebox{\n"
                         .  "\\begin{minipage}{3.5in}\n"
                         .  "\\vspace{3pt}\n\n";

        if ( $title )
        {
            $self->{scratch} .= "\\begin{center}\n"
                             .  "\\large{\\bfseries{" . $title . "}}\n"
                             .  "\\end{center}\n\n";
        }
    }
}

sub end_sidebar
{
    my $self = shift;
    if ( $self->{emit_environment}->{sidebar} )
    {
        $self->{scratch} .= "\\end{"
                         .  $self->{emit_environment}->{sidebar} . "}\n\n";
    }
    else
    {
        $self->{scratch} .= "\\vspace{3pt}\n"
                         .  "\\end{minipage}\n"
                         # end framebox
                         .  "}\n"
                         .  "\\end{center}\n"
                         .  "\\end{figure}\n";
    }
}

BEGIN
{
    for my $end (qw( bullet number text))
    {
        my $end_sub = sub {
            my $self = shift;
            $self->{scratch} .= "\n\n";
            $self->emit();
        };

        no strict 'refs';
        *{ 'end_item_' . $end } = $end_sub;
    }

    my %formats = (
        B => [ '\\textbf',   ''  ],
        C => [ '\\texttt',   ''  ],
        I => [ '\\emph',     ''  ],
        U => [ '\\url',      ''  ],
        R => [ '\\emph',     ''  ],
        L => [ '\\url',      ''  ],
        N => [ '\\footnote', ''  ],
        G => [ '$^',         '$' ],
        H => [ '$_',         '$' ],
    );

    while ( my ( $code, $fixes ) = each %formats )
    {
        my $start_sub = sub {
            my $self = shift;
            $self->{scratch} .= $fixes->[0] . '{';
        };

        my $end_sub = sub {
            my $self = shift;
            $self->{scratch} .= '}' . $fixes->[1];
        };

        no strict 'refs';
        *{ 'start_' . $code } = $start_sub;
        *{ 'end_'   . $code } = $end_sub;
    }

}

1;
__END__

=encoding utf8

=head1 NAME

Pod::PseudoPod::LaTeX - convert Pod::PseudoPod documents into LaTeX

=head1 SYNOPSIS

This module is a C<Pod::PseudoPod> subclass, itself a C<Pod::Simple> subclass.  This
means that this is a full-fledged POD parser.  Anything those modules can do,
this can do.

Perhaps a little code snippet.

    use Pod::PseudoPod::LaTeX;

    my $parser = Pod::PseudoPod::LaTeX->new();
    $parser->emit_environments( sidebar => 'sidebar' );
    $parser->output_fh( $some_fh );
    $parser->parse_file( 'some_document.pod' );

    ...

=head1 LATEX PREAMBLE

The generated LaTeX code needs some packages to be loaded to work correctly.
Currently it needs

    \usepackage{fancyvrb}  % for Screen and Verbatim environments
    \usepackage{url}       % for L<> URLs
    \usepackage{titleref}  % for A<> generated code

The standard font in LaTeX (Computer Modern) does not support bold and italic
variants of its monospace font, an alternative is

    \usepackage[T1]{fontenc}
    \usepackage{textcomp}
    \usepackage[scaled]{beramono}

=head1 MODULE OPTIONS

Currently we support:

=over

=item C<keep_ligatures>

LaTeX usually joins some pairs of letters (ff, fi and fl), named
ligatures. By default the module splits them. If you prefer to render
them with ligatures, use:

    my $parser = Pod::PseudoPod::LaTeX->new( keep_ligatures => 1 );

=item C<captions_below>

Set this flag to a true value if you prefer that figure and table
captions are placed below the object and not above (the default).

=item C<full>

Create a standalone document which can immediately be run through C<latex>
or C<pdflatex>.

=back

=head1 STYLES / EMITTING ENVIRONMENTS

The C<emit_environments> method accepts a hashref whose keys are POD environments
and values are LaTeX environments. Use this method if you would like
C<Pod::PseudoPod::LaTeX> to emit a simple C<\begin{foo}...\end{foo}> environment
rather than emit specific formatting codes. You must define any environments you
use in this way in your LaTeX prelude.

You can define your own environments easily. First you need to define
the C<=begin...=end> environment with:

    $parser->acept_target_as_text('my_environment');

Then, you can use the C<emit_environments> method to tell
C<Pod::PseudoPod::LaTeX> what LaTeX environment to emit:

    $parser->emit_environments('my_environment' => 'latex_env');

Also, if C<my_environment> is used in POD with a title, it is passed
as the first argument to the LaTeX environment. That is,

    =begin my_environment Some title

Will generate

    \begin{latex_env}{Some title}

=head1 AUTHOR

chromatic, C<< <chromatic at wgz.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-pseudopod-tex at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-PseudoPod-LaTeX>.  I'll
hear about it and you'll hear about any progress on your bug as I make changes.

=head1 SUPPORT

Read this documentation with the perldoc command:

    $ B<perldoc Pod::PseudoPod::LaTeX>

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-PseudoPod-LaTeX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-PseudoPod-LaTeX>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-PseudoPod-LaTeX>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-PseudoPod-LaTeX>

=back

=head1 ACKNOWLEDGEMENTS and SEE ALSO

Based on Allison Randal's L<Pod::PseudoPod> module.

See also L<perlpod>, L<Pod::Simple> and L<Pod::TeX>.  I did not reuse the
latter because I need to support the additional POD directives found in
PseudoPod.

Thanks to multiple contributors, including (but not limited to) Dean Serenevy,
Moritz Lenz, Alberto Simões, and Jerome Quelin.

Thanks to Onyx Neon Press (L<http://www.onyxneon.com/>) for sponsoring this
work under free software guidelines.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006, 2009 - 2019, chromatic.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl 5.30.

=cut
