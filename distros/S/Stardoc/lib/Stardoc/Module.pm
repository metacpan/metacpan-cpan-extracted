##
# name:      Stardoc::Module
# abstract:  Stardoc Module base class
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Stardoc::Module;
use Mouse;

has file => (is => 'ro');
has string => (is => 'ro');

has meta => (is => 'ro', default => sub {+{}});

has sections => (
    is => 'ro',
    default => sub{[]},
);

sub has_doc {
    my ($self) = @_;
    return exists $self->meta->{name};
}

1;
