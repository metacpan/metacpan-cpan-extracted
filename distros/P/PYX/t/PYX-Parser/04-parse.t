use strict;
use warnings;

use File::Object;
use Perl6::Slurp qw(slurp);
use PYX::Parser;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# PYX::Parser object.
my $obj = PYX::Parser->new(
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
my $data = slurp($data_dir->file('parse.pyx')->s);

# Parse.
$obj->parse($data);

# Process attributes.
sub attribute {
	my ($self, $att, $attval) = @_;
	is($self->{'_line'}, "A$att $attval", 'Attribute callback.');
	return;
}

# Process start element.
sub start_element {
	my ($self, $elem) = @_;
	is($self->{'_line'}, "($elem", 'Start of element callback.');
	return;
}

# Process end element.
sub end_element {
	my ($self, $elem) = @_;
	is($self->{'_line'}, ")$elem", 'End of element callback.');
	return;
}

# Process data.
sub data {
	my ($self, $data) = @_;
	is($self->{'_line'}, "-$data", 'Data callback.');
	return;
}

# Process instruction.
sub instruction {
	my ($self, $target, $code) = @_;
	is($self->{'_line'}, "?$target $code", 'Instruction callback.');
	return;
}

# Process comment.
sub comment {
	my ($self, $comment) = @_;
	is($self->{'_line'}, "_$comment", 'Comment callback.');
	return;
}

# Process other.
sub other {
	my ($self, $other) = @_;
	is($self->{'_line'}, $other, 'Callback for other.');
	return;
}
