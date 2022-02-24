package ODS::Serialize::JSON;

use YAOO;
use JSON;

has pretty => isa(boolean(1)), lazy;

has file_suffix => isa(string('json'));

has json => isa(object(1)), coerce => sub { JSON->new->pretty($_[0]->pretty); };

sub parse {
	my ($self, $data) = @_;
	return $self->json->decode($data);
}

sub stringify {
	my ($self, $data) = @_;
	return $self->json->encode($data);
}

1;
