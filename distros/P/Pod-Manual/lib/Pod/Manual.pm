package Pod::Manual;

use Object::InsideOut;

use warnings;
no warnings qw/ uninitialized /;
use strict;
use Carp;

use Cwd;
use XML::LibXML;
use Pod::XML;
use Pod::Find qw/ pod_where /;
use XML::XPathScript;
use Pod::Manual::PodXML2Docbook;
use Pod::Manual::Docbook2LaTeX;

our $VERSION = '0.08';

my @parser_of        :Field;
my @dom_of           :Field;
my @appendix_of      :Field;
my @root_of          :Field;
my @ignored_sections :Field;
my @doc_title_of     :Field;

sub _init :Init {
    my $self = shift;
    my $args_ref = shift;

    my $parser = $parser_of[ $$self ] = XML::LibXML->new;

    $dom_of[ $$self ] = $parser->parse_string(
        '<book><bookinfo><title/></bookinfo></book>' 
    );

    $dom_of[ $$self ]->setEncoding( 'iso-8859-1' );

    $root_of[ $$self ] = $dom_of[ $$self ]->documentElement;

    $appendix_of[ $$self ] = undef;

    if ( my $title = $args_ref->{ title } ) {
        $self->_set_doc_title( $title );
    }

    if ( my $x = $args_ref->{ignore_sections} ) {
        push @{ $ignored_sections[ $$self ] }, ref $x ? @$x : $x ;
    }

}

sub _set_doc_title {
    my( $self, $title ) = @_;

    $doc_title_of[ $$self ] = $title;
    my $title_node = $dom_of[ $$self ]->findnodes( '/book/bookinfo/title')
                                      ->[0];
    # remove any possible title already there
    $title_node->removeChild( $_ ) for $title_node->childNodes;

    $title_node->appendText( $title );

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _find_module_pod {
    my $self = shift;
    my $module = shift;

    my $file_location = pod_where( { -inc => 1 }, $module )
        or die "couldn't find pod for module $module\n";

    local $/ = undef;
    open my $pod_fh, '<', $file_location 
        or die "can't open pod file $file_location: $!";

    return <$pod_fh>;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _convert_pod_to_xml {
    my $self = shift;
    my $pod = shift;

    my $parser = Pod::XML->new;

    my $podxml;
    local *STDOUT;
    open STDOUT, '>', \$podxml;
    open my $input_fh, '<', \$pod;
    $parser->parse_from_filehandle( $input_fh );

    $podxml =~ s/xmlns=".*?"//;
    $podxml =~ s#]]></verbatim>\n<verbatim><!\[CDATA\[##g;

    my $dom = eval { 
        $parser_of[ $$self ]->parse_string( $podxml ) 
    } or die "error while converting raw pod to xml for '$pod': $@";

    return $dom;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _get_podxml {
    my $self = shift;
    my $pod = shift;

    my $pod_location = pod_where( { -inc => 1 }, $pod );

    my $parser = Pod::XML->new;

    my $podxml;
    local *STDOUT;
    open STDOUT, '>', \$podxml;
    $parser->parse_from_file( $pod_location );
    close STDOUT;

    $podxml =~ s/xmlns=".*?"//;
    $podxml =~ s#]]></verbatim>\n<verbatim><!\[CDATA\[##g;

    my $dom = eval { 
        $parser_of[ $$self ]->parse_string( $podxml ) 
    } or die "error while converting raw pod to xml for '$pod': $@";

    return $dom;
}

sub add_chapters { 
    my $self = shift;
    my $options = 'HASH' eq ref $_[-1] ?  %{ pop @_ } : { };

    $self->add_chapter( $_ => $options ) for @_;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub add_chapter {
    my $self = shift;
    my $chapter = shift;

    my $options = 'HASH' eq ref $_[-1] ? pop @_ : { };

    my $podxml;
   
    # the chapter can be passed as various things
    if ( $chapter =~ /\n/ ) {   # it's pure pod
        $podxml = $self->_convert_pod_to_xml( $chapter );
    }
    elsif ( -f $chapter ) {     # it's a file
        local $/ = undef;
        open my $pod_fh, '<', $chapter 
            or die "can't open pod file $chapter: $!";
        $podxml = $self->_convert_pod_to_xml( <$pod_fh> );
    }
    else {                     # it's a module name
        $podxml = $self->_convert_pod_to_xml( 
                        $self->_find_module_pod( $chapter ) 
        );
    }

    my $dom = $dom_of[ $$self ];

    my $docbook = XML::XPathScript->new->transform( $podxml, 
            $Pod::Manual::PodXML2Docbook::stylesheet );

    my $subdoc = eval { 
        XML::LibXML->new->parse_string( $docbook )->documentElement;
    };

    if ( $@ ) {
        croak "chapter couldn't be converted to docbook: $@";
    }

    # use the title of that section if the 'doc_title' option is
    # used, or if there are no title given yet
    if ( $options->{set_title} or not defined $doc_title_of[ $$self ] ) {
        my $title = $subdoc->findvalue( '/chapter/title/text()' );
        $title =~ s/\s*-.*//;  # remove desc after the '-'
        $self->_set_doc_title( $title ) if $title;
    }


    $dom->adoptNode( $subdoc );

    # if there is no appendix, it adds the chapter
    # at the end of the document
    $root_of[ $$self ]->insertBefore( $subdoc, $appendix_of[ $$self ] );

    if ( my $list = $options->{move_to_appendix} ) {
        for my $section_title ( ref $list ? @{ $list  } : $list ) {
            $self->_add_to_appendix( 
                grep { $_->findvalue( 'title/text()' ) eq $section_title }
                     $subdoc->findnodes( 'section' )
            );
        }
    }

    if ( $ignored_sections[ $$self ] ) {
        my %to_ignore = map { $_ => 1 } @{ $ignored_sections[ $$self ] };
        for my $section ( $subdoc->findnodes( 'section' ) ) {
            my $title = $section->findvalue( 'title/text()' );
            if ( $to_ignore{$title} ) {
                $section->parentNode->removeChild( $section );
            }
        }
    }

    return $self;
}

sub as_dom {
    my $self = shift;
    return $dom_of[ $$self ];
}

sub as_docbook {
    my $self = shift;
    my %option = ref $_[0] eq 'HASH' ? %{ $_[0] } : () ;

    my $dom = $dom_of[ $$self ];

    if ( my $css = $option{ css } ) {
        # make a copy of the dom so that we're not stuck with the PI
        $dom = $parser_of[ $$self ]->parse_string( $dom->toString );

        my $pi = $dom->createPI( 'xml-stylesheet' 
                                    => qq{href="$css" type="text/css"} );
        $dom->insertBefore( $pi, $dom->firstChild );
    }

    return $dom->toString;
}

sub as_latex {
    my $self = shift;

    my $xps = XML::XPathScript->new;

    my $docbook = eval { $xps->transform( 
         $self->as_docbook => $Pod::Manual::Docbook2LaTeX::stylesheet
    ) } ;

    croak "couldn't convert to docbook: $@" if $@;

    return $docbook;
}

sub save_as_pdf {
    my $self = shift;
    my $filename = shift 
        or croak 'save_as_pdf: requires a filename as an argument';

    $filename =~ s/\.pdf$// 
        or croak "save_as_pdf: filename '$filename'"
                ."must have suffix '.pdf'";

    my $original_dir = cwd();    # let's remember where we are

    if ( $filename =~ s#^(.*)/## ) {
        chdir $1 or croak "can't chdir to $1: $!";
    }

    my @temp_files = grep { -e } map "$filename.$_" => qw/ aux log pdf tex toc /;
    if ( @temp_files ) {
        chdir $original_dir;
        my $plural = 's' x ( @temp_files > 1 );
        die "temp file$plural " . join( ' ', @temp_files )
                            . " in the way, please remove\n";
        return 0;
    }

    my $latex = $self->as_latex;

   die $@ if $@;

   open my $latex_fh, '>', $filename.'.tex' 
       or croak "can't write to '$filename.tex': $!";
   print {$latex_fh} $latex;
   close $latex_fh;

    for ( 1..2 ) {       # two times to populate the toc
        system "pdflatex -interaction=batchmode $filename > /dev/null";
           # and croak "problem running pdflatex: $!";
    }

   for my $ext ( qw/ aux log tex toc / ) {
       unlink "$filename.$ext" or croak "can't delete '$filename.$ext': $!";
   }

    chdir $original_dir;

    return 1;
}

sub _add_to_appendix {
    my ( $self, @nodes ) = @_;

    unless ( $appendix_of[ $$self ] ) {
        # create appendix
        $root_of[ $$self ]->appendChild( 
            $appendix_of[ $$self ] = $root_of[ $$self ]->new( 'appendix' )
        );
        my $label = $appendix_of[ $$self ]->new( 'label' );
        $label->appendText( 'Appendix' );
        $appendix_of[ $$self ]->appendChild( $label );
    }

    $appendix_of[ $$self ]->appendChild( $_ ) for @nodes;

    return $self;
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Pod::Manual - Aggregates several PODs into a single manual

=head1 VERSION

This document describes Pod::Manual version 0.08

This module is still in early development and must be 
considered as alpha quality. Use with caution.


=head1 SYNOPSIS

    use Pod::Manual;

    my $manual = Pod::Manual->new({ title => 'Pod::Manual' });

    $manual->add_chapter( 'Pod::Manual' );

    my $docbook = $manual->as_docbook;


=head1 DESCRIPTION

The goal of B<Pod::Manual> is to gather the pod of several 
modules into a comprehensive manual.  Its primary objective
is to generate a document that can be printed, but it also
allow to output the document into other formats 
(e.g., docbook).

=head1 METHODS

=head2 new( I< %options > )

Creates a new manual. Several options can be passed to the 
constructor:

=over

=item title => $title

Sets the title of the manual to I<$title>.

=item ignore_sections => \@section_names

When importing pods, discards any section having its title listed
in I<@section_names>.

=back

=head2 add_chapter( I<$module>, \%options )

    $manual->add_chapter( 'Pod::Manual', { set_title => 1 } );

Adds the pod of I<$module> to the manual.

=over

=item set_title

If true, uses the shortened title of the chapter as the title
of the manual. 

=back

=head2 add_chapters( I<@modules>, \%options )

    $manual->add_chapters( 'Some::Module', 'Some::Other::Module' )

Adds the pod of several modules to the manual.

=head2 as_docbook( { css => $filename } )

    print $manual->as_docbook({ css => 'stylesheet.css' });

Returns the manual in a docbook format. If the option I<css> 
is given, a 'xml-stylesheet' PI pointing to I<$filename> will
be added to the document. 

=head2 as_latex

    print $manual->as_latex;

Returns the manual in a LaTeX format.

=head2 save_as_pdf( $filename )

    $manual->save_as_pdf( '/path/to/document.pdf' );

Saves the manual as a pdf file. Several temporary
files will be created (and later on 
cleaned up) in the same directory. If any of those files
already exist, the method will abort.

Returns 1 if the pdf has been created, 0 otherwise.

B<NOTE>: this function requires to have 
TeTeX installed and I<pdflatex> accessible
via the I<$PATH>.


=head1 BUGS AND LIMITATIONS

As this is a preliminary release, a lot of both.

Please report any bugs or feature requests to
C<bug-pod-manual@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 REPOSITORY

Pod::Manual's development git repository can be accessed at
http://babyl.dyndns.org/git/pod-manual.git.

=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
