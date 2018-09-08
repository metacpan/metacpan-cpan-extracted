package ObjectDB::Meta::Relationship::OneToOne;

use strict;
use warnings;

our $VERSION = '3.27';

use base 'ObjectDB::Meta::Relationship::ManyToOne';

sub type     { 'one to one' }
sub is_multi { 0 }

1;
