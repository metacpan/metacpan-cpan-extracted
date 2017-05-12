
package PRANG::Cookbook::Library;
$PRANG::Cookbook::Library::VERSION = '0.18';
use Moose;
use PRANG::Graph;
use PRANG::XMLSchema::Types;

has_element 'book' =>
	xml_nodeName => 'book',
	is => 'rw',
	isa => 'ArrayRef[PRANG::Cookbook::Book]',
	xml_required => 1,
	required => 1,
	;

sub root_element {'library'}
with 'PRANG::Cookbook';

1;

=pod

=head1 NAME

PRANG::Cookbook::Library - Basic PRANG Features

=head1 DESCRIPTION

This recipe series gives you a good overview of some of advanced of PRANG's
capabilites. Showing how to do lists of nodes and then lists of any of a number
of different nodes.

=head1 CONCLUSION

...

=head1 AUTHOR

Andrew Chilton, E<lt>andy@catalyst dot net dot nz<gt>

=head1 COPYRIGHT & LICENSE

This software development is sponsored and directed by New Zealand Registry
Services, http://www.nzrs.net.nz/

The work is being carried out by Catalyst IT, http://www.catalyst.net.nz/

Copyright (c) 2009, NZ Registry Services.  All Rights Reserved.  This software
may be used under the terms of the Artistic License 2.0.  Note that this
license is compatible with both the GNU GPL and Artistic licenses.  A copy of
this license is supplied with the distribution in the file COPYING.txt.

=cut
