package ODS::Serialize::YAML;

use YAOO;

use YAML::XS;

has file_suffix => isa(string('yml'));

sub parse {
	my ($self, $data) = @_;
	return Load $data;
}

sub stringify {
	my ($self, $data) = @_;
	return Dump $data;
}

1;
