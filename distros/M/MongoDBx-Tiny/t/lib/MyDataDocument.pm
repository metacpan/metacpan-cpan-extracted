package MyDataDocument;

use strict;

BEGIN { our @EXPORT = qw/is_my_data_document_exported/; }

use base qw(MongoDBx::Tiny::Document);

sub is_my_data_document { 1 }
sub is_my_data_document_exported { 1 }

1;
