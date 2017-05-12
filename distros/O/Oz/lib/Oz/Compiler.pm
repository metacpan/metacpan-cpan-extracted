package Oz::Compiler;

# Handles the assembly of Oz files, execution of the compiler
# and the collection of the results.

use 5.008;
use strict;
use Carp              ();
use IPC::Run3   0.037 ();
use File::Temp   0.18 ();
use File::pushd  0.99 ();
use File::Which  0.05 ();
use Params::Util 1.00 ();

our $VERSION = '0.01';

use Object::Tiny 1.01 qw{
	ozc
	tempdir
	script
	main_oz
	main_ozf
	main_ozi
	main_ozm
	main_exe
};

# Platform abstraction
my $EXTENSION = (
	$^O eq 'MSWin32'
	or
	$^O eq 'dos'
	or
	$^O eq 'os2'
) ? '.exe' : '';





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check compiler and apply defaults
	$self->{ozc} ||= File::Which::which('ozc');
	unless (
		Params::Util::_STRING($self->ozc)
		and
		-f $self->ozc
		and
		-r $self->ozc
		and
		-x $self->ozc
	) {
		Carp::croak("The ozc param is not an executable file path");
	}

	# Check tempdir and apply defaults
	$self->{tempdir} ||= File::Temp::tempdir( CLEANUP => 1 );
	unless (
		Params::Util::_STRING($self->tempdir)
		and
		-d $self->tempdir
		and
		-r $self->tempdir
		and
		-w $self->tempdir
	) {
		croak("The tempdir param is not a read-writable directory");
	}

	# Get or check the script
	if ( $self->script and ! Params::Util::_INSTANCE($self->script, 'Oz::Script') ) {
		$self->{script} = Oz::Script->new( $self->{script} );
	}
	unless ( Params::Util::_INSTANCE($self->script, 'Oz::Script') ) {
		Carp::croak("The script param is not a valid Oz::Script object");
	}

	# Apply defaults for the file name
	$self->{main_exe} ||= File::Spec->catfile(
		$self->tempdir, "main$EXTENSION",
	);
	foreach my $ext ( qw{oz ozf ozi ozm} ) {
		$self->{"main_$ext"}  ||= File::Spec->catfile(
			$self->tempdir, "main.$ext",
		);
	}

	# Save the main script to the correct location
	$self->script->write( $self->main_oz );

	# Ready to rock
	return $self;
}





#####################################################################
# Building or Executing Files

# Change to the target directory while compiling
sub cmd {
	my $self = shift;
	my $dir  = File::pushd::pushd( $self->tempdir );
	return IPC::Run3::run3( @_ );
}

sub make_ozf {
	my $self = shift;
	my $cmd  = [
		$self->ozc,
		'-c' => $self->main_oz,
		'-o' => $self->main_ozf,
	];
	my $rv = $self->cmd( $cmd, \undef, \undef, \undef );
	return !! -f $self->main_ozf;
}

sub make_ozi {
	my $self = shift;
	my $cmd  = [
		$self->ozc,
		'-E' => $self->main_oz,
		'-o' => $self->main_ozi,
	];
	my $rv = $self->cmd( $cmd, \undef, \undef, \undef );
	return !! -f $self->main_ozi;
}

sub make_ozm {
	my $self = shift;
	my $cmd  = [
		$self->ozc,
		'-S' => $self->main_oz,
		'-o' => $self->main_ozm,
	];
	my $rv = $self->cmd( $cmd, \undef, \undef, \undef );
	return !! -f $self->main_ozm;
}

sub make_exe {
	my $self = shift;
	my $cmd  = [
		$self->ozc,
		'-x' => $self->main_oz,
		'-o' => $self->main_exe,
	];
	my $rv = $self->cmd( $cmd, \undef, \undef, \undef );
	return !! -f $self->main_exe;
}

sub run {
	my $self = shift;

	# Compile if needed
	unless ( -f $self->main_exe ) {
		$self->make_exe or return undef;
	}

	# Execute the program and capture the results
	my $out = '';
	my $cmd = [ $self->main_exe, @_ ];
	my $rv  = $self->cmd( $cmd, \undef, \$out, \undef );
	return $out;
}

1;
