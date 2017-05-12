#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Role::XMLRPC;
{
  $Net::Gandi::Role::XMLRPC::VERSION = '1.122180';
}

# ABSTRACT: A Perl interface for gandi api

use XMLRPC::Lite;
use Moose::Role;
use MooseX::Types::Moose 'Str';

use Carp;

has '_proxy' => (
    is       => 'ro',
    isa      => 'XMLRPC::Lite',
    builder  => '_build_proxy',
    init_arg => undef,
    lazy     => 1,
);

sub _build_proxy {
    my ( $self ) = @_;

    my $proxy = XMLRPC::Lite->proxy($self->apiurl, timeout => $self->timeout );
    $proxy->transport->agent($self->useragent);

    $proxy;
}

sub api_call {
    my ( $self, $method, @args ) = @_;

    my $api_response = $self->_proxy->call($method, $self->apikey, @args);

    if ( $api_response->faultstring() ) {
        $self->err($api_response->faultcode());
        $self->errstr($api_response->faultstring());
        croak 'Error: ' . $self->err . ' ' . $self->errstr;
    }

    return $self->date_to_datetime
        ? $self->_date_to_datetime($api_response->result())
        : $api_response->result();
}


sub cast_value {
    my ( $self, $type, $value ) = @_;

    return XMLRPC::Data->type($type)->value($value);
}

1;

__END__
=pod

=head1 NAME

Net::Gandi::Role::XMLRPC - A Perl interface for gandi api

=head1 VERSION

version 1.122180

=head1 cast_value

Force XMLRPC data types, to use before calls when using booleans for example.

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

