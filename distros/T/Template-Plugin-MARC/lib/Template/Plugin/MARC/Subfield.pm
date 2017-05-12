package Template::Plugin::MARC::Subfield;

=head1 Template::Plugin::MARC::Subfield

Object class to allow nested auto-loading. Not used directly.

=cut


use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

sub new {
    my ($class, $code, $value) = @_;

    return bless {
        code => $code,
        value => $value,
    }, $class;
}

sub code {
    my $self = shift;
    return $self->{'code'};
}

sub value {
    my $self = shift;
    return $self->{'value'};
}

1;

