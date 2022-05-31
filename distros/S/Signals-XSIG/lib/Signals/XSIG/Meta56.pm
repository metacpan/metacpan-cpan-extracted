package Signals::XSIG::Meta56;
use Carp;
use strict;
use warnings;

*_qualify_handler = \&Signals::XSIG::_qualify_handler;

# Meta-handler object for Perl v5.6, where you cannot
# pass negative indicies to the FETCH and STORE methods of
# a tied array class.
#
# The workaround for 5.6 is to use a fixed-size list for the
# signal handlers, and to croak when the number of signal
# handlers exceeds reason (50-100).
#
# Even in >v5.6, we should still be able to use this implementation
# if we keep the number of signal handlers within reason.

sub _too_many {
    croak "Signals::XSIG::Meta56: too many sighandlers for " . $_[0]->{key};
}

sub _new {
    my ($pkg, $sig, @handlers) = @_;
    my $good = defined $Signals::XSIG::SIGTABLE{$sig} &&
        !defined($Signals::XSIG::alias{"sub:$sig"});
    my $self = {
	key => $sig,
	handlers => [ (undef) x 100 ],
        max => 50,
        bottom => 99,                 # next free slot for _unshift
	xh => [],
        ta => [],
        good => $good,
	sigacshun => sub { Signals::XSIG::_sigaction($sig, @_) }
    };
    if ($good) {
        for my $i (0 .. $#handlers) {
            $self->{handlers}[$i] = _qualify_handler($handlers[$i]);
        }
        $self->{top} = 0 + @handlers; # next free slot for _push
    }
    tie @{$self->{ta}}, 'Signals::XSIG::TieArray', $sig;
    bless $self, $pkg;
    return $self->_refresh;
}

sub _refresh {
    my $self = shift(@_);
    return $self if !$Signals::XSIG::_REFRESH;
    if (!$self->{good}) {
        return;
    }
    my $seen_default = 0;
    $self->{xh} = [];
    my $ignore_main_default = 0;
    for my $i ($self->{bottom} .. 99, 0 .. $self->{top} - 1) {
        my $h = $self->{handlers}[$i];
	next if !defined $h;
	next if $h eq '';
	$ignore_main_default = 1 if $i != 0;
	next if $h eq 'IGNORE';
	if ($h eq 'DEFAULT') {
	    next if $i == 0 && $ignore_main_default;
	    next if $seen_default++;
	    push @{$self->{xh}}, 'DEFAULT';
	} else {
	    next if !defined &$h;
	    push @{$self->{xh}}, $h;
	}
    }
    return if !$Signals::XSIG::_INITIALIZED;
    if (@{$self->{xh}}) {
	$Signals::XSIG::OSIG{$self->{key}} = $self->{sigacshun};
    } else {
        no warnings 'signal', 'uninitialized';
        die unless $self->{key}; # ASSERT
	$Signals::XSIG::OSIG{$self->{key}} = undef;
    }
    return $self;
}

sub _fetch {
    my ($self, $index) = @_;
    return $self->{handlers}[$index];
}

sub _store {
    my ($self, $index, $handler) = @_;
    $index += 100 if $index < 0;
    $self->_too_many if $index < 0 || $index >= 100;

    if ($index == $self->{top}) {
        $self->{top}++;
    } elsif ($index == $self->{bottom}) {
        $self->{bottom}--;
    } elsif ($index > $self->{max}) {
        $self->{bottom} = $index - 1 if $index <= $self->{bottom};
    } else {
        $self->{top} = $index+1 if $index >= $self->{top};
    }
    if ($self->{top} >= $self->{max} || $self->{bottom} <= $self->{max}) {
        $self->_too_many;
    }

    my $old = $self->{handlers}[$index];
    if ($self->{good}) {
        $self->{handlers}[$index] = _qualify_handler($handler);
    }
    $self->_refresh;
    return $old;
}

sub _handlers {
    my $self = shift;
    croak "Not expected to call this function";
    my @h = @{$self->{handlers}};
    return @h[$self->{bottom}+1 .. 99, 0 .. $self->{top}-1];
}

sub _size {
    my $self = shift(@_);
    return 100;
    #return scalar @{$self->{handlers}};
}

sub _exists {
    my ($self, $index) = @_;
    return $index >= 0 && exists $self->{handlers}[$index];
}

sub _delete {
    my ($self, $index) = @_;
    return if $index < 0  || $index >= 100;
    my $old = $self->{handlers}[$index];
    $self->{handlers}[$index] = undef;
    $self->_refresh;
    return $old;
}

sub _unshift {
    my ($self, @list) = @_;
    foreach my $handler (reverse @list) {
	$self->{handlers}[$self->{bottom}] = $handler;
	$self->{bottom}--;
        $self->_too_many if $self->{bottom} <= $self->{max};
    }
    $self->_refresh;
    return $self->_size;
}

sub _push {
    my ($self, @list) = @_;
    if ($self->{top} == 0) {
	# don't set index 0 with PUSH
	$self->{top} = 1;
    }
    foreach my $handler (@list) {
	$self->{handlers}[$self->{top}] = $handler;
	$self->{top}++;
	$self->_too_many if $self->{top} >= $self->{max};
    }
    $self->_refresh;
    return $self->_size;
}

sub _shift {
    my $self = shift(@_);
    if ($self->{bottom} < 99) {
	$self->{bottom}++;
	my $val = $self->{handlers}[$self->{bottom}];
	$self->{handlers}[$self->{bottom}] = undef;
	$self->_refresh;
	return $val;
    }
    return;
}

sub _pop {
    my $self = shift(@_);
    if ($self->{top} > 1) {
	$self->{top}--;
	my $val = $self->{handlers}[$self->{top}];
	$self->{handlers}[$self->{top}] = undef;
	$self->_refresh;
	return $val;
    }
    return;
}




1;
