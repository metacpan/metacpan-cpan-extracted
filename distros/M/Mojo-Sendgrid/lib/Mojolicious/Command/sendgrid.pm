package Mojolicious::Command::sendgrid;
use Mojo::Base 'Mojolicious::Commands';

has description => 'Sendgrid API';
has hint        => <<EOF;

See 'APPLICATION sendgrid help API' for more information on a specific
api.
EOF
has message    => sub { shift->extract_usage . "\nAPI:\n" };
has namespaces => sub { ['Mojolicious::Command::sendgrid'] };

sub help { shift->run(@_) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::sendgrid - Command interface to the Sendgrid API

=head1 SYNOPSIS

  Usage: APPLICATION sendgrid ENDPOINT [OPTIONS]

    export SENDGRID_APIKEY='your sendgrid api key'
    mojo sendgrid mail send -t a@b.com -f x@y.com -s Subject < /tmp/file

=head1 DESCRIPTION

L<Mojolicious::Command::sendgrid> lists available Sendgrid endpoints.

=head1 ATTRIBUTES

L<Mojolicious::Command::sendgrid> inherits all attributes from
L<Mojolicious::Commands> and implements the following new ones.

=head2 description

  my $description = $sendgrid->description;
  $sendgrid       = $sendgrid->description('Foo');

Short description of this command, used for the command list.

=head2 hint

  my $hint   = $sendgrid->hint;
  $sendgrid  = $sendgrid->hint('Foo');

Short hint shown after listing available sendgrid commands.

=head2 message

  my $msg    = $sendgrid->message;
  $sendgrid  = $sendgrid->message('Bar');

Short usage message shown before listing available sendgrid commands.

=head2 namespaces

  my $namespaces = $sendgrid->namespaces;
  $sendgrid      = $sendgrid->namespaces(['MyApp::Command::sendgrid']);

Namespaces to search for available sendgrid commands, defaults to
L<Mojolicious::Command::sendgrid>.

=head1 METHODS

L<Mojolicious::Command::sendgrid> inherits all methods from
L<Mojolicious::Commands> and implements the following new ones.

=head2 help

  $sendgrid->help('app');

Print usage information for sendgrid command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut