package RunApp::Control::AppControl;
use strict;
require App::Control::Apache;
require YAML;
use base qw(RunApp::Control);
use Config;

sub build {
  my $self = shift;
  my ($conf) = @_;

  $self->{CONTROL} ||= 'App::Control';
  $self->load($self->{CONTROL});

  $self->{control} = $self->{CONTROL}->new
      ( EXEC => $self->{binary},
        ARGS => $self->{args},
        PIDFILE => $conf->{pidfile},
        SLEEP => 1,
        LOOP => 1);

  $self->write;
}

sub dispatch {
  my ($self, $cmd) = @_;
  if ($self->{control}) {
    $self->{control}->$cmd;
  } else {
    system ($self->{file}, $cmd);
  }
}

sub write {
  my $self = shift;
  open my $fh, '>', $self->{file} or die "$self->{file}: $!";
  #warn ". building $self->{file}\n";
  my $control = YAML::Dump ($self->{control});

  my $perl = $Config{'perlpath'};
  $perl = $^X if $^O eq 'VMS';

  print $fh (<< ".");
#!$perl -w
use strict;
use App::Control::Apache;
require YAML;
my \$cmd = shift or die "\$0: <start|stop|restart|graceful|hup|status>\\n";
YAML::Load ( << 'YAML')->dispatch (\$cmd);
$control
YAML

.
}

=head1 NAME

RunApp::Control::AppControl - Class for controlling daemon with App::Control

=head1 SYNOPSIS

 see RunApp::Apache

=head1 DESCRIPTION

The class writes to a perl script that uses App::Control to control
the daemon in the C<build> phase of L<RunApp>, and invokes the control
script in other phases.

=head1 SEE ALSO

L<App::Control>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
