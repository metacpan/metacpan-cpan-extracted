package Mojolicious::Plugin::CHI;
use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util 'weaken';
use CHI;

our $VERSION = '0.19';

# Register Plugin
sub register {
  my ($plugin, $mojo, $param) = @_;

  # Load parameter from config file
  if (my $config_param = $mojo->config('CHI')) {
    $param = { %$param, %$config_param };
  };

  # Hash of cache handles
  my $caches;

  # Add 'chi_handles' attribute
  # Necessary for multiple cache registrations
  unless ($mojo->can('chi_handles')) {
    $mojo->attr(
      chi_handles => sub {
        return ($caches //= {});
      }
    );
  }

  # Get caches from application
  else {
    $caches = $mojo->chi_handles;
  };

  # Support classes
  my $chi_class = delete $param->{chi_class} // 'CHI';

  # Support namespaces
  my $ns = delete $param->{namespaces} // 1;

  # Create log callback for CHI Logging
  my $log = $mojo->log;
  weaken $log;
  my $log_ref = sub {
    $log->warn( shift ) if defined $log;
  };

  # Loop through all caches
  foreach my $name (keys %$param) {
    my $cache_param = $param->{$name};

    next unless ref $cache_param && ref $cache_param eq 'HASH';

    # Already exists
    if (exists $caches->{$name}) {
      $mojo->log->warn(qq{Multiple attempts to establish cache "$name"});
      next;
    };

    # Set namespace
    if ($ns) {
      $cache_param->{namespace} //= $name unless $name eq 'default';
    };

    # Get CHI handle
    my $cache = $chi_class->new(

      # Set logging routines
      on_get_error => $log_ref,
      on_set_error => $log_ref,

      %$cache_param
    );

    # No succesful creation
    $mojo->log->warn(qq{Unable to create cache handle "$name"}) unless $cache;

    # Store CHI handle
    $caches->{$name} = $cache;
  };

  # Only establish once
  unless (exists $mojo->renderer->helpers->{chi}) {

    # Add 'chi' command
    push @{$mojo->commands->namespaces}, __PACKAGE__;

    # Add 'chi' helper
    $mojo->helper(
      chi => sub {
        my $c = shift;
        my $name = shift // 'default';

        my $cache = $caches->{$name};

        # Cache unknown
        $c->app->log->warn(qq{Unknown cache handle "$name"}) unless $cache;

        # Return cache
        return $cache;
      }
    );
  };
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CHI - Use CHI Caches in Mojolicious


=head1 SYNOPSIS

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    }
  });

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => {
      driver => 'Memory',
      global => 1
    }
  };

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value');
  print $c->chi('MyCache')->get('my_key');

  # Using the default cache
  $c->chi->set(from_memory => 'With love!');
  print $c->chi->get('from_memory');


=head1 DESCRIPTION

L<Mojolicious::Plugin::CHI> is a simple plugin to work with
L<CHI> caches within Mojolicious.


=head1 METHODS

=head2 register

  # Mojolicious
  $app->plugin(CHI => {
    MyCache => {
      driver     => 'FastMmap',
      root_dir   => '/cache',
      cache_size => '20m'
    },
    default => {
      driver => 'Memory',
      global => 1
    },
    namespaces => 1
  });

  # Mojolicious::Lite
  plugin 'CHI' => {
    default => { driver => 'Memory', global => 1 }
  };

  # Or in your config file
  {
    CHI => {
      default => {
        driver => 'Memory',
        global => 1
      }
    }
  }

Called when registering the plugin.
On creation, the plugin accepts a hash of cache names
associated with L<CHI> objects.
All cache handles are qualified L<CHI> namespaces.
You can omit this mapping by passing a C<namespaces>
parameter with a C<false> value.
The handles have to be unique, i.e.
you can't have multiple different C<default> caches in mounted
applications using L<Mojolicious::Plugin::Mount>.
Logging defaults to the application log, but can be
overridden using L<on_get_error|CHI/CONSTRUCTOR> and
L<on_set_error|CHI/CONSTRUCTOR>.

All parameters can be set as part of the configuration
file with the key C<CHI> or on registration
(that can be overwritten by configuration).

Use custom CHI subclasses by passing a C<chi_class>
parameter with the class name of a CHI subclass.

=head1 HELPERS

=head2 chi

  # In Controllers:
  $c->chi('MyCache')->set(my_key => 'This is my value', '10 min');
  print $c->chi('MyCache')->get('my_key');
  print $c->chi->get('from_default_cache');

Returns a L<CHI> handle if registered.
Accepts the name of the registered cache.
If no cache handle name is given, a cache handle name
C<default> is assumed.


=head1 COMMANDS

The following commands are available
when the plugin is registered.

=head2 chi list

  perl app.pl chi list

List all CHI caches associated with your application.


=head2 chi purge

  perl app.pl chi purge mycache

Remove all expired entries from the cache namespace.


=head2 chi clear

  perl app.pl chi clear mycache

Remove all entries from the cache namespace.


=head2 chi expire

  perl app.pl chi expire mykey
  perl app.pl chi expire mycache mykey

Set the expiration date of a key to the past.
This does not necessarily delete the data,
but makes it unavailable using C<get>.


=head2 chi remove

  perl app.pl chi remove mykey
  perl app.pl chi remove mycache mykey

Remove a key from the cache.



=head1 DEPENDENCIES

L<Mojolicious>,
L<CHI>.

B<Note:> Old versions of L<CHI> had a lot of dependencies.
It was thus not recommended to use this plugin in a CGI
environment. Since new versions of CHI use L<Moo> instead of
L<Moose>, more use cases may be possible.


=head1 CONTRIBUTORS

L<Boris Däppen|https://github.com/borisdaeppen>

L<Renée Bäcker|https://github.com/reneeb>

L<Rouzier|https://github.com/rouzier>

L<Mohammad S Anwar|https://github.com/manwar>


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-CHI


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
