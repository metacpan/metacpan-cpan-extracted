package Example::Schema;
use parent 'DBIx::Class::Schema';
__PACKAGE__->load_namespaces(default_resultset_class => 'DefaultRS');

1;

