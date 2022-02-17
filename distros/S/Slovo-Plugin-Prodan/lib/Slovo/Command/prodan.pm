package Slovo::Command::prodan;

use Mojo::Base 'Mojolicious::Commands';

has hint => <<"EOF";

See '$0 prodan help ACTION' for more information on a specific command.
EOF
has message     => sub { shift->extract_usage . "\nActions:\n" };
has namespaces  => sub { [__PACKAGE__] };
has description => 'Sales related commands for a Slovo-based site.';

1;

=encoding utf8

=head1 NAME

Slovo::Command::prodan - A sales command

=head1 SYNOPSIS

    List available subcommands
    slovo prodan

=head1 DESCRIPTION

Slovo::Command::prodan is just a namespace for sales management related
commands for a site based on L<Slovo>.
These commands are still alfa quality and their functionalities may change often.

=head1 SEE ALSO

L<Slovo::Command::prodan::products>,
L<Slovo::Plugin::Prodan>,
L<Slovo>

=cut

