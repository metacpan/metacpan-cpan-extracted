package Mojolicious::Command::sendgrid::mail;
use Mojo::Base 'Mojolicious::Commands';

has description => 'Sendgrid Mail API';
has hint        => <<EOF;

See 'APPLICATION sendgrid mail help API' for more information on a specific
api.
EOF
has message    => sub { shift->extract_usage . "\nAPI:\n" };
has namespaces => sub { ['Mojolicious::Command::sendgrid::mail'] };

sub help { shift->run(@_) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::sendgrid::mail - Command interface to the mail endpoint
of the Sendgrid API

=head1 SYNOPSIS

  Usage: APPLICATION sendgrid mail COMMAND [OPTIONS]

    export SENDGRID_APIKEY='your sendgrid api key'
    mojo sendgrid mail send -t a@b.com -f x@y.com -s Subject < /tmp/file

=head1 DESCRIPTION

L<Mojolicious::Command::sendgrid::mail> lists available Sendgrid commands for
the mail endpoint.

=head1 ATTRIBUTES

L<Mojolicious::Command::sendgrid::mail> inherits all attributes from
L<Mojolicious::Commands> and implements the following new ones.

=head2 description

  my $description = $mail->description;
  $mail           = $mail->description('Foo');

Short description of this command, used for the command list.

=head2 hint

  my $hint   = $mail->hint;
  $mail      = $mail->hint('Foo');

Short hint shown after listing available sendgrid commands.

=head2 message

  my $msg    = $mail->message;
  $mail      = $mail->message('Bar');

Short usage message shown before listing available sendgrid commands.

=head2 namespaces

  my $namespaces = $mail->namespaces;
  $mail          = $mail->namespaces(['MyApp::Command::sendgrid::mail']);

Namespaces to search for available sendgrid commands, defaults to
L<Mojolicious::Command::sendgrid::mail>.

=head1 METHODS

L<Mojolicious::Command::sendgrid::mail> inherits all methods from
L<Mojolicious::Commands> and implements the following new ones.

=head2 help

  $mail->help('app');

Print usage information for sendgrid command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut