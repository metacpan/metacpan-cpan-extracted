package MyTracer::SpanContext;

sub new {
    my $class = shift;
    my %data = @_;
    
    my $self = \%data;
    
    return bless $self, $class
}

sub get_baggage_item { ... }

sub with_baggage_item { ... }


BEGIN {
    
    use Role::Tiny::With;

    with OpenTracing::Interface::SpanContext;

}



1;
