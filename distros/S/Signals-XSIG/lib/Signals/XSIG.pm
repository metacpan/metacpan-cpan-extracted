package Signals::XSIG;

## no critic (RequireLocalizedPunctuationVars, ProhibitAutomaticExport)

use Signals::XSIG::Default;
use Carp;
use Config;
use Exporter;
use POSIX ();
use Symbol qw(qualify);
use Time::HiRes 'time';
use warnings;
use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(%XSIG);
our @EXPORT_OK = qw(untied %DEFAULT_BEHAVIOR);

our %DEFAULT_BEHAVIOR;
*DEFAULT_BEHAVIOR = \%Signals::XSIG::Default::DEFAULT_BEHAVIOR;

our $VERSION = '0.16';
our (%XSIG, %_XSIG, %SIGTABLE, $_REFRESH, $_DISABLE_WARNINGS);
our $_INITIALIZED = 0;
our $SIGTIE = bless {}, 'Signals::XSIG::TieSIG';
our $XSIGTIE = bless {}, 'Signals::XSIG::TieXSIG';
our $TIEARRAY_CLASS = 'Signals::XSIG::TieArray';

my %TIEDSCALARS = (); # map signal names to S::X::TiedScalar objs
my %alias = ();


###
# to be removed when we get a handle on intermittent t/02 failures
our ($XDEBUG,$XN,@XLOG) = (0,1001);
sub XLOG{no warnings"uninitialized";push @XLOG,($XN++)." @_";XLOG_DUMP() if $XDEBUG>1}
sub XLOG_DUMP{my $r = join("\n",@XLOG); @XLOG=(); print "$r\n"}
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

&_init;

sub _init {
    return if $_INITIALIZED;
    $_REFRESH = 0;
    if ($Config{PERL_VERSION} <= 6) {
	require Signals::XSIG::TieArray56;
	$TIEARRAY_CLASS = 'Signals::XSIG::TieArray56';
    }

    my @z = ();
    my @num = split ' ', $Config{sig_num};
    my @name = split ' ', $Config{sig_name};
    for (my $i=0; $i<@name; $i++) {
	if (defined $z[$num[$i]]) {
	    $alias{$name[$i]} = $z[$num[$i]];
	    $alias{$z[$num[$i]]} = $name[$i];
	    $alias{"pk:$z[$num[$i]]"} = 1;
	}
	$z[$num[$i]] = $name[$i];
    }

    foreach my $sig (@name, '__WARN__', '__DIE__') {
	tie $_XSIG{$sig}, 'Signals::XSIG::TieScalar', $sig;
#### this functionality all happens within S::X::TieScalar::TIESCALAR now
#	$_XSIG{$sig} = [];
#	tie @{$_XSIG{$sig}}, $TIEARRAY_CLASS, $sig;
#	$_XSIG{$sig}[0] = $SIG{$sig};
    }
    tie %SIG, 'Signals::XSIG::TieSIG';
    $_REFRESH = 1;
    foreach my $sig (@name, '__WARN__', '__DIE__') {
	next if $sig eq 'ZERO';
	unless (eval { (tied @{$_XSIG{$sig}})->_refresh_SIG; 1 }) {
	    Carp::confess "Error initializing \@{\$XSIG{$sig}}!: $@\n";
	}
    }
    tie %XSIG, 'Signals::XSIG::TieXSIG';

    my @signo = split ' ', $Config{sig_num};
    my @signame = split ' ', $Config{sig_name};
    for (my $i=0; $i<@signo; $i++) {
	my $signo = $signo[$i];
	my $signame = $signame[$i];
	$SIGTABLE{$signo} ||= $signame;
	$SIGTABLE{'SIG' . $signame} = $SIGTABLE{$signame} = $SIGTABLE{$signo};
    }
    $SIGTABLE{'__WARN__'} = '__WARN__';
    $SIGTABLE{'__DIE__'} = '__DIE__';
    return ++$_INITIALIZED;
}

sub __shadow__warn__handler {          ## no critic (Unpacking)
    return &__shadow_signal_handler('__WARN__',@_) 
}
sub __shadow__die__handler  {          ## no critic (Unpacking)
    return &__shadow_signal_handler('__DIE__',@_) 
}

END { &__END; }

sub __END {
    no warnings 'redefine';
    *__inGD = sub () { 1 };
}

sub __shadow_signal_handler {
    my ($signal, @args) = @_;

    # %XSIG might be partially or completely untied during global destruction
    return if __inGD();
    my $seen_default = 0;

    my $h = tied @{$XSIG{$signal}};
    my @handlers = $h->handlers;
    my $start = $h->{start} - 1;
    my $ignore_main_default = 0;

    # @HANDLER_SEQUENCE: the handlers that have already processed this signal
    # will using 'local' be sufficient to distinguish handler count when
    # signal handling is interrupted by another signal?
    local @Signals::XSIG::HANDLER_SEQUENCE = ();
    while (@handlers) {
	my $subhandler = shift @handlers;
	$start++;
	next if !defined($subhandler);
	next if $subhandler eq '';
	if ($start != 0) {
	    $ignore_main_default = 1;
	}
	next if $subhandler eq 'IGNORE';
	if ($subhandler eq 'DEFAULT') {
	    if ($start == 0) {
		if ($ignore_main_default) {
		    next;
		}
		if (0 != grep { defined($_) && $_ ne '' } @handlers) {
		    next;
		}
	    }
	    next if $seen_default++;
	    Signals::XSIG::Default::perform_default_behavior($signal, @args);
	    push @Signals::XSIG::HANDLER_SEQUENCE, 'DEFAULT';
	} else {
	    next if !defined &$subhandler;
	    no strict 'refs';                    ## no critic (NoStrict)
	    if ($signal =~ /__\w+__/) {
		$subhandler->(@args);
	    } else {
		$subhandler->($signal, @args);
	    }
	    push @Signals::XSIG::HANDLER_SEQUENCE, $subhandler;
	}
    }
    return;
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

# execute a block of code while %SIG is temporarily untied.

sub untied (&) {                    ## no critic (SubroutinePrototypes)
    my $BLOCK = shift;

    untie %SIG;
    my @r = wantarray ? $BLOCK->() : scalar $BLOCK->();
    tie %SIG, 'Signals::XSIG::TieSIG';

    return wantarray ? @r : $r[0];
}



# in %SIG and %XSIG assignments, string values are qualified to the
# 'main' package, unqualified *glob values are qualified to the
# calling package.
sub _qualify_handler {
    my $handler = shift;

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

	$handler = qualify($handler, $package || 'main');
    } else {
	$handler = qualify($handler, 'main');
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

sub Signals::XSIG::TieSIG::FETCH {
    my ($self,$key) = @_;

    # track function calls to diagnose test failures
    $XDEBUG && $key ne '__DIE__'
            && XLOG("FETCH key=$key caller=",caller);
    if (_resolve_signal($key)) {
        $XDEBUG && $key ne '__DIE__' && XLOG("    result(1)=",$_XSIG{$key}[0]);
	return $_XSIG{$key}[0];
    } else {
	no warnings 'uninitialized';
	my $r = untied { $SIG{$key} };
        $XDEBUG && $key ne '__DIE__' && XLOG("    result(2)=$r");
	return $r;
    }
}

sub Signals::XSIG::TieSIG::STORE {
    my ($self,$key,$value) = @_;
    no warnings 'uninitialized';
    $XDEBUG && $key ne '__DIE__'
        && XLOG("STORE($key,$value) caller=",caller);
    if (_resolve_signal($key)) {
	my $old = $_XSIG{$key}[0];
	$_XSIG{$key}[0] = $value;
	return $old;
    } else {
	my $old;
        $XDEBUG && XLOG("    key $key not resolved");
	untied {
	    no warnings 'signal';          ## no critic (NoWarnings)
	    $old = $SIG{$key};
	    $SIG{$key} = $value;
	};
	return $old;
    }
}

sub Signals::XSIG::TieSIG::DELETE {
    my ($self,$key) = @_;
    $XDEBUG && $key ne '__DIE__'
        && XLOG("DELETE key=$key caller=",caller);
    if (_resolve_signal($key)) {
	my $old = $_XSIG{$key}[0];
        $XDEBUG && XLOG("    DELETE result(1)=$old");
	$_XSIG{$key}[0] = undef;
	return $old;
    } else {
	my $old = $self->FETCH($key);
	no warnings 'uninitialized';
        $XDEBUG && XLOG("    DELETE result(2)=$old");
	untied {
	    $SIG{$key} = undef;
	    delete $SIG{$key};
	};
	return $old;
    }
}

sub Signals::XSIG::TieSIG::CLEAR {
    my ($self) = @_;
    $XDEBUG && do {
        XLOG("CLEAR caller=",caller);
        XLOG("    CLEAR init USR1=",@{$_XSIG{USR1}});
        XLOG("    CLEAR init USR2=",@{$_XSIG{USR2}});
    };

    # this used to say
    #     $_XSIG{$_}[0] = undef for keys %_XSIG
    # but on some platforms, for a reason I don't yet understand,
    # the signal handler for the first value in the for loop
    # would not get cleared properly. For another reason I don't
    # yet understand, this is apparently not an issue for the
    # __WARN__ and __DIE__ handlers, so we'll manipulate the signal
    # list to make sure those handlers go first.
    
    my @sigs = reverse sort keys %_XSIG;
    $XDEBUG && XLOG("    \@sigs = qw(@sigs);");
    for (@sigs) {
	$_XSIG{$_}[0] = undef;
    }

    $XDEBUG && do {
        XLOG("    CLEAR final USR1=",@{$_XSIG{USR1}});
        XLOG("    CLEAR final USR2=",@{$_XSIG{USR2}});
    };
    return;
}

sub Signals::XSIG::TieSIG::EXISTS {
    my ($self,$key) = @_;
    $XDEBUG && $key ne '__DIE__'
        && XLOG("EXISTS key=$key caller=",caller);
    return untied { exists $SIG{$key} };
}

sub Signals::XSIG::TieSIG::FIRSTKEY {
    my ($self) = @_;
    $XDEBUG && XLOG("FIRSTKEY caller=",caller);
    my $a = keys %_XSIG;
    $XDEBUG && XLOG("    FIRSTKEY result=$a");
    return each %_XSIG;
}

sub Signals::XSIG::TieSIG::NEXTKEY {
    my ($self, $lastkey) = @_;
    $XDEBUG && XLOG("NEXTKEY lastkey=$lastkey caller=",caller);
    return each %_XSIG;
}

sub Signals::XSIG::TieSIG::UNTIE {
    $XDEBUG && !__inGD() && XLOG("UNTIE caller=",caller);
    return;
}

############################################################
#
# Signals::XSIG::TieArray
#
# Applied to @{$XSIG{signal}}.
# On update, refreshes the handler for the signal.
#

sub Signals::XSIG::TieArray::TIEARRAY {
    my ($class, @list) = @_;
    my $obj = bless {}, 'Signals::XSIG::TieArray';
    $obj->{key} = shift @list;
    $obj->{start} = 0;  # {start} refers to slot for first element of {handlers}
    $obj->{handlers} = [ map { _qualify_handler($_) } @list ];
    return $obj;
}

# Wow. Those Perl guys thought of everything.
$Signals::XSIG::TieArray::NEGATIVE_INDICES = 1;

sub Signals::XSIG::TieArray::FETCH {
    my ($self, $index) = @_;
    $index -= $self->{start};
    return if $index < 0;
    return $self->{handlers}[$index];
}

sub Signals::XSIG::TieArray::STORE {
    my ($self, $index, $handler) = @_;
    $index -= $self->{start};

    while ($index < 0) {
	unshift @{$self->{handlers}}, undef;
	$index++;
	$self->{start}--;
    }

    while ($index > $#{$self->{handlers}}) {
	push @{$self->{handlers}}, undef;
    }

    my $old = $self->{handlers}[$index];

    $handler = _qualify_handler($handler);
    $self->{handlers}[$index] = $handler;
    $XDEBUG
	&& XLOG("TA::STORE key=$self->{key} index=$index val=",$handler,
		" caller=",caller);
    $self->_refresh_SIG();
    return $old;
}

sub Signals::XSIG::TieArray::_refresh_SIG {
    my $self = shift;
    return if $_REFRESH == 0;

    my $sig = $self->{key};
    my @index_list = ();
    my @handlers = @{$self->{handlers}};
    my ($seen_default, $seen_ignore) = (0,0);
    for (my $i=0; $i<@handlers; $i++) {
	next if !defined $handlers[$i];
	next if $handlers[$i] eq 'DEFAULT' && $seen_default++;
	next if $handlers[$i] eq 'IGNORE' && $seen_ignore++;
	push @index_list, $i + $self->{start};
    }

    my $handler_to_install;
    if (@index_list == 0) {
	$handler_to_install = undef;
    }

    # XXX - if there is a single handler, and that handler is 'DEFAULT',
    #       do we want to install the shadow signal handler anyway?
    #       The caller may have overridden the DEFAULT behavior of the signal,
    #       so yeah, I think we do.

    elsif (@index_list == 1 && 
	   ($seen_default == 0 || ref($DEFAULT_BEHAVIOR{$sig}) eq '')) {
	$handler_to_install = $handlers[$index_list[0]];
    } else {
	if ($sig eq '__WARN__') {
	    $handler_to_install = \&Signals::XSIG::__shadow__warn__handler;
	} elsif ($sig eq '__DIE__') {
	    $handler_to_install = \&Signals::XSIG::__shadow__die__handler;
	} else {
	    $handler_to_install = \&Signals::XSIG::__shadow_signal_handler;
	}
    }
    untied {
	no warnings qw(uninitialized signal); ## no critic (NoWarnings)
        $XDEBUG
	    && XLOG("refresh_SIG key=$self->{key} handler=$handler_to_install");
	$SIG{$sig} = $handler_to_install;
    };
    return;
}

sub Signals::XSIG::TieArray::handlers {
    my $self = shift;
    return @{$self->{handlers}};
}

sub Signals::XSIG::TieArray::FETCHSIZE {
    my ($self) = @_;
    return scalar @{$self->{handlers}};  
}

sub Signals::XSIG::TieArray::STORESIZE { }

sub Signals::XSIG::TieArray::EXTEND { }

sub Signals::XSIG::TieArray::EXISTS {
    my ($self, $index) = @_;
    return if $index < $self->{start};
    return exists $self->{handlers}[$index - $self->{start}];
}

sub Signals::XSIG::TieArray::DELETE {
    my ($self, $index) = @_;
    $index -= $self->{start};
    return if $index < 0;
    my $old = $self->{handlers}[$index];
    $self->{handlers}[$index] = undef;
    $self->_refresh_SIG;
    return $old;
}

sub Signals::XSIG::TieArray::CLEAR {
    my ($self) = @_;
    $self->{handlers} = [];
    $self->{start} = 0;
    $self->_refresh_SIG;
    return;
}

sub Signals::XSIG::TieArray::UNSHIFT {
    my ($self, @list) = @_;
    unshift @{$self->{handlers}}, @list;
    $self->{start} -= @list;
    $self->_refresh_SIG;
    return $self->FETCHSIZE;
}

sub Signals::XSIG::TieArray::POP {
    my ($self) = @_;
    if (@{$self->{handlers}} + $self->{start} <= 1) {
	return;
    }
    my $val = pop @{$self->{handlers}};
    $self->_refresh_SIG;
    return $val;
}

sub Signals::XSIG::TieArray::SHIFT {
    my $self = shift;
    if ($self->{start} >= 0) {
	return;
    }
    my $val = shift @{$self->{handlers}};
    $self->{start}++;
    $self->_refresh_SIG;
    return $val;
}

sub Signals::XSIG::TieArray::PUSH {
    my ($self, @list) = @_;
    if (@{$self->{handlers}} + $self->{start} <= 0) {
	unshift @list, undef;
    }
    my $val = push @{$self->{handlers}}, @list;
    $self->_refresh_SIG;
    return $val;
}

sub Signals::XSIG::TieArray::SPLICE { }

##################################################################
#
# Signals::XSIG::TieScalar
#
# For tie-ing $XSIG{signal}.
# Handles expressions like  $XSIG{signal} = [ ... ]
# and                       $XSIG{signal} = handler
# Main purpose is to assert that $XSIG{$sig} is always set
# to a reference to a  Signals::XSIG::TieArray  object.
#

sub Signals::XSIG::TieScalar::TIESCALAR {
    my ($class, @list) = @_;
    my $key = $list[0];
    if (defined($alias{$key}) && !defined($alias{"pk:$key"})) {
	return $TIEDSCALARS{$key} = $TIEDSCALARS{$alias{$key}};
    }

    my $self = bless { key => $key }, 'Signals::XSIG::TieScalar';
    $self->{val} = [];
    tie @{$self->{val}}, $TIEARRAY_CLASS, $key;
    $self->{val}[0] = $SIG{$key};
    $TIEDSCALARS{$key} = $self;
    return $self;
}

sub Signals::XSIG::TieScalar::FETCH {
    my $self = shift;
    my $key = my $key2 = $self->{key};
    Signals::XSIG::_resolve_signal($key);
    if ($key ne $key2 && !$self->{copied}) {
	$self->{val} = (tied $Signals::XSIG::_XSIG{$key})->FETCH;
	$self->{copied} = $key;
        push @{(tied $Signals::XSIG::_XSIG{$key})->{aliases}}, $key2;
    } elsif ($self->{copied}) {
        $self->{val} = $Signals::XSIG::_XSIG{ $self->{copied} };
    }
    return $self->{val};
}

# $XSIG{key} = [ LIST ]   ==>  store LIST, tie LIST as TieArray
# $XSIG{key} = EXPR       ==>  treat as  $SIG{key}=EXPR,$XSIG{key}[0]=EXPR
sub Signals::XSIG::TieScalar::STORE {
    my ($self, $value) = @_;
    my $old = $self->{val};

    if (ref $value ne 'ARRAY') {
	$value = [ $value ];
    }

    my $key = $self->{key};
    $self->{val} = [];
    tie @{$self->{val}}, $TIEARRAY_CLASS, $self->{key}, @$value;
    (tied @{$self->{val}})->_refresh_SIG;
    return $old;
}

##################################################################
#
# Signals::XSIG::TieXSIG
#
# Only for tie-ing %XSIG.
# adds behavior to %XSIG hash so we can make assignments to
# $XSIG{sig} so that @{$XSIG{$sig}} is always a
# Signals::XSIG::TieArray
#

sub Signals::XSIG::TieXSIG::TIEHASH {
    return $XSIGTIE;
}

sub Signals::XSIG::TieXSIG::FETCH {
    my ($self,$key) = @_;
    _resolve_signal($key,1);
    return $_XSIG{$key};
}

sub Signals::XSIG::TieXSIG::STORE {
    my ($self, $key, $value) = @_;
    _resolve_signal($key,1);
    my $old = $_XSIG{$key};
    # (tied $_XSIG{$key})->STORE($key,$value); #
    $_XSIG{$key} = $value;
    return $old;
}

sub Signals::XSIG::TieXSIG::DELETE {
    my ($self, $key) = @_;
    _resolve_signal($key,1);
    my $old = $_XSIG{$key};
    $XSIG{$key} = [];
    return $old;
}

sub Signals::XSIG::TieXSIG::CLEAR {
    my ($self) = @_;

    my @aliases = ();
    for my $xsig (keys %_XSIG) {
	my $osig = $xsig;
	if (_resolve_signal($xsig, 1)) {
	    if ($osig ne $xsig) {
		push @aliases, [$xsig, $osig];
	    } else {
		$XSIG{$xsig} = [];
	    }
	} else {
	    delete $_XSIG{$xsig};
	}
    }
    foreach my $pair (@aliases) {
	my ($xsig, $alias) = @$pair;
	$_XSIG{$alias} = $_XSIG{$xsig};
    }
    return;
}

sub Signals::XSIG::TieXSIG::EXISTS {
    my ($self,$key) = @_;
    _resolve_signal($key,1);
    return exists $_XSIG{$key};
}

sub Signals::XSIG::TieXSIG::FIRSTKEY {
    my ($self) = @_;
    my $a = keys %_XSIG;
    return each %_XSIG;
}

sub Signals::XSIG::TieXSIG::NEXTKEY {
    my ($self, $lastkey) = @_;
    return each %_XSIG
}

1;

__END__

=head1 NAME

Signals::XSIG - install multiple signal handlers through %XSIG

=head1 VERSION

Version 0.16

=head1 SYNOPSIS

    use Signals::XSIG q{:all};

    # drop-in replacement for regular signal handling through %SIG
    $SIG{TERM} = \&my_sigterm_handler;
    $SIG{USR1} = sub { ... };
    $SIG{PIPE} = 'DEFAULT';

    # %XSIG interface to installing multiple signal handlers
    $SIG{TERM} = \&handle_sigterm;  # same as  $XSIG{TERM}[0] = ...
    $XSIG{TERM}[3] = \&posthandle_sigterm;
    $XSIG{TERM}[-1] = \&prehandle_sigterm;
    # SIGTERM calls prehandle_sigterm, handle_sigterm, posthandle_sigterm
    # in that order.

    # array operations allowed on @{$XSIG{signal}}
    push @{$XSIG{__WARN__}}, \&log_warnings;
    unshift @{$XSIG{__WARN__}}, \&remotely_log_warnings;
    warn "This warning invokes both handlers";
    shift @{$XSIG{__WARN__}};
    warn "This warning only invokes the 'log_warnings' handler";
    
=head1 DESCRIPTION

Perl provides the magic global hash variable C<%SIG> to make it
easy to trap and set a custom signal handler (see L<perlvar/"%SIG"> and 
L<perlipc|perlipc>) on most of the available signals.
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
L<"BUGS AND LIMITATIONS">).

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

None

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

=head2 Avoid C<local %SIG>

This module converts C<%SIG> into a tied hash. As documented in 
L<the perltie "BUGS" section|perltie/"BUGS">,
C<local>izing a tied hash will cause the old data
not to be restored when the local version of the hash goes out of scope.
Avoid doing this:

    {
        local %SIG;
        ...
    }

or using modules and functions which localize C<%SIG> 
(fortunately, there are not that many examples of code that
use this construction 
[L<https://code.google.com/archive/search?q=local%20%25SIG>]).

If a code block that localizes C<%SIG> can't be avoided, the
workaround for Perl E<lt>v5.36 is to save C<%SIG> and restore
at the end of the localizing scope:

    use Signals::XSIG;
    ...
    my %temp = %SIG;
    function_call_or_block_that_localizes_SIG();
    %SIG = %temp;

Since Perl v5.36, you must also unforunately untie and retie
C<%SIG> around localization.

    use Signals::XSIG;
    ...
    my %temp = %SIG;
    untie %SIG if $] >= 5.035;
    function_call_or_block_that_localizes_SIG();
    tie %SIG, 'Signals::XSIG::TieSIG' if $] >= 5.035;
    %SIG = %temp;


In addition, the behavior of the tied C<%SIG> while it is C<local>'ized
is different in different versions of Perl, and all of the features
of C<Signals::XSIG> might or might not work while a local copy
of C<%SIG> is in use.

Just avoid C<local %SIG> whenever you can.

Note that it is perfectly fine to C<local>ize an I<element> of C<%SIG>:

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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Signals-XSIG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Signals-XSIG>

=item * Search CPAN

L<http://search.cpan.org/dist/Signals-XSIG>

=back

Please report any bugs or feature requests to 
C<bug-signal-handler-super at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Signals-XSIG>.  
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.

=cut

_head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2022 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
