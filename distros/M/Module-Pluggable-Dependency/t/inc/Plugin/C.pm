package Plugin::C;
use base qw( Plugin::Ignore );

sub name    { "C" } 
sub depends { qw( Plugin::B ) }

1;
