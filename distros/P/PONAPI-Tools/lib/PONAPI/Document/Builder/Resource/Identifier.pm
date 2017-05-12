# ABSTRACT: document builder - resource identifier
package PONAPI::Document::Builder::Resource::Identifier;

use Moose;

with 'PONAPI::Document::Builder',
     'PONAPI::Document::Builder::Role::HasMeta';

has id   => ( is => 'ro', isa => 'Str', required => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );

sub build {
    my $self   = $_[0];
    my $result = {};

    $result->{id}   = $self->id;
    $result->{type} = $self->type;
    $result->{meta} = $self->_meta if $self->has_meta;

    return $result;
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Resource::Identifier - document builder - resource identifier

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
