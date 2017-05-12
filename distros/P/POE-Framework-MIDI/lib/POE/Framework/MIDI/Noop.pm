# $Id: Noop.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# POE::Framework::MIDI::Noop - an object representing a null operation 
# (for twiddling the more obscure midi params)	
#
# Author:  Author: Steve McNabb (steve@justsomeguy.com)

package POE::Framework::MIDI::Noop;

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

# no idea how this works yet...
sub params
{
	# So what is this even for then?
}

1;

=head1 NAME

POE::Framework::MIDI::Noop

=head1 DESCRIPTION

not sure how this will work yet.  need to root around in the MIDI::Simple 
code to find out what weird things we can set like pitch wheel and attack
and such

=head1 BUGS

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

=cut
