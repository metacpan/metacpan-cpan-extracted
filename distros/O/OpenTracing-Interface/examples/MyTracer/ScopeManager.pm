package MyTracer::ScopeManager;

sub new {
    my $class = shift;
    my %data = @_;
    
    my $self = \%data;
    
    return bless $self, $class
}

sub activate_span {
    my $self = shift;
    my $span = shift;
    my $finish_span_on_close = shift;
    
    print $finish_span_on_close ? "finish me" : "keep me alive";
    
    return MyTracer::Scope->new(
        
    )
}

sub get_active_scope { ... }


BEGIN {
    
    use Role::Tiny::With;

    with OpenTracing::Interface::ScopeManager;

}



1;
