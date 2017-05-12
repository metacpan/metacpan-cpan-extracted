package Proc::Daemontools::Service;

use warnings;
use strict;
use Config;

my (%SIGNUM, %SIGMETH);
BEGIN {
  my $i = 0;
  for my $name (split ' ', $Config{sig_name}) {
    $SIGNUM{$name} = $i++;
  }

  %SIGMETH = (
    INT  => 'svc_interrupt',
    HUP  => 'svc_hangup',
    TERM => 'svc_terminate',
    ALRM => 'svc_alarm',
  );
}

=head1 NAME

Proc::Daemontools::Service - services that play nicely with daemontools

=head1 VERSION

 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  package Foo::Service;
  use base qw(Proc::Daemontools::Service);

  sub svc_up { ... }

  # In other code...

  my $serv = Foo::Service->new;
  $serv->run;

=head1 DESCRIPTION

See the daemontools page, at
L<http://cr.yp.to/daemontools.html>, and particularly the
svc page, at L<http://cr.yp.to/daemontools/svc.html>.

=head1 METHODS

=head2 C<< new >>

Takes no arguments (yet).

=cut

sub new {
  my $class = shift;
  die "no arguments to new" if @_;
  return bless {} => $class;
}

=head2 C<< run >>

Install signal handlers and call C<< svc_run >>, which
may continue indefinitely.

If C<< svc_run >> ever finishes, calls C<< exit >>.

=cut

sub run {
  my $self = shift;
  $self->install_handlers;
  $self->svc_run;
  $self->exit(0);
}

=head2 C<< exit >>

  $serv->exit($exit_status);

Exit, calling C<< svc_exit >> first if it exists.  Default
signal handlers call this.

=cut

sub exit {
  my $self = shift;
  if ($self->can('svc_exit')) {
    $self->svc_exit;
  }
  exit(shift);
}

=head2 C<< install_handlers >>

Install signal handlers to queue signals for processing by
C<< svc_* >> methods, below.

NOTE: signal handlers are global.  This means that two
instances of Proc::Daemontools::Service will fight with each
other.  Don't do that.

=cut

sub install_handlers {
  my $self = shift;
  require sigtrap;
  my @args;
  for my $sig (qw(HUP INT TERM ALRM)) {
    push @args, handler => sub { $self->_handle_signal($sig) } => $sig;
  }
  sigtrap->import(@args);
}

sub _handle_signal {
  my ($self, $signame) = @_;
  my $arg = {
    signame => $signame,
    signum  => $SIGNUM{$signame},
  };
  my $meth = $self->can($SIGMETH{$signame}) || $self->can('svc_default');
  $self->$meth($arg);
}

=head1 HOOKS

=head2 C<< svc_run >>

Called by C<< run >>.  Your main program body should be here.

=head2 C<< svc_exit >>

Called by C<< exit >>.  Any cleanup should be here. (optional)

=head1 SIGNALS

Subclasses should define their own copy of each of these
methods.  They will be called by Proc::Daemontools::Service
as signals are caught.

Names are taken from the full names of svc options.

When called, these methods will be passed a hashref
indicating state.

=over 4

=item B<signal>

the name of the signal (e.g. TERM)

=item B<signum>

the number of the signal (e.g. 15)

=back

=head2 C<< svc_hangup >>

=head2 C<< svc_alarm >>

=head2 C<< svc_interrupt >>

=head2 C<< svc_terminate >>

=head1 DEFAULT HANDLERS

Uncaught signals will cause your program to exit.  If your
package defines a C<< svc_exit >> method, it will be called
before exiting (see L</exit>).

The exit value will be the number of the signal that caused
program exit.

=head2 C<< svc_default >>

Override this method to provide your own default for the
signals listed above.

=cut

sub svc_default {
  my ($self, $arg) = @_;
  $self->exit($arg->{signum});
}

=head1 UNCATCHABLE SIGNALS

=head2 C<< KILL >>

=head2 C<< STOP >>

=head2 C<< CONT >>

Technically CONT isn't uncatchable; however, given that you
can't catch STOP, you probably don't want to catch CONT
either.

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-proc-daemontools-service@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Proc-Daemontools-Service>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Proc::Daemontools::Service
