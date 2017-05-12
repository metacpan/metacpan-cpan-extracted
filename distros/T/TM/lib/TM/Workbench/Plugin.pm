package TM::Workbench::Plugin;                    # the mother of all plugins

sub new {
    my $class = shift;
    return bless {}, $class;
}

1;

