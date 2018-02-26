package Pithub::Users::Emails;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01034';
# ABSTRACT: Github v3 User Emails API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub add {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (arrayref)' unless ref $args{data} eq 'ARRAY';
    return $self->request(
        method => 'POST',
        path   => '/user/emails',
        %args,
    );
}


sub delete {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: data (arrayref)' unless ref $args{data} eq 'ARRAY';
    return $self->request(
        method => 'DELETE',
        path   => '/user/emails',
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    return $self->request(
        method => 'GET',
        path   => '/user/emails',
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Users::Emails - Github v3 User Emails API

=head1 VERSION

version 0.01034

=head1 METHODS

=head2 add

=over

=item *

Add email address(es)

    POST /user/emails

Examples:

    my $e = Pithub::Users::Emails->new( token => 'b3c62c6' );
    my $result = $e->add( data => [ 'plu@cpan.org', 'plu@pqpq.de' ] );

=back

=head2 delete

=over

=item *

Delete email address(es)

    DELETE /user/emails

Examples:

    my $e = Pithub::Users::Emails->new( token => 'b3c62c6' );
    my $result = $e->delete( data => [ 'plu@cpan.org', 'plu@pqpq.de' ] );

=back

=head2 list

=over

=item *

List email addresses for a user

    GET /user/emails

Examples:

    my $e = Pithub::Users::Emails->new( token => 'b3c62c6' );
    my $result = $e->list;

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
