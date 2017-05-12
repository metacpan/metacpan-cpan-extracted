# ABSTRACT: document builder - errors
package PONAPI::Document::Builder::Errors;

use Moose;

with 'PONAPI::Document::Builder';

has _errors => (
    init_arg => undef,
    traits   => [ 'Array' ],
    is       => 'ro',
    isa      => 'ArrayRef[ HashRef ]',
    lazy     => 1,
    default  => sub { +[] },
    handles  => {
        'has_errors' => 'count',
        # private ...
        '_add_error' => 'push',
    }
);

sub add_error {
    my ( $self, $error ) = @_;
    $self->_add_error( $error );
}

sub build {
    my $self = $_[0];
    return +[ @{ $self->_errors } ];
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Document::Builder::Errors - document builder - errors

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
