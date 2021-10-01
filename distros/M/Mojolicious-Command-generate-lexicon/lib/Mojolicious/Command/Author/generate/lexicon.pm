package Mojolicious::Command::Author::generate::lexicon;

use Mojo::Base 'Mojolicious::Command';

use Mojolicious::Command::generate::lexicon;

has command =>
  sub { Mojolicious::Command::generate::lexicon->new()->app(shift->app) };
has description => sub { shift->command->description() };
has usage       => sub { shift->command->usage() };

sub run {
    shift->command->run(@_);
}

1;

__END__

=head1 NAME

Mojolicious::Command::Author::generate::lexicon - Decorator of the Mojolicious::Command::generate::lexicon

=head1 SYNOPSIS

  See L<Mojolicious::Command::generate::lexicon>
