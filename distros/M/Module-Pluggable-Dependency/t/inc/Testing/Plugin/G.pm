package Testing::Plugin::G;

sub name    { "G" } 
sub depends { qw( Testing::Plugin::D Testing::Plugin::E ) }

1;
