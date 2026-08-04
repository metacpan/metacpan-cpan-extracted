package TestTokenSchema;

# ABSTRACT: Test schema for Fondation::Auth::Token

use strict;
use warnings;
use base 'DBIx::Class::Schema';

our $VERSION = '1';

__PACKAGE__->load_namespaces;

1;
