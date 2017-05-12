package Mojolicious::Command::sendgrid::mail::send;
use Mojo::Base 'Mojolicious::Command';

use Mojo::JSON 'j';
use Mojo::Sendgrid;

use Data::Dumper;
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);

has description => 'sendgrid mail send';
has usage => sub { shift->extract_usage };

has sendgrid => sub { Mojo::Sendgrid->new(shift->app->config('sendgrid')) };

sub run {
  my ($self, @args) = @_;

  GetOptionsFromArray \@args,
    't|to=s'      => \my $to,
    'f|from=s'    => \my $from,
    's|subject=s' => \my $subject;

  die $self->usage unless $to && $from && $subject;

  say Data::Dumper::Dumper $self->sendgrid->mail(to=>$to,from=>$from,subject=>$subject,text=>join("\n",<STDIN>))->send->res->json;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::sendgrid::mail::send - Send command of the Sendgrid API
mail endpoint.

=head1 SYNOPSIS

  Usage: APPLICATION sendgrid mail send [OPTIONS]

    export SENDGRID_APIKEY='your sendgrid api key'
    mojo sendgrid mail send -t a@b.com -f x@y.com -s Subject < /tmp/file

  Options:
    -h, --help      Show this summary of available options
    -t, --to        Email address of the recipient
    -f, --from      Email address of the sender
    -s, --subject   Subject of the email

=head1 DESCRIPTION

L<Mojolicious::Command::sendgrid::mail::send> sends emails.
Prints the json response to STDOUT.

=head1 ATTRIBUTES

L<Mojolicious::Command::sendgrid::mail::send> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $app->description;
  $app            = $app->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $app->usage;
  $app      = $app->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Mojolicious::Command::sendgrid::mail::send> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $app->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
