package ODS::Storage::File::YAML;

use YAOO;
use YAML::XS;

extends 'ODS::Storage::File';

has file_suffix => isa(string('yml'));

sub parse_data_format {
	my ($self, $data) = @_;
	return Load $data;
}

sub stringify_data_format {
	my ($self, $data) = @_;
	return Dump $data;
}

1;
