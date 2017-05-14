# $Id: Noop.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Noop;

use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {
    my ($self, $class) = ({}, shift);
    bless $self, $class;
    $self->{cfg} = shift;
    return $self;    
}

# no idea how this works yet...
#
# the idea of this object is that it will allow the manipulation of various aspects
# of the midi environment that are not note or rest related.  things like pitch bend, 
# mod wheel, attack, decay, etc etc.    at the moment it does nothing terribly interesting
# this is just a placeholder package for now
sub params {
    # So what is this even for then?
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Noop - An object representing a MIDI null operation

=head1 ABSTRACT

=head1 DESCRIPTION

Not sure how this will work yet.  need to root around in the 
MIDI::Simple code to find out what weird things we can set like pitch 
wheel and attack and such.

(for twiddling the more obscure midi params)    

=head1 SYNOPSIS

=head1 SEE ALSO

L<POE>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
