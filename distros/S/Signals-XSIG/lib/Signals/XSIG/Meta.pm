package Signals::XSIG::Meta;
use Carp;
use strict;
use warnings;

*_qualify_handler = \&Signals::XSIG::_qualify_handler;

# A handler for a multi-signal handler (as in, multiple handlers for
# a signal, not handler for multiple signals).
#
# All elements of %Signals::XSIG::ZSIG will have this object type.
# Also see  Signals::XSIG::Meta56  for an alternate implementation
# that gets around the restriction of older perls in calling FETCH
# and STORE for a tied array class with negative indices.

sub _new {
    my ($pkg, $sig, @handlers) = @_;
    my $good = defined $Signals::XSIG::SIGTABLE{$sig} &&
	!defined($Signals::XSIG::alias{"sub:$sig"});
    if ($good) {
        @handlers = map { _qualify_handler($_) } @handlers;
    }
    my $self = {
	key => $sig,
	handlers => [ @handlers ],
	start => 0,
	xh => [],
        ta => [],
        good => $good,
	sigacshun => sub { Signals::XSIG::_sigaction($sig, @_) }
    };
    tie @{$self->{ta}}, 'Signals::XSIG::TieArray', $sig;
    bless $self, $pkg;
    return $self->_refresh;
}

sub _refresh {
    my $self = shift(@_);
    return $self if !$Signals::XSIG::_REFRESH;
    if (!$self->{good}) {
	Carp::cluck("_refresh: called on bad signal  " . $self->{key});
        return;
    }
    my $seen_default = 0;
    $self->{xh} = [];
    my $start = $self->{start} - 1;
    my $ignore_main_default = 0;
    for my $h (@{$self->{handlers}}) {
	$start++;
	next if !defined $h;
	next if $h eq '';
	$ignore_main_default = 1 if $start != 0;
	next if $h eq 'IGNORE';
	if ($h eq 'DEFAULT') {
	    next if $start == 0 && $ignore_main_default;
	    next if $seen_default++;
	    push @{$self->{xh}}, 'DEFAULT';
	} else {
	    next if !defined &$h;
	    push @{$self->{xh}}, $h;
	}
    }
    if ($Signals::XSIG::_INITIALIZED && @{$self->{xh}}) {
	$Signals::XSIG::OSIG{$self->{key}} = $self->{sigacshun};
    } elsif ($Signals::XSIG::_INITIALIZED) {
        no warnings 'signal', 'uninitialized';
        die unless $self->{key}; # ASSERT
	$Signals::XSIG::OSIG{$self->{key}} = undef;
    }
    return $self;
}

sub _fetch {
    my ($self, $index) = @_;
    $index -= $self->{start};
    return if $index < 0;
    return $self->{handlers}[$index];
}

sub _store {
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
    if ($self->{good}) {
        $handler = _qualify_handler($handler);
    }
    $self->{handlers}[$index] = $handler;
    $self->_refresh;
    return $old;
}

sub _size {
    my $self = shift(@_);
    return scalar @{$self->{handlers}};
}

sub _unshift {
    my ($self, @list) = @_;
    unshift @{$self->{handlers}}, @list;    
    $self->{start} -= @list;
    $self->_refresh;
    return $self->_size;
}

sub _push {
    my ($self, @list) = @_;
    if (@{$self->{handlers}} + $self->{start} <= 0) {
        # push should not set the default handler
        unshift @list, undef;
    }
    push @{$self->{handlers}}, @list;
    $self->_refresh;
    return $self->_size;
}

sub _shift {
    my $self = shift(@_);
    return if $self->{start} >= 0;
    $self->{start}++;
    $self->_refresh;
    return shift @{$self->{handlers}};
}

sub _pop {
    my $self = shift(@_);
    return if $self->{start} > 0;
    return if $self->{start} == 0 && $#{$self->{handlers}} == 0;
    my $val = pop @{$self->{handlers}};
    $self->_refresh;
    return $val;
}

1;
