package Mojolicious::Plugin::CHI::chi;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw/tablify quote/;

use Getopt::Long qw/GetOptions :config no_auto_abbrev no_ignore_case/;

has description => 'Interact with CHI caches';
has usage       => sub { shift->extract_usage };

sub _unknown {
  return 'Unknown cache handle ' . quote($_[0]) . ".\n\n"
};

# Run chi
sub run {
  my $self = shift;

  my $command = shift;

  print $self->usage and return unless $command;

  # Get the application
  my $app = $self->app;
  my $log = $app->log;

  # List all associated caches
  if ($command eq 'list') {
    my $caches = $app->chi_handles;
    my @list;
    foreach (sort { lc($a) cmp lc($b) } keys %$caches) {
      push(@list, [$_, ($caches->{$_}->short_driver_name || '[UNKNOWN]')]);
    };
    print tablify \@list;
    return 1;
  }

  # Purge or clear a cache
  elsif ($command eq 'purge' || $command eq 'clear') {
    my $cache = shift || 'default';

    my $chi = $app->chi($cache);

    # Cache is unknown
    print _unknown($cache) and return unless $chi;

    # Do not modify non-persistant in-process caches!
    if ($chi->short_driver_name =~ /^(?:Raw)?Memory$/) {
      $log->warn("You are trying to $command a ".
                   $chi->short_driver_name .
                   '-Cache');
    };

    $chi->$command();

    # Purge or clear cache
    print qq{Cache "$cache" was } . $command .
      ($command eq 'clear' ? 'ed' : 'd') . ".\n\n";

    return 1;
  }

  # Remove or expire a key
  elsif ($command eq 'remove' || $command eq 'expire') {
    my $key   = pop(@_);
    my $cache = shift || 'default';

    if ($key) {

      my $chi = $app->chi($cache);

      # Cache is unknown
      print _unknown($cache) and return unless $chi;;

      # Do not modify non-persistant in-process caches!
      if ($chi->short_driver_name =~ /^(?:Raw)?Memory$/) {
        $log->warn("You are trying to $command " .
                     'a key from a '.
                     $chi->short_driver_name .
                     '-Cache');
      };

      # Remove or expire key
      if ($chi->$command($key)) {
        print qq{Key "$key" from cache "$cache" was } . $command . "d.\n\n";
      }

      # Not successful
      else {
        print 'Unable to ' . $command .
          qq{ key "$key" from cache "$cache".\n\n};
      };

      return 1;
    };
  };

  # Unknown command
  print $self->usage and return;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CHI::chi - Interact with CHI caches


=head1 SYNOPSIS

  usage: perl app.pl chi <command> [cache] [key]

    perl app.pl chi list
    perl app.pl chi purge
    perl app.pl chi clear mycache
    perl app.pl chi expire mykey
    perl app.pl chi remove mycache mykey

  Interact with CHI caches associated with your application.
  Valid commands include:

    list
      List all chi caches associated with your application.

    purge [cache]
      Remove all expired entries from the cache namespace.

    clear [cache]
      Remove all entries from the cache namespace.

    expire [cache] [key]
      Set the expiration date of a key to the past.
      This does not necessarily delete the data.

    remove [cache] [key]
      Remove a key from the cache

  "purge" and "expire" expect a cache namespace as their only argument.
  If no cache namespace is given, the default cache namespace is assumed.

  "expire" and "remove" expect a cache namespace and a key name as their
  arguments. If no cache namespace is given, the default cache
  namespace is assumed.


=head1 DESCRIPTION

L<Mojolicious::Plugin::CHI::chi> helps you to interact with
caches associated with L<Mojolicious::Plugin::CHI>.


=head1 ATTRIBUTES

L<Mojolicious::Plugin::CHI::chi> inherits all attributes
from L<Mojolicious::Command> and implements the following new ones.


=head2 description

  my $description = $chi->description;
  $chi = $chi->description('Foo!');

Short description of this command, used for the command list.


=head2 usage

  my $usage = $chi->usage;
  $chi = $chi->usage('Foo!');

Usage information for this command, used for the help screen.


=head1 METHODS

L<Mojolicious::Plugin::CHI::chi> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.


=head2 run

  $chi->run;

Run this command.


=head1 DEPENDENCIES

L<Mojolicious>,
L<CHI>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016, L<Nils Diewald||http://nils-diewald.de>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

The documentation is based on L<Mojolicious::Command::eval>,
written by Sebastian Riedel.

=cut
