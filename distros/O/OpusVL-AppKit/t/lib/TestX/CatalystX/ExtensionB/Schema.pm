package TestX::CatalystX::ExtensionB::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces
(
    result_namespace => 'Result',
);

1;
