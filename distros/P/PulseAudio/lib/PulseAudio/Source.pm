package PulseAudio::Source;
use strict;
use warnings;
use autodie;

use constant _CAT => 'source';

use PulseAudio::Backend::Utilities;

use Moose;

with 'PulseAudio::Roles::Object';

use PulseAudio::Types qw(PA_Index);
has 'index' => ( isa => PA_Index, is => 'ro', required => 1 );

foreach my $cmd ( @{_commands()} ) {
	__PACKAGE__->meta->add_method( $cmd->{alias} => $cmd->{sub} );
}

sub _commands {
	PulseAudio::Backend::Utilities->_pacmd_help->{catagory}{ _CAT() };
}

sub exec {
	my $self = shift;

	my ( $prog, @args );	
	if ( ref $_[0] eq 'HASH' ) {
		my $attr = shift;
		$prog = $attr->{prog};
		@args = @{$attr->{args}};

		Carp::croak "No 'prog' supplied in hash arg to exec\n"
			unless $prog
		;
	}
	else {
		( $prog, @args ) = @_;
	}
	
	local $ENV{PATH} = undef;
	my @env_args = grep defined, (
		(
			$self->server->_has_pulse_server
			? sprintf("PULSE_SERVER=%s", $self->server->pulse_server)
			: undef
		)
		, sprintf("PULSE_SINK=%s", $self->index)
	);
	
	my $pid = fork;
	if ( $pid == 0 ) {
		system(
			'/usr/bin/env'
			, @env_args
			, $prog
			, @args
		);
	}

}

__PACKAGE__->meta->make_immutable;
