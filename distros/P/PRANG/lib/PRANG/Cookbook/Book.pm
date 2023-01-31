
package PRANG::Cookbook::Book;
$PRANG::Cookbook::Book::VERSION = '0.21';
use Moose;
use PRANG::Graph;
use PRANG::XMLSchema::Types;

# attributes
has_attr 'isbn' =>
	is => 'rw',
	isa => 'Str',
	;

# elements
has_element 'title' =>
	xml_nodeName => 'title',
	is => 'rw',
	isa => 'Str',
	xml_required => 1,
	required => 1,
	;

has_element 'author' =>
	xml_nodeName => 'author',
	is => 'rw',
	isa => 'ArrayRef[Str]',
	xml_required => 1,
	required => 1,
	;

has_element 'pages' =>
	xml_nodeName => 'pages',
	is => 'rw',
	isa => 'Int',
	xml_required => 1,
	required => 1,
	;

has_element 'published' =>
	xml_nodeName => 'published',
	is => 'rw',
	isa => 'PRANG::Cookbook::Date',
	xml_required => 0,
	;

sub root_element {'book'}
with 'PRANG::Cookbook';

1;
