package OpenTracing::Role::ScopeManager;

=head1 NAME

OpenTracing::Role::ScopeManager - Role for OpenTracing implementations.

=head1 SYNOPSIS

    package OpenTracing::Implementation::MyBackendService::ScopeManager;
    
    use Moo;
    
    with 'OpenTracing::Role::ScopeManager'
    
    sub activate_span { ... }
    
    sub get_active_scope { ... }
    
    1;

=cut

use Moo::Role;



=head1 DESCRIPTION

This is a role for OpenTracing implenetations that are compliant with the
L<OpenTracing::Interface>.

=cut



requires 'activate_span';



requires 'get_active_scope';



BEGIN {
#   use Role::Tiny::With;
    with 'OpenTracing::Interface::ScopeManager'
        if $ENV{OPENTRACING_INTERFACE};
}



1;
