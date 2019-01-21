package MyApp::DB::DBIC_Schema;

# ABSTRACT: Schema class

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;

our $VERSION = 0.01;

__PACKAGE__->load_namespaces(
    result_namespace => ['Test', 'Virtual', 'Core::Result'],
    resultset_namespace => ['Test', 'Virtual', 'Core::Result'],
);

# ---
# Put your own code below this comment
# ---

# ---

1;