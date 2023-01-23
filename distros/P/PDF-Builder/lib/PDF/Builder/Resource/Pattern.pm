package PDF::Builder::Resource::Pattern;

use base 'PDF::Builder::Resource';

use strict;
use warnings;

our $VERSION = '3.025'; # VERSION
our $LAST_UPDATE = '2.031'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::Pattern - support stub for patterns. Inherits from L<PDF::Builder::Resource>

=cut

sub new {
    my ($class, $pdf, $name) = @_;

    my $self = $class->SUPER::new($pdf, $name);

    $self->type('Pattern');

    return $self;
}

1;
