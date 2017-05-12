package FirstTestApp::Cmd::Test::Cmd::Test;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}

sub execute { @_ }

1;
