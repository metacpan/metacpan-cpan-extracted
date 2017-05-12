package ThirdTestApp;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd execute_from_new => undef;

around _build_command_execute_method_name => sub { "run" };

sub mach_mich_perwoll { goto \&MooX::Cmd::Role::_initialize_from_cmd; }

sub run { @_ }

1;
