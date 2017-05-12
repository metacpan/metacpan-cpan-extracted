package OpusVL::AppKit::Form::Login;

use strict;
use warnings;
use Moose;
use HTML::FormHandler::Moose;

use CatalystX::SimpleLogin::Form::Login;
extends 'CatalystX::SimpleLogin::Form::Login';

has_field '+password' => ( element_attr => { autocomplete => 'off' } );

override 'validate' => sub 
{
    my $self = shift;

    my %values = %{$self->values}; # copy the values
    my $rs = $self->ctx->model('AppKitAuthDB::User')->search(
        \[
            'lower(username) = ?', [ dummy => lc ($self->values->{username}) ]
        ]
    );
    unless (
        $self->ctx->authenticate(
            {
                password => $self->values->{password},
                dbix_class => {
                    resultset => $rs,
                }
            },
            ($self->has_authenticate_realm ? $self->authenticate_realm : ()),
        )
    ) {
        $self->add_auth_errors;
        return;
    }
    return 1;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Form::Login

=head1 VERSION

version 2.29

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
