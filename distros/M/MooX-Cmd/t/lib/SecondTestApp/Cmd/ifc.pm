package SecondTestApp::Cmd::ifc;

BEGIN
{
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;";
    $@ and die $@;
    $moodel->import;

    __PACKAGE__->can("with")->("MooX::Cmd::Role");
}

around _build_command_execute_method_name => sub { "run" };

around _build_command_execute_from_new => sub { 1 };

sub run { @_ }

eval "use MooX::Cmd;";

1;
