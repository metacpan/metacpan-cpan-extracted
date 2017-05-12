package Sys::Gamin;

use strict;
use Carp;
use Cwd;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
$VERSION='0.1';

sub AUTOLOAD {
  my $constname;
  ($constname = $AUTOLOAD) =~ s/.*:://;
  my $val = constant($constname);
  if ($! != 0) {
    if ($! =~ /Invalid/ || $!{EINVAL}) {
      $AutoLoader::AUTOLOAD = $AUTOLOAD;
      goto &AutoLoader::AUTOLOAD;
    } else {
      croak "Your vendor has not defined Sys::Gamin macro $constname";
    }
  }
  eval "sub $AUTOLOAD { $val }";
  goto &$AUTOLOAD;
}

sub DESTROY {}			# Bypass AUTOLOAD

bootstrap Sys::Gamin $VERSION;

sub err(;$) {
  return $_[0] if @_ and $_[0] != -1;
  my $err=famerror();
  croak 'Sys::Gamin: ' . ($err ? $err : $! ? "$!" : 'unknown error');
}

{
  my %mapping=(
	       FAMChanged() => 'change',
	       FAMDeleted() => 'delete',
	       FAMStartExecuting() => 'start_exec',
	       FAMStopExecuting() => 'stop_exec',
	       FAMCreated() => 'create',
	       FAMMoved() => 'move',
	       FAMAcknowledge() => 'ack',
	       FAMExists() => 'exist',
	       FAMEndExist() => 'end_exist',
	      );
  sub FAMEventPtr::type {
    my ($self)=@_;
    my $code=err $self->code;
    $mapping{$code} or die "Sys::Gamin: Unknown event code $code";
  }
}

use vars qw($reqcnt);
$reqcnt=0;

sub abspath($;) {
  my ($path)=@_;

  Cwd::abs_path ($path)
	 or die "Sys::Gamin: could not resolve path $path";
}

1;
__END__

=head1 NAME

B<Sys::Gamin> - Perl interface to Gamin (File Access Monitor implementation)

=head1 SYNOPSIS

  use Sys::Gamin;
  my $fm=new Sys::Gamin;
  $fm->monitor('/foo');
  $fm->monitor('/foo/bar.txt');
  while (1) {
    my $event=$fm->next_event;	# Blocks
    print "Pathname: ", $event->filename,
      " Event: ", $event->type, "\n";
  }

Asynchronous mode:

  while ($fm->pending) {
    my $event=$fm->next_event; # Immediate
    ...
  }
  # Do something else

=head1 DESCRIPTION

Provides a somewhat higher-level and friendlier interface to the Gamin File Access
Monitor API. This allows one to monitor both local and remote (NFS-mounted) files and
directories for common filesystem events. To do so, you must register "monitors" on
specified pathnames and wait for events to arrive pertaining to them.

Since FAM only deals with absolute pathnames, all paths are canonicalized internally
and monitors are held on canonical paths. Whenever a path is returned from this module,
howvever, via B<which> or B<monitored> with no arguments, the originally specified path
is given for convenience.

=head1 MAIN METHODS

=head2 B<new> [ I<appname> ]

Create a new FAM connection. An application name may be given.

=cut

sub new {
  my ($class, $appname)=@_;
  my $rawconn=new FAMConnectionPtr;
  err $rawconn->Open2($appname or $0);
  bless {conn => $rawconn, monitors => {},
	 suspended => {}, reqnums => {}}, $class;
}

=head2 B<pending>

True if there is an event waiting. Returns immediately.

=cut

sub pending {
  my ($self)=@_;
  err $self->{conn}->Pending;
}

=head2 B<next_event>

Returns next event in queue, as an event object. Blocks if necessary until one is
available.

=cut

sub next_event {
  my ($self)=@_;
  my $rawev=new FAMEventPtr;
  err $self->{conn}->NextEvent($rawev);
  $rawev;
}

=head2 B<monitor> I<path> [ I<unique> [ I<type> [ I<depth> I<mask> ] ] ]

Monitor the specified file or directory. Expect a slew of events immediately (B<exist>
and B<end_exist>) which may not interest you.

I<unique>, if specified and true, will produce a warning if the monitored path is not
unique among those already being monitored. This can be helpful for debugging, but
normally this is harmless.

I<type> may be B<file>, B<dir> or B<coll>; it defaults to B<file> or B<dir> according
to an I<existing> filesystem entry. If you specify B<coll> (collection), pass
additional depth and mask arguments, if you ever figure out what that does (SGI does
not say).

=cut

sub monitor {
  my ($self, $_path, $unique, $type, $depth, $mask)=@_;
  my $path=abspath($_path);
  die "Sys::Gamin: `$_path' does not currently exist" unless $type or -e $_path;
  if (exists $self->{monitors}{$path}) {
    warn "Sys::Gamin: attempt to re-monitor $_path (canon. $path)" if $unique;
    return;
  }
  my $conn=$self->{conn};
  $type=(-d $path ? 'dir' : 'file') unless $type;
  my $rawreq=new FAMRequestPtr;
  $rawreq->setreqnum(++$reqcnt);
  $self->{monitors}{$path}=$rawreq;
  if ($type eq 'file') {
    err $conn->MonitorFile2($path, $rawreq);
  } elsif ($type eq 'dir') {
    err $conn->MonitorDirectory2($path, $rawreq);
  } elsif ($type eq 'coll') {
    err $conn->MonitorCollection($path, $rawreq, undef, $depth, $mask);
  } else {
    die "Sys::Gamin: unknown monitor style $type";
  }
  my $reqnum=$rawreq->reqnum;
  my $orig=$self->{reqnums}{$reqnum};
  die "Sys::Gamin: attempt to reuse request numbers from $orig to $_path" if $orig;
  $self->{reqnums}{$reqnum}=$_path;
}

=head2 B<cancel> I<path>

Stop monitoring this path.

=cut

sub check_monitored {
  my ($self, $path)=@_;
  die "Sys::Gamin: `$path' is not monitored"
    unless exists $self->{monitors}{abspath($path)};
}

sub cancel {
  my ($self, $_path)=@_;
  my $path=abspath($_path);
  $self->check_monitored($path);
  err $self->{conn}->CancelMonitor($self->{monitors}{$path});
  delete $self->{monitors}{$path};
}

=head2 B<monitored> [ I<path> ]

List all currently monitored paths, or check if a specific one is being monitored. Does
not check if a monitor is suspended.

=cut

sub monitored {
  my ($self, $_path)=@_;
  if ($_path) {
    exists $self->{monitors}{abspath($_path)};
  } else {
    my $reqnums=$self->{reqnums};
    sort map {$reqnums->{$_->reqnum}} values %{$self->{monitors}};
  }
}

=head2 B<suspended> I<path>

True if the specified monitor is suspended.

=cut

sub suspended {
  my ($self, $_path)=@_;
  my $path=abspath($_path);
  $self->check_monitored($path);
  $self->{suspended}{$path};
}

=head2 B<suspend> [ I<path> ]

Suspend monitoring of a path, or all paths if unspecified.

=cut

sub suspend {
  my ($self, $_path)=@_;
  if ($_path) {
    my $path=abspath($_path);
    $self->check_monitored($path);
    return if $self->{suspended}{$path};
    err $self->{conn}->SuspendMonitor($self->{monitors}{$path});
    $self->{suspended}{$path}=1;
  } else {
    foreach (keys %{$self->{monitors}}) {
      unless ($self->{suspended}{$_}) {
	err $self->{conn}->SuspendMonitor($self->{monitors}{$_});
	$self->{suspended}{$_}=1;
      }
    }
  }
}

=head2 B<resume> [ I<path> ]

Resume monitoring of a path, or all paths if unspecified.

=cut

sub resume {
  my ($self, $_path)=@_;
  if ($_path) {
    my $path=abspath($_path);
    $self->check_monitored($path);
    return unless $self->{suspended}{$path};
    err $self->{conn}->ResumeMonitor($self->{monitors}{$path});
    delete $self->{suspended}{$path};
  } else {
    foreach (keys %{$self->{suspended}}) {
      err $self->{conn}->ResumeMonitor($self->{monitors}{$path});
      delete $self->{suspended}{$_};
    }
  }
}

=head2 B<which> I<event>

Gives the pathname for the monitor generating this event. Often this will be the same
as C<$event-E<gt>filename>, but will differ in some cases, e.g. in B<create> events
where B<filename> will yield the basename of the new file while the B<which> method
must be invoked to determine the directory of creation, if more than one is being
monitored.

=cut

sub which {
  my ($self, $event)=@_;
  my $reqnum=$event->fr->reqnum;
  $self->{reqnums}{$reqnum}
  or die "Sys::Gamin: Monitor \x23$reqnum not found for this connection";
}

=head1 EVENT METHODS

=head2 B<hostname>

Host of event. Does not seem to work, actually.

=head2 B<filename>

Path of event, according to FAM.

=head2 B<type>

Type of event; one of the following strings: B<change>, B<delete>, B<start_exec>,
B<stop_exec>, B<create>, B<move>, B<ack>, B<exist>, B<end_exist>.

=head1 BUGS

Most of these can be observed with F<monitor>.

=over 4

=item Hostnames

Do not seem to be supplied at all.

=item Timing

Is somewhat erratic. For example, creating a file that had been monitored and deleted
will signal a B<create> event on it, after about a second pause.

=item Execute Events

Are not sent, as far as the author can determine.

=back

=head1 SEE ALSO

For the raw SGI interface (rather poorly documented), see L<fam(3x)>.

=head1 AUTHORS

J. Glick B<jglick@sig.bsh.com>: Original SGI::FAM code, in which this module is based.

Carlos Garnacho B<carlosg@gnome.org>.

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$ release $ProjectRelease$. $Copyright$"$>
F<lib/SGI/FAM.pm> last modified Thu, 04 Mar 2005 22:05:42 -0100 release 0.1. Original SGI::FAM module: Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
