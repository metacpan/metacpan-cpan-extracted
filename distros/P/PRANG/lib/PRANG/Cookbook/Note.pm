
package PRANG::Cookbook::Note;
$PRANG::Cookbook::Note::VERSION = '0.18';
use Moose;
use PRANG::Graph;
use PRANG::XMLSchema::Types;

# attributes
has_attr 'replied' =>
	is => 'rw',
	isa => 'PRANG::XMLSchema::boolean',
	required => 0,
	xml_required => 0,
	;

# elements
has_element 'from' =>
	xml_nodeName => 'from',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	required => 1,
	;

has_element 'to' =>
	xml_nodeName => 'to',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	required => 1,
	;

has_element 'sent' =>
	xml_nodeName => 'sent',
	is => 'rw',
	isa => 'PRANG::Cookbook::DateTime',
	xml_required => 0,
	;

has_element 'location' =>
	xml_nodeName => 'location',
	is => 'rw',
	isa => 'PRANG::Cookbook::Location',
	xml_required => 0,
	;

has_element 'subject' =>
	xml_nodeName => 'subject',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	required => 1,
	;

has_element 'body' =>
	xml_nodeName => 'body',
	is => 'rw',
	isa => 'Str',
	required => 0,
	xml_required => 0,
	;

sub root_element {'note'}
with 'PRANG::Cookbook';

1;

=pod

=head1 NAME

PRANG::Cookbook::Note - Basic PRANG Features

=head1 DESCRIPTION

This recipe series gives you a good overview of PRANG's capabilites starting
with simple XML elements and attributes.

...

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
