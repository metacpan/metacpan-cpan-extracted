package t::lib::MyDelegatableProcess;

use strict;
use Process              ();
use Process::Storable    ();
use Process::Delegatable ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = qw{
		Process::Delegatable
		Process::Storable
		Process
	};
}

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	$self;
}

sub prepare { 1 }

sub run {
	my $self = shift;
	$self->{launcher_version} = $Process::Launcher::VERSION;
	$self->{process_version}  = $Process::VERSION;
	if ( $self->{pleasedie} ) {
		die "You wanted me to die";
		return '';
	} else {
		$self->{somedata} = 'foo';
		return 1;
	}
}

1;
