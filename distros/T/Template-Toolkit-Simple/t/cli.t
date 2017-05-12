use lib 'inc';

use TestML;

TestML->new(
    testml => do { local $/; <DATA> },
    bridge => 'main',
)->run;

{
    package main;
    use base 'TestML::Bridge';
    use TestML::Util;

    sub run_command {
        my ($self, $command) = @_;
        $command = $command->value;
        if (-d 'test') {
            $command =~ s/\bt\b/test/g;
        }
        open my $execution, "$^X bin/$command |"
        or die "Couldn't open subprocess: $!\n";
        local $/;
        my $output = <$execution>;
        close $execution;
        return str $output;
    }

    sub expected {
        return str <<'...';
Hi Löver,

Have a nice day.

Smööches, Ingy
...
    }
}

__DATA__
%TestML 0.1.0

Plan = 3;

*command.Chomp.run_command == expected();

=== Render
--- command
tt-render --post-chomp --data=t/render.yaml --path=t/template/ letter.tt

=== Render with path//template
--- command
tt-render --post-chomp --data=t/render.yaml t/template//letter.tt

=== Options abbreviated
--- command
tt-render --post-c --d=t/render.yaml -I t/template/ letter.tt
