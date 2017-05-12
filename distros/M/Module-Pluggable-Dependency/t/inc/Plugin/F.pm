package Plugin::F;
use base qw( Plugin::Ignore );

sub name    { "F" } 
sub depends {
    qw(
        Plugin::B
        Plugin::D
        Plugin::E
        Plugin::G
    )
}

1;
