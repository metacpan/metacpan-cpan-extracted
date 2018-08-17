package Mojolicious::Plugin::Util::Endpoint::endpoints;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => "Show available endpoints.\n";
has usage       => <<"EOF";
usage: $0 endpoints

  perl app.pl endpoints

EOF


# Run endpoints
sub run {
  my $self = shift;

  # Options
  local @ARGV = @_;

  my $c = $self->app->build_controller;
  $c->app($self->app);

  # Get endpoints
  my $endpoints = $c->get_endpoints;

  # No endpoints
  return unless $endpoints;

  # Print all endpoints
  foreach my $name (sort { $a cmp $b } keys %$endpoints) {
    printf " %-20s %s\n", qq{"$name"}, $endpoints->{$name};
  };
  print "\n";

  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::Util::Endpoint::endpoints - List Template URIs

=head1 SYNOPSIS

  use Mojolicious::Plugin::Util::Endpoint::endpoints;

  my $ep = Mojolicious::Plugin::Util::Endpoint::endpoints->new;
  $ep->run;


=head1 DESCRIPTION

L<Mojolicious::Plugin::Util::Endpoint::endpoints> lists all
endpoints established by L<Mojolicious::Plugin::Util::Endpoint>.

It is normally started from the command line:

  $ perl app.pl endpoints


=head1 ATTRIBUTES

L<Mojolicious::Plugin::Util::Endpoint::endpoints> inherits all
attributes from L<Mojolicious::Command> and implements the following
new ones.


=head2 description

  my $description = $ep->description;
  $ep = $ep->description('Foo!');

Short description of this command, used for the command list.


=head2 usage

  my $usage = $ep->usage;
  $ep       = $ep->usage('Foo!');

Usage information for this command, used for the help screen.


=head1 METHODS

L<Mojolicious::Plugin::Util::Endpoint::endpoints> inherits all
methods from L<Mojolicious::Command> and implements the following new ones.


=head2 run

  $ep->run;

Run this command.


=head1 DEPENDENCIES

L<Mojolicious>,
L<Mojolicious::Plugin::Util::Endpoint>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Util-Endpoint


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

The documentation is based on L<Mojolicious::Command::eval>,
written by Sebastian Riedel.

=cut
