package MyApp::DB::DBIC_Schema;

# ABSTRACT: Schema class

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;

our $VERSION = 0.01;

__PACKAGE__->load_namespaces(
    result_namespace => ['Core', 'Virtual'],
    resultset_namespace => 'Virtual',
);

# ---
# Put your own code below this comment
# ---
print "This is some custom code!";
# ---

1;
