package MyTracer::Tracer;

use MyTracer::Scope;
use MyTracer::ScopeManager;

sub new {
    my $class = shift;
    my %data = @_;
    
    my $self = \%data;
    
    return bless $self, $class
}

sub get_active_span { ... }

sub start_active_span {

{ use Data::Dumper; local $Data::Dumper::Sortkeys = 1; warn Dumper(@_) . "\n"; } # XXX REMOVE ME

    my $self = shift;
    
    MyTracer::Scope->new( );
}

sub get_scope_manager { 
    my $self = shift;
    
    MyTracer::ScopeManager->new( );
}

sub start_span { ... }

sub inject_context { ... }

sub extract_context { ... }

BEGIN {
    
    use Role::Tiny::With;

    with OpenTracing::Interface::Tracer;

}



1;
