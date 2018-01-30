use strict;
use warnings;

package Test::Server::MPD;

our $VERSION = '0';

use Moo;

use IO::Async::Loop;
use File::Share qw( dist_file );
use File::Which qw( which );
use Path::Tiny qw( path );
use Types::Path::Tiny qw( File Dir );
use Types::Standard qw( Str Int HashRef ArrayRef Undef );
use Net::EmptyPort qw( empty_port check_port );

has port => (
  is => 'ro',
  isa => Int,
  lazy => 1,
  default => sub {
    my $port = $ENV{MPD_PORT} // 6600;
    check_port($port) ? empty_port() : $port;
  },
);

has host => (
  is => 'ro',
  isa => Str,
  lazy => 1,
  default => 'localhost',
);

has template => (
  is => 'rw',
  lazy => 1,
  isa => File,
  coerce => 1,
  default => sub { path( dist_file('Net-Async-MPD', 'mpd.conf.template') ) },
);

has profiles => (
  is => 'rw',
  isa => HashRef[ArrayRef],
  lazy => 1,
  default => sub { {} }
);

has root => (
  is => 'ro',
  lazy => 1,
  isa => Dir,
  coerce => 1,
  default => sub { Path::Tiny::tempdir() }
);

has config => (
  is => 'ro',
  lazy => 1,
  isa => File,
  coerce => 1,
  default => sub { $_[0]->_populate_config }
);

has bin => (
  is => 'ro',
  lazy => 1,
  isa => File,
  coerce => 1,
  default => sub {
    which 'mpd'
      or die 'Could not find MPD executable in PATH. Try setting it manually', "\n";
  }
);

has _pid => (
  is => 'rw',
  isa => Int|Undef,
);

sub BUILD {
  my ($self) = @_;

  $self->root->child('playlists')->mkpath;
  $self->root->child('music')->mkpath;
}

sub _populate_config {
  my ($self) = @_;

  my $template = $self->template->slurp;

  foreach my $method (qw( port root )) {
    my $value = $self->$method;
    $template =~ s/\{\{ $method \}\}/$value/g;
  }

  my $host = $self->host;
  $template =~ s/\{\{ host \}\}/$host/g;

  my $profiles = q{};
  foreach my $password (keys %{$self->profiles}) {
    my @permissions = @{$self->profiles->{$password}};
    $profiles .=
        qq{password\t"$password\@}
      . join(',', @permissions)
      . qq{"\n}
  }

  $profiles = qq{default_permissions\t"read,add,control,admin"\n}
    if $profiles eq q{};

  $template =~ s/\{\{ profiles \}\}\s*\n/$profiles/g;

  my $config = $self->root->child('mpd.conf');
  $config->spew($template);

  return $config;
}

sub is_running { defined $_[0]->_pid }

sub start {
  my ($self) = @_;

  my $loop = IO::Async::Loop->new;
  my $start = $loop->new_future;

  $self->_pid(
    $loop->run_child(
      command => [ $self->bin, $self->config->realpath ],
      on_finish => sub {
        my ($pid, $exitcode, $stdout, $stderr) = @_;
        return $start->fail('Could not start MPD server: ' . $stdout)
          if $exitcode != 0;

        $start->done;
      },
    )
  );

  $start->get;
  return $self->_pid;
}

sub stop {
  my ($self) = @_;

  return unless $self->is_running;

  my $loop = IO::Async::Loop->new;
  my $stop = $loop->new_future;

  $loop->run_child(
    command => [ $self->bin, '--kill', $self->config->realpath ],
    on_finish => sub {
      my ($pid, $exitcode, $stdout, $stderr) = @_;

      return $stop->fail('Could not stop MPD server: ' . $stdout)
        if $exitcode != 0;

      $self->_pid(undef);
      $stop->done;
    },
  );

  return $stop->get;
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Server::MPD - Create MPD test servers at whim

=head1 SYNOPSIS

    use Test::Server::MPD;

    my $server = Test::Server::MPD->new(
      port => '12345', # defaults to 6600 or an empty port
      profiles => {
        'letmein' => [qw( read control )],
      },
    );
    $server->start;

    ...

    # You might want to put this in and END block, or
    # guard it with Scope::Guard, in case your test dies
    $server->stop;

=head1 DESCRIPTION

This module makes it easy to start and stop MPD server instances for testing.

=head1 ATTRIBUTES

=over 4

=item C<config>

The path to a configfile for the server. If this attribute is set, then that
file will be used to start the server. If not provided, then the file provided
as the C<template> attribute will be populated with the rest of the object's
attributes.

=item C<template>

The path to a config template file. Defaults to a file shipped with this
distribution. The template uses a very limited version of the mustache
templating system. It recognises the following keys: C<port>, C<root>, C<host>.

The special key C<profiles> populates the C<password> attributes of the MPD
config files. If no C<profiles> are provided, this key will instead populate
the C<default_permissions> value with all permissions.

=item C<port>

The port on which the server will be listening. Defaults to the value of the
C<MPD_PORT> environment variable, or 6600 if undefined. If 6600 is already in
use (likely by another MPD server), an empty port will be found using
L<Net::EmptyPort>.

Note that it is possible (however unlikely) that the port that was found to
be empty is actually not by the time the server starts.

=item C<host>

The host to use for the server. Defaults to C<localhost>.

=item C<profiles>

A hash reference with as many keys as profiles to use. Keys are the passwords,
and the values (which should be array references) indicate the permissions
for that profile.

=item C<bin>

The path to the MPD binary. Defaults to the one found by L<File::Which>. This
value is not checked until the server is C<start>ed (or C<stop>ped).

=back

=head1 METHODS

=over 4

=item C<start>

Start the MPD server using the object's C<config> file, or one created by the
object's C<template>. Returns the C<pid> of the server process.

This method will throw an exception if the C<bin> attribute is not set to a
plain file, or if there was an error starting the server.

=item C<stop>

Stop the MPD server.

This method will throw an exception if the C<bin> attribute is not set to a
plain file, or if there was an error stopping the server.

=back

=head1 SEE ALSO

=over 4

=item L<Test::Corpus::Audio::MPD>

The inspiration for this module, used by L<POE::Component::Client::MPD> and
L<Audio::MPD>. The fact that it cannot be made to coexist with a running
instance of MPD, and that it starts its server automatically upon use,
partly explain the existance of this module.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
