# ABSTRACT: request - role - has data
package PONAPI::Client::Request::Role::HasData;

use Moose::Role;

has _data => (
    init_arg  => 'data',
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
);

has data => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_data',
);

sub _build_data {
    my $self = shift;
    my $data = $self->_data;

    $data->{type} = $self->type if !defined $data->{type};
    $data->{id}   = $self->id   if !defined $data->{id}
                        && $self->does('PONAPI::Client::Request::Role::HasId');

    return $data;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request::Role::HasData - request - role - has data

=head1 VERSION

version 0.002012

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
