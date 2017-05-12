package Test::BrewBuild::Plugin::UnitTestPluginInst;

sub brewbuild_exec {
    shift;
    my $arg = shift;
    return $arg if defined $arg;
    return "test plugin";
}
1;
