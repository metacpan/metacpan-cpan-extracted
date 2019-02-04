# ABSTRACT: DAO request role - `page`
package PONAPI::DAO::Request::Role::HasPage;

use Moose::Role;

has page => (
    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef',
    handles  => {
        "has_page" => 'count',
    },
);

sub _validate_page {
    my ( $self, $args ) = @_;

    return unless defined $args->{page};

    $self->has_page
        or $self->_bad_request( "`page` is missing values" );

    return;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasPage - DAO request role - `page`

=head1 VERSION

version 0.003003

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

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
