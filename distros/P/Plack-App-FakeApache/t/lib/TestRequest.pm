package TestRequest;
use FindBin qw/$Bin/;
use lib "$Bin/../../lib"; 
use parent qw/Plack::App::FakeApache::Request/;

sub do_print {
	my ($self, @out) = @_;
	$self->print(@out);
}

1;
