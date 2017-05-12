{
package Foo;
use strict;
use warnings;


sub new {
    my $class = shift;
    my %args  = @_;

    my $self = bless \%args, $class;

    $self->{thing} //= q[23];

    return $self;
}

if( !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor } ) {
Class::XSAccessor->import(
    accessors => { q[thing] => q[thing] }
);

}
else {
*thing = sub {
    # This is hand optimized.  Yes, even adding
    # return will slow it down.
    @_ > 1 ? $_[0]->{ q[thing] } = $_[1]
           : $_[0]->{ q[thing] };
}

}

1;
}