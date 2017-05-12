package RunApp;
use strict;
use base qw(RunApp::Control);
our $VERSION = '0.13';

=head1 NAME

RunApp - A generic module to run web-applications

=head1 SYNOPSIS

 use RunApp '-chdir';

 use RunApp;
 use RunApp::Apache;

 my $cmd = shift || 'development';
 my $config = { var => 'value', app_apache => { var_for_apache => 'value'} };
 RunApp->new (app_apache => RunApp::Apache->new
                    (root => catfile (cwd, $_),
                     httpd => '/path/to/httpd'),
              my_daemon => RunApp::Control::AppControl->new
                    (binary => '/path/to/daemon',
                     args => ['--daemon'],
                     pidfile => '/path/to/daemon.pid',
                    )
                 )->$cmd ($config);

=head1 DESCRIPTION

C<RunApp> streamlines the process for configuring applications
that requires one or more web servers and/or other daemons, during
development or deployment.

It builds the config files required by the services from the
C<$config> hash, such as apache's httpd.conf.

=head1 OPTIONS

 use RunApp '-chdir';
 use RunApp qw(-chdir ..);

This will cause the your script to C<chdir> to the base directory.  If
it's a symbolic link it will be resolved and you will be in the
directory of where the original script is.  The C<lib> directory will
be added into C<@INC>, and you can use the modules in that path.

It also takes an optional relative path if want the script to chdir to
somewhere else.

This makes it possible for symlinking the your runapp script into
system's rc.d startup directory.

=head1 CONSTRUCTOR

=head2 new (@services)

C<@services> is actually an hash, with keys being the name of the
service, and values being C<RunApp::Control> objects.  Use an
array instead of a hash here to retain the order of dispatching.

The names are used to pick config from the hash, which will be flatten
into top level of the config hash, when running C<build> for the each
service.

=cut

use File::Spec::Functions qw(catdir splitpath);
use Cwd;

sub import {
  my $class = shift;
  my $opt = shift or return;
  if ($opt eq '-chdir') {
    my $dir = shift;
    $0 = Cwd::abs_path ($0);
    my (undef, $path) = splitpath ($0);
    chop $path if length $path > 1;
    $path = catdir ($path, $dir) if defined $dir;
    $path ||= Cwd::cwd;
    unshift @INC, catdir ($path, 'lib');
    chdir ($path);
  }
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->services (@_);
  return $self;
}

sub dispatch {
  my $self = shift;
  my $cmd = shift;
  $_->$cmd (@_) for @{$self->services}{@{$self->{order}}};
}

sub services {
  my $self = shift;
  if (@_) {
      my $key;
      $self->{order} = [grep { ($key = !$key) ? $_ : ()} @_];
      $self->{services} = {@_};
  }
  $self->{services};
}

=head1 METHODS

=head2 $self->development ($conf)

Runs C<build> and C<start>, and then waits for SIGINT to <stop> the
servers.

=cut

sub development {
  my ($self, $conf) = @_;
  $self->build ($conf);
  $self->start;
  $self->report ($conf);
  local $SIG{INT} = sub { $self->stop; exit };
  $self->debug if $conf->{debug};
  select (undef, undef, undef, undef);
}

sub build {
  my ($self, $conf) = @_;
  for (@{$self->{order}}) {
    my $subconf = ref $conf->{$_} ? $conf->{$_} : {};
    next unless $self->services->{$_};
    $self->services->{$_}->build ( {%$conf, %$subconf} );
  }
}

=head1 AUTOLOAD

All other methods are dispatched to the C<RunApp::Control> objects in
the order called in CONSTRUCTOR.  Note that this is done with
L<RunApp::Control> dispatching to the C<dispatch> method.

=head1 SEE ALSO

L<RunApp::Apache>, L<RunApp::Control::AppControl>, L<App::Control>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

Refactored from works by Leon Brocard E<lt>acme@astray.comE<gt> and
Tom Insam E<lt>tinsam@fotango.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
