package MyTracer::Scope;

sub new {
    my $class = shift;
    my %data = @_;
    
    my $self = \%data;
    
    return bless $self, $class
}

sub close { ... }

sub get_span { ... }


BEGIN {
    
    use Role::Tiny::With;

    with OpenTracing::Interface::Scope;

}



1;
