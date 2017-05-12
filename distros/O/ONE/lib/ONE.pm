# ABSTRACT: A Node.js style AnyEvent class, using MooseX::Event
package ONE;
{
  $ONE::VERSION = 'v0.2.0';
}
use AnyEvent;
use ONE::Collect;
use MooseX::Event;

with 'MooseX::Event::Role::ClassMethods';


sub collect (&) {
    my $collect = ONE::Collect->new();
    my $wrapper = MooseX::Event->add_listener_wrapper( sub {
        my( $todo ) = @_;
        $collect->listener( $todo );
    } );
    $_[0]->();
    MooseX::Event->remove_listener_wrapper( $wrapper );
    $collect->complete;
}

has '_loop_cv' => (is=>'rw', init_arg=>undef);
has '_idle_cv' => (is=>'rw', init_arg=>undef );
has '_signal'  => (is=>'rw', default=>sub{{}}, init_arg=>undef);



has_events qw(
    idle 
    SIGHUP   SIGINT  SIGQUIT SIGILL  SIGTRAP SIGABRT SIGBUS    SIGFPE    SIGKILL
    SIGUSR1  SIGSEGV SIGUSR2 SIGPIPE SIGALRM SIGTERM SIGSTKFLT SIGCHLD   SIGCONT
    SIGSTOP  SIGTSTP SIGTTIN SIGTTOU SIGURG  SIGXCPU SIGXFSZ   SIGVTALRM SIGPROF
    SIGWINCH SIGIO   SIGPWR  SIGSYS );




# We would just use MooseX::Singleton, but it's nice to maintain compatibility with Mouse
BEGIN {
    my $instance;
    sub instance {
        my $class = shift;
        return $instance ||= $class->new(@_);
    }
}



sub activate_event {
    my $self = shift;
    my( $event ) = @_;
    if ( $event eq 'idle' ) {
        $self->_idle_cv( AE::idle( sub { $self->emit('idle'); } ) );
    }
    elsif ( $event =~ /^SIG([\w\d]+)$/ ) {
        my $sig  = $1;
        $self->_signal->{$sig} = AE::signal $sig, sub { $self->emit("SIG$sig") };
    }
}


sub deactivate_event {
    my $self = shift;
    my( $event ) = @_;
    if ( $event eq 'idle' ) {
        $self->_idle_cv( undef );
    }
    elsif ( $event =~ /^SIG([\w\d]+)$/ ) {
        delete $self->_signal->{$1};
    } 
}


sub loop {
    my $cors = shift;
    my $self = ref $cors ? $cors : $cors->instance;
    if ( defined $self->_loop_cv ) {
        $self->_loop_cv->send();
    }
    my $cv = AE::cv;
    $self->_loop_cv( $cv );
    $cv->recv();
}


sub stop {
    my $cors = shift;
    my $self = ref $cors ? $cors : $cors->instance;
    return unless defined $self->_loop_cv;
    $self->_loop_cv->send();
    delete $self->{'_loop_cv'};
}

sub import {
    my $class = shift;
    my $caller = caller;
    
    for (@_) {
        my($module,$args) = split /=/;
        my @args = split /[:]/, $args || "";

        local $@;
        eval "require ONE::$module;"; 
        if ( $@ ) {
            require Carp;
            Carp::croak( $@ );
        }
        eval "package $caller; ONE::$module->import(\@args);" if @args or !/=/;
        if ( $@ ) {
            require Carp;
            Carp::croak( $@ );
        }
    }
    
    no strict 'refs';
    *{$caller.'::collect'} = $class->can('collect');
}


sub unimport {
    my $caller = caller;
    no strict 'refs';
    delete ${$caller.'::'}{'collect'};
}

__PACKAGE__->meta->make_immutable();
no MooseX::Event;

1;


__END__
=pod

=head1 NAME

ONE - A Node.js style AnyEvent class, using MooseX::Event

=head1 VERSION

version v0.2.0

=head1 SYNOPSIS

# General event loop:

    use ONE;
    
    ONE->start;

# Collation:

    use ONE;
    use ONE::Timer;
    
    collect {
         ONE::Timer->after( 2 => sub { say "two" } );
         ONE::Timer->after( 3 => sub { say "three" } );
    }; # After three seconds will have printed "two" and "three"

=head1 DESCRIPTION

=head1 EVENTS

=head2 idle

This is an AnyEvent idle watcher.  It will repeatedly invoke the listener
whenever the process is idle.  Several thousand times per second on a
moderately loaded system.  Attaching a once listener to this will let you
defer code until any active events have finished processing. 

=head2 SIG*

You can register event listeners for any of the following events:

    SIGHUP   SIGINT  SIGQUIT SIGILL  SIGTRAP SIGABRT SIGBUS    SIGFPE    SIGKILL
    SIGUSR1  SIGSEGV SIGUSR2 SIGPIPE SIGALRM SIGTERM SIGSTKFLT SIGCHLD   SIGCONT
    SIGSTOP  SIGTSTP SIGTTIN SIGTTOU SIGURG  SIGXCPU SIGXFSZ   SIGVTALRM SIGPROF
    SIGWINCH SIGIO   SIGPWR  SIGSYS

Some of these may not actually be catchable (ie, SIGKILL), this is just the
list from "kill -l" on a modern Linux system.  Using one of these installs
any AnyEvent signal watcher.  As with AnyEvent, this will work

=head1 CLASS METHODS

=head2 our method instance() returns ONE

Return the singleton object for this class

=head2 our method loop()

Starts the main event loop.  This will return when the stop method is
called.  If you call start with an already active loop, the previous loop
will be stopped and a new one started.

=head2 our method stop() 

Exits the main event loop.

=head1 HELPERS

=head2 collect { ... }

Will return after all of the events declared inside the collect block have
been emitted at least once.

=begin internal




=end internal

=head1 our method activate_event( $event )

This method is called by MooseX::Event when the first event listener for a
particular event is registered.  We use this to start the AE::idle or
AE::signal event listeners.  We wouldn't want them running when the user has
no active listeners.

=begin internal




=end internal

=head1 our method deactivate_event( $event )

This method is called by MooseX::Event when the last event listener for a
particular event is removed.  We use this to shutdown the AE::idle or
AE::signal event listeners when the last acitve listener is removed.

=begin internal




=end internal

=head1 our method unimport()

Removes the collect helper method

=for test_synopsis use v5.10.0;

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

