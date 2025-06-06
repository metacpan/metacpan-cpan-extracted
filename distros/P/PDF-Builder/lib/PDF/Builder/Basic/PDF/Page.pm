#=======================================================================
#
#   THIS IS A REUSED PERL MODULE, FOR PROPER LICENCING TERMS SEE BELOW:
#
#   Copyright Martin Hosken <Martin_Hosken@sil.org>
#
#   No warranty or expression of effectiveness, least of all regarding
#   anyone's safety, is implied in this software or documentation.
#
#   This specific module is licensed under the Perl Artistic License.
#   Effective 28 January 2021, the original author and copyright holder, 
#   Martin Hosken, has given permission to use and redistribute this module 
#   under the MIT license.
#
#=======================================================================
package PDF::Builder::Basic::PDF::Page;

use base 'PDF::Builder::Basic::PDF::Pages';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Dict;
use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Basic::PDF::Page - Represents a PDF page

Inherits from L<PDF::Builder::Basic::PDF::Pages>

=head1 DESCRIPTION

Represents a page of output in PDF. It also keeps track of the content stream,
any resources (such as fonts) being switched, etc.

Page inherits from Pages due to a number of shared methods. They are really
structurally quite different.

=head1 INSTANCE VARIABLES

A page has various working variables:

=over

=item ' curstrm'

The currently open stream

=back

=head1 METHODS

=head2 new

    PDF::Builder::Basic::PDF::Page->new($pdf, $parent, $index)

=over

Creates a new page based on a pages object (perhaps the root object).

The page is also added to the parent at this point, so pages are ordered in
a PDF document in the order in which they are created rather than in the order
they are closed.

Only the essential elements in the page dictionary are created here, all others
are either optional or can be inherited.

The optional index value indicates the index in the parent list that this page
should be inserted (so that new pages need not be appended)

=back

=cut

sub new {
    my ($class, $pdf, $parent, $index) = @_;
    my $self = {};

    $class = ref($class) if ref($class);
    $self = $class->SUPER::new($pdf, $parent);
    $self->{'Type'} = PDFName('Page');
    delete $self->{'Count'};
    delete $self->{'Kids'};
    $parent->add_page($self, $index);
    
    return $self;
}

# the add() method was deleted from PDF::API2 2.034, but it looks like it
# still may be used in Builder.pm! apparently calls Content.pm's add().

#=head2 add
#
#    $p->add($str)
#
#=over
#
#Adds the string to the currently active stream for this page. If no stream
#exists, then one is created and added to the list of streams for this page.
#
#The slightly cryptic name is an aim to keep it short given the number of times
#people are likely to have to type it.
#
#=back
#
#=cut
#
#sub add {
#    my ($self, $string) = @_;
#
#    my $dict = $self->{' curstrm'};
#
#    unless (defined $dict) {
#        $dict = PDF::Builder::Basic::PDF::Dict->new();
#        foreach my $pdf (@{$self->{' destination_pdfs'}}) { 
#	    $pdf->new_obj($dict); 
#        }
#        $self->{'Contents'} = PDFArray() unless defined $self->{'Contents'};
#        unless (ref($self->{'Contents'}) eq 'PDF::Builder::Basic::PDF::Array') {
#	    $self->{'Contents'} = PDFArray($self->{'Contents'}); 
#        }
#        $self->{'Contents'}->add_elements($dict);
#        $self->{' curstrm'} = $dict;
#    }
#
#    $dict->{' stream'} .= $string;
#
#    return $self;
#}

=head2 ship_out

    $p->ship_out($pdf)

=over

Ships the page out to the given output file context

=back

=cut

sub ship_out {
    my ($self, $pdf) = @_;

    $pdf->ship_out($self);
    if (defined $self->{'Contents'}) {
        $pdf->ship_out($self->{'Contents'}->elements());
    }

    return $self;
}

1;
