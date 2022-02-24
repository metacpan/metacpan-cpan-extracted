package ODS::Storage::File::YAML;

use YAOO;

extends 'ODS::Storage::File';

use ODS::Serialize::YAML;

has _serialize_class => isa(object('ODS::Serialize::YAML')), coerce(sub {
	my ($self, $value) = @_;
	$value->new;
});

1;
