package PulseAudio::Client;
use strict;
use warnings;

use constant _CAT => 'client';

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

__PACKAGE__->meta->make_immutable;
