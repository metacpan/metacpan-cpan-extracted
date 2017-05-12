package MyBackgroundProcess;

use strict;
use File::Remove ();
use Process::Backgroundable ();
use Process ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = qw{
		Process::Backgroundable
		Process
	};
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self->{file} and -f $self->{file} or return undef;
	return $self;
}

sub prepare {
	my $self = shift;

	# Confirm again the file exists
	if ( $self->{file} and -f $self->{file} ) {
		# print STDOUT "Found file $self->{file}\n";
		return 1;
	} else {
		# print STDOUT "Didn't find file $self->{file}\n";
		return undef;
	}
}

sub run {
	my $self = shift;

	# Slight delay to allow the test to check for existance after
	# their ->background call.
	# print STDOUT "Sleeping\n";
	sleep 1;

	# Delete the file
	# print STDOUT "Removing\n";
	File::Remove::remove($self->{file});
	# print STDOUT "Exiting\n";
	# sleep 20;
	exit(0);
}

1;
