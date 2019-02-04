# ABSTRACT: DAO request role - `id`
package PONAPI::DAO::Request::Role::HasID;

use Moose::Role;

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

sub _validate_id {
    my $self = shift;

    $self->_bad_request( "`id` is missing for this request" )
        unless $self->has_id;
}

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::DAO::Request::Role::HasID - DAO request role - `id`

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
