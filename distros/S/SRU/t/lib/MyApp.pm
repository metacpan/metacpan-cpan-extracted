############################
## a harmless SRU::Server subclass 

package MyApp;

use base qw( SRU::Server );

sub explain {
    my $self = shift;
    my $response = $self->response();
    $response->record( 
        SRU::Response::Record->new(
            recordSchema => 'http://explain.z3950.org/dtd/2.0/',
            recordData   => '<foo>bar</foo>'
        )
    );
}

sub searchRetrieve {
}

sub scan {
}

1;
