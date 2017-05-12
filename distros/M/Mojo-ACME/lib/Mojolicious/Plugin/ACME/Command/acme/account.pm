package Mojolicious::Plugin::ACME::Command::acme::account;

use Mojo::Base 'Mojolicious::Commands';

has description => 'ACME service account commands';
has hint => <<END;

See $0 acme account help COMMAND for more information on a specific command
END

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { [__PACKAGE__] };
has usage => sub { $_[0]->extract_usage . $_[0]->hint };

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme::account - ACME account commands

=head1 SYNOPSIS

  Usage: APPLICATION acme account COMMAND [OPTIONS]
    myapp acme account register

=cut

