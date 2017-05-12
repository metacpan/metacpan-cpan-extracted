package MyMoose;

use Import::Into;
use Moose ();
use MooseX::XSAccessor ();

sub import
{
	shift;
	my $caller = caller;
	"Moose"->import::into($caller, @_);
	"MooseX::XSAccessor"->import::into($caller);
}

1;