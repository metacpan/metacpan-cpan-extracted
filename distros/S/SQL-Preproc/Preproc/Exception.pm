package SQL::Preproc::Exception;
#
#	SQL::Preproc::Exception - runtime exception handler module for SQL::Preproc
#
#	Provides a container object for SQL::Preproc context and exception
#	handling. When this object goes out of scope, the DESTROY method
#	will remove it from the sqlpp_ctxt exception stack
#
use strict;
our $VERSION = '0.10';

sub new {
	my ($class, $ctxt, $handler) = @_;
	
	return undef 
		unless (defined($handler) &&
			(ref $handler) &&
			(ref $handler eq 'CODE'));
#
#	use arrayref to save memory/runtime
#
	my $obj = [ $ctxt, $handler ];
	bless $obj, $class;
	return $obj;
}

sub catch {
	my $obj = shift;
#
#	make sure that any exceptions thrown within the
#	handler are caught by the default handlers
#
	my $old_handler = $obj->[0]{handler_idx};
	$obj->[0]{handler_idx} = 0;
	if (defined($_[1]) && ref $_[1]) {
#
#	shortcut: we've got a handle, so grab info from it
#
		my $h = $_[1];
		$obj->[1]->($_[0], $h->err, $h->state, $h->errstr);
	}
	else {
		$obj->[1]->(@_);
	}
	$obj->[0]{handler_idx} = $old_handler;
	return 1;
}

sub raise {
	my $obj = shift;
#
#	make sure that any exceptions thrown within the
#	handler are caught by the default handlers
#
	my $old_handler = $obj->[0]{handler_idx};
	$obj->[0]{handler_idx} = 0;
	$obj->[1]->(@_);
	$obj->[0]{handler_idx} = $old_handler;
	return 1;
}

1;