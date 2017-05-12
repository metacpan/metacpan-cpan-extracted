package POE::Sugar::Attributes::SymInfo;
use strict;
use warnings;
use Class::Struct;
use Attribute::Handlers;

struct (__PACKAGE__,
    [
        'flags'     => '$',
        'coderef'   => '$',
        '_name'      => '$',
        'package'   => '$',
        'events'    => '@',
        'data'      => '*@'
    ]);

sub name {
    my ($self,$pkg) = @_;
    if($self->_name) {
        return $self->_name;
    }
    
    $pkg ||= $self->package;
    my $glob = Attribute::Handlers::findsym($pkg, $self->coderef);
    if(!$glob) {
        warn("Can't find symbol for " . $self->coderef);
        return;
    }
    my $symname = *$glob{NAME};
    $self->_name($symname);
    return $symname;
}

package POE::Sugar::Attributes::PkgInfo;
use strict;
use warnings;
use Class::Struct;

struct (__PACKAGE__,
    [
        'ctor' => '$',
        'dtor' => '$',
        'events' => '%',
        'catcher' => '$',
        'reaper' => '$',
        'sigs' => '%',
        'syms' => '%'
    ]);


package POE::Sugar::Attributes;
use strict;
use warnings;

use POE;
use POE::Session;

our $VERSION = 0.02;

use base qw(Exporter);
use Log::Fu { level => "info" };
use Data::Dumper;
our @EXPORT_OK;
BEGIN {
@EXPORT_OK = qw(
    wire_new_session
    wire_current_session
);
}

use Attribute::Handlers;

use Constant::Generate [qw(
    PA_EVENT
    PA_CTOR
    PA_DTOR
    PA_TIMER
    PA_CATCHER
    PA_REAPER
    PA_SIGHANDLER
    
    PA_NAME_RESOLVE
)], -type => 'bitfield',
    -start_at => 1;

use Constant::Generate [qw(
    FLD_FLAGS
    FLD_DATA
    FLD_CODE
)];

my %map_names;
my %pkgcache;
my %const2hkey;

my ($HKEY_CATCHER,
    $HKEY_REAPER,
    $HKEY_SIGHANDLERS
);

%map_names = (
    Start    => PA_CTOR,
    Stop     => PA_DTOR,
    Event    => PA_EVENT,
    State    => PA_EVENT,
    Recurring=> PA_TIMER,
    Catcher => PA_CATCHER,
    Reaper  => PA_REAPER,
    SigHandler=> PA_SIGHANDLER,
);

#Ensure we don't actually collide with a real symbol
$HKEY_CATCHER = __PACKAGE__ . "__HKEY_CATCHER__";
$HKEY_REAPER = __PACKAGE__ . "__HKEY_REAPER__";
$HKEY_SIGHANDLERS = __PACKAGE__ . "__HKEY_SIGHANDLERS__";

%const2hkey = (
    PA_CATCHER, $HKEY_CATCHER,
    PA_REAPER, $HKEY_REAPER
);



sub _get_infos {
    my ($pkg,$cv) = @_;
    my $pkginfo = ($pkgcache{$pkg} ||=
        POE::Sugar::Attributes::PkgInfo->new());
    my $syminfo = ($pkginfo->syms->{$cv+0} ||=
        POE::Sugar::Attributes::SymInfo->new(
            package => $pkg,
            coderef => $cv)
        );
    
    return ($pkginfo,$syminfo);
}

sub _poe_attr_handler :ATTR(CODE) {
    my ($pkg,undef,$cv,$attr,$data) = @_;
    
    my @opt_array;
    my %opt_hash;
    
    if(ref $data) {
        if(@$data % 2 == 0) {
            %opt_hash = @$data;
        }
        @opt_array = @$data;
    }
    
    my $flag = $map_names{$attr};
    die "No such attribute: $attr" unless defined $flag;
    
    my ($pkg_info,$sym_info) = _get_infos($pkg, $cv);
    
    $sym_info->flags( ($sym_info->flags || 0) | $flag );
    
    if($flag == PA_EVENT)
    {
        if(@opt_array) {
            push @{$sym_info->events}, @opt_array;
        } else {
            push @{$sym_info->events}, \undef;
        }
    }
    
    elsif ($flag == PA_TIMER)
    {
        my $interval = delete $opt_hash{Interval};
        die("Timer must have interval ()") unless $interval;
        my $evname = $opt_hash{Name};
        $evname ||= \undef;
        $sym_info->data->[PA_TIMER] = [ $evname, $interval ];
    }
    
    elsif ($flag == PA_CTOR || $flag == PA_DTOR)
    {
        if($flag == PA_CTOR) {
            $pkg_info->ctor($sym_info);
        }
        elsif($flag == PA_DTOR) {
           $pkg_info->dtor($sym_info); 
        }
        #Do we have anything to do here?
    }
    
    
    elsif ($flag == PA_CATCHER) {
        $pkg_info->catcher($sym_info);
    }
    
    elsif ($flag == PA_REAPER) {
        $pkg_info->reaper($sym_info);
    }
    
    elsif ($flag == PA_SIGHANDLER) {
        if(!ref $data) {
            push @opt_array, $data;
        }
        foreach my $signame (@opt_array) {
            log_debug("Found signal $signame");
            $pkg_info->sigs->{$signame} = $sym_info;
        }
    }    
}

sub Start    :ATTR(CODE) { goto &_poe_attr_handler }
sub Stop     :ATTR(CODE) { goto &_poe_attr_handler }
sub Event    :ATTR(CODE) { goto &_poe_attr_handler }
sub State    :ATTR(CODE) { goto &_poe_attr_handler }
sub Recurring:ATTR(CODE) { goto &_poe_attr_handler }
sub Catcher  :ATTR(CODE) { goto &_poe_attr_handler }
sub Reaper   :ATTR(CODE) { goto &_poe_attr_handler }
sub SigHandler:ATTR(CODE){ goto &_poe_attr_handler }

sub _get_params {
    my $pkg = shift;
    my $pkg_info = $pkgcache{$pkg};
    die("Don't have anything registered for $pkg")
        unless defined $pkg_info;
        
    my ($ctor,$dtor,$catcher,$reaper);
    my @events;
    my @timers;
    
    foreach my $sym_info (values %{$pkg_info->syms}) {
        
        my $symname = $sym_info->name();
        $symname = $pkg ."::$symname";
        
        if($sym_info->flags & PA_EVENT) {
            foreach my $evname (@{$sym_info->events}) {
                if(ref $evname) {
                    log_debug("Event is the symbol name itself.. converting");
                    $evname = $sym_info->name();
                }
                push @events, [$evname, $symname ];
            }
        }
        
        if($sym_info->flags & PA_TIMER) {
            my ($evname,$interval) = @{$sym_info->data->[PA_TIMER] };
            if(ref $evname) {
                log_debug("Timer event name is the symbol itsef.. converting");
                $evname = $sym_info->name();
            }
            push @timers, [ $evname, $symname, $interval ];
        }
        
        if($sym_info->flags & PA_CTOR) {
            $ctor = $symname;
        }
        if($sym_info->flags & PA_DTOR) {
            $dtor = $symname;
        }
    }
    
    my $params = {
        Events => \@events,
        Timers => \@timers,
        Ctor    => $ctor,
        Dtor    => $dtor
    };

    
    foreach (
        ['reaper', 'Reaper'],
        ['catcher', 'Catcher']
    ) {
        my ($meth,$key) = @$_;
        if(my $handler = $pkg_info->can($meth)->($pkg_info)) {
            my $symname = $handler->name;
            push @events, [ $symname, $pkg . "::$symname" ];
            $params->{$key} = $symname;
        }
    }
    
    while (my ($signame,$sighandler) = each %{$pkg_info->sigs} ) {
        my $symname = $sighandler->name();
        push @events, [ $symname, $pkg ."::$symname" ] ;
        $params->{Signals}->{$signame} = $symname;
    }
    
    return $params;
}

sub _setup_events {
    my ($events,$poe_kernel) = @_;
    foreach (@$events) {
        my ($evname,$subname) = @$_;
        log_debug("$evname:$subname");
        $poe_kernel->state($evname, sub { goto &{$subname} } );
    }
}

sub _setup_timers {
    my ($timers,$poe_kernel) = @_;
    foreach (@$timers) {
        my ($evname, $symname, $interval) = @$_;
        my $wrap = sub {
            $poe_kernel->delay($evname, $interval);
            goto &{$symname};
        };
        $poe_kernel->state($evname, $wrap);
        $poe_kernel->delay($evname, $interval);
    }
}

sub _setup_signals {
    my ($signals, $poe_kernel) = @_;
    return unless $signals;
    while (my ($signame,$evname) = each %$signals) {
        log_debugf("$signame => $evname");
        $poe_kernel->sig($signame, $evname);
    }
}

sub inline_states {
    my ($cls,$pkg,$alias) = @_;
    $pkg ||= caller();
    my $params = _get_params($pkg);
    my $sess_hash =  {
        _start => sub {
            if($alias) {
                $_[KERNEL]->alias_set($alias);
            }
            _setup_timers($params->{Timers}, $_[KERNEL]);
            _setup_events($params->{Events}, $_[KERNEL]);
            
            if($params->{Catcher}) {
                log_debug("Setting DIE handler: ", $params->{Catcher});
                $_[KERNEL]->sig(DIE => $params->{Catcher});
            }
            
            if(my $reaper = $params->{Reaper}) {
                log_debugf("Setting CHLD handler: %s", $reaper);
                $_[KERNEL]->sig(CHLD => $reaper);
            }
            
            if($params->{Signals}) {
                _setup_signals($params->{Signals}, $_[KERNEL]);
            }
            
            if($params->{Ctor}) {
                goto &{ $params->{Ctor} };
            }
        },
        _stop => sub {
            if($params->{Dtor}) {
                goto &{ $params->{Dtor} };
            }
        }
    };
    
    return $sess_hash;
}

#This is for other modules which inject themselves, in-situ, into a session
sub wire_current_session {
    my ($cls,$poe_kernel,$pkg) = @_;
    $pkg ||= caller();
    my $params = _get_params($pkg);
    _setup_timers($params->{Timers}, $poe_kernel);
    _setup_events($params->{Events}, $poe_kernel);
    _setup_signals($params->{Signals}, $poe_kernel);
}


sub wire_new_session {
    my $alias = shift;
    if( $alias && $alias eq __PACKAGE__) {
        $alias = shift;
    }
    
    my $pkg = shift;
    $pkg ||= caller();
    
    POE::Session->create(
        inline_states => __PACKAGE__->inline_states($pkg, $alias)
    );
}

1;

__END__

=head1 NAME

POE::Sugar::Attributes - Subrouting Attributes for common POE tasks

=head1 SYNOPSIS

The following is mainly copy/pasted from demo.pl in the distribution

    use POE::Sugar::Attributes qw(wire_current_session wire_new_session);
    use base qw(POE::Sugar::Attributes);
    use POE;
    use POE::Session;
    use POE::Kernel;
    use Log::Fu;
    
    sub say_alias : Event
    {
        my ($alias_name,$do_stop) = @_[ARG0,ARG1];
        log_infof("I was passed %s", $alias_name);
        if(!$do_stop) {
            $_[KERNEL]->post($alias_name, say_alias => $alias_name, 1);
        }
    }
    
    sub my_event :Event(foo_event, bar_event)
    {
        log_warnf("I'm called as %s.", $_[STATE]);
    }
    
    sub tick :Recurring(Interval => 2)
    {
        log_info("Tick");
    }
    
    sub tock :Recurring(Interval => 1)
    {
        log_info("Tock");
    }
    
    sub hello :Start
    {
        log_info("Beginning");
        $_[KERNEL]->post($_[SESSION], $_, "Hi")
            for (qw(foo_event bar_event));
        $_[KERNEL]->yield(say_alias => "session alias", 0);
    }
    
    sub byebye :Stop
    {
        log_warnf("We're stopping");
    }
    
    POE::Session->create(inline_states => POE::Sugar::Attributes->inline_states);
    POE::Kernel->run();
    
=head2 ATTRIBUTES


=head3 Event, Event(list,of,names)

Specify that this subroutine will act as an event. In the first form, the name
of the subroutine itself is the event name. In the second form, the function
will be the target of all the listed events (but I<not> the function name itself,
unless it is also included in the list).

C<:Event> may be specified multiple times

=head3 Recurring(Interval => $seconds, [Name => 'event_name;])

Specify that this is a recurring timer. It will be called every C<Interval> until
the session terminates, or the timer is manually removed (using the
L<POE::Kernel>::C<delay>) method.

A new event will be added which will default to the subroutine name. If you wish
to use different name, add the C<Name> key with the preferred event name as the
value.

Internally, the function is wrapped around with code which looks like this:

    $poe_kernel->delay($evname, $interval);
    goto &{$symname};

If during execution there is need to remove the event, you can do something like

    sub nag :Recurring(Interval => 3600) {
        if($dont_nag) {
            $_[KERNEL]->delay($_[STATE], undef);
        } else {
            #....
        }
    }
    


=head3 SigHandler(SIGNAL,LIST)

This function will act as a signal handler for those signals specified in the
signal list. Each signal in the list is a signal name recognized by POE. See
L<POE::Kernel> for more information on the signals and the arguments they
take

=head3 Catcher

This is an exception handler. This will do the equivalent of

    $poe_kernel->state(subname => \&subname)
    $poe_kernel->sig(DIE => subname)
    
Doing C<:SigHandler(DIE)> will produce a similar effect

=head3 Reaper

This is a handler for C<SIGCHLD>

=head3 Start

Indicate that this function will be invoked as L<POE::Session>'s C<_start> event.

=head3 Stop

Indicate that this function will be invoked as L<POE::Session>'s C<_stop> event.

=head2 WIRING

In order to have your attributed subroutines behave as expected, it is needed
to call one of the wiring functions, so that C<POE> will know about the new events
that you have created.

There are two functions, exported on request, or accessible via their C<POE::Attribues>
namespace

=head3 POE::Sugar::Attributes->wire_current_session(kernel, [pkgname])

Call this during a I<running> session to add new events. C<_start> and C<_stop>
handlers will not be wired, but all others will.

C<pkgname> is the name of the package in which the attributed subroutines were
defined. If this is not specified, it is assumed to be the calling package

=head3 POE::Sugar::Attributes->wire_new_session(alias, [pkgname])

Call this to initialize a new session. C<alias> is the desired alias for your
session, or C<undef> to disable an alias.

C<pkgname> has the semantics as in C<wire_current_session>

=head3 POE::Sugar::Attributes->inline_states(pkgname, [alias])

This returns a hash reference, which can be used as so:

    POE::Session->create(
        inline_states => POE::Sugar::Attributes->inline_states()
    );
    
The C<pkgname> and C<alias> parameters have the same semantics as in the previous
functions.


=head2 RATIONALE

POE itself is quite light in terms of the syntactic sugar it provides. There are
some nice wrappers, such as L<MooseX::POE> and L<POE::Declare>, but they provide
a heavier layer of abstraction.

This module was intended so that one can keep the same calling and argument conventions
of POE itself, while trying to avoid boilerplate for common tasks.

Another possibility with this module, that really does not exist with alternatives,
is the ease of maintaining 'mixins'. Mixins are modules which reside outside of
the main session, but are logically part of it - and do not need the management
overhead of creating a new session.

=head1 SEE ALSO

There are quite a few modules out there which have intended to something similar
but are either incomplete, too basic, or require much more baggage

L<POE::Session::Attribute>

L<POE::Session::AttributeBased>


=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2011 by M. Nunberg

You may use and distribute this module under the same terms and conditions as perl
itself.
