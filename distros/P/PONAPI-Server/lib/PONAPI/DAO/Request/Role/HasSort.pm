# ABSTRACT: DAO request role - `sort`
package PONAPI::DAO::Request::Role::HasSort;

use Moose::Role;

has sort => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { +[] },
    handles  => {
        "has_sort" => 'count',
    },
);

sub _validate_sort {
    my ( $self, $args ) = @_;

    return unless defined $args->{sort};

    $self->has_sort
        or $self->_bad_request( "`sort` is missing values" );

    return;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasSort - DAO request role - `sort`

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
