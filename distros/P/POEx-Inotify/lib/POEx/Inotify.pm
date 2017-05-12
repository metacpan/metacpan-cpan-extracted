## $Id$
#####################################################################
package POEx::Inotify;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.0201';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

use POE;
use POE::Session::PlainCall;
use Storable qw( dclone );
use Carp;
use Data::Dump qw( pp );

use Linux::Inotify2;

sub DEBUG () { 0 }
sub DEBUG2 () { 0 }

#############################################
sub spawn
{
    my( $package, %init ) = @_;

    my $options = delete $init{options};
    $options ||= {};

    POE::Session::PlainCall->create(
                    package   => $package,
                    ctor_args => [ \%init ],
                    options   => $options,
                    states    => [ qw( _start _stop shutdown
                                       poll inotify
                                       monitor unmonitor
                                       __pending_deleted __pending_created
                                       __self_deleted
                                 ) ]
                );
}


#############################################
sub new
{
    my( $package, $args ) = @_;

    my $self = bless {
                       path=>{}         # path => $notifies
                     }, $package;
    $self->{alias} = $args->{alias} || 'inotify';
    $self->build_inotify;
    return $self;
}

#############################################
sub _start
{
    my( $self ) = @_;
    DEBUG and warn "$self->{alias}: _start";
    poe->kernel->alias_set( $self->{alias} );
    poe->kernel->sig( shutdown => 'shutdown' );
    $self->setup_inotify;
}

#############################################
sub _stop
{
    my( $self ) = @_;
    DEBUG and warn "$self->{alias}: _stop";
}

#############################################
sub shutdown
{
    my( $self ) = @_;
    DEBUG and 
        warn "$self->{alias}: shutdown";
    $self->{shutdown} = 1;
    foreach my $path ( keys %{ $self->{path} } ) {
        local $self->{force} = 1;
        $self->unmonitor( { path=>$path } );
    }
    poe->kernel->select_read( $self->{fh} ) if $self->{fh};
    poe->kernel->alias_remove( $self->{alias} );
    delete $self->{fh};
#    delete $self->{inotify};
    return;
}

#############################################
sub build_inotify
{
    my( $self ) = @_;
    $self->{inotify} = Linux::Inotify2->new;
}

#############################################
sub setup_inotify
{
    my( $self ) = @_;
    $self->{inotify}->blocking( 0 );
    $self->{fh} = IO::Handle->new_from_fd( $self->{inotify}->fileno, "r" );
    poe->kernel->select_read( $self->{fh}, 'poll' );
}

sub add_inotify
{
    my( $self, $path, $mask ) = @_;
    DEBUG and warn sprintf "$self->{alias}: mask=%08x path=$path", $mask;
    return $self->{inotify}->watch( $path, $mask, 
                                    poe->session->callback( inotify=>$path ) );
}

#############################################
# Poll the Inotify object
sub poll
{
    my( $self ) = @_;
    return if $self->{shutdown};
    DEBUG and warn "$self->{alias}: poll";
    $self->{inotify}->poll
}

#############################################
# Callback from Inotify object
sub inotify
{
    my( $self, $N, $E ) = @_;
    my $notify = $self->_find_path( $N->[0] );
    next unless $notify;

    foreach my $e ( @$E ) {
        DEBUG and do {
                warn "$self->{alias}: inotify ", $e->fullname;
                foreach my $flag ( qw( ACCESS MODIFY ATTRIB CLOSE_WRITE CLOSE_NOWRITE 
                       OPEN MOVED_FROM MOVED_TO CREATE DELETE DELETE_SELF
                       MOVE_SELF ONESHOT ONLYDIR DONT_FOLLOW
                       MASK_ADD CLOSE MOVE ) ) {
                    my $method = "IN_$flag";
                    warn "$self->{alias}: IN_$flag" if $e->$method();
                }
            };        

        foreach my $call ( @{ $notify->{call} } ) {
            DEBUG and 
                warn sprintf "$self->{alias}: %08x vs %08x", $e->mask, $call->{tmask};
            
            next unless $e->mask & $call->{tmask};

            my $CB = dclone $call->{cb};
            $CB->[2] = $e;
            poe->kernel->call( @$CB );
        }
    }
}

#############################################
sub _find_path
{
    my( $self, $path ) = @_;
    return $self->{path}{ $path };
}


sub _build_calls
{
    my( $self, $args ) = @_;

    unless( $args->{events} ) {
        return "No event specified" unless $args->{event};
        my $event = delete $args->{event};
        my $mask  = delete $args->{mask};
        my $A     = delete $args->{args};

        $mask = IN_ALL_EVENTS unless defined $mask;
        $args->{events} = { $mask => { event=>$event, 
                                       args => $A
                                     } };
    }

    my $total_mask = 0;
    my @calls;

    foreach my $mask ( keys %{ $args->{events} } ) {
        $total_mask |= 0+$mask;

        my $E = $args->{events}{ $mask };

        my( $event, $A );
        my $r = ref $E;
        unless( $r ) {              # { MASK => 'event' }
            $event = $E;
            $A = [];
        }
        elsif( 'ARRAY' eq $r ) {    # { MASK => ['event', @ARGS }
            $event = shift @$E;
            $A = $E;
        }
        else {                      # { MASK => { event=>'event', args=>[] }
            $event = $E->{event};
            $A = $E->{args}||$args->{args};
        }
                                        # undef is place holder for the change object
        my $call = [ $args->{session}, $event, undef ];

        push @calls, { cb   => $call,   # list of callbacks
                       mask => $mask,                   # user specified mask
                      tmask => $self->_const2mask( $mask, $args ),      # true mask
                       mode => $args->{mode}            # mode we want for this
                     };
        next unless $A;

        $A = dclone $A if ref $A;
        if( 'ARRAY' eq ref $A ) {
            push @$call, @$A;
        }
        else {
            push @$call, $A;
        }
    }
    return "No event specified" unless @calls;

    return $total_mask, @calls;
}

sub _const2mask
{
    my( $self, $mask, $args ) = @_;
    if( -f $args->{path} and $mask | IN_DELETE ) {
        $mask |= IN_DELETE_SELF;    # IN_DELETE is useless on a file
    }
    return $mask;
}

#############################################
sub monitor
{
    my( $self, $args ) = @_;
    return if $self->{shutdown};
    $args->{session} = poe->sender;

    my $mode = $args->{mode} ||= 'cooked';

    my $caller = join ' ', at => poe->caller_file,
                               line => poe->caller_line . "\n";

    my( $new_mask, @calls ) = $self->_build_calls( $args );
    die "Nothing to do: $new_mask $caller" unless @calls;

    return $self->_monitor_add( $args->{path}, $mode, \@calls, $caller );
}

#############################################
sub _monitor_add 
{
    my( $self, $path, $mode, $calls, $caller ) = @_;
    confess "Why no calls? calls=", pp $calls unless $calls and 'ARRAY' eq ref $calls;
    $caller ||= '';
    if( !-e $path ) {
        if( $mode eq 'cooked' ) {
            $self->_pending( $path, $calls ) and return 1;
        }
        return;
    }

    my $notify = $self->_find_path( $path );

    # save the new calls
    if( $notify ) {
        DEBUG and 
            warn "$self->{alias}: monitor $path again for $mode ($notify) $caller";
        push @{ $notify->{call} }, @$calls;
    }
    else {
        $notify = {
                    path => $path,
                    call => [ @$calls ],
                    mask => 0,
                    # watch => 
                };
        DEBUG and 
            warn "$self->{alias}: monitor $path for $mode ($notify) $caller";
        $self->{path}{$path} = $notify;
        DEBUG2 and warn "$self->{alias}: REFCNT PLUS  ", poe->session->ID, " (me) $path";
        poe->kernel->refcount_increment( poe->session->ID, "NOTIFY $path" );

        $self->_self_monitor( $path ) unless $mode eq 'raw'
                                            or $mode =~ /^_/;
    }

    $notify->{new_mask} = $self->_notify_mask( $notify );

    $notify->{watch} = $self->add_inotify( $path, $notify->{new_mask} );
    die "Unable to watch $path: $! $caller" unless $notify->{watch};

    # And increment the sender's refcnt
    foreach my $call ( @$calls ) {
        use Carp;
        use Data::Dump qw( pp );
        confess pp $calls if 'ARRAY' eq ref $call;
        DEBUG2 and warn "$self->{alias}: REFCNT PLUS  ", $call->{cb}[0], " ($call->{mode}) $path";
        DEBUG2 and $call->{mode} eq 'self' and warn "$self->{alias}: REFCNT $caller";
        poe->kernel->refcount_increment( $call->{cb}[0], "NOTIFY $path" );
    }
    return 1;
}


#############################################
sub unmonitor
{
    my( $self, $args ) = @_;
    my $path = $args->{path};
    $args->{session} = poe->sender;
    $args->{mask} = 0xFFFFFFFF unless defined $args->{mask};
    my $caller = join ' ', at => poe->caller_file,
                               line => poe->caller_line . "\n";

    DEBUG and 
        warn "$self->{alias}: Unmonitor $path $caller";

    my $once = 0;
    my $notify = $self->_find_path( $path );
    if( $notify ) {
        $self->_unmonitor_remove( $path, $notify, $args, $caller );
        $once++;
    }
    
    my $P = $self->_find_pending( $path );
    if( $P ) {
        $self->_pending_remove( $path, $P, $args, $caller );
        $once++;
    }

    unless( $once or $self->{shutdown} ) {
        warn "$self->{alias}: $path wasn't monitored $caller";
    }
    return $once;
}

sub _unmonitor_remove
{
    my( $self, $path, $notify, $args, $caller ) = @_;

    # Go through the calls, dropping those the sender wants us to drop
    my $ours = 0;
    my( @calls, @dec );
    foreach my $call ( @{ $notify->{call} } ) {
        if( $self->_call_match( $call, $args ) ) {
            push @dec, $call;
        }
        else {
            $ours++ if $call->{cb}[0] == poe->session->ID;
            push @calls, $call;
        }
    }

    my $finished = 0;
    if( @calls > $ours ) {
        # If we have any non-internal calls, we keep the notify
        DEBUG and 
            warn "$self->{alias}: still monitor $path";
        $notify->{call} = \@calls;
        if( @dec ) {
            # If we found a CB to remove, that means the mask might have changed
            $notify->{mask} = $self->_notify_mask( $notify );
            $self->add_inotify( $path, $notify->{mask} );
        }
    }
    else {
        # No external calls so we can drop this notify
        DEBUG and 
            warn "$self->{alias}: unmonitor $path";
        $notify->{watch}->cancel; 
        delete $notify->{watch};
        DEBUG2 and warn "$self->{alias}: REFCNT MINUS ", poe->session->ID, " (me) $path";
        poe->kernel->refcount_decrement( poe->session->ID, "NOTIFY $path" );
        delete $self->{path}{ $path };
        $self->_self_unmonitor( $path );
        push @dec, @calls;
        $finished = 1;
    }

    # Now clear the refcnt for the sender
    foreach my $call ( @dec ) {
        DEBUG2 and warn "$self->{alias}: REFCNT MINUS ", $call->{cb}[0], " ($call->{mode}) $path";
        poe->kernel->refcount_decrement( $call->{cb}[0], "NOTIFY $path" );
    }
    return $finished;
}

sub _call_match
{
    my( $self, $call, $args ) = @_;
    return 1 if $self->{force};
    return unless $call->{cb}[0] == $args->{session};
    my @E;
    
    # Which event do we want to unmonitor
    if( $args->{event} ) {          # event => 'event'
        @E = ( $args->{event} );
    }
    elsif( $args->{events} ) {
        my $r = ref $args->{events};
        if( 'ARRAY' eq ref $r ) {   # events => [ ... ]
            @E = @{ $args->{event} };
        }
        elsif( 'HASH' eq $r ) {     # events => { mask => 'event' }
            while( my( $mask, $event ) = each %{ $args->{event} } ) {
                next unless $call->{mask} & $mask;
                push @E, $event;
            }
            return 0 unless @E;     # no mask matched
        }
    }
    return 1 unless @E;             # all of them for this session?

    # only some of them
    foreach my $event ( @E ) {
        return 1 if $event eq '*';
        return 1 if $event eq $call->{cb}[1];
    }
        
    return;
}


sub _notify_mask
{
    my( $self, $notify ) = @_;
    my $mask = 0;
    foreach my $call ( @{ $notify->{call} } ) {
        confess pp $notify if 'ARRAY' eq ref $call;
        $mask |= $call->{mask};
    }
    return $mask;
}




#####################################################################
sub _pending
{
    my( $self, $path, $calls ) = @_;

    my $P = $self->_find_pending( $path );
    if( $P and $P->{monitored} ) {
        DEBUG and warn "$self->{alias}: pending $path more";
        push @{ $P->{call} }, @$calls if $calls;
        return 1;
    }

    my @todo = File::Spec->splitdir( $path );
    while( @todo > 1 ) {
        my $want = pop @todo;
        my $maybe = File::Spec->catdir( @todo );
        if( -e $maybe ) {
            if( $self->_pending_monitor( $path, $maybe, $want ) ) {
                DEBUG and warn "$self->{alias}: want $want in $maybe";
                my $P = $self->_find_pending( $path );
                $P->{monitored} = 1;
                push @{ $P->{call} }, @$calls if $calls;
                return;
            }
        }
    }
    return $self->_pending_monitor( $path, File::Spec->rootdir, @todo, $calls );
}

#############################################
sub _pending_remove
{
    my( $self, $path, $P, $args, $caller ) = @_;

    my( @calls, @dec );
    foreach my $call ( @{ $P->{call} } ) {
        next if $self->_call_match( $call, $args );
        push @calls, $call;
    }

    my $finished = 0;
    if( @calls ) {
        DEBUG and 
            warn "$self->{alias}: still pending $path ($P)";
        $P->{call} = \@calls;
    }
    else {
        # No external calls so we can drop this notify
        DEBUG and 
            warn "$self->{alias}: unpending $path ($P)";
        unless( $self->_pending_N( $path, $P->{exists} ) ) {
            $self->_pending_unmonitor( $path, $P->{exists} );
        }
           
        delete $self->{pending}{ $path };
        $finished = 1;
    }

    return $finished;
}

#############################################
sub _pending_monitor
{
    my( $self, $path, $exists, $want ) = @_;
    DEBUG and 
        warn "$self->{alias}: pending monitor $exists";

    $self->{pending}{ $path } ||= { call=>[] };
    $self->{pending}{ $path }{exists} = $exists;

    my $M = { path => $exists,
              mode => '_pending',
              events => {
                    (IN_DELETE_SELF|IN_MOVE_SELF) => 
                                    [ '__pending_deleted', $path, $exists ],
                    (IN_MOVED_TO|IN_CREATE|IN_CLOSE_WRITE) => 
                                    [ '__pending_created', $path, $exists, $want ]
                }
            };
    # this has to be a call bacause ->monitor calls poe->sender
    return poe->kernel->call( $self->{alias}, 'monitor', $M );
}


sub _pending_unmonitor
{
    my( $self, $path, $exists ) = @_;

    my $P = $self->_find_pending( $path );
    return unless $P and $P->{monitored};
    DEBUG and 
        warn "$self->{alias}: pending unmonitor $exists";
    poe->kernel->call( $self->{alias}, 'unmonitor', 
                            {   path=>$exists,  
                                events => [ qw( __pending_deleted __pending_created ) ]
                            } );
    $P->{monitored} = 0;
}

#############################################
sub _find_pending
{
    my( $self, $path ) = @_;
    return $self->{pending}{ $path };
}

sub _pending_N
{
    my( $self, $path, $exists ) = @_;
    foreach my $kpath ( keys %{ $self->{pending} } ) {
        next if $kpath eq $path;
        return 1 if $self->{pending}{ $kpath }{exists} eq $exists;
    }    
    return 0;
}

#############################################
sub __pending_deleted
{
    my( $self, $ch, $path, $exists ) = @_;

    my $P = $self->_find_pending( $path );
    return unless $P;

    DEBUG and 
        warn "$self->{alias}: pending deleted $exists";
    unless( $self->_pending_N( $path, $exists ) ) {
        $self->_pending_unmonitor( $path, $exists );
    }
    else {
        $P->{monitored} = 0;
    }
    $self->_pending( $path );
}

#############################################
sub __pending_created
{
    my( $self, $ch, $path, $exists, $want ) = @_;
    return unless $ch->name eq $want;

    my $P = $self->_find_pending( $path );
    return unless $P;

    DEBUG and warn "$self->{alias}: pending $path created ", $ch->name;
    unless( $self->_pending_N( $path, $exists ) ) {
        $self->_pending_unmonitor( $path, $exists );
    }
    else {
        $P->{monitored} = 0;
    }
    delete $self->{pending}{ $path };
    if( $self->_monitor_add( $path, 'cooked', $P->{call} ) ) {
        $self->_fake_created( $path );
    }
}





#####################################################################
sub _self_monitor
{
    my( $self, $path ) = @_;
    my $S = $self->_find_self( $path );
    if( $S and $S->{monitored} ) {
        DEBUG and warn "$self->{alias}: check $path more";
        return;
    }

    $S = $self->{self}{ $path } = {};

    my $M = {   path => $path,
                mask => (IN_MOVE_SELF|IN_DELETE_SELF),
                event => '__self_deleted',
                mode => '_self',
                args => [ $path ]
            };

    $S->{monitored} = poe->kernel->call( $self->{alias} => 'monitor', $M );
    return 1 if $S->{monitored};
    warn "$self->{alias}: Monitoring $path failed";
    delete $self->{self}{ $path };
    return;
}

#############################################
sub _self_remove
{
    my( $self, $path, $S, $args, $caller ) = @_;

    my( @calls, @dec );
    foreach my $call ( @{ $S->{call} } ) {
        next if $self->_call_match( $call, $args );
        push @calls, $call;
    }

    my $finished = 0;
    if( @calls ) {
        DEBUG and 
            warn "$self->{alias}: still self $path";
        $S->{call} = \@calls;
    }
    else {
        DEBUG and 
            warn "$self->{alias}: unself $path";
        $self->_self_unmonitor( $path );
        $finished = 1;
    }

    return $finished;
}

    
#############################################
sub _self_unmonitor
{
    my( $self, $path ) = @_;
    delete $self->{self}{ $path };
    # we are called from ->unmonitor which has already cleared {path}
    # and the Inotify2 object, so we don't have to do anything more

    # But if we do add an 'unmonitor' call here, then we must add a _self_N
    # to make sure we only unmonitor when no one is interested
}

#############################################
sub __self_deleted
{
    my( $self, $ch, $path ) = @_;
    DEBUG and warn "$self->{alias}: check $path deleted";

    return if $self->{shutdown};

    my $P = $self->_find_path( $path );

    local $self->{force} = 1;   # delete everything for this path.  It no longer exists!
    $self->unmonitor( { path=>$path } );

    my @keep;
    my $changed;
    foreach my $call ( @{ $P->{call} } ) {
        if( $call->{mode} eq 'cooked' ) {
            push @keep, $call;
        }
        else {
            $changed = 1;
        }
    }
    if( @keep ) {
        $self->_pending( $path, \@keep );
    }
}

#############################################
sub _find_self
{
    my( $self, $path ) = @_;
    return $self->{self}{ $path };
}


#####################################################################
sub _fake_created
{
    my( $self, $path ) = @_;
    my $notify = $self->_find_path( $path );
    return unless $notify;
    my $ch = bless { mask => IN_CREATE,
                     cookie => 0,
                     name => '',
                     w => $notify->{watch}
                   }, 'Linux::Inotify2::Event';
    poe->kernel->post( $self->{alias}, 'inotify', [ $path ], [ $ch ] );
}

1;


__END__

=head1 NAME

POEx::Inotify - inotify interface for POE

=head1 SYNOPSIS

    use strict;

    use POE;
    use POEx::Inotify;

    POEx::Inotify->new( alias=>'notify' );

    POE::Session->create(
        package_states => [ 
                'main' => [ qw(_start notification) ],
        ],
    );

    $poe_kernel->run();
    exit 0;

    sub _start {
        my( $kernel, $heap ) = @_[ KERNEL, HEAP ];

        $kernel->post( 'notify' => monitor => {
                path => '.',
                mask  => IN_CLOSE_WRITE,
                event => 'notification',
                args => [ $args ]
             } );
        return;  
    }

    sub notification {
        my( $kernel, $e, $args ) = @_[ KERNEL, ARG0, ARG1];
        print "File ready: ", $e->fullname, "\n";
        $kernel->post( notify => 'shutdown' );
        return;
    }

=head1 DESCRIPTION

POEx::Inotify is a simple interface to the Linux file and directory change
notification interface, also called C<inotify>.

It can monitor an existing directory for new files, deleted files, new
directories and more.  It can monitor an existing file to see if it changes,
is deleted or moved.

=head1 METHODS

=head2 spawn

    POEx::Inotify->spawn( %options );

Creates the C<POEx::Inotify> session.  It takes a number of arguments, all
of which are optional.

=over 4

=item alias

The session alias to register with the kernel.  Defaults to C<inotify>.

=item options

A hashref of POE::Session options that are passed to the component's 
session creator.

=back




=head1 EVENTS

=head2 monitor

    $poe_kernel->call( inotify => 'monitor', $arg );

Starts monitoring the specified path for the specified types of changes.

Accepts one argument, a hashref containing the following keys: 

=over 4

=item path

The filesystem path to the directory to be monitored.  Mandatory.

=item mask

A mask of events that you wish to monitor.  May be any of the following constants
(exported by L<Linux::Inotify2>) ORed together.  Defaults to C<IN_ALL_EVENTS>.

=back

=over 8

=item IN_ACCESS

object was accessed

=item IN_MODIFY

object was modified

=item IN_ATTRIB

object metadata changed

=item IN_CLOSE_WRITE

writable fd to file / to object was closed

=item IN_CLOSE_NOWRITE

readonly fd to file / to object closed

=item IN_OPEN

object was opened

=item IN_MOVED_FROM

file was moved from this object (directory)

=item IN_MOVED_TO

file was moved to this object (directory)

=item IN_CREATE

file was created in this object (directory always, file in cooked mode)

=item IN_DELETE

file was deleted from this object (directory)

=item IN_DELETE_SELF

object itself was deleted

=item IN_MOVE_SELF

object itself was moved

=item IN_ALL_EVENTS

all of the above events


=item IN_ONESHOT

only send event once

=item IN_ONLYDIR

only watch the path if it is a directory

=item IN_DONT_FOLLOW

don't follow a sym link

=item IN_MASK_ADD

not supported with the current version of this module

=item IN_CLOSE

same as IN_CLOSE_WRITE | IN_CLOSE_NOWRITE

=item IN_MOVE

same as IN_MOVED_FROM | IN_MOVED_TO

=back


=over 4

=item event

The name of the event handler in the current session to post changes back
to.  Mandatory.

The event handler will receive an L<Linux::Inotify2::Event> as its first argument.  Other
arguments are those specified by L</args>.

=item args

An arrayref of arguments that will be passed to the event handler.

=item events

A hashref of mask=>event tupples.  You may use C<events> to register
multiple callbacks at once. The keys are masks, the values are either a
scalar (event in current session), arrayref (first element is an event, next
elements are arguments) or hashref (with the keys C<event> and C<args>.

And remember, C<=E<gt>> will turn a bare word into a string.  So use C<,> or
C<()> to force the use of a constant.

    { IN_CLOSE_WRITE => 'file_changed' }    # WRONG!
    { IN_CLOSE_WRITE, 'file_changed' }      # OK
    { IN_CLOSE_WRITE() => 'file_changed' }  # OK


=item mode

One of 2 strings: C<raw> or C<cooked>.  Raw mode requires that the monitored
path exist prior to calling L</monitor>; if the path doesn't exist, an
exception is thrown.

Cooked mode, however, will wait for the path to be created and then start
monitoring it.  It does this by checking the parent directories and
monitoring the deepest one that exists.  And if the path is deleted then
parent directories are monitored until the path is created again.

Finaly, in cooked mode, C<IN_CREATE> events are generated for the path. 
These are normaly never generated for files.  For directories, which normaly
generate C<IN_CREATE> when a file is created, you may check C<name>; it will
be C<''> for the directory creation event.

The default is C<cooked>.

=back



=head3 Example

    use Linux::Inotify2;

    my $dir = '/var/ftp/incoming';

    # Monitor a single event
    my $M = {
            path => $dir,
            mask => IN_DELETE|IN_CLOSE,
            event => 'uploaded',
            args  => [ $dir ]
        };
    $poe_kernel->call( inotify => 'monitor', $M );

    sub uploaded 
    {
        my( $e, $dir ) = @_[ARG0, ARG1];
        warn $e->fullname, " was uploaded to $dir";
        .....
    }

    # monitor multiple events
    $M = {
            path => $path
            events => {
                    (IN_MOVE_TO|IN_CLOSE_WRITE) => 'file_created',
                    (IN_MOVE_FROM|IN_DELETE) => { event => 'file_deleted',
                                                    args  => [ $one, $two ] },
                    IN_CLOSE_NOWRITE, [ 'file_accessed', $path ]
                }
        };
    $poe_kernel->call( inotify => 'monitor', $M );

    sub file_created
    {
        my( $e ) = $_[ARG0];
        .....
    }

    sub file_deleted
    {
        my( $e, $one, $two ) = $_[ARG0, ARG1, ARG2];
        .....
    }

    sub file_accessed
    {
        my( $e, $path ) = $_[ARG0, ARG1];
        .....
    }


=head2 unmonitor


    $poe_kernel->call( inotify => 'unmonitor', $arg );

Ends monitoring of the specified path for the current session.

Accepts one argument, a hashref containing the following keys: 

=over 4

=item path

The filesystem path to the directory to to stop monitoring.  Mandatory.

=item event

Name of the monitor event that was used in the original L</monitor> call.
You may use C<*> to unmonitor all events for the current session.

=item events

Use this to unregister multiple events at once.  This argument may be an
arrayref of event names, or a hashref of mask=>event name tupples.

    events => \@names,
    events => { IN_CLOSE_WRITE() => 'event' }

Note that the mask doesn't have to be an exact match to remove an event. For
example, if you monitored C<IN_CLOSE>, which is
C<IN_CLOSE_WRITEE<verbar>IN_CLOSE_NOWRITE>, but only use C<IN_CLOSE_NOWRITE>
in your unmonitor call, it will still match and unmonitor C<IN_CLOSE>.

=back

=head3 Note

Multiple sessions may monitor the same path at the same time.  A single
session may monitor multiple paths.  However, if a single session is
monitoring the same path multiple times it must use different events
to distinguish them.


=head2 shutdown

    $poe_kernel->call( inotify => 'shutdown' );
    # OR
    $poe_kernel->signal( $poe_kernel => 'shutdown' );
 
Shuts down the component gracefully. All monitored paths will be closed. Has
no arguments.

=head1 BUGS

=over 4

=item The fake C<IN_CREATE> events for cooked mode should be called C<IN_CREATE_SELF>.

=back

=head1 TODO

=over 4

=item Add a C<recursive> mode.  It would create monitors for all
subdirectories of a path.

=back


=head1 SEE ALSO

L<Inotify|http://inotify.aiken.cz/>, L<POE>, L<Linux::Inotify2>.

This module's API was heavily inspired by
L<POE::Component::Win32::ChangeNotify>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
