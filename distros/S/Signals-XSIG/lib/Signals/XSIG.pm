package Signals::XSIG;

## no critic (RequireLocalizedPunctuationVars, ProhibitAutomaticExport)

use Signals::XSIG::Default;
use Carp;
use Config;
use Exporter;
use Symbol;
use warnings;
use strict;
require Signals::XSIG::Meta;

our @ISA = qw(Exporter);
our @EXPORT = qw(%XSIG);
our @EXPORT_OK = qw(%DEFAULT_BEHAVIOR);

our %DEFAULT_BEHAVIOR;
*DEFAULT_BEHAVIOR = \%Signals::XSIG::Default::DEFAULT_BEHAVIOR;

our $VERSION = '1.00';
our (%XSIG);
our (%OSIG, %ZSIG, %SIGTABLE, %alias, $_REFRESH);
my (%OOSIG, %YSIG, $_DISABLE_WARNINGS);
our $_INITIALIZED = 0;

# singleton tied hash classes
our $SIGTIE = bless {}, 'Signals::XSIG::TieSIG';
our $XSIGTIE = bless {}, 'Signals::XSIG::TieXSIG';

###
# to be removed when we get a handle on intermittent t/02 failures
our ($XDEBUG,$XN,@XLOG) = ($ENV{XSIGDEBUG},1001);
sub XLOG{
    no warnings "uninitialized";
    push @XLOG,($XN++)." @_";
    XLOG_DUMP() if $XDEBUG>1
}
sub XLOG_DUMP{my $r=join("\n",@XLOG);@XLOG=();Test::More::diag($r)}
###


BEGIN {
    # how to detect global destruction. Idea from Devel::GlobalDestruction 0.13
    if (defined ${^GLOBAL_PHASE}) {
        eval 'sub __inGD() {${^GLOBAL_PHASE} eq "DESTRUCT" && __END()}; 1';
    } else {
        require B;
        eval 'sub __inGD() { ${B::main_cv()}==0 && __END();}; 1';
    }
}

sub import {
    Signals::XSIG->export_to_level(1, @_);
    _init();
}

sub unimport {
    untie %main::SIG;
}

sub _init {
    return if $_INITIALIZED;
    $_REFRESH = 0;
    if ($ENV{XSIG_56} || $Config{PERL_VERSION} <= 6) {
        print STDERR "Using  Signals::XSIG::Meta56  to manage multi-handlers\n";
	require Signals::XSIG::Meta56;
    }

    my @z = ();
    my @num = split ' ', $Config{sig_num};
    my @name = split ' ', $Config{sig_name};
    for (my $i=0; $i<@name; $i++) {
	my $signo = $num[$i];
	my $signame = $name[$i];
	$SIGTABLE{$signo} ||= $signame;
	$SIGTABLE{'SIG' . $signame} = $SIGTABLE{$signame} = $SIGTABLE{$signo};
	if (defined $z[$signo]) {
	    $alias{$signame} = $z[$signo];
	    $alias{$z[$signo]} = $signame;
	    $alias{"pk:$z[$signo]"} = 1;
            $alias{"sub:$signame"} = 1;
	}
	$z[$signo] = $signame;
    }
    $SIGTABLE{'__WARN__'} = '__WARN__';
    $SIGTABLE{'__DIE__'} = '__DIE__';

    *OSIG = \%main::SIG;
    %OOSIG = %OSIG;

    foreach my $sig ('__WARN__', '__DIE__', @name) {
	next if $SIGTABLE{$sig} ne $sig;
	$ZSIG{$sig} = Signals::XSIG->_new($sig, $OSIG{$sig});
    }
    *main::SIG = \%YSIG;
    tie %SIG, 'Signals::XSIG::TieSIG';
    tie %XSIG, 'Signals::XSIG::TieXSIG';
    $_REFRESH = 1;
    $_->_refresh foreach values %ZSIG;
    return ++$_INITIALIZED;
}

END { &__END; }

sub __END {
    no warnings 'redefine';
    *__inGD = sub () { 1 };
}

sub Signals::XSIG::_sigaction {  # function, not method
    my ($signal, @args) = @_;
    foreach my $handler (@{$ZSIG{$signal}->{xh}}) {
	# print STDERR "_sigaction($signal) => $handler\n";
	if ($handler eq 'DEFAULT') {
	    Signals::XSIG::Default::perform_default_behavior(
		$signal, @args);
	} elsif ($signal ne '__WARN__' && $signal ne '__DIE__') {
            no strict 'refs';
	    $handler->($signal, @args);
	} else {
            no warnings 'uninitialized';
            no strict 'refs';
            print STDERR "Calling $signal signal handler $handler \@args=@args\n";
	    $handler->($signal, @args);
	}
    }
}


# convert a signal name to its canonical name. If not disabled,
# warn if the input is not a valid signal name.
#      TERM => TERM
#      CLD  => CHLD
#      OOK  => warning
sub _resolve_signal {
    my ($sig, $DISABLE_WARNINGS) = @_;
    $DISABLE_WARNINGS ||= $_DISABLE_WARNINGS;
    $sig = $SIGTABLE{uc $sig};
    if (defined $sig) {
	$_[0] = $sig;  ## no critic (Unpacking)
	return 1;
    }
    return 1 if !$_INITIALIZED;

    # signal could not be resolved -- issue warning and return false
    unless ($DISABLE_WARNINGS) {
	if (defined($sig) && $sig =~ /\d/ && $sig !~ /\D/) {
	    carp "Invalid signal number $sig.\n";
	} elsif (warnings::enabled('signal')) {
	    Carp::cluck "Invalid signal name $sig.\n";
	}
    }
    return;
}


# in %SIG and %XSIG assignments, string values are qualified to the
# 'main' package, unqualified *glob values are qualified to the
# calling package.
sub _qualify_handler {
    my $handler = shift(@_);

    if (!defined($handler)
	|| $handler eq ''
	|| $handler eq 'IGNORE'
	|| $handler eq 'DEFAULT') {
	return $handler;
    }

    if (substr($handler,0,1) eq '*') {
	my $n = 0;
	my $package = caller;
	while (defined($package) && $package =~ /^Signals::XSIG/) {
	    $package = caller(++$n);
	}
	$handler = Symbol::qualify($handler, $package || 'main');
    } else {
	$handler = Symbol::qualify($handler, 'main');
    }
    return $handler;
}

#####################################################
#
# Signals::XSIG::TieSIG
#
# Only for tie-ing %SIG.
# Associates $SIG{key} with $XSIG{$sig}[0]
#

sub Signals::XSIG::TieSIG::TIEHASH {
    $XDEBUG && XLOG("TieSIG::TIE caller=",caller);
    return $SIGTIE;
}

# called when we say  $x = $SIG{signal}
sub Signals::XSIG::TieSIG::FETCH {
    my ($self,$key) = @_;

    # track function calls to diagnose test failures
    $XDEBUG && $key ne '__DIE__'
            && XLOG("FETCH key=$key caller=",caller);
    if (_resolve_signal($key)) {
	my $old = $ZSIG{$key}->_fetch(0);
        $XDEBUG && $key ne '__DIE__' && XLOG("    result(1)=",$old);
	return $old;
    } else {
	no warnings 'uninitialized';
	my $r = $OSIG{$key};
        $XDEBUG && $key ne '__DIE__' && XLOG("    result(2)=$r");
	return $r;
    }
}

# called when we say  $SIG{signal} = handler
sub Signals::XSIG::TieSIG::STORE {
    my ($self,$key,$value) = @_;
    no warnings 'uninitialized';
    $XDEBUG && $key ne '__DIE__'
        && XLOG("STORE($key,$value) caller=",caller);
    if (_resolve_signal($key)) {
	return $ZSIG{$key}->_store(0, $value);
    } else {
	my $old;
        $XDEBUG && XLOG("    key $key not resolved");
	no warnings 'signal';          ## no critic (NoWarnings)
	$old = $OSIG{$key};
	$OSIG{$key} = $value;
	return $old;
    }
}

# called when we say   delete $SIG{signal}
sub Signals::XSIG::TieSIG::DELETE {
    my ($self,$key) = @_;
    $XDEBUG && $key ne '__DIE__'
        && XLOG("DELETE key=$key caller=",caller);
    if (_resolve_signal($key)) {
	my $old = $ZSIG{$key}->_store(0, undef);
        $XDEBUG && XLOG("    DELETE result(1)=$old");
	return $old;
    } else {
	my $old = $self->FETCH($key);
	no warnings 'uninitialized';
        $XDEBUG && XLOG("    DELETE result(2)=$old");
	$OSIG{$key} = undef;
	delete $OSIG{$key};
	return $old;
    }
}

# called when we say  %SIG = ();
sub Signals::XSIG::TieSIG::CLEAR {
    my ($self) = @_;
    $XDEBUG && $^O ne "MSWin32" && do {
        XLOG("CLEAR caller=",caller);
        XLOG("    CLEAR init USR1=",@{$ZSIG{USR1}{handlers}});
        XLOG("    CLEAR init USR2=",@{$ZSIG{USR2}{handlers}});
    };

    my @sigs = reverse sort keys %ZSIG;
    $XDEBUG && XLOG("    \@sigs = qw(@sigs);");
    for (@sigs) {
	$ZSIG{$_} = Signals::XSIG->_new($_);
    }

    $XDEBUG && $^O ne 'MSWin32' && do {
        XLOG("    CLEAR final USR1=",@{$ZSIG{USR1}{handlers}});
        XLOG("    CLEAR final USR2=",@{$ZSIG{USR2}{handlers}});
    };
    return;
}

# called when we say   exists $SIG{signal}
sub Signals::XSIG::TieSIG::EXISTS {
    my ($self,$key) = @_;
    $XDEBUG && $key ne '__DIE__'
        && XLOG("EXISTS key=$key caller=",caller);
    return exists $OSIG{$key};
}

sub Signals::XSIG::TieSIG::FIRSTKEY {
    my ($self) = @_;
    $XDEBUG && XLOG("FIRSTKEY caller=",caller);
    my $a = keys %OSIG;
    $XDEBUG && XLOG("    FIRSTKEY result=$a");
    return each %OSIG;
}

sub Signals::XSIG::TieSIG::NEXTKEY {
    my ($self, $lastkey) = @_;
    $XDEBUG && XLOG("NEXTKEY lastkey=$lastkey caller=",caller);
    return each %OSIG;
}

# invoked with   untie %SIG
sub Signals::XSIG::TieSIG::UNTIE {
    no warnings 'uninitialized';
    $XDEBUG && !__inGD() && XLOG("UNTIE caller=",caller);
    *main::SIG = \%Signals::XSIG::OSIG;
    *OSIG = \%YSIG;
    %main::SIG = %OOSIG;
    $_INITIALIZED = 0;
    return;
}

############################################################
#
# Signals::XSIG::TieArray
#
# Creates association between @{$XSIG{signal}} / $XSIG{signal}[index]
# and $ZSIG{signal}
#

sub Signals::XSIG::TieArray::TIEARRAY {
    my ($class, $signal) = @_;
    return bless {key => $signal}, 'Signals::XSIG::TieArray';
}

# Those Perl guys thought of everything.
{
    no warnings 'once';
    $Signals::XSIG::TieArray::NEGATIVE_INDICES = 1;
}

# called with  $x = $XSIG{signal}[index]
sub Signals::XSIG::TieArray::FETCH {
    my ($self, $index) = @_;
    return $ZSIG{$self->{key}}->_fetch($index);
}


# called with  $XSIG{signal}[index] = handler
sub Signals::XSIG::TieArray::STORE {
    my ($self, $index, $handler) = @_;
    return $ZSIG{$self->{key}}->_store($index, $handler);
}

sub Signals::XSIG::TieArray::handlers {
    my $self = shift(@_);
    return @{$self->{handlers}};
}

sub Signals::XSIG::TieArray::FETCHSIZE {
    my ($self) = @_;
    return $ZSIG{$self->{key}}->_size;
}

sub Signals::XSIG::TieArray::STORESIZE { }

sub Signals::XSIG::TieArray::EXTEND { }

# called with  exists $XSIG{signal}[index]
sub Signals::XSIG::TieArray::EXISTS {
    my ($self, $index) = @_;
    my $zsig = $ZSIG{$self->{key}};
    return if $index < $zsig->{start};
    return exists $zsig->{handlers}[$index - $zsig->{start}];
}


# called with   delete $XSIG{signal}[index]
sub Signals::XSIG::TieArray::DELETE {
    my ($self, $index) = @_;
    return $ZSIG{$self->{key}}->_store($index, undef);
}

# called with   $XSIG{signal} = []
#               @{$XSIG{signal}} = ()
sub Signals::XSIG::TieArray::CLEAR {
    my ($self) = @_;
    $ZSIG{$self->{key}} = Signals::XSIG->_new($self->{key});
    return;
}


# called with  unshift @{$XSIG{signal}}, @list
sub Signals::XSIG::TieArray::UNSHIFT {
    my ($self, @list) = @_;
    return $ZSIG{$self->{key}}->_unshift(@list);
}


# called with  pop @{$XSIG{signal}}
sub Signals::XSIG::TieArray::POP {
    my ($self) = @_;
    return $ZSIG{$self->{key}}->_pop;
}


# called with  shift @{$XSIG{signal}}
sub Signals::XSIG::TieArray::SHIFT {
    my $self = shift(@_);
    return $ZSIG{$self->{key}}->_shift;
}


# called with  push @{$XSIG{signal}}, @list
sub Signals::XSIG::TieArray::PUSH {
    my ($self, @list) = @_;
    return $ZSIG{$self->{key}}->_push(@list);
}

sub Signals::XSIG::TieArray::SPLICE { }  # TODO

##################################################################
#
# Signals::XSIG::TieXSIG
#
# $XSIG{sig} must produce a tied array that can be used in these ways:
#
#     $aref = $XSIG{signal}
#     $XSIG{signal} = $aref
#     @{$XSIG{signal}} = @list
#     $h = $XSIG{signal}[index]
#     $XSIG{signal}[index] = $h
#     push|unshift @{$XSIG{signal}}, @list
#     $h = pop|shift @{$XSIG{signal}}
#
#
# Only for tie-ing %XSIG.
# adds behavior to %XSIG hash so we can make assignments to
# $XSIG{sig} so that @{$XSIG{$sig}} is always a
# Signals::XSIG::TieArray
#

sub Signals::XSIG::TieXSIG::TIEHASH {
    return $XSIGTIE;
}

# $aref = $XSIG{signal}

sub Signals::XSIG::TieXSIG::FETCH {
    my ($self,$key) = @_;
    _resolve_signal($key,1);
    return $ZSIG{$key} ? $ZSIG{$key}{ta} : [];
}

# called with  $XSIG{signal} = handler, $XSIG{signal} = [handlers]
sub Signals::XSIG::TieXSIG::STORE {
    my ($self, $key, $value) = @_;
    # print STDERR "\n\aTieXSIG::STORE($key)\n\n";
    _resolve_signal($key,1);
    return unless $ZSIG{$key};
    if (ref $value ne 'ARRAY') {
	$value = [ $value ];
    }
    my $old = $ZSIG{$key}->{handlers};
    $ZSIG{$key} = Signals::XSIG->_new($key, @$value);
    return $old;
}

sub Signals::XSIG::TieXSIG::DELETE {
    my ($self, $key) = @_;
    _resolve_signal($key,1);
    my $old = $ZSIG{$key} && $ZSIG{$key}->{handlers};
    $ZSIG{$key} &&= Signals::XSIG->_new($key);
    return $old;
}

sub Signals::XSIG::TieXSIG::CLEAR {
    my ($self) = @_;
    my @names = keys %ZSIG;
    for my $key (@names) {
	$ZSIG{$key} = Signals::XSIG->_new($key);
    }
    return;
}

sub Signals::XSIG::TieXSIG::EXISTS {
    my ($self,$key) = @_;
    _resolve_signal($key,1);
    return exists $ZSIG{$key};
}

sub Signals::XSIG::TieXSIG::FIRSTKEY {
    my ($self) = @_;
    my $a = keys %ZSIG;
    return each %ZSIG;
}

sub Signals::XSIG::TieXSIG::NEXTKEY {
    my ($self, $lastkey) = @_;
    return each %ZSIG
}


# Signals::XSIG object implementation, all with 'private' functions
# Elements of %ZSIG are objects of this type

sub _new {
    my ($___pkg, $sig, @handlers) = @_;
    if ($ENV{XSIG_56} || $Config{PERL_VERSION} <= 6) {
        return Signals::XSIG::Meta56->_new($sig, @handlers);
    } else {
        return Signals::XSIG::Meta->_new($sig, @handlers);
    }
}


1;

__END__

=head1 NAME

Signals::XSIG - install multiple signal handlers through %XSIG

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use Signals::XSIG;

    # drop-in replacement for regular signal handling through %SIG
    $SIG{TERM} = \&my_sigterm_handler;
    $SIG{USR1} = sub { ... };
    $SIG{PIPE} = 'DEFAULT';

    # %XSIG interface to installing multiple signal handlers
    $SIG{TERM} = \&handle_sigterm;  # same as  $XSIG{TERM}[0] = ...
    $XSIG{TERM}[3] = \&posthandle_sigterm;
    $XSIG{TERM}[-1] = \&prehandle_sigterm;
    # On SIGTERM, prehandle_sigterm, handle_sigterm, and posthandle_sigterm
    # are called, in that order.

    # array operations allowed on @{$XSIG{signal}}
    push @{$XSIG{__WARN__}}, \&log_warnings;
    unshift @{$XSIG{__WARN__}}, \&remotely_log_warnings;
    warn "This warning invokes both handlers";
    shift @{$XSIG{__WARN__}};
    warn "This warning only invokes the 'log_warnings' handler";

    # turn off all %XSIG signal handling, restore %SIG to its state
    #      before Signals::XSIG was imported
    unimport Signals::XSIG;

=head1 DESCRIPTION

Perl provides the magic global hash variable C<%SIG> to make it
easy to trap and set a custom signal handler (see L<perlvar/"%SIG"> and
L<perlipc|perlipc/"Signals">) on most of the available signals.
The hash-of-lists variable C<%XSIG> provided by this module
has a similar interface for setting an arbitrary number of
handlers on any signal.

There are at least a couple of use cases for this module:

=over 4

=item 1. 

You have written a module that raises signals and makes
use of signal handlers, but you don't want to preclude the
end-user of your module from doing their own handling of that
signal. This module solves this issue by allowing you to
install a list of handlers for a signal, and installing your
own signal handler into a "non-default" index. Now your module's
end-user can set and unset C<$SIG{signal}> as much as he or she 
would like. When the signal is trapped, both your module's 
signal handler and the end-user's signal handler (if any) 
will be invoked.

    package My::Module::With::USR1::Handler;
    use Signals::XSIG;
    sub import {
       ...
       # use $XSIG{USR1}, not $SIG{USR1}, in case the user of
       # this module also wants to install a SIGUSR1 handler.
       # Execute our handler BEFORE any user's handler.
       $XSIG{'USR1'}[-1] = \&My_USR1_handler;
       ...
    }
    sub My_USR1_handler { ... }
    sub My_sub_that_raises_SIGUSR1 { ... }
    ...
    1;

Now users of your module can still install their own
C<SIGUSR1> handler through C<$SIG{USR1}> without interfering
with your own C<SIGUSR1> handler.

=item 2. 

You have multiple "layers" of signal handlers that you
want to enable and disable at will. For example, you
may want to enable some handlers to write logging information
about signals received.

    use Signals::XSIG;

    # log all warning messages
    $XSIG{__WARN__}[1] = \&log_messages;
    do_some_stuff();

    # now enable extra logging -- warn will invoke both functions now
    $XSIG{__WARN__}[2] = \&log_messages_with_authority;
    do_some_more_stuff();

    # done with that block. disable extra layer of logging
    $XSIG{__WARN__}[2] = undef;
    # continue, &log_warnings will still be called at next warn statement

=back

=head1 %XSIG

Extended signal handling is provided by making assignments to and performing
other operations on the hash-of-lists C<%XSIG>, which is imported into
the calling namespace by default.

A signal C<handler> is one of the following or any scalar variable 
that contains one of the following:

=over 4

    DEFAULT
    IGNORE
    undef
    ''
    unqualified_sub_name  # qualified to main::unqualified_sub_name
    qualified::sub_name
    \&subroutine_ref
    sub { anonymous sub }
    *unqualified_glob     # qualified to *CallingPackage::unqualified_glob
    *qualified::glob

=back

(the last two handler specifications cannot be used with Perl 5.8
due to a limitation with assigning globs to tied hashes. See
L</"BUGS AND LIMITATIONS">).

There are several ways to enable additional handlers on a signal.

=over 4

=item $XSIG{signal} = handler

Sets a single signal handler for the given signal.

=item $XSIG{signal}[0] = handler

Behaves identically to the conventional C<$SIG{signal} = handler>
expression. Installs the specified signal handler as the "main" 
signal handler. If you are using this module because you don't 
want your signal handlers to trample on the signal handlers of 
your users, then you generally I<don't> want to use this 
expression.

=item $XSIG{signal}[n] = handler  for  n E<gt> 0

=item $XSIG{signal}[-n] = handler  for  -n E<lt> 0

Installs the given signal handler at the specified indicies.
When multiple signal handlers are installed and a signal is
trapped, the signal handlers are invoked in order from lowest
indexed to highest indexed.

For example, this code:

    $XSIG{USR1}[-2] = sub { print "J" };
    $XSIG{USR1}[-1] = sub { print "A" };
    $XSIG{USR1}[1] = sub { print "H" };
    $SIG{USR1} = sub { print "P" };   # $SIG{USR1} is alias for $XSIG{USR1}[0]
    kill 'USR1', $$;

should output the string C<JAPH>. If a "main" signal handler is
installed, then use this expression with a I<negative> index to
register a handler to run before the main handler, and with a
I<positive> index for a handler to run after the main handler.

A signal handler at a specific slot can be removed by assigining
C<undef> or C<''> (the empty string) to that slot.

    $XSIG{USR1}[1] = undef;

=item $XSIG{signal} = [handler1, handler2, ...]

=item @{$XSIG{signal}} = (handler1, handler2, ...)

Installs multiple handlers for a signal in a single expression.
Equivalent to

    $XSIG{signal} = [];   # clear all signal handlers
    $XSIG{signal}[0] = handler1;
    $XSIG{signal}[1] = handler2;
    ...

All the handlers for a signal can be uninstalled with a
single expression like

    $XSIG{signal} = [];
    @{XSIG{signal}} = ();

=item push @{$XSIG{signal}}, handler1, handler2, ...

Installs additional signal handlers to be invoked I<after>
all currently installed signal handlers. There is a
corresponding C<pop> operation, but it cannot be used to
remove the main handler or any prior handlers.

    $XSIG{USR1} = [];
    $XSIG{USR1}[-1] = \&prehandler;
    $XSIG{USR1}[0] = \&main_handler;
    $XSIG{USR1}[1] = \&posthandler;
    push @{$XSIG{USR1}}, \&another_posthandler;
    pop @{$XSIG{USR1}};   # removes \&another_posthandler
    pop @{$XSIG{USR1}};   # removes \&posthandler
    pop @{$XSIG{USR1}};   # no effect - pop doesn't remove index <= 0

=item unshift @{$XSIG{signal}}, handler1, handler2, ...

Analagous to C<push>, installs additional signal handlers
to be invoked I<before> all currently installed signal handlers.
The corresponding C<shift> operation cannot be used to remove
the main handler or any later handlers.

    $XSIG{USR1} = [ $h1, $h2, $h3, $h4 ];
    $XSIG{USR1}[-1] = $j1;
    $XSIG{USR1}[-3] = $j3;
    unshift @{$XSIG{USR1}}, $j4; # installed at $XSIG{USR1}[-4]
    shift @{$XSIG{USR1}};     # removes $j4
    shift @{$XSIG{USR1}};     # removes $j3
    shift @{$XSIG{USR1}};     # removes $XSIG{USR1}[-2], which is undef
    shift @{$XSIG{USR1}};     # removes $j1
    shift @{$XSIG{USR1}};     # no effect - shift doesn't remove index >= 0

=back

=head1 OVERRIDING DEFAULT SIGNAL BEHAVIOR

C<Signals::XSIG> provides two ways that the 'DEFAULT' signal behavior
(that is, the behavior of a trapped signal when one or more of 
its signal handlers is set to C<'DEFAULT'>,
B<not> the behavior when a signal does not have a signal handler set)
can be overridden for a specific signal.

=over 4

=item * define a C<< Signals::XSIG::Default::default_<SIG> >> function

    sub Signals::XSIG::Default::default_QUIT {
        print "Hello world.\n";
    }
    $SIG{QUIT} = 'DEFAULT';
    kill 'QUIT', $$;

=item * set a handler in C< %Signals::XSIG::DEFAULT_BEHAVIOR >

    $Signals::XSIG::DEFAULT_BEHAVIOR{USR1} = sub { print "dy!" }
    $XSIG{'USR1'} = [ sub {print "How"}, 'DEFAULT',  sub{print$/} ];
    kill 'USR1', $$;     #  "Howdy!\n"

=back

Note again that the overridden 'DEFAULT' behavior will only be used for
signals where a handler has been explicitly set to C<'DEFAULT'>, and
not for signals that do not have any signal handler installed. So

    $SIG{USR1} = 'DEFAULT'; kill 'USR1', $$;

will use the overridden default behavior, but

    $XSIG{USR1} = []; kill 'USR1', $$;

will not.

Also note that in any chain of signal handler calls, the 'DEFAULT'
signal handler will be called at most once. So for example this code

    my $x = 0;
    $Signals::XSIG::DEFAULT_BEHAVIOR{USR2} = sub { $x++ };
    $XSIG{USR2} = [ 'DEFAULT', sub {$x=11}, 'DEFAULT', 'DEFAULT' ];
    kill 'USR2', $$;
    print $x;

will output 11, not 13. This is DWIM.

When is this feature useful? Perhaps when C<Signals::XSIG> makes the wrong
assumptions about what a default signal behavior is. Or when you have an
unusual system with different default signal behavior than your typical
system, and out of portability concerns you want your unusual system
to behave the way you are used to.

=head1 EXPORT

The C<%XSIG> extended signal handler hash is exported into
the calling namespace by default.

=head1 FUNCTIONS

=head2 unimport 

To disable this module and restore C<%SIG> to its original state
(before this module was imported), call

    unimport Signals::XSIG;

=head2 import

To reactivate this module and enable C<%XSIG> signal handling after
calling L<"unimport">, call

    import Signals::XSIG

Selectively disabling this module with local C<{ no Signals::XSIG; ... }>
blocks is not yet supported.

=cut

=head1 OTHER NOTES

=head2 DEFAULT signal handler

If the main handler for a signal (C<$XSIG{signal}[0]>) is set to C<DEFAULT>,
that handler will be ignored if there are any other handlers installed
for that signal. This is DWIM.

For example, this will invoke the default behavior for SIGUSR1
(typically terminating the program):

    $SIG{USR1} = 'DEFAULT';
    kill 'USR1', $$;

but this will not

    $SIG{USR1} = 'DEFAULT';
    $XSIG{USR1}[1] = \&do_something_else;
    kill 'USR1', $$;

This will also invoke the default behavior for SIGTERM (probably terminating
the program) since it is not the main handler that is the C<DEFAULT> handler:

    $SIG{TERM} = \&trap_sigterm;
    $XSIG{TERM}[-1] = 'DEFAULT';
    kill 'TERM', $$;

If the C<DEFAULT> handler is installed more than once, the default
behavior for that signal will still only be invoked once when
that signal is trapped.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Using this module may make it more difficult to use Perl
in some other ways.

=head2 C<local %SIG> not DWIM

Version of C<Signals::XSIG> prior to 1.00 did not work well when
a caller would C<local>ize C<%SIG>, and those versions strongly
recommended using C<Signals::XSIG> in any program than also used
C<local %SIG>. It is safe to call C<local %SIG> with C<Signals::XSIG>
now, though it probably will not do what you expect. In older perls,
C<local %SIG> with C<Signals::XSIG> has no effect at all. In newer
perls, setting a signal handler on a C<local %SIG> with C<Signals::XSIG> 
will not be used to handle a signal.

Note that it is and has always been perfectly fine to C<local>ize an 
I<element> of C<%SIG>:

    {
        local $SIG{TERM} = ...; # this is ok.
        something_that_might_raise_SIGTERM();
    } # end of local scope, $SIG{TERM} restored.

=head2 $SIG{signal} = *foo on Perl 5.8

L<perlvar/"%SIG"> specifies that you can assign a signal handler with
the construction

    $SIG{signal} = *foo;    # same as ... = \&__PACKAGE__::foo

It turns out that in Perl 5.8, this causes a fatal error when
you use this type of assignment to a tied hash. This is a limitation
of tied hashes in the implementation of Perl 5.8,
not a problem with the magic of C<%SIG>.

=head2 Overhead of processing signals

C<Signals::XSIG> adds some overhead to signal processing
and that could ultimately make your signal processing
I<less> stable as each signal takes longer to process.
This module may not be suitable for applications where
many signals need to be processed in a short time.

=head2 Using Perl debugger is more painful

This module hangs its hat on many of the same hooks
that the Perl debugger needs to use. As you step through
code in the debugger, you may often find yourself
stepping through the code in this module (say, where
some core module is installing a C<$SIG{__WARN__}>
handler. You may find this annoying.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Signals::XSIG

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Signals-XSIG>

=item * Search CPAN

L<http://search.cpan.org/dist/Signals-XSIG>

=back

Please report any bugs or feature requests to 
C<bug-signals-xsig at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Signals-XSIG>.  
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=cut

=head1 ACKNOWLEDGEMENTS

This module was greatly simplified thanks to a suggestion from
L<Leon Timmermans|https://metacpan.org/author/LEONT>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2022 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
