package Net::RDAP::Object::Autnum;
use base qw(Net::RDAP::Object);
use strict;

=head1 NAME

L<Net::RDAP::Object::Autnum> - an RDAP object representing an
autonymous system.

=head1 DESCRIPTION

L<Net::RDAP::Object::Autnum> represents one or more autonymous system
numbers.

L<Net::RDAP::Object::Autnum> inherits from L<Net::RDAP::Object> so has
access to all that module's methods.

Other methods include:

	$start = $network->start;

Returns an integer representing the starting number in the block of
Autonomous System numbers.

	$end = $network->end;

Returns an integer representing the ending number in the block of
Autonomous System numbers.

	$name = $network->name;

Returns a string containing the identifier assigned to the autnum
registration by the registration holder.

	$type = $network->type;

Returns a string containing an RIR-specific classification of the
autnum.

	$country = $network->country;

Returns a string containing the two-character country code of the
autnum.

=cut

sub start		{ $_[0]->{'startAutnum'}	}
sub end			{ $_[0]->{'endAutnum'}		}
sub name		{ $_[0]->{'name'}		}
sub type		{ $_[0]->{'type'}		}
sub country		{ $_[0]->{'country'}		}

=pod

=head1 COPYRIGHT

Copyright 2019 CentralNic Ltd. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
