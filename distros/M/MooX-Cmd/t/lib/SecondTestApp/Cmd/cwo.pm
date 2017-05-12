package SecondTestApp::Cmd::cwo;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd execute_return_method_name => 'run_result', creation_method_name => "mach_mich_neu", execute_from_new => 1;

around _build_command_execute_method_name => sub { "run" };

sub run { @_ }

1;
