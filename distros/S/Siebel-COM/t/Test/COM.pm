package Test::COM;
use Moose;

with 'Siebel::COM';

around BUILDARGS => sub {

    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        return $class->$orig( { _ole => $_[0] } );
    }
    else {
        return $class->$orig(@_);
    }

};

1;
