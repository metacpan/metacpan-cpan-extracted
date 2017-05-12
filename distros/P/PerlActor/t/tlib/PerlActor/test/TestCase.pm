package PerlActor::test::TestCase;

use base 'Test::Unit::TestCase';
use strict;
use Error qw( :try );
use PerlActor::Exception;

#===============================================================================================
# Public Methods
#===============================================================================================

sub assert_exception
{
	my $self = shift;
	my $exceptionClass = shift;
	my $code = shift;
	my $exception;
	try
	{
		&$code;
	}
	catch $exceptionClass with
	{
		$exception = shift;
	};
	$self->assert($exception, "did not throw exception '$exceptionClass'");
}

sub assert_no_exception
{
	my $self = shift;
	my $code = shift;
	my $exception = '';
	try
	{
		&$code;
	}
	catch PerlActor::Exception with
	{
		$exception = shift;
	};
	$self->assert(!$exception, "caught unexpected exception: '$exception'");
}

sub assert_array_equals
{
	my $self = shift;
	my $expectedRef = shift;
	my $arrayRef = shift;
	
	my @expected = @$expectedRef;
	my @array = @$arrayRef;
		
	my $message = $self->_make_array_message($expectedRef, $arrayRef);	
	$self->assert(scalar @expected == scalar @array, "arrays contains incorrect number of items: $message");
	
	while (my $item = shift @array)
	{
		my $expectedItem = shift @expected;
		$self->assert_str_equals($expectedItem, $item, "array items don't match: $message");
	}
}

#===============================================================================================
# Protected Methods - Don't even think about calling these from outside the class.
#===============================================================================================

sub _make_array_message
{
	my $self = shift;
	my $expectedRef = shift;
	my $arrayRef = shift;
	my $message = "wanted (" 
			. (join ',',@$expectedRef)
			. ") but got ("
			. (join ',',@$arrayRef) 
			. ")";
	return $message;
		
}

# Keep Perl happy.
1;
