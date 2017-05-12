package MyDBIC::Main;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_classes();

sub init_connect_info {'dbi:SQLite:t/dbic_example.db'}

1;
