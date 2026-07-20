#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/22.object.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'PersonName::Format::Generic' ) || BAIL_OUT( 'Unable to load PersonName::Format::Generic' );
    use_ok( 'PersonName::Format::Name' )    || BAIL_OUT( 'Unable to load PersonName::Format::Name' );
};

{
    # Hide from CPAN
    package
        Local::Object;
    use parent qw( PersonName::Format::Generic );

    sub init
    {
        my $self = shift( @_ );
        my $args = $self->_get_args_as_hash( @_ );
        $self->SUPER::init(
            debug => delete( $args->{debug} ),
            fatal => delete( $args->{fatal} ),
        );
        return( $self->error( "Unknown option." ) ) if( keys( %$args ) );
        return( $self );
    }
}

my $object = Local::Object->new( debug => $DEBUG );
isa_ok( $object, 'Local::Object' );
is( $object->debug, ( $DEBUG ? $DEBUG : 0 ), 'debug defaults to ' . ( $DEBUG ? 'true' : 'false' ) );
is( $object->fatal, 0, 'fatal defaults to false' );

$object->debug(1);
is( $object->debug, 1, 'scalar accessor can set a value' );

ok( !Local::Object->new( unsupported => 1 ), 'constructor failure returns undef' );
isa_ok( Local::Object->error, 'PersonName::Format::Exception' );
is( Local::Object->error->message, 'Unknown option.', 'class error is available after constructor failure' );

ok(
    PersonName::Format::Name->implements_name_contract( bless( {}, 'Local::NameContract' ) ) == 0,
    'name contract rejects an object without methods',
);

done_testing;

__END__
