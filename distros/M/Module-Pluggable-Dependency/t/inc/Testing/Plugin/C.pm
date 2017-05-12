package Testing::Plugin::C;

sub name    { "C" } 
sub depends {
    qw(
        Testing::Plugin::B
    )
}

1;
