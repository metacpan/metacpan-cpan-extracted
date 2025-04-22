package PDF::Builder::Outlines;

use base 'PDF::Builder::Outline';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Outlines - Further Outline handling

Inherits from L<PDF::Builder::Outline>

This creates the I<root> of any collection of Uutline entries. It is thus
limited to one instance in a document, although it may be called multiple
times to provide the root to Outline calls (see Examples).

=cut

sub new {
    my ($class, $api) = @_;

    # creates a new Outlines object only if one doesn't already exist
    my $self = $class->SUPER::new($api);
    $self->{'Type'} = PDFName('Outlines');

    return $self;
}

sub count {
    my $self = shift();
    return abs($self->SUPER::count());
}

1;
