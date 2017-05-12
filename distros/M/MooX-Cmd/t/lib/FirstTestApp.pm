package FirstTestApp;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd;

sub execute { @_ }

1;
