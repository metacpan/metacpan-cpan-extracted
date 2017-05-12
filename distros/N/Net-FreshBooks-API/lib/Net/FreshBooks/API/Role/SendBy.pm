use strict;
use warnings;

package Net::FreshBooks::API::Role::SendBy;
$Net::FreshBooks::API::Role::SendBy::VERSION = '0.24';
use Moose::Role;
use Data::Dump qw( dump );

sub send_by_email {
    my $self = shift;
    return $self->_send_using( 'sendByEmail' );
}

sub send_by_snail_mail {
    my $self = shift;
    return $self->_send_using( 'sendBySnailMail' );
}

sub _send_using {
    my $self = shift;
    my $how  = shift;

    my $method   = $self->method_string( $how );
    my $id_field = $self->id_field;

    my $res = $self->send_request(
        {   _method   => $method,
            $id_field => $self->$id_field,
        }
    );

    # refetch the estimate so that the flags are updated.
    $self->get( { $id_field => $self->$id_field } );

    return 1;
}

1;

# ABSTRACT: Send by email and snail mail roles

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Role::SendBy - Send by email and snail mail roles

=head1 VERSION

version 0.24

=head1 SYNOPSIS

Roles for sending by email and snail mail. Used for both Estimates and
Invoices. Please refer to these modules for specific examples of how to use
these methods.

=head2 send_by_email

=head2 send_by_snail_mail

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
