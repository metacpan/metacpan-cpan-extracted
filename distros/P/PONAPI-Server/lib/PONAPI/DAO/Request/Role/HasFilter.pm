# ABSTRACT: DAO request role - `filter`
package PONAPI::DAO::Request::Role::HasFilter;

use Moose::Role;

has filter => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} },
    handles  => {
        "has_filter" => 'count',
    },
);

sub _validate_filter {
    my ( $self, $args ) = @_;

    return unless defined $args->{filter};

    $self->has_filter
        or $self->_bad_request( "`filter` is missing values" );

    return;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasFilter - DAO request role - `filter`

=head1 VERSION

version 0.003002

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
