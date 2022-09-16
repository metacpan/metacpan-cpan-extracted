package PDF::Builder::Outlines;

use base 'PDF::Builder::Outline';

use strict;
use warnings;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.024'; # manually update whenever code is changed

use PDF::Builder::Basic::PDF::Utils;

=head1 NAME

PDF::Builder::Outlines - further Outline handling. Inherits from L<PDF::Builder::Outline>

=cut

sub new {
    my ($class, $api) = @_;

    my $self = $class->SUPER::new($api);
    $self->{'Type'} = PDFName('Outlines');

    return $self;
}

sub count {
    my $self = shift();
    return abs($self->SUPER::count());
}

1;
