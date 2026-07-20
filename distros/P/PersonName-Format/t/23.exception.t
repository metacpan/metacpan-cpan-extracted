#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/23.exception.t
##----------------------------------------------------------------------------
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    use Scalar::Util qw( refaddr );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use_ok( 'PersonName::Format::Exception' ) || BAIL_OUT( 'Unable to load PersonName::Format::Exception' );
    use_ok( 'PersonName::Format::Generic' )   || BAIL_OUT( 'Unable to load PersonName::Format::Generic' );
};

my $exception = PersonName::Format::Exception->new( 'Something ', sub{ 'went wrong.' } );
isa_ok( $exception, 'PersonName::Format::Exception' );
is( $exception->message, 'Something went wrong.', 'message is assembled from scalar and code arguments' );
ok( $exception, 'exception is true in boolean context' );
like( "$exception", qr/^Something went wrong\. within package /, 'exception stringifies with its origin' );
like( "$exception", qr/\n\z/, 'stringified exception ends with a newline for die()' );

$exception->code( 'bad_name' );
$exception->type( 'validation' );
$exception->retry_after( 5 );
is( $exception->code, 'bad_name', 'code accessor works' );
is( $exception->type, 'validation', 'type accessor works' );
is( $exception->retry_after, 5, 'retry_after accessor works' );

my $clone = $exception->clone;
isa_ok( $clone, 'PersonName::Format::Exception' );
isnt( refaddr( $clone ), refaddr( $exception ), 'clone returns a distinct object' );
is( $clone->message, $exception->message, 'clone preserves the message' );

{
    # Hide from CPAN
    package
        Local::FatalObject;
    use parent qw( PersonName::Format::Generic );

    sub fail
    {
        my $self = shift( @_ );
        return( $self->error( 'Fatal failure.' ) );
    }
}

my $fatal = Local::FatalObject->new( fatal => 1 );
my $caught;
eval
{
    $fatal->fail;
};
$caught = $@;
isa_ok( $caught, 'PersonName::Format::Exception' );
is( $caught->message, 'Fatal failure.', 'fatal errors throw the dedicated exception object' );

my $rethrown;
eval
{
    $caught->rethrow;
};
$rethrown = $@;
isa_ok( $rethrown, 'PersonName::Format::Exception' );
is( $rethrown->message, 'Fatal failure.', 'rethrow preserves the exception message' );

done_testing;

__END__
