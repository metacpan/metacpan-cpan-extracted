package ObjectDB::Stmt;

use strict;
use warnings;

sub new { bless { @_[ 1 .. $#_ ] }, $_[0] }
sub to_sql  { shift->{sql} }
sub to_bind { @{ shift->{bind} } }

1;
