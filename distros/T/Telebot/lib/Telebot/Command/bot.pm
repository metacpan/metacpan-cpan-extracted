package Telebot::Command::bot;
use Mojo::Base 'Mojolicious::Commands';

has description => 'Telebot commands';
has hint        => <<EOF;

See 'APPLICATION telebot help' for more information on a specific command.
EOF
has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { ['Telebot::Command::bot'] };

sub help { shift->run(@_) }

1;

=encoding utf8

=head1 NAME

Telebot::Command::bot - Telebot command

=head1 SYNOPSIS

  Usage: APPLICATION telebot COMMAND [OPTIONS]

    telebot bot generate

=head1 DESCRIPTION

L<Telebot::Command::bot> lists available generators.

This is a core command, that means it is always enabled and its code a good example for learning to build new commands,
you're welcome to fork it.

See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are available by default.

=head1 ATTRIBUTES

L<Telebot::Command::bot> inherits all attributes from L<Mojolicious::Commands> and implements the
following new ones.

=head2 description

  my $description = $generator->description;
  $generator      = $generator->description('Foo');

Short description of this command, used for the command list.

=head2 hint

  my $hint   = $generator->hint;
  $generator = $generator->hint('Foo');

Short hint shown after listing available generator commands.

=head2 message

  my $msg    = $generator->message;
  $generator = $generator->message('Bar');

Short usage message shown before listing available generator commands.

=head2 namespaces

  my $namespaces = $generator->namespaces;
  $generator     = $generator->namespaces(['MyApp::Command::generate']);

Namespaces to search for available generator commands, defaults to L<Telebot::Command::bot>.

=head1 METHODS

L<Telebot::Command::bot> inherits all methods from L<Mojolicious::Commands> and implements the
following new ones.

=head2 help

  $generator->help('app');

Print usage information for generator command.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
