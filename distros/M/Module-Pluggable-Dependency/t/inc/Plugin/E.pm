package Plugin::E;
use base qw( Plugin::Ignore );

sub name    { "E" } 
sub depends { qw( Plugin::D ) }

1;
