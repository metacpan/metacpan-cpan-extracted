#!perl
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Storable::Improved ();
    use HTTP::XSHeaders ();
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

eval( "use HTTP::XSHeaders ();" );
plan( skip_all => "HTTP::XSHeaders required for testing XS with Storable::Improved" ) if( $@ );

sub HTTP::XSHeaders::STORABLE_freeze
{
    my( $self, $cloning ) = @_;
    return if( $cloning );
    my $class = ref( $self ) || $self;
    my $h = {};
    my $headers = [];
    my $order = [];
    $self->scan(sub
    {
        my( $f, $val ) = @_;
        if( exists( $h->{ $f } ) )
        {
            $headers->{ $f } = [ $h->{ $f } ] unless( ref( $h->{ $f } ) eq 'ARRAY' );
            push( @{$h->{ $f }}, $val );
        }
        else
        {
            $h->{ $f } = $val;
            push( @$order, $f );
        }
    });
    foreach my $f ( @$order )
    {
        push( @$headers, $f, $h->{ $f } );
    }
    my %hash  = %$self;
    $hash{_headers_to_restore} = $headers;
    return( $class, \%hash );
}

sub HTTP::XSHeaders::STORABLE_thaw
{
    my( $self, undef, $class, $hash ) = @_;
    $class //= ref( $self ) || $self;
    $hash //= {};
    $hash->{_class} = $class;
    $self->{_deserialisation_params} = $hash;
    # Useles to do more in STORABLE_thaw, because Storable anyway ignores the value returned
    # so we just store our hash of parameters for STORABLE_thaw_post_processing to do its actual job
    return( $self );
}

sub HTTP::XSHeaders::STORABLE_thaw_post_processing
{
    my $obj = shift( @_ );
    my $hash = ( exists( $obj->{_deserialisation_params} ) && ref( $obj->{_deserialisation_params} ) eq 'HASH' )
        ? delete( $obj->{_deserialisation_params} )
        : {};
    my $class = delete( $hash->{_class} ) || ref( $obj ) || $obj;
    my $headers = ref( $hash->{_headers_to_restore} ) eq 'ARRAY'
        ? delete( $hash->{_headers_to_restore} )
        : [];
    my $new = $class->new( @$headers );
    foreach( keys( %$hash ) )
    {
        $new->{ $_ } = delete( $hash->{ $_ } );
    }
    return( $new );
}

my $h = HTTP::XSHeaders->new(
    Content_Type => 'text/html; charset=utf8',
);
isa_ok( $h => 'HTTP::XSHeaders' );
is( $h->header( 'Content-Type' ) => 'text/html; charset=utf8', 'Content-Type header' );
diag( "Serialising." ) if( $DEBUG );
my $serial = Storable::Improved::freeze( $h );
my $h2 = Storable::Improved::thaw( $serial );
isa_ok( $h2 => 'HTTP::XSHeaders', 'deserialised object is of class HTTP::XSHeaders' );
diag( "Can header? ", ( $h2->can( 'header' ) ? 'yes' : 'no' ) ) if( $DEBUG );
ok( ( Scalar::Util::blessed( $h2 ) && $h2->can( 'header' ) ), 'deserialised object can "header"' );
is( $h2->header( 'Content-Type' ) => 'text/html; charset=utf8', 'accessing Content-Type header with deserialised object' );

done_testing();

__END__


