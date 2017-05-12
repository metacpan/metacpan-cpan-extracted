package UnitTestPlugin;

sub brewbuild_exec {
    shift;
    my $log = shift;
    my $arg = shift;
    return $arg if defined $arg;
    return "test plugin";
}
1;