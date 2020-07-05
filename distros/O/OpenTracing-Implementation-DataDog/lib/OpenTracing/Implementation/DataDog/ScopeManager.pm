package OpenTracing::Implementation::DataDog::ScopeManager;



=head1 NAME

OpenTracing::Implementation::DataDog::ScopeManager - Keep track of active scopes

=head1 SYNOPSIS

    my $span = $TRACER->build_span( ... );
    
    my $scope_manager = $TRACER->get_scope_manager;
    
    my $scope = $scope_manager->build_scope(
        span                 => $span,
        finish_span_on_close => true,
    );
    
    ...
    
    $scope->close;

=cut

our $VERSION = 'v0.41.2';

use Moo;

use OpenTracing::Implementation::DataDog::Scope;

has '+active_scope' => (
    clearer => 'final_scope',
);

=head1 DELEGATED INSTANCE METHODS



=head2 build_scope

This method will build a new C<Scope> object, that, when C<close> is being
called (which you should), the current scope is being set back as the active
scope.

See L<OpenTracing::Roles::ScopeManager> for the description of the method.

=cut

sub build_scope {
    my $self = shift;
    my $options = { @_ };
    
    my $current_scope = $self->get_active_scope;
    
    my $scope = OpenTracing::Implementation::DataDog::Scope->new(
        span                 => $options->{ span },
        finish_span_on_close => $options->{ finish_span_on_close },
        on_close             => sub {
            $current_scope ?
                $self->set_active_scope( $current_scope )
                :
                $self->final_scope() #clear
        }
    );
    
    return $scope
}



BEGIN {
    with 'OpenTracing::Role::ScopeManager';
}



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::ScopeManager>

Role for OpenTracing implementations.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
