package Testing::Plugin::F;

sub name    { "F" } 
sub depends {
    qw(
        Testing::Plugin::B
        Testing::Plugin::D
        Testing::Plugin::E
        Testing::Plugin::G
    )
}

1;
