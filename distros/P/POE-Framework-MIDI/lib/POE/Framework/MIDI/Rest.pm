# POE::Framework::MIDI::Rest - object representing a rest
#
# Author:  Author: Steve McNabb (steve@justsomeguy.com)
package POE::Framework::MIDI::Rest;

use strict;
use POE::Framework::MIDI::Utility;
use constant VERSION => 0.1;

sub new
{
	my ($self,$class) = ({},shift);
	bless $self,$class;
	$self->{cfg} = shift;
	return $self;	
}

sub duration
{
	my ($self,$new_duration) = @_;
	$new_duration 
		? $self->{cfg}->{duration} = $new_duration 
		: return $self->{cfg}->{duration}		
}

sub name
{
	return 'rest';	
}

1;
=head1 NAME

POE::Framework::MIDI::Rest

=head1 DESCRIPTION

A rest event

=head1 USAGE

my $rest = new POE::Framework::MIDI::Rest({ duration => 'qn'}); # a quarternote rest

=head1 AUTHOR

	Steve McNabb
	CPAN ID: JUSTSOMEGUY
	steve@justsomeguy.com
	http://justsomeguy.com/code/POE/POE-Framework-MIDI 

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1). POE.  Perl-MIDI




1;