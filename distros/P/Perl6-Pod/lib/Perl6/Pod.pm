package Perl6::Pod;

=pod

=head1 NAME

Perl6::Pod - Pod6 implementation

=head1 SYNOPSIS

    use Perl6::Pod;

    =comment
    Some text

    =head1 Head title
    =para
    Some text of para

Delimited style, paragraph style, or abbreviated style of blocks

    =begin para :formatted<B I>
    Perl is a stable, cross platform programming language. 
    =end para

    =for para :formatted<B I>
    Perl is a stable, cross platform programming language. 

    =para
    Perl is a stable, cross platform programming language. 

Unordered lists 

    =item FreeBSD
    =item Linux
    =item Windows
    =item MacOS

Definition lists 

    =defn XML
    Extensible Markup Language
    =defn HTML
    Hyper Text Markup Language


=head1 DESCRIPTION

Pod is an evolution of Perl 5's Plain Old Documentation (POD) markup. Compared to Perl 5 POD, Perldoc's Pod dialect is much more uniform, somewhat more compact, and considerably more expressive. The Pod dialect also differs in that it is a purely descriptive mark-up notation, with no presentational components. 

=head2 General syntactic structure 

Pod documents are specified using directives, which are used to declare configuration information and to delimit blocks of textual content. Every directive starts with an equals sign (=) in the first column.

The content of a document is specified within one or more blocks. Every Pod block may be declared in any of three equivalent forms: delimited style, paragraph style, or abbreviated style. 

=head3 Delimited blocks 

The general syntax is:

    =begin BLOCK_TYPE  OPTIONAL CONFIG INFO
    =                  OPTIONAL EXTRA CONFIG INFO
    BLOCK CONTENTS
    =end BLOCK_TYPE

For example:

    =begin table  :caption<Table of Contents>
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57
    =end table

    =begin Name  :required
    =            :width(50)
    The applicant's full name
    =end Name

    =begin Contact  :optional
    The applicant's contact details
    =end Contact


=head3 Paragraph blocks 

Paragraph blocks are introduced by a =for marker and terminated by the next Pod directive or the first blank line (which is not considered to be part of the block's contents). The =for marker is followed by the name of the block and optional configuration information. The general syntax is:

    =for BLOCK_TYPE  OPTIONAL CONFIG INFO
    =                OPTIONAL EXTRA CONFIG INFO
    BLOCK DATA

For example:

    =for table  :caption<Table of Contents>
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57

    =for Name  :required
    =          :width(50)
    The applicant's full name

    =for Contact  :optional
    The applicant's contact details

=head3 Abbreviated blocks

Abbreviated blocks are introduced by an '=' sign in the first column, which is followed immediately by the typename of the block. The rest of the line is treated as block data, rather than as configuration. The content terminates at the next Pod directive or the first blank line (which is not part of the block data). The general syntax is:

    =BLOCK_TYPE  BLOCK DATA
    MORE BLOCK DATA

For example:

    =table
        Constants           1
        Variables           10
        Subroutines         33
        Everything else     57

    =Name     The applicant's full name
    =Contact  The applicant's contact details

Note that abbreviated blocks cannot specify configuration information. If configuration is required, use a =for or =begin/=end instead. 

=head3 Block equivalence 

The three block specifications (delimited, paragraph, and abbreviated) are treated identically by the underlying documentation model, so you can use whichever form is most convenient for a particular documentation task. In the descriptions that follow, the abbreviated form will generally be used, but should be read as standing for all three forms equally.

For example, although Headings shows only:

    =head1 Top Level Heading

this automatically implies that you could also write that block as:

    =for head1
    Top Level Heading

or:

    =begin head1
    Top Level Heading
    =end head1

=head3 Standard configuration options

Pod predefines a small number of standard configuration options that can be applied uniformly to built-in block types. These include:


=head4 :numbered

This option specifies that the block is to be numbered. The most common use of this option is to create numbered headings and ordered lists, but it can be applied to any block.

It is up to individual renderers to decide how to display any numbering associated with other types of blocks.

=head4 :formatted

This option specifies that the contents of the block should be treated as if they had one or more formatting codes placed around them.

For example, instead of:

        =for comment
            The next para is both important and fundamental,
            so doubly emphasize it...

        =begin para
        B<I<
        Warning: Do not immerse in water. Do not expose to bright light.
        Do not feed after midnight.
        >>
        =end para

you can just write:

        =begin para :formatted<B I>
        Warning: Do not immerse in water. Do not expose to bright light.
        Do not feed after midnight.
        =end para

The internal representations of these two versions are exactly the same, except that the second one retains the :formatted option information as part of the resulting block object.

Like all formatting codes, codes applied via a :formatted are inherently cumulative. For example, if the block itself is already inside a formatting code, that formatting code will still apply, in addition to the extra "basis" and "important" formatting specified by :formatted<B I>.

=head4 :like

This option specifies that a block or config has the same formatting properties as the type named by its value. This is useful for creating related configurations. For example:

        =config head2  :like<head1> :formatted<I>

=head4 :allow

This option expects a list of formatting codes that are to be recognized within any V<> codes that appear in (or are implicitly applied to) the current block. The option is most often used on =code blocks to allow mark-up within those otherwise verbatim blocks, though it can be used in any block that contains verbatim text. See Formatting within code blocks. 

=head2 Blocks 

=head2 Formatting codes

=head2 API

Perl6::Pod - in general, a set of classes, scripts and modules for maintance Perl6's pod documentation using perl5.

The suite contain the following classes:

=over

=item * L<Perl6::Pod::Grammars> - Pod6 Grammars

=item * L<Perl6::Pod::Block> - base class for Perldoc blocks

=item * L<Perl6::Pod::FormattingCode> - base class for formatting code

=item * L<Perl6::Pod::To> - base class for output formatters

=back

=cut

$Perl6::Pod::VERSION = '0.72';

use warnings;
use strict;
use re 'eval';

use Filter::Simple;

my $IDENT            = qr{ (?> [^\W\d] \w* )            }xms;
my $QUAL_IDENT       = qr{ $IDENT (?: :: $IDENT)*       }xms;
my $TO_EOL           = qr{ (?> [^\n]* ) (?:\Z|\n)       }xms;
my $HWS              = qr{ (?> [^\S\n]+ )               }xms;
my $OHWS             = qr{ (?> [^\S\n]* )               }xms;
my $BLANK_LINE       = qr{ ^ $OHWS $ | (?= ^ =)         }xms;
my $DIRECTIVE        = qr{ config | encoding | use      }xms;
my $OPT_EXTRA_CONFIG = qr{ (?> (?: ^ = $HWS $TO_EOL)* ) }xms;


# Recursive matcher for =DATA sections...

my $DATA_PAT = qr{
    ^ = 
    (?:
        begin $HWS DATA $TO_EOL
        $OPT_EXTRA_CONFIG
            (.*?)
        ^ =end $HWS DATA
    |
        for $HWS DATA $TO_EOL
        $OPT_EXTRA_CONFIG
            (.*?)
        $BLANK_LINE
    |
        DATA \s
            (.*?)
        $BLANK_LINE
    )
}xms;


# Recursive matcher for all other Perldoc sections...
no strict 'vars';

my $POD_PAT; $POD_PAT = qr{
    ^ =
    (?:
        (?:(?:begin|for) $HWS)? END
        (?> .*) \z
    |
        begin $HWS ($IDENT) (?{ local $type = $^N}) $TO_EOL
        $OPT_EXTRA_CONFIG
            (?: ^ (??{$POD_PAT}) | . )*?
        ^ =end $HWS (??{$type}) $TO_EOL
    |
        for $HWS $TO_EOL
        $OPT_EXTRA_CONFIG
            .*?
        $BLANK_LINE
    |
        ^ $DIRECTIVE $HWS $TO_EOL
        $OPT_EXTRA_CONFIG
    |
        ^ (?! =end) =$IDENT $HWS $TO_EOL
            .*?
        $BLANK_LINE
    |
        $IDENT $TO_EOL
            .*?
        $BLANK_LINE
    )
}xms;


FILTER {
    my @DATA;

    # Extract DATA sections, deleting them but preserving line numbering...
    s{ ($DATA_PAT) }{
        my ($data_block, $contents) = ($1,$+);

        # Special newline handling required under Windows...
        if ($^O =~ /MSWin/) {
            $contents =~ s{ \r\n }{\n}gxms;
        }

        # Save the data...
        push @DATA, $contents;

        # Delete it from the source code, but leave the newlines...
        $data_block =~ tr[\n\0-\377][\n]d;

        $data_block;
    }gxmse;

    # Collect all declared package names...
    my %packages = (main=>1);
    s{ (\s* package \s+ ($QUAL_IDENT)) }{
        my ($package_decl, $package_name) = ($1,$2);
        $packages{$package_name} = 1;
        $package_decl;
    }gxmse;

    # Delete all other pod sections, preserving newlines...
    s{ ($POD_PAT) }{ my $text = $1; $text =~ tr[\n\0-\377][\n]d; $text }gxmse;

    # Consolidate data and open a filehandle to it...
    local *DATA_glob;
    my $DATA_as_str = join q{}, @DATA;
    *DATA_glob = \$DATA_as_str;
    *DATA_glob = \@DATA;
    open *DATA_glob, '<', \$DATA_as_str
        or require Carp
        and croak( "Can't set up *DATA handle ($!)" );

    # Alias each package's *DATA, @DATA, and $DATA...
    for my $package (keys %packages) {
        no strict 'refs'; 
        *{$package.'::DATA'} = *DATA_glob;
    }
#    warn "OUTPUT:". $_ ."<<<";

}


1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

(Perl6::Pod derived from Perl6::Perldoc by Damian Conway  C<< <DCONWAY@CPAN.org> >>)

=head1 CREDITS

Ivan Baidakou, <dmol@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

