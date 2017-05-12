package SecondTestApp;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd execute_from_new => 0;

around _build_command_execute_method_name => sub { "run" };

sub run { @_ }

sub was_haste { return $_[0]->{was_haste} }

1;
