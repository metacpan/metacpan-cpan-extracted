package PulseAudio::Sample;
use strict;
use warnings;

use constant _CAT => 'sample';

use PulseAudio::Backend::Utilities;

use Moose;

with 'PulseAudio::Roles::Object';

use PulseAudio::Types qw(PA_Index PA_Name);

has 'name'  => ( isa => PA_Name, is => 'ro', required => 1 );

has 'index' => (
	isa => PA_Index
	, is => 'ro'
	, lazy => 1
	, default => sub {
		my $self = shift;
		return $self->get('index')
	}
);

foreach my $cmd ( @{_commands()} ) {
	__PACKAGE__->meta->add_method( $cmd->{alias} => $cmd->{sub} );
}

sub _commands {
	PulseAudio::Backend::Utilities->_pacmd_help->{catagory}{ _CAT() };
}

__PACKAGE__->meta->make_immutable;
