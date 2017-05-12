package Pod::IkiWiki;
use strict;
use warnings;
use Carp;
use utf8;

use base qw(Pod::Parser);

use Pod::ParseUtils;

use constant {
    YES     =>  1,
    NOT     =>  0,
};

our $VERSION = '0.0.4';

my %search_in_level1 = (
    'author'        =>  qr{AUTHOR}xmsi,
    'title'         =>  qr{NAME}xmsi,
    'license'       =>  undef,
    'copyright'     =>  undef,
    'description'   =>  undef,
);

sub new {
    my  ($class,@params)    =   @_;
    my  $self               =   $class->SUPER::new( );

    if ($self) {
        # add private data as a hash ...
        $self->_private( @params );
    }

    return $self;
}

sub _private {
    my  $self   =   shift;
    my  %params =   @_;

    if (not exists $self->{_PACKAGE_}) {
        # initialize the internal structure: 
        $self->{_PACKAGE_} = {
            Paragraphs      =>  [],         # Paragraphs
            Globals         =>  {           # updatable values 
                Indent      =>  4,          # Spaces by indent level
                Metadata    =>  YES,        # Metadata scanning
                Wikilinks   =>  undef,      # Build wikilinks (undef) or insert into a base
                Formatters      =>  {       # Include special paragraph for these 
                    'ikiwiki'   =>  1,      # formatters 
                },
            },
            Meta            =>  {           # Meta directives: search only in level
                                            # one headers
                Title           =>  undef,  # Page title
                Author          =>  undef,  # Page author
                License         =>  undef,  
                Copyright       =>  undef,  
                Description     =>  undef,
            },
            LinkParser      =>  undef,      # Reference to parser links object
            ListCounter     =>  0,          # Lists counter
            ListType        =>  [],         # list type array: bullets, numbered or plain
            ActiveCommand   =>  undef,      # what is the active command ? 
            IgnoreParagraph =>  NOT,        # ignore paragraphs ?
            Searching       =>  undef,      # what are we search ? (title, author, undef ...)
        };

        #
        # Analyze the parameters
        #
       
        # Blank spaces for every indent level ...
        if (defined $params{'indent'}) {
            $self->{_PACKAGE_}->{Globals}->{Indent} = $params{indent};
        }

        # Don't scanning metadata ...
        if (defined $params{no_metadata}) {
            $self->{_PACKAGE_}->{Globals}->{Metadata} = NOT;
        }

        # Don't build ikiwiki wikilinks ...
        if (defined $params{links_base}) {
            $self->{_PACKAGE_}->{Globals}->{Wikilinks} = $params{links_base};
        }

        # Included special formatters ...
        if (defined $params{formatters}) {
            my @fmt_list = split(m{, }, $params{formatters});

            $self->{_PACKAGE}->{Globals}->{Formatters}->{$_} = 1 foreach @fmt_list;
        }
    }

    return $self->{_PACKAGE_};
}

sub _ignore_next_paragraph {
    my  $parser     =   shift;
    my  $switch     =   shift;
    
    $parser->_private()->{IgnoreParagraph} = $switch;

    return $parser;
}

sub _process_paragraph {
    my $parser      =   shift;

    return $parser->_private()->{IgnoreParagraph} == NOT;
}

sub dump_as_ikiwiki {
    my  $parser     =   shift;
    my  $data       =   $parser->_private();
    my  @ikiwiki   =   ();

    push(@ikiwiki, $parser->_build_mdwn_head());

    foreach my $pair (@{ $data->{Paragraphs} }) {
        push(@ikiwiki, $parser->_indent_text( $pair->[0], $pair->[1] ));
    }

    # add the necesary lines for every logical paragraph
    return join("\n" x 2, @ikiwiki );
}

#
#   This function adds meta directives for ikiwiki 
#

sub _build_mdwn_head {
    my  $parser         =   shift;
    my  $data           =   $parser->_private();
    my  @headerlines    =   ();

    # Add meta directives with content
    foreach my $meta_name (keys %{ $data->{Meta} }) {
        if (defined $data->{Meta}->{$meta_name}) {
            push( @headerlines, sprintf '[[meta %s="%s"]]', 
                                    lc $meta_name, 
                                    $data->{Meta}->{$meta_name} 
                );
        }
    }

    return @headerlines;
}

sub _save {
    my  $parser         =   shift;
    my  $text           =   shift;
    my  $indent_level   =   shift || 0;
    my  $data           =  $parser->_private();

    push @{ $data->{Paragraphs} }, [ $indent_level, $text ];

    return;
}

sub _indent_text {
    my  ($parser, $indent_level, $text)    = @_;
    my  $data               = $parser->_private();
    my  $indent             = '';

    if ($indent_level > 0) {
        $indent = ' ' x ($indent_level * $data->{Globals}->{Indent});
    }

    return sprintf '%s%s', $indent, $text;
}

sub _clean_text {
    my  $parser     =   shift;
    my  $text       =   shift;
    my  @trimmed    =   grep { $_; } split(/\n/, $text);

    return wantarray ? @trimmed : join("\n", @trimmed);
}

sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;
    my  $data   =   $parser->_private();

    # cleaning the text
    $paragraph = $parser->_clean_text( $paragraph );

    # saving the command name 
    $data->{ActiveCommand} = $command;

    # is it a header ? 
    if ($command =~ m{head(\d)}xms) {
        my  $level = $1;

        # the headers never are indented 
        $parser->_save( sprintf '%s %s', '#' x $level, $paragraph );

        # extract the next paragraph as metadata ?
        if ($level == 1) {
            $data->{Searching} = undef;

            if ($data->{Globals}->{Metadata} == YES) {
                foreach my $search_name (keys %search_in_level1) {
                    next if not defined $search_in_level1{$search_name};

                    if ($paragraph =~ $search_in_level1{$search_name}) {
                        $data->{Searching} = $search_name;
                        last;
                    }
                }
            }
        }

        $parser->_ignore_next_paragraph(NOT);
    }
    # is a list command ? 
    elsif ($command =~ m{over|back|item}xmsi) {
        $parser->_list_command( $command, $paragraph, $line_num );
    }
    # is a special formatter text ? 
    elsif ($command =~ m{begin|end|for}xms) {
        $parser->_special_formatter( $command, $paragraph, $line_num );
    }

    # ignore other commands
    return;
}

sub _list_command {
    my  $parser     =   shift;
    my  $command    =   shift;
    my  $paragraph  =   shift;
    my  $line_num   =   shift;
    my  $data       =   $parser->_private();

    # opening a list ? 
    if ($command =~ m{over}xms) {
        # update indent level     
        $data->{ListCounter} ++;

    # closing a list ?         
    } elsif ($command =~ m{back}xms) {
        # decrement indent level 
        $data->{ListCounter} --;

    }
    elsif ($command =~ m{item}xms) {
        my ($list_type, $paragraph) = $parser->_scan_list_type( $paragraph );

        # is this the first item viewed in the list ? 
        if (not defined $data->{ListType}->[ $data->{ListCounter} ]) {
            # yes, take his type as the list type
            $data->{ListType}->[ $data->{ListCounter} ] = $list_type;
        }
        else {
            # no, take the list type instead
            $list_type = $data->{ListType}->[ $data->{ListCounter} ];
        }

        # interpolate, indent (with trick) and save the text
        $parser->_save( sprintf ('%s %s', $list_type, 
                        $parser->interpolate($paragraph, $line_num) ),
                        $data->{ListCounter} - 1);
    } 

    return;
}

#
#   This function parses a item list and extracts the list type and the item
#   text.
#

sub _scan_list_type {
    my  ($parser, $paragraph)   =   @_;
    my  $data                   =   $parser->_private();
    my  $list_type              =   undef;
    my  $newparagraph           =   undef;

    # looking for a number and a period
    if ($paragraph =~ m{^(\d+.)\s+(.+)}) {
        $list_type      = '1.';
        $newparagraph   = $2;
    }
    # looking for an asterisk or a minus sign
    elsif ($paragraph =~ m{^([\*\-])\s+(.+)}) {
        $list_type      = '-';
        $newparagraph   = $2;
    }
    # select a default value 
    else {
        $list_type      = '-';
        $newparagraph   = $paragraph;
    }

    return ($list_type, $newparagraph);
}

sub _special_formatter {
    my  $parser     =   shift;
    my  $command    =   shift;
    my  $paragraph  =   shift;
    my  $line_num   =   shift;
    my  $data       =   $parser->_private();

    if ($command =~ m{begin}xmsi) {
        if (exists $data->{Globals}->{Formatters}->{lc $paragraph}) {
            $parser->_ignore_next_paragraph(NOT);
        }
        else {
            $parser->_ignore_next_paragraph(YES);
        }
    }
    elsif ($command =~ m{end}xmsi) {
        $parser->_ignore_next_paragraph(NOT);
    }
    elsif ($command =~ m{for}xmsi) {
        if ($paragraph =~ m{^(\w+)\s+(.+)$}xms) {
            if (exists $data->{Globals}->{Formatters}->{lc $1}) {
                # copy 
                $parser->_save( $parser->interpolate($2, $line_num) );
            }
        }
    }

    return;
}


sub verbatim {
    my ($parser, $paragraph, $line_num) =   @_;
    my  $data   = $parser->_private();

    if ($parser->_process_paragraph()) {
        $parser->_save( $parser->_clean_text($paragraph), 
                        $data->{ListCounter} + 1);
    }
}

sub textblock {
    my  ($parser, $paragraph, $line_num) = @_;
    my  $data   =   $parser->_private();

    if (not $parser->_process_paragraph()) {
        return;
    }

    # interpolate the paragraph for embebed sequences 
    $paragraph = $parser->interpolate( $paragraph, $line_num );

    # clean the empty lines
    $paragraph = $parser->_clean_text( $paragraph );

    # searching ?
    if ($data->{Searching}) {
        $data->{Meta}->{ucfirst $data->{Searching}} = $paragraph;
        $data->{Searching} = undef;
    }

    # save the text
    $parser->_save( $paragraph, $data->{ListCounter});
}

sub interior_sequence {
    my  ($parser, $seq_command, $seq_argument, $pod_seq) = @_;
    my  $data = $parser->_private();
    my  %interiores = (
        'I'     =>  sub { return '_'  . $_[1] . '_' },       # cursive
        'B'     =>  sub { return '__' . $_[1] . '__' },      # bold
        'C'     =>  sub { return '`'  . $_[1] . '`' },       # monospace
        'F'     =>  sub { return '`'  . $_[1] . '`' },       # system path
        'S'     =>  sub { return '`'  . $_[1] . '`' },       # code
        'E'     =>  sub {
                        my ($seq, $charname) = @_;

                        return '<' if $charname eq 'lt';
                        return '>' if $charname eq 'gt';
                        return '|' if $charname eq 'verbar';
                        return '/' if $charname eq 'sol';
                        return $charname;
                    },
        'L'     =>  sub {
                        $parser->_resolv_link( @_ ),
                    },
    );

    if (exists $interiores{$seq_command}) {
        my $code = $interiores{$seq_command};

        return $code->( $seq_command, $seq_argument, $pod_seq );
    }
    else {
        return sprintf '%s<%s>', $seq_command, $seq_argument;
    }
}

sub _resolv_link {
    my  $parser     =   shift;
    my  ($cmd, $arg, $pod_seq) = @_;
    my  $data       =   $parser->_private();

    if (not defined $data->{LinkParser}) {
        $data->{LinkParser} = Pod::Hyperlink->new( $arg );
    }
    else {
        $data->{LinkParser}->parse( $arg );
    }

    # if is a hyper link ...
    my $type = $data->{LinkParser}->type();
    if ($type eq 'hyperlink') {
        return sprintf '<%s>', $data->{LinkParser}->node();
    }
    elsif ($type =~ 'page|section|item') {
        return $parser->_build_page_link( $data->{LinkParser} );
    }

    return;
}

sub _build_page_link {
    my  $parser     =   shift;
    my  $link       =   shift;
    my  $data       =   $parser->_private();

    if (not defined $data->{Globals}->{Wikilinks}) {
        my  $wikilink   =   '[[';

        if ($link->alttext()) {
            $wikilink .= $link->alttext() . '|';
        }

        if ($link->page()) {
            $wikilink .= $link->page();
        }

        if ($link->node()) {
            $wikilink .= '#' . $link->node();
        }

        $wikilink .= ']]';

        return $wikilink;
    }
    else {
        return sprintf ($data->{Globals}->{Wikilinks} . '%s', $link->page());
    }

}

1;

__END__

=head1 NAME

Pod::IkiWiki - Pod translator to IkiWiki's Markdown format

=head1 VERSION

This documentation refers to Pod::IkiWiki version 0.0.3

=head1 SYNOPSIS

	use Pod::IkiWiki;

    my $parser = Pod::IkiWiki->new();

    $parser->parse_from_file( $my_input_file );

    print STDOUT $parser->dump_as_ikiwiki();

=head1 DESCRIPTION

This package provides a POD translator for ikiwiki's markdown format.

=head1 SUBROUTINES/METHODS

This package inherits from L<Pod::Parser> and his public methods are the same.

There are some particularities in some public methods such as the cleaning
process of empty lines.

=head2 new( )

Build a new parser object and adds a private data structure under the key
_PACKAGE_.

Accepts the following options: 

=over

=item indent

Set the number of the blank spaces for every indentation level. By default is four (4) spaces.

=item no_metadata

Disable the metadata scanning. By default is enabled.

=item no_links

Disable the build of wikilinks for all links without protocol scheme. By
default is enabled.

=item formatters

Add one or more formatter's names for included in the markdown source. By
default only the ikiwiki special formatter is enabled.

=back

=head2 command( )

This method process the following groups of POD commands:

=over

=item headers

If it found a level one header the function tries to extract special
information about the document, such as the author name, the title or the
license.

=item lists

Support nested, ordered and unordered lists.

=item special formatters

By now the function acknowledges the special formatter I<ikiwiki> and ignores
everything else.

=back

=head2 dump_as_ikiwiki( )

After a succesfull parse of the POD source, this object method returns a
IkiWiki source file. 

=head2 verbatim( )

Verbatim copy of the source paragraph without interpolating.

=head2 textblock( )

Interpolate, clean and save the paragraph and respect the indentation.

=head2 interior_sequence( )

This function support several special sequences, such as I<italic text>, B<bold
text>, C<code text>, F<filename>, S<non-breaking spaces> and some I<escaped
characters>.

On the other hand it provides support for POD links and ikiwiki metalinks. If
the link begins with a scheme name such as I<http> or I<ftp> the function make
a direct link; otherwise it builds a ikiwiki link.

=head1 DIAGNOSTICS

A list of every error and warning message that the module
can generate.

=head1 CONFIGURATION AND ENVIRONMENT

Don't need any special configuration or environment changes.

=head1 DEPENDENCIES

=over

=item L<Pod::Parser>

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module; please report problems to the author.
Patches are welcome also.

=head1 AUTHOR

Victor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 <Victor Moral>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

