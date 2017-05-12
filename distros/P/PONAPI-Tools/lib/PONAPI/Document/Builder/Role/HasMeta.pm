# ABSTRACT: document builder - role - meta
package PONAPI::Document::Builder::Role::HasMeta;

use Moose::Role;

has _meta => (
    init_arg => undef,
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        has_meta  => 'count',
    }
);

sub add_meta {
    my ($self, %args) = @_;
    @{ $self->_meta }{ keys %args } = values %args;
    return $self;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Role::HasMeta - document builder - role - meta

=head1 VERSION

version 0.001002

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
