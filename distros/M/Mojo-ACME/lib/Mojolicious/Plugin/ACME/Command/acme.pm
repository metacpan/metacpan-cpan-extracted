package Mojolicious::Plugin::ACME::Command::acme;

use Mojo::Base 'Mojolicious::Commands';

has description => 'Interact with remote ACME services (e.g. letsencrypt)';
has hint => <<END;

See $0 acme help COMMAND for more information on a specific command
END

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { [__PACKAGE__] };
has usage => sub { $_[0]->extract_usage . $_[0]->hint };

1;

=head1 NAME

Mojolicious::Plugin::ACME::Command::acme - ACME commands

=head1 SYNOPSIS

  Usage: APPLICATION acme COMMAND [OPTIONS]
    myapp acme account register
    myapp acme cert generate

=cut


