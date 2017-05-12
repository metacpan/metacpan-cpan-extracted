package Plugin::G;
use base qw( Plugin::Ignore );

sub name    { "G" } 
sub depends { qw( Plugin::D Plugin::E ) }

1;
