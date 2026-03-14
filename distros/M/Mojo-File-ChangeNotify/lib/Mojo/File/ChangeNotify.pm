package Mojo::File::ChangeNotify 0.03;
use 5.020;
use lib '../Filesys-Notify-Win32-ReadDirectoryChanges/lib';
use Mojo::Base 'Mojo::EventEmitter', -signatures;
use Mojo::File::ChangeNotify::WatcherProcess 'watch';
use Mojo::IOLoop::Subprocess;
use Scalar::Util 'weaken';
use PerlX::Maybe;

our $is_win32 = $^O =~ /mswin32/i;

=head1 NAME

Mojo::File::ChangeNotify - turn file changes into Mojo events

=head1 SYNOPSIS

  my $watcher =
    Mojo::File::ChangeNotify->instantiate_watcher
        ( directories => [ '/my/path', '/my/other' ],
          filter      => qr/\.(?:pm|conf|yml)$/,
          on_change   => sub( $watcher, @event_lists ) {
              ...
          },
        );

  # alternatively
  $watcher->on( 'change' => sub( $watcher, @event_lists ) {
      for my $l (@event_lists) {
          for my $e ($l->@*) {
              print "[$e->{type}] $e->{path}\n";
          }
      }
  });
  # note that the watcher might need about 1s to start up

=head1 IMPLEMENTATION

L<File::ChangeNotify> only supports blocking waits or polling as an
interface. This module creates a subprocess that blocks and communicates
the changes to the main process.

=head1 SEE ALSO

L<File::ChangeNotify> - the file watching implementation

=cut

has 'watcher';
has 'watcher_pid';  # Store the PID so we can access it in DESTROY

our %PIDs;

sub _spawn_watcher_subprocess( $self, $args ) {
    my $subprocess = Mojo::IOLoop::Subprocess->new();

    {
        weaken( my $weak_self = $self );
        $subprocess->on('spawn' => sub( $w ) {
            my $pid = $w->pid;
            $PIDs{ $pid } = 1;
            $weak_self->watcher_pid($pid) if $weak_self;  # Store PID for DESTROY access
        });

        $subprocess->on('progress' => sub( $w, $events ) {
            $weak_self->emit('change' => $events ) if $weak_self;
        });
    }
    #use Data::Dumper; warn Dumper( File::ChangeNotify->usable_classes );
    $subprocess->run( sub( $subprocess ) {
        watch( $subprocess, $args );
        return () # return an empty list here to not return anything after the process ends
    }, sub ($subprocess, $err, @results ) {
        if( $err
            and $err !~ /malformed JSON string/  # caused by us terminating the child
            and $err !~ /Missing or empty input/ # caused by us terminating the child
        ) {
            warn "Subprocess error: $err" and return;
        }
        say "Surprising results: @results"
            if @results;
    });
}

our %action_map = (
    added    => 'create',
    removed  => 'delete',
    modified => 'modify',
);

sub _spawn_watcher_win32( $self, $args) {
    require Filesys::Notify::Win32::ReadDirectoryChanges;
    weaken $self;

    # This spawns a thread
    my $watcher = Filesys::Notify::Win32::ReadDirectoryChanges->new(
        maybe directories => $args->{directories},
              subtree => 1,
    );

    # ... and we poll its queue frequently
    my $poll;
    $poll = Mojo::IOLoop->recurring( 0.1, sub($loop) {
        if(    ! $self
            || !defined $watcher->queue->pending ) {
            $watcher->stop;
            $loop->remove( $poll );
            return;
        };
        my @events = map {
            my $action = $action_map{ $_->{action} } // $_->{action};
            +{ type => $action, path => $_->{path}}
        } grep {
            defined $_
        } $self->watcher->queue->dequeue_nb(32);
        if( @events ) {
            $self->emit(change => \@events);
        }
    });

    return $watcher
}

sub instantiate_watcher( $class, %args ) {
    my $handler = delete $args{ on_change };
    my $self = $class->new();
    if( $handler ) {
        $self->on( 'change' => $handler );
    }

    if( $is_win32 ) {
        $self->watcher( $self->_spawn_watcher_win32( \%args ));

    } else {
        $self->watcher( $self->_spawn_watcher_subprocess( \%args ));
    }

    return $self;
}

# Cleanup watchers when we are removed
sub DESTROY( $self ) {
    my $pid = $self->watcher_pid;
    if( $pid ) {
        delete $PIDs{ $pid };
        kill KILL => $pid;
        waitpid($pid,0); # gobble up the child exit code
    }
    if( $is_win32 and my $w = $self->watcher ) {
        $w->stop;
    }
}

# Clean up watchers if we die for other reasons
END {
    kill KILL => keys %PIDs
}

1;
