package ThirdTestApp::Cmd::Foo;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}

sub _build_command_execute_method_name { "run" }

sub run { @_ }

1;
