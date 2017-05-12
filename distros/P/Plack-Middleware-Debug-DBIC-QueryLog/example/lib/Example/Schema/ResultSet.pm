package Example::Schema::ResultSet;
use parent 'DBIx::Class::ResultSet';

sub as_hri {
    (shift)->
    search({}, {
		result_class => 'DBIx::Class::ResultClass::HashRefInflator',
	});
}

1;

