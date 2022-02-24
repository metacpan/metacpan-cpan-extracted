package ODS::Storage::File::JSON;

use YAOO;

use ODS::Utils qw/load/;

extends 'ODS::Storage::File';

use ODS::Serialize::JSON;

has _serialize_class => isa(object('ODS::Serialize::JSON')), coerce(sub {
	my ($self, $value) = @_;
	$value->new;
});

1;
