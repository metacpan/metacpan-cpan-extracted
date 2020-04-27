use strict;
use warnings;

use Encode qw(decode_utf8);
use File::Object;
use PYX::Parser;
use Test::More 'tests' => 17;
use Test::NoWarnings;

# PYX::Parser object.
my $obj = PYX::Parser->new(
	'input_encoding' => 'iso-8859-2',
	'callbacks' => {
		'attribute' => \&attribute,
		'start_element' => \&start_element,
		'end_element' => \&end_element,
		'data' => \&data,
		'instruction' => \&instruction,
		'comment' => \&comment,
		'other' => \&other,
	},
);

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Parse.
$obj->parse_file($data_dir->file('parse_encoding_latin2.pyx')->s);

# Process attributes.
sub attribute {
	my ($self, $att, $attval) = @_;
	is($self->{'_line'}, "A$att $attval", 'Attribute callback.');
	is($att, decode_utf8('čaj'), 'Attribute in iso-8859-2.');
	is($attval, decode_utf8('teč'), 'Attribute value in iso-8859-2.');
	return;
}

# Process start element.
sub start_element {
	my ($self, $elem) = @_;
	is($self->{'_line'}, "($elem", 'Start of element callback.');
	is($elem, decode_utf8('čupřina'), 'Start of element in iso-8859-2.');
	return;
}

# Process end element.
sub end_element {
	my ($self, $elem) = @_;
	is($self->{'_line'}, ")$elem", 'End of element callback.');
	is($elem, decode_utf8('čupřina'), 'End of element in iso-8859-2.');
	return;
}

# Process data.
sub data {
	my ($self, $data) = @_;
	is($self->{'_line'}, "-$data", 'Data callback.');
	is($data, decode_utf8('datíčka'), 'Data in iso-8859-2.');
	return;
}

# Process instruction.
sub instruction {
	my ($self, $target, $code) = @_;
	is($self->{'_line'}, "?$target $code", 'Instruction callback.');
	is($target, decode_utf8('cíl'), 'Target in iso-8859-2.');
	is($code, decode_utf8('datíčka'), 'Target code in iso-8859-2.');
	return;
}

# Process comment.
sub comment {
	my ($self, $comment) = @_;
	is($self->{'_line'}, "_$comment", 'Comment callback.');
	is($comment, decode_utf8('komentář'), 'Comment in iso-8859-2.');
	return;
}

# Process other.
sub other {
	my ($self, $other) = @_;
	is($self->{'_line'}, $other, 'Callback for other.');
	is($other, decode_utf8('špatný element'), 'Other in iso-8859-2.');
	return;
}
