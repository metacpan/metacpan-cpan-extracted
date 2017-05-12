package Signals::XSIG::TieArray56;

use Carp;
use strict;
use warnings;

############################################################
#
# Signals::XSIG::TieArray
# for Perl <=v5.6.
#
# Applied to @{$XSIG{signal}}.
# On update, refreshes the handler for the signal.
#

# perl 5.6 does not pass negative indices to the STORE and FETCH
# methods, so we must use a different implementation to
# let us say $XSIG{signal}[-3] = ...



sub TIEARRAY {
    my ($class, @list) = @_;
    my $obj = bless {}, __PACKAGE__;
    $obj->{key} = shift @list;

    # {handlers}[0 .. max-1] are for "positive" indices,
    # {handlers}[max .. 99] are for "negative" indices
    $obj->{max} = 50;

    $obj->{bottom} = 99;         # next free slot for "unshift" operation
    $obj->{handlers} = [ (undef) x 100 ];
    for my $i (0 .. $#list) {
	$obj->{handlers}[$i] = Signals::XSIG::_qualify_handler($list[$i]);
    }
    $obj->{top} = scalar @list;  # next free slot for "push" operation

    # {start} is not used by TieArray56, but __shadow_signal_handler
    # refers to it.
    $obj->{start} = 0;
    return $obj;
}

sub FETCH {
    my ($self, $index) = @_;
    croak if $index < 0;
    return $self->{handlers}[$index];
}

sub STORE {
    my ($self, $index, $handler) = @_;
    croak if $index < 0;

    if ($index == $self->{top}) {
	$self->{top}++;
	$self->{max} = $self->{top} if $self->{max} <= $self->{top};
    } elsif ($index == $self->{bottom}) {
	$self->{bottom}--;
	$self->{max} = $self->{bottom} if $self->{max} >= $self->{bottom};
    } elsif ($index >= $self->{max}) {
	$self->{bottom} = $index-1 if $index <= $self->{bottom};
    } else {
	$self->{top} = $index+1 if $index >= $self->{top};
    }
    if ($self->{top}>$self->{bottom}
	|| $self->{top}>99
	|| $self->{bottom}>99
	|| $self->{top}<0
	|| $self->{bottom}<0) {
	croak "INCONSISTENT \n";
    }

    my $old = $self->{handlers}[$index];
    $handler = Signals::XSIG::_qualify_handler($handler);
    $self->{handlers}[$index] = $handler;
    $self->_refresh_SIG();
    return $old;
}

sub _refresh_SIG {
    my $self = shift;
    return if $Signals::XSIG::_REFRESH == 0;

    local $Signals::XSIG::_REFRESH = 0;

    my $sig = $self->{key};
    my @index_list = ();
    my @handlers = @{$self->{handlers}};
    my ($seen_default, $seen_ignore) = (0,0);
    for my $i ($self->{bottom} .. 99, 0 .. $self->{top}-1) {
	next if !defined $handlers[$i];
	next if $handlers[$i] eq 'DEFAULT' && $seen_default++;
	next if $handlers[$i] eq 'IGNORE' && $seen_ignore++;
	push @index_list, $i;
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
	   ($seen_default == 0 ||
	    ref($Signals::XSIG::DEFAULT_BEHAVIOR{$sig}) eq '')) {

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
    Signals::XSIG::untied {
	no warnings qw(uninitialized signal); ## no critic (NoWarnings)
	$SIG{$sig} = $handler_to_install;
    };
    return;
}

sub handlers {
    my $self = shift;
    my @h = @{$self->{handlers}};
    return @h[$self->{bottom}+1 .. 99, 0 .. $self->{top}-1];
}

sub FETCHSIZE {
    my ($self) = @_;
    return 100;
    # return scalar $self->handlers;
}

sub STORESIZE { }

sub EXTEND { }

sub EXISTS {
    my ($self, $index) = @_;
    croak if $index<0;
    return exists $self->{handlers}[$index];
}

sub DELETE {
    my ($self, $index) = @_;
    croak if $index < 0;
    my $old = $self->{handlers}[$index];
    $self->{handlers}[$index] = undef;
    $self->_refresh_SIG;
    return $old;
}

sub CLEAR {
    my ($self) = @_;
    $self->{handlers} = [(undef) x 100];
    $self->{top} = 0;
    $self->{bottom} = 99;
    $self->{max} = 50;
    $self->_refresh_SIG;
    return;
}

sub UNSHIFT {
    my ($self, @list) = @_;
    foreach my $handler (reverse @list) {
	$self->{handlers}[$self->{bottom}] = $handler;
	$self->{bottom}--;
	if ($self->{bottom} < $self->{max}) {
	    $self->{max}--;
	}
	if ($self->{bottom} < $self->{top}) {
	    croak;
	}
    }
    $self->_refresh_SIG;
    return $self->FETCHSIZE;
}

sub POP {
    my ($self) = @_;
    # POP cannot be used to remove the default handler (index 0)
    if ($self->{top} > 1) {
	$self->{top}--;
	my $val = $self->{handlers}[$self->{top}];
	$self->{handlers}[$self->{top}] = undef;
	$self->_refresh_SIG;
	return $val;
    }

    # disable this block: pop cannot be used to retrieve pre-handlers ...
    if (0 && $self->{bottom} < 99) {
	my $val = pop @{$self->{handlers}};
	splice @{$self->{handlers}}, $self->{max}, 0, undef;
	$self->{bottom}++;
	$self->_refresh_SIG;
	return $val;
    }

    # nothing to pop
    return;
}


sub SHIFT {
    my $self = shift;
    if ($self->{bottom} < 99) {
	$self->{bottom}++;
	my $val = $self->{handlers}[$self->{bottom}];
	$self->{handlers}[$self->{bottom}] = undef;
	$self->_refresh_SIG;
	return $val;
    }

    # disable this block: shift cannot be used to retrieve post-handlers ?
    if (0 && $self->{top} > 0) {
	my $val = shift @{$self->{handlers}};
	splice @{$self->{handlers}}, $self->{max}-1, 0, undef;
	$self->{top}--;
	return $val;
    }

    # nothing to shift
    return;
}

sub PUSH {
    my ($self, @list) = @_;
    if ($self->{top} == 0) {
	# don't set index 0 with PUSH
	$self->{top} = 1;
    }
    foreach my $handler (@list) {
	$self->{handlers}[$self->{top}] = $handler;
	$self->{top}++;
	$self->{max}++ if $self->{top} > $self->{max};
	croak if $self->{top} > $self->{bottom};
    }
    $self->_refresh_SIG;
    return $self->FETCHSIZE;
}

sub SPLICE { }

1;
