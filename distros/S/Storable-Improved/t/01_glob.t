#!perl
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use Test::More qw( no_plan );
    use Storable::Improved ();
    use Scalar::Util ();
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

eval( "use IO::File ();" );
plan( skip_all => "IO::File required for testing GLOB with Storable::Improved" ) if( $@ );

my $io = IO::File->new( __FILE__, 'r' );
isa_ok( $io => 'IO::File' );
sub IO::File::STORABLE_freeze_pre_processing
{
    # diag( __PACKAGE__, "::STORABLE_freeze_pre_processing: Got arguments '", join( "', '", @_ ), "'" ) if( $DEBUG );
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    my $args = [ __FILE__, 'r' ];
    # We change the glob object into a regular hash-based one to be Storable-friendly
    my $this = bless( { args => $args, class => $class } => $class );
    return( $this );
}

sub IO::File::STORABLE_thaw_post_processing
{
    # diag( __PACKAGE__, "::STORABLE_thaw_post_processing: Got arguments '", join( "', '", @_ ), "'" ) if( $DEBUG );
    my $self = shift( @_ );
    my $args = $self->{args};
    my $class = $self->{class};
    # We restore our glob object. Geez that was hard. Not.
    my $obj = $class->new( @$args );
    return( $obj );
}

my $serial = Storable::Improved::freeze( $io );
ok( defined( $serial ) );
my $obj = Storable::Improved::thaw( $serial );
isa_ok( $obj => 'IO::File' );
ok( Scalar::Util::reftype( $obj ) => 'GLOB' );

done_testing();

__END__

