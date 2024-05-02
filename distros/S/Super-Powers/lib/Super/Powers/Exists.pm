package Super::Powers::Exists;

use strict;
use warnings;
use Rope;
use Rope::Autoload;

use Mac::OSA::Dialog::Tiny qw/all/;

prototyped (
	title => '',
	message => '',
	buttons => []
);

function print => sub {
	my ($self) = @_;
	print $self->title . "\n\n";
	print $self->message . "\n";
};

function popup => sub {
	dialog(
		t => $_[0]->title,
		m => $_[0]->message,
		b => $_[0]->buttons,
	);
};

1;
