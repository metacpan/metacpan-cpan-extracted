package Mojolicious::Plugin::ACME::Command::acme::cert;

use Mojo::Base 'Mojolicious::Commands';

has description => 'ACME service certificate commands';
has hint => <<END;

See $0 acme cert help COMMAND for more information on a specific command
END

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { [__PACKAGE__] };
has usage => sub { $_[0]->extract_usage . $_[0]->hint };

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme::cert - ACME certificate commands

=head1 SYNOPSIS

  Usage: APPLICATION acme cert COMMAND [OPTIONS]
    myapp acme cert generate
    myapp acme cert revoke

=cut

