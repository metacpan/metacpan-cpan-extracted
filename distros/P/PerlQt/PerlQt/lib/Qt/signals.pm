package Qt::signals;
use Carp;
#
# Proposed usage:
#
# use Qt::signals fooActivated => ['int'];
#
# use Qt::signals fooActivated => {
#     name => 'fooActivated(int)',
#     args => ['int']
# };
#
# sub whatever { emit fooActivated(10); }
#

sub import {
    no strict 'refs';
    my $self = shift;
    my $caller = $self eq "Qt::signals" ? (caller)[0] : $self;
    my $parent = ${ $caller . '::ISA' }[0];
    my $parent_qt_emit = $parent . '::qt_emit';

    Qt::_internal::installqt_invoke($caller . '::qt_emit') unless defined &{ $caller. '::qt_emit' };

#    *{ $caller . '::qt_emit' } = sub {
#	my $meta = \%{ $caller . '::META' };
#	die unless $meta->{object};
#	my $offset = $_[0] - $meta->{object}->signalOffset;
#	if($offset >= 0) {
#	    Qt::_internal::invoke(Qt::this(), $meta->{signals}[$offset], $_[1]);
#	    return 1;
#	} else {
#	    Qt::this()->$parent_qt_emit(@_);
#	}
#    } unless defined &{ $caller . '::qt_emit' };

    my $meta = \%{ $caller . '::META' };
    croak "Odd number of arguments in signal declaration" if @_%2;
    my(%signals) = @_;
    for my $signalname (keys %signals) {
	my $signal = { name => $signalname };
	my $args = $signals{$signalname};
	$signal->{arguments} = [map { s/\s(?=[*&])//; { type => $_, name => "" } } @$args];
	my $arglist = join ',', @$args;
	$signal->{prototype} = $signalname . "($arglist)";
	$signal->{returns} = 'void';
	$signal->{method} = $signalname;
	push @{$meta->{signals}}, $signal;
	my $signal_index = $#{ $meta->{signals} };

	my $argcnt = scalar @$args;
	my $mocargs = Qt::_internal::allocateMocArguments($argcnt);
	my $i = 0;
	for my $arg (@$args) {
	    my $a = $arg;
	    $a =~ s/^const\s+//;
	    if($a =~ /^(bool|int|double|char\*|QString)&?$/) {
		$a = $1;
	    } else {
		$a = 'ptr';
	    }
	    my $valid = Qt::_internal::setMocType($mocargs, $i, $arg, $a);
	    die "Invalid type for signal argument ($arg)\n" unless $valid;
	    $i++;
	}

	$meta->{signal}{$signalname} = $signal;
	$signal->{index} = $signal_index;
	$signal->{mocargs} = $mocargs;
	$signal->{argcnt} = $argcnt;

	Qt::_internal::installsignal("$caller\::$signalname");
    }
    @_ and $meta->{changed} = 1;
}

1;
