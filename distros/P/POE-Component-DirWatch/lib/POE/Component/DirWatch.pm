package POE::Component::DirWatch;

our $VERSION = "0.300004";

use POE;
use Moose;
use Class::Load;
use MooseX::Types::Path::Class qw/Dir/;

sub import {
  my ($class, %args) = @_;
  return if delete $args{no_aio};
  return unless eval { Class::Load::load_class("POE::Component::AIO") };
  if (eval { Class::Load::load_class("POE::Component::DirWatch::Role::AIO") }){
    $class->meta->make_mutable;
    POE::Component::DirWatch::Role::AIO->meta->apply($class->meta);
    $class->meta->make_immutable;
  }
  return;
}

#--------#---------#---------#---------#---------#---------#---------#--------#

has alias => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  default => 'dirwatch'
);

has directory => (
  is => 'rw',
  isa => Dir,
  required => 1,
  coerce => 1
);

has interval => (
  is => 'rw',
  isa => 'Int',
  required => 1
);

has next_poll => (
  is => 'rw',
  isa => 'Int',
  clearer => 'clear_next_poll',
  predicate => 'has_next_poll'
);

has filter => (
  is => 'rw',
  isa => 'CodeRef',
  clearer => 'clear_filter',
  predicate => 'has_filter'
);

has dir_callback  => (
  is => 'rw',
  isa => 'Ref',
  clearer => 'clear_dir_callback',
  predicate => 'has_dir_callback'
);

has file_callback => (
  is => 'rw',
  isa => 'Ref',
  clearer => 'clear_file_callback',
  predicate => 'has_file_callback'
);

sub BUILD {
  my ($self, $args) = @_;
  POE::Session->create(
    object_states => [
      $self,
      {
        _start   => '_start',
        _pause   => '_pause',
        _resume  => '_resume',
        _child   => '_child',
        _stop    => '_stop',
        shutdown => '_shutdown',
        poll     => '_poll',
        ($self->has_dir_callback  ? (dir_callback  => '_dir_callback')  : () ),
        ($self->has_file_callback ? (file_callback => '_file_callback') : () ),
      },
    ]
  );
}

sub session { $poe_kernel->alias_resolve( shift->alias ) }

#--------#---------#---------#---------#---------#---------#---------#---------

sub _start {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $kernel->alias_set($self->alias); # set alias for ourselves and remember it
  $self->next_poll( $kernel->delay_set(poll => $self->interval) );
}

sub _pause {
  my ($self, $kernel, $until) = @_[OBJECT, KERNEL, ARG0];
  $kernel->alarm_remove($self->next_poll) if $self->has_next_poll;
  $self->clear_next_poll;
  return unless defined $until;

  my $t = time;
  $until += $t if $t > $until;
  $self->next_poll( $kernel->alarm_set(poll => $until) );

}

sub _resume {
  my ($self, $kernel, $when) = @_[OBJECT, KERNEL, ARG0];
  $kernel->alarm_remove($self->next_poll) if $self->has_next_poll;
  $self->clear_next_poll;
  $when = 0 unless defined $when;

  my $t = time;
  $when += $t if $t > $when;
  $self->next_poll( $kernel->alarm_set(poll => $when) );
}

sub _stop {}

sub _child {}

#--------#---------#---------#---------#---------#---------#---------#---------

sub pause {
  my ($self, $until) = @_;
  $poe_kernel->call($self->alias, _pause => $until);
}

sub resume {
  my ($self, $when) = @_;
  $poe_kernel->call($self->alias, _resume => $when);
}

sub shutdown {
  my ($self) = @_;
  $poe_kernel->alarm_remove($self->next_poll) if $self->has_next_poll;
  $self->clear_next_poll;
  $poe_kernel->post($self->alias, 'shutdown');
}

#--------#---------#---------#---------#---------#---------#---------#---------

sub _poll {
  my ($self, $kernel) = @_[OBJECT, KERNEL];
  $self->clear_next_poll;

  #just do this part once per poll
  my $filter = $self->has_filter ? $self->filter : undef;
  my $has_dir_cb  = $self->has_dir_callback;
  my $has_file_cb = $self->has_file_callback;

  while (my $child = $self->directory->next) {
    if($child->is_dir){
      next unless $has_dir_cb;
      next if ref $filter && !$filter->($child);
      $kernel->yield(dir_callback => $child);
    } else {
      next unless $has_file_cb;
      next if $child->basename =~ /^\.+$/;
      next if ref $filter && !$filter->($child);
      $kernel->yield(file_callback => $child);
    }
  }

  $self->next_poll( $kernel->delay_set(poll => $self->interval) );
}

#these are only here so allow method modifiers to hook into them
#these are prime candidates for inlining when the class is made immutable
sub _file_callback {
  my ($self, $kernel, $file) = @_[OBJECT, KERNEL, ARG0];
  $self->file_callback->($file);
}

sub _dir_callback {
  my ($self, $kernel, $dir) = @_[OBJECT, KERNEL, ARG0];
  $self->dir_callback->($dir);
}

#--------#---------#---------#---------#---------#---------#---------#---------

sub _shutdown {
  my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
  #cleaup heap, alias, alarms (no lingering refs n ish)
  %$heap = ();
  $kernel->alias_remove($self->alias);
  $kernel->alarm_remove_all();
}

#--------#---------#---------#---------#---------#---------#---------#---------

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__;

=head1 NAME

POE::Component::DirWatch - POE directory watcher

=head1 SYNOPSIS

  use POE::Component::DirWatch;

  my $watcher = POE::Component::DirWatch->new
    (
     alias      => 'dirwatch',
     directory  => '/some_dir',
     filter     => sub { $_[0]->is_file ? $_[0] =~ /\.gz$/ : 1 },
     dir_callback  => sub{ ... },
     file_callback => sub{ ... },
     interval   => 1,
    );

  $poe_kernel->run;

=head1 DESCRIPTION

POE::Component::DirWatch watches a directory for files or directories.
Upon finding either it will invoke a user-supplied callback function
depending on whether the item is a file or directory.

=head1 ASYNCHRONOUS IO SUPPORT

This object supports asynchronous IO access using L<IO::AIO>. At load time,
the class will detect whether IO::AIO is present in the host system and, if it
is present, apply the L<POE::Component::DirWatch::Role::AIO> role to the
current class, adding the C<aio> attribute, the <aio_callback> event, and
replacing C<_poll> with an asynchronous version. If you do not wish to use AIO
you can specify so with he C<no_aio> flag like this:

    use POE::Component::DirWatch (no_aio => 1);

=head1 ATTRIBUTES

=head2 alias

Read only alias for the DirWatch session.  Defaults to C<dirwatch> if not
specified. You can NOT rename a session at runtime.

=head2 directory

Read-write, required. A L<Path::Class::Dir> object for the directory watched.
Automatically coerces strings into L<Path::Class::Dir> objects.

=head2 interval

Required read-write integer representing interval between the end of a poll
event and the scheduled start of the next. Defaults to 1.

=head2 file_callback

=over 4

=item B<has_file_callback> - predicate

=item B<clear_file_callback> - clearer

=back

Optional read-write code reference to call when a file is found. The code
reference will passed a single argument, a L<Path::Class::File> object
representing the file found. It usually makes most sense to process the file
and remove it from the directory to avoid duplicate processing

=head2 dir_callback

=over 4

=item B<has_dir_callback> - predicate

=item B<clear_dir_callback> - clearer

=back

Optional read-write code reference to call when a directory is found. The code
reference will passed a single argument, a L<Path::Class::Dir> object
representing the directory found.

=head2 filter

=over 4

=item B<has_filter> - predicate

=item B<clear_filter> - clearer

=back

An optional read-write code reference that, if present, will be called for each
item in the watched directory. The code reference will passed a single
argument, a L<Path::Class::File> or L<Path::Class::Dir> object representing
the file/dir found. The code should return true if the callback should be
called and false if the file should be ignored.

=head2 next_poll

=over 4

=item B<has_next_poll> - predicate

=item B<clear_next_poll> - clearer

=back

The ID of the alarm for the next scheduled poll, if any. Has clearer
and predicate methods named C<clear_next_poll> and C<has_next_poll>.
Please note that clearing the C<next_poll> just clears the next poll id,
it does not remove the alarm, please use C<pause> for that.

=head1 OBJECT METHODS

=head2 new( \%attrs)

  See SYNOPSIS and ATTRIBUTES.

=head2 session

Returns a reference to the actual POE session.
Please avoid this unless you are subclassing. Even then it is recommended that
it is always used as C<$watcher-E<gt>session-E<gt>method> because copying the
object reference around could create a problem with lingering references.

=head2 pause [$until]

Synchronous call to _pause. This just posts an immediate _pause event to the
kernel.

=head2 resume [$when]

Synchronous call to _resume. This just posts an immediate _resume event to the
kernel.

=head2 shutdown

Convenience method that posts a FIFO shutdown event.

=head2 meta

See L<Moose>;

=head1 EVENT HANDLING METHODS

These methods are not part of the public interface of this class, and expect
to be called from whithin POE with the standard positional arguments.
Use them at your own risk.

=head2 _start

Runs when C<$poe_kernel-E<gt>run> is called to set the session's alias and
schedule the first C<poll> event.

=head2 _poll

Triggered by the C<poll> event this is the re-occurring action. _poll will use
get a list of all items in the directory and call the appropriate callback.

=head2 _file_callback

Will execute the C<file_callback> code reference, if any.

=head2 _pause [$until]

Triggered by the C<_pause> event this method will remove the alarm scheduling
the next directory poll. It takes an optional argument of $until, which
dictates when the polling should begin again. If $until is an integer smaller
than the result of time() it will treat $until as the number of seconds to wait
before polling. If $until is an integer larger than the result of time() it
will treat $until as an epoch timestamp.

     #these two are the same thing
     $watcher->pause( time() + 60);
     $watcher->pause( 60 );

     #this is one also the same
     $watcher->pause;
     $watcher->resume( 60 );


=head2 _resume [$when]

Triggered by the C<_resume> event this method will remove the alarm scheduling
the next directory poll (if any) and schedule a new poll alarm. It takes an
optional argument of $when, which dictates when the polling should begin again.
If $when is an integer smaller than the result of time() it will treat $until
as the number of seconds to wait before polling. If $until is an integer larger
than the result of time() it will treat $when as an epoch timestamp and
schedule the poll alarm accordingly. If not specified, the alarm will be
scheduled with a delay of zero.

=head2 _shutdown

Delete the C<heap>, remove the alias we are using and remove all set alarms.

=head2 BUILD

Constructor. C<create()>s a L<POE::Session>.

=head1 TODO

=over 4

=item More examples

=item More tests

=item ChangeNotify support (patches welcome!)

=back

=head1 SEE ALSO

L<POE::Session>, L<POE::Component>, L<Moose>, L<POE>,

The git repository for this project can be found in on github,
L<http://github.com/arcanez/poe-component-dirwatch/>

=head1 AUTHOR

Guillermo Roditi, <groditi@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-dirwatch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-DirWatch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=over 4

=item #poe & #moose on irc.perl.org

=item Matt S Trout

=item Rocco Caputo

=item Charles Reiss

=item Stevan Little

=item Eric Cholet

=back

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut
