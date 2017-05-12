#
#	SQL::Preproc::ExceptContainer - a container for exception
#	objects so scope gets cleaned up properly
#
package SQL::Preproc::ExceptContainer;

use SQL::Preproc::Exception;
use strict;
our $VERSION = '0.10';

sub new_SQLERROR {
#
#	use an array, since we're pretty final
#	and it uses much less memory
#
	my $obj = [];
	bless $obj, shift;
	$obj->[0] = shift;	# sqlpp_ctxt
	$obj->[1] = SQL::Preproc::Exception->new($obj->[0], @_);
	push @{$obj->[0]->{SQLERROR}}, $obj->[1];
	return $obj;
}

sub new_NOTFOUND {
#
#	use an array, since we're pretty final
#	and it uses much less memory
#
	my $obj = [];
	bless $obj, shift;
	$obj->[0] = shift;	# sqlpp_ctxt
	$obj->[1] = SQL::Preproc::Exception->new($obj->[0], @_);
	push @{$obj->[0]->{NOTFOUND}}, $obj->[1];
	return $obj;
}

sub DESTROY {
	my $obj = shift;
#
#	remove the Exception object from us *and*
#	from the sqlpp_ctxt
#
	my $ctxt = $obj->[0];
	my $except = $obj->[1];
	$obj->[0] = undef;
	$obj->[1] = undef;
#
#	in theory we should be at the top of the stack, but
#	to be safe, we'll splice anyway
#	also note that we don't permit the base handler to
#	be destroyed
#
	foreach (1..$#{$ctxt->{SQLERROR}}) {
		splice (@{$ctxt->{SQLERROR}}, $_, 1),
		return 1
			if ($ctxt->{SQLERROR}[$_] eq $except);
	}
	
	foreach (1..$#{$ctxt->{NOTFOUND}}) {
		splice (@{$ctxt->{NOTFOUND}}, $_, 1),
		return 1
			if ($ctxt->{NOTFOUND}[$_] eq $except);
	}
#
#	the exception will be destroyed now
#
	1;
}
#
#	default handlers
#	SQLERROR: die
#	NOTFOUND: silently ignore
#
sub default_SQLERROR {
	my $obj = [];
	bless $obj, shift;
	$obj->[0] = shift;	# sqlpp_ctxt
	$obj->[1] = SQL::Preproc::Exception->new($obj->[0], 
		sub {
			my ($obj, $err, $state, $errstr) = @_;
			$err = '(Unknown error)' unless defined($err);
			$state = '(Unknown state)' unless (defined($state) && ($state ne ''));
			$errstr = '(No error message)' unless defined($errstr);
			my ($pkg, $subr, $line) = caller(1);
			
			die "Error $err (SQLSTATE $state): $errstr
at $pkg\:\:$subr: $line";
		});
	$obj->[0]{SQLERROR}[0] = $obj->[1];
	return $obj;
}

sub default_NOTFOUND {
	my $obj = [];
	bless $obj, shift;
	$obj->[0] = shift;	# sqlpp_ctxt
	$obj->[1] = SQL::Preproc::Exception->new($obj->[0], 
		sub { return 1; });
	$obj->[0]{NOTFOUND}[0] = $obj->[1];
	return $obj;
}

1;