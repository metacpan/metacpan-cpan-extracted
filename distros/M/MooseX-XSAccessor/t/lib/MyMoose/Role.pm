package MyMoose::Role;

use Import::Into;
use Moose::Role ();
use MooseX::XSAccessor ();

sub import
{
	shift;
	my $caller = caller;
	"Moose::Role"->import::into($caller, @_);
	"MooseX::XSAccessor"->import::into($caller);
}

1;