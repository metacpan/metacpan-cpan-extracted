#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/24.error_propagation.t
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
    use_ok( 'PersonName::Format::Generic' )    || BAIL_OUT( 'Unable to load PersonName::Format::Generic' );
    use_ok( 'PersonName::Format::Exception' )  || BAIL_OUT( 'Unable to load PersonName::Format::Exception' );
    use_ok( 'PersonName::Format::NullObject' ) || BAIL_OUT( 'Unable to load PersonName::Format::NullObject' );
};

{
    # Hide from CPAN
    package
        Local::ErrorSource;
    use warnings::register;
    use parent qw( PersonName::Format::Generic );

    sub fail
    {
        my $self = shift( @_ );
        return( $self->error( 'Source failure.' ) );
    }
}

{
    # Hide from CPAN
    package
        Local::ErrorTarget;
    use warnings::register;
    use parent qw( PersonName::Format::Generic );

    sub propagate
    {
        my $self   = shift( @_ );
        my $source = shift( @_ );
        $source->fail;
        return( $self->pass_error( $source->error, { code => 'source_failure' } ) );
    }

    sub propagate_previous
    {
        my $self = shift( @_ );
        $self->error( 'Previous failure.' );
        return( $self->pass_error({ code => 'previous_failure' }) );
    }
}

my $source = Local::ErrorSource->new;
my $target = Local::ErrorTarget->new;

{
    no warnings 'Local::ErrorTarget';
    ok( !defined( $target->propagate( $source ) ), 'pass_error returns undef in scalar context' );
}
isa_ok( $target->error, 'PersonName::Format::Exception' );
is( $target->error->message, 'Source failure.', 'pass_error preserves the exception message' );
is( $target->error->code, 'source_failure', 'pass_error can attach an error code' );
is( refaddr( $target->error ), refaddr( $source->error ), 'pass_error preserves the original exception object' );

ok( !defined( $target->propagate_previous ), 'pass_error can propagate the current object error' );
is( $target->error->message, 'Previous failure.', 'the current error is propagated' );
is( $target->error->code, 'previous_failure', 'a code is attached to the current error' );

my $object_result = $target->error( 'Object-context failure.' );
# The assignment above is scalar context, so it remains undef.
ok( !defined( $object_result ), 'ordinary scalar context remains undef' );

my $null = $target->error( 'Expected object.' )->anything->deeper;
ok( !defined( $null ), 'PersonName::Format::NullObject' );

my $fatal = Local::ErrorTarget->new( fatal => 1 );
local $@;
my $caught;
eval
{
    $fatal->pass_error( PersonName::Format::Exception->new( 'Fatal propagation.' ) );
};
$caught = $@;
isa_ok( $caught, 'PersonName::Format::Exception' );
is( $caught->message, 'Fatal propagation.', 'fatal pass_error throws the propagated object' );

done_testing;

__END__
