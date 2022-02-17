package ODS::Storage::File::JSON;

use YAOO;
use JSON;

extends 'ODS::Storage::File';

has json => isa(object), default => sub { JSON->new->pretty(1) };

has file_suffix => isa(string('json'));

sub parse_data_format {
	my ($self, $data) = @_;
	return $self->json->decode($data);
}

sub stringify_data_format {
	my ($self, $data) = @_;
	return $self->json->encode($data);
}

1;
