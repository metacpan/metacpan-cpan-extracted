# ABSTRACT: DAO request role - `include`
package PONAPI::DAO::Request::Role::HasInclude;

use Moose::Role;

has include => (
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef',
    default  => sub { +[] },
    handles  => {
        "has_include" => 'count',
    },
);

sub _validate_include {
    my ( $self, $args ) = @_;

    return unless defined $args->{include};

    return $self->_bad_request( "`include` is missing values" )
        unless $self->has_include >= 1;

    my $type = $self->type;

    for ( @{ $self->include } ) {
        $self->repository->has_relationship( $type, $_ )
            or $self->_bad_request( "Types `$type` and `$_` are not related", 404 );
    }
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasInclude - DAO request role - `include`

=head1 VERSION

version 0.003001

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
