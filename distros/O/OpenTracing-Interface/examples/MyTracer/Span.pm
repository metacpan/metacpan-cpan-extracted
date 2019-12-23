package MyTracer::Span;

use MyTracer::SpanContext;

sub new {
    my $class = shift;
    my %data = @_;
    
    my $self = \%data;
    
    return bless $self, $class
}


sub get_context {
    my $self = shift;
    
    my $ctx = MyTracer::SpanContext->new( Bar => "Qux" );
    
    return $ctx
};

sub overwrite_operation_name { ... };

sub finish { ... };

sub set_tag {
    my $self = shift;
    
    print"@_\n";
    
    return $self
};

sub log_data {
    my $self = shift;
    
    print"@_\n";
    
    return $self
};

sub set_baggage_item { ... };

sub get_baggage_item { "booh" };

BEGIN {
    
    use Role::Tiny::With;

    with OpenTracing::Interface::Span;

}



1;
