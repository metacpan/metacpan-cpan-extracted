# patronite is a vanadium sulfide mineral, but it could also be
# the brand name of a heavy-duty padlock, so it is a fitting
# name for the class to manage synchronization of proxy objects

package Patro::Archy;
use Fcntl qw(:flock :seek);
use File::Temp;
use Scalar::Util 'refaddr';
use Time::HiRes qw(time sleep);
use Carp;
use base 'Exporter';
our @EXPORT_OK = (qw(plock punlock pwait pnotify
		  FAIL_EXPIRED FAIL_INVALID_WO_LOCK FAIL_DEEP_RECURSION));
our %EXPORT_TAGS = (
    'all' => [qw(plock punlock pwait pnotify)],
    'errno' => [qw(FAIL_EXPIRED FAIL_INVALID_WO_LOCK FAIL_DEEP_RECURSION)]
    );

use constant {
    STATE_NULL => 0,
    STATE_WAIT => 1,
    STATE_NOTIFY => 2,
    STATE_STOLEN => 3,
    STATE_LOCK => 4,
    STATE_LOCK_MAX => 254,

    FAIL_EXPIRED => 1001,
    FAIL_INVALID_WO_LOCK => 1002,
    FAIL_DURING_RELOCK => 1004,
    FAIL_DEEP_RECURSION => 1111,
};
our $VERSION = '0.16';
our $DEBUG;

my $DIR;
$DIR //= do {
    my $d = "/dev/shm/patro-resources-$$";
#    if ($^O eq 'MSWin32') {
#	$d = "C:/Temp/resource-$$";
    #    }
    if (! -d "/dev/shm" && -d "/tmp") {
	$d = "/tmp/patro-resources-$$";
    }
    my $pid = $$;
    # !!! need to clean up resource dir when program exits
    $d;
};
mkdir $DIR,0755 unless -d $DIR;
die "Patro::Archy requires a system with /dev/shm" unless -d $DIR;

my %lookup;

sub _unlocked { $_[0] !~ qr/[^\000-\002]/ }

sub _lookup {
    my ($id) = @_;
    $id =~ s/^\s+//;
    $id =~ s/\s+$//;
    croak "invalid monitor id '$id': id is too long" if length($id) > 20;
    open my $lock, '>>', "$DIR/.lock";
    flock $lock, LOCK_EX;
    $lookup{$id} //= do {
        my $lu;
        my $maxlu = -1;
        if (open my $fh, '<', "$DIR/.index") {
            my $data;
            while (read $fh, $data, 24) {
                my $i = substr($data,0,20);
		$i =~ s/^\s+//;
                my $val = 0 + substr($data,20,4);
                if ($val > $maxlu) {
                    $maxlu = $val;
                }
		if ($i eq $id) {
                    $lu = $val;
                    close $fh;
                    last;
                }
            }
        }
        if (!defined $lu) {
            $lu = $maxlu + 1;
            open my $fh, '>>', "$DIR/.index";
            printf $fh "%-20s%04d", $id, $lu;
            close $fh;
        }
        $lu;
    };
    close $lock;
    return $lookup{$id};
}


sub _addr {
    use B;
    my $obj = shift;
    my $addr = B::svref_2object($obj)->MAGIC;
    $addr ? $addr->OBJ->RV->IV : refaddr($obj);
}

sub plock {
    my ($obj, $id, $timeout, $steal) = @_;
    my $lu = _lookup($id);
    my $addr = _addr($obj);

    my $expire = $timeout && $timeout > 0 ? time + $timeout : 9E19;
    my $fh;
    open($fh,'+<',"$DIR/$addr") || open($fh,'+>', "$DIR/$addr") || die;
    binmode $fh;
    flock $fh, LOCK_EX;

    $DEBUG && print STDERR "Archy: checking state for $DIR/$addr\@$lu\n";

    # if we already have the lock, increment the lock counter and return OK
    my $ch = _readbyte($fh,$lu);
    if ($ch >= STATE_LOCK) {
        if ($ch > STATE_LOCK_MAX) {
	    carp "Patro::Archy: deep recursion on plock for $obj";
	    $! = FAIL_DEEP_RECURSION;
	    return;
        }
	$DEBUG && print STDERR "Archy: already locked \@ $lu\n";
        _writebyte($fh,$lu,$ch+1);
        close $fh;
        return 1;
    }

    # if no one else has the lock, get the lock
    if (_unlocked(_readall($fh))) {
        _writebyte($fh, $lu, STATE_LOCK);
        close $fh;
	$DEBUG && print STDERR "Archy: acquired the lock \@ $lu\n";
        return 1;
    }
    
    # if non-blocking, return EXPIRED
    if ($timeout && $timeout < 0) {
	if ($steal) {
	    my @b = split //,_readall($fh);
	    foreach my $i (0 .. $#b) {
		my $stolen;
		if (ord($b[$i]) >= STATE_LOCK && $i != $lu) {
		    _writebyte($i, STATE_STOLEN);
		    $stolen = $i;
		}
	    }
	    if (defined($stolen)) {
		# ??? lookup monitor id for $stolen?
		carp "lock for $addr stolen by monitor $id";
	    }
	    _writebyte($fh, $lu, STATE_LOCK);
	    close $fh;
	    return 1;
	}
	close $fh;
	$! = FAIL_EXPIRED;
	$DEBUG && print STDERR "Archy: non-blocking, lock not avail \@ $lu\n";
	return;
    }
    close $fh;

    # wait until timeout for the lock
    my $left = $expire - time;
    while ($left > 0) {
	$threads::threads ? threads->yield : sleep 1;

        open $fh, '+<', "$DIR/$addr";
	binmode $fh;
        flock $fh, LOCK_EX;
        $left = $expire - time;
	$DEBUG && print STDERR "Archy: waiting for lock \@ $lu (up to $left)\n";

        if (_unlocked(_readall($fh))) {
            _writebyte($fh,$lu,STATE_LOCK);
	    $DEBUG && print STDERR "Archy: acquired lock \@ $lu after wait\n";
	    close $fh;
            return 1;
        }
        close $fh;
    }
    if ($steal) {
        open $fh, '+<', "$DIR/$addr";
	binmode $fh;
        flock $fh, LOCK_EX;
	my @b = split //, _readall($fh);
	foreach my $i (0 .. $#b) {
	    my $stolen;
	    if (ord($b[$i]) >= STATE_LOCK && $i != $lu) {
		_writebyte($i, STATE_STOLEN);
		$stolen = $i;
	    }
	}
	if (defined($stolen)) {
	    # ??? lookup monitor id for $stolen?
	    carp "lock for $addr stolen by monitor $id";
	}
	_writebyte($fh, $lu, STATE_LOCK);
	close $fh;
	return 1;
    }
    $! = FAIL_EXPIRED;
    $DEBUG && print STDERR "Archy: expired waiting for lock \@ $lu\n";
    return;
}

sub punlock {
    my ($obj, $id, $count) = @_;
    my $lu = _lookup($id);
    my $addr = _addr($obj);
    $count ||= 1;

    my $fh;
    open($fh,'+<',"$DIR/$addr") || open($fh,'+>', "$DIR/$addr") || die;
    binmode $fh;
    flock $fh, LOCK_EX;

    # if we already have the lock, decrement the lock counter and return OK
    $DEBUG && print STDERR "Archy: checking state for unlock \@ $lu\n";
    $ch = _readbyte($fh,$lu);
    if ($ch > STATE_LOCK) {
	if ($count < 0) {
	    $count = $ch - STATE_LOCK + 1;
	    $ch = 0;
	} else {
	    if ($count > $ch - STATE_LOCK + 1) {
		carp "punlock: count ($count) exceeded lock count (",
		    $ch - STATE_LOCK + 1, ")";
		$count = $ch - STATE_LOCK + 1;
		$ch = STATE_NULL;
	    } else {
		$ch -= $count;
	    }
	}
	if ($ch < STATE_LOCK) {
	    $ch = STATE_NULL;
	}
        _writebyte($fh,$lu,$ch);
        close $fh;
	$DEBUG && print STDERR
	    "Archy: unlock successful \@ $lu. New state $ch\n";
        return $count;
    } elsif ($ch == STATE_LOCK) {
	if ($count > 1) {
	    carp "punlock: count ($count) exceeded lock count (1)";
	    $count = 1;
	}
        _writebyte($fh,$lu,STATE_NULL);
        close $fh;
	$DEBUG && print STDERR
	    "Archy: unlock successful \@ $lu. New state NULL\n";
        return 1;
    } elsif ($ch == STATE_STOLEN) {
	close $fh;
	carp "punlock: lock was stolen";

	# we don't know whether it was a single lock or a stack of locks
	# that was stolen; preserve the STATE_STOLEN byte in case the
	# monitor wants to call unlock again and again
	
	return "0 but true";
    }
    close $fh;
    carp "Patro::Archy: punlock called on $obj monitor without lock";
    $! = FAIL_INVALID_WO_LOCK;
    return;
}

sub pwait {
    my ($obj, $id, $timeout) = @_;
    my $lu = _lookup($id);
    my $addr = _addr($obj);
    my $expire = $timeout && $timeout > 0 ? time + $timeout : 9E19;

    my $unlocks = punlock($obj, $id, -1);
    if (!$unlocks) {
	$! = FAIL_INVALID_WO_LOCK;
        return;
    } elsif ($unlocks == 0) {
	# wait called but lock was stolen
	$! = FAIL_INVALID_WO_LOCK;
	return;
    }
    my $fh;
    open($fh,'+<',"$DIR/$addr") || open($fh,'+>', "$DIR/$addr") || die;
    binmode $fh;
    flock $fh, LOCK_EX;
    _writebyte($fh,$lu,STATE_WAIT);
    close $fh;

    my $left = $expire - time;
    while ($left > 0) {
	$threads::threads ? threads->yield : sleep 1;

        open $fh, '+<', "$DIR/$addr";
	binmode $fh;
        flock $fh, LOCK_EX;
        my $ch = _readbyte($fh,$lu);
        close $fh;
        $left = $expire - time;

        if ($ch == STATE_NOTIFY) {    # got notify

	    open $fh, '+<', "$DIR/$addr";
	    binmode $fh;
	    flock $fh, LOCK_EX;
	    _writebyte($fh,$lu,STATE_NULL);
	    close $fh;
	    $left = $expire - time;
	    if ($left <= 0 || ($timeout && $timeout < 0)) {
		$left = -1;
	    }

	    # if pwait was called on a stack of locks,
	    # then we must restack the locks
	    while ($unlocks > 1 && plock($obj,$id,$left)) {
		$unlocks--;
	    }
	    return if $unlocks != 1;
            return plock($obj,$id,$left);
        }
	last if $timeout && $timeout < 0;
    }

    # !!! what state should the monitor be left in when a
    # !!! wait call times out?
    
    $! = FAIL_EXPIRED;
    return;
}

sub pnotify {
    my ($obj, $id, $count) = @_;
    $count ||= 1;
    my $lu = _lookup($id);
    my $addr = _addr($obj);

    my $fh;
    open($fh,'+<',"$DIR/$addr") || open($fh,'+>', "$DIR/$addr") || die;
    binmode $fh;
    flock $fh, LOCK_EX;
    seek $fh, 0, SEEK_END;
    my $sz = tell($fh);

    # assert that this monitor holds the resource
    my $ch = _readbyte($fh,$lu);
    if ($ch < STATE_LOCK) {
	carp "Patro::Archy: pnotify called on $obj monitor without lock";
	$! = FAIL_INVALID_WO_LOCK;
	return;
    }

    my @y1 = (0 .. $sz-1);
    my @y = splice @y1, int($sz * rand);
    push @y, @y1;
    my $notified = 0;
    foreach my $y (@y) {
        $ch = _readbyte($fh,$y);
        if ($ch == STATE_WAIT) {
            _writebyte($fh,$y,STATE_NOTIFY);
	    last if ++$notified >= $count && $count > 0;
        }
    }
    close $fh;
    return $notified || "0 but true";
}

sub pstate {
    my ($obj, $id) = @_;
    my $lu = _lookup($id);
    my $addr = _addr($obj);

    my $fh;
    open($fh,'+<',"$DIR/$addr") || return STATE_NULL;
    binmode $fh;
    # no need to lock?
    my $state = _readbyte($fh,$lu);
    close $fh;
    return $state;
}


# extract the $n-th byte from filehandle $fh
sub _readbyte {
    my ($fh,$n) = @_;
    my $b = "\n";
    seek $fh, $n, SEEK_SET;
    my $p = read $fh, $b, 1;
    my $ch = $p ? ord($b) : 0;
    if ($DEBUG) {
	print STDERR "Archy:     readbyte($n) = $ch\n";
    }
    return $ch;
}

# update the $n-th byte of filehandle $fh with chr($val)
sub _writebyte {
    my ($fh,$n,$val) = @_;

    if ($n > -s $fh) {
	# extend the file so that we can write to byte $n
	my $newlen = $n - (-s $fh);
        seek $fh, 0, SEEK_END;
        print $fh "\0" x $newlen;
	if ($DEBUG) {
	    print STDERR "Archy:     extend($newlen)\n";
	}
    }
    seek $fh,0,0;
    my $z1 = seek $fh, $n, 0;
    my $z2 = print $fh chr($val);
    if ($DEBUG) {
	print STDERR "Archy:     writebyte($n,$val)\n";
    }
    $z2;
}

sub _readall {
    my ($fh) = @_;
    my $buffer = '';
    seek $fh, 0, SEEK_SET;
    read $fh, $buffer, 32678;
    if ($DEBUG) {
	print STDERR "Archy:     readall => [",
	    join(" ",map ord,split(//,$buffer)), "]\n";
    }
    return $buffer;
}

1;

=head1 NAME

Patro::Archy - establish norms about exclusive access to references

=cut

# This is not necessarily just for Patro-proxy objects

=head1 DESCRIPTION

At times we want threads and processes to have exclusive access to
some resources, even if they have to wait for it. The C<Patro::Archy>
provides functions to request exclusive access to a resource and to
relinquish control of the resource. It also implements an additional
wait/notify feature.

The functions of C<Patro::Archy> all take the same two first
arguments: a reference -- the resource that will be used exclusively
in one thread or process, and an id that uniquely identifies a
thread or process that seeks exclusive access to a resource.

Like most such locks in Perl,
the locks from this package are advisory -- they can only
prevent access to the resource from other threads and processes
that use the same locking scheme.


=head1 FUNCTIONS

=head2 plock

=head2 $status = plock($object, $id [, $timeout])

Attempts to acquire an exclusive (but advisory) lock on the
reference given by C<$object> for a monitor identified by
C<$id>. Returns true if the lock was successfully acquired.

The monitor id C<$id> is an arbitrary string that identifies
the thread or process that seeks to acquire the resource.
In this function and in the other public functions of
C<Patro::Archy>, there is an implementation limitation
that the monitor id be no more than 20 characters.

If a positive C<$timeout> argument is provided, the function
will give up trying to acquire the lock and return false after
C<$timeout> seconds. If C<$timeout> is negative, the function
call will be treated as a I<non-blocking> lock call, and the
function will return as soon as it can be determined whether
the lock is available.

It is acceptable to call C<plock> for a monitor that already
possesses the lock. Successive lock calls "stack", so that you
must call L<"punlock"> the same number of times that you called
C<plock> on a reference (or provide a C<$count> argument to
L<"punlock">) before it will be released.


=head2 punlock

=head2 $status = punlock($object, $id[, $count])

Releases the lock on reference C<$object> held by the monitor
identified by C<$id>. Returns true on success. A false return
value generally means that the monitor did not have possession
of the lock at the time of the C<punlock> call.

A positive C<$count> argument, if provided, will apply the
unlock operation C<$count> times. Since lock calls from the
same monitor "stack" (see L<"plock">), it may be necessary to
apply the unlock operation more than once to release control of
the reference. A negative C<$count> argument will
release control of the reference unconditionally.


=head2 pwait

=head2 $status = pwait($object, $id [, $timeout])

Releases the lock on reference C<$object> and waits for the
L<"pnotify"> function to be called from another monitor.
After the L<"pnotify"> call is received by the monitor,
the monitor will attempt to acquire the lock on the resource
again. The monitor is only supposed to call this function
when it is in possession of the lock.

Returns true after the lock has been successfully acquired.
Returns false if the function is called while the monitor
does not have the lock on the resource, or if C<$timeout>
is specified and it takes longer than C<$timeout> seconds
to acquire the lock.

=head2 pnotify

=head2 $status = pnotify($object, $id [, $count])

Causes one or more (depending whether C<$count> is specified)
monitors that have previously called L<"pwait"> to wake up and
attempt to reacquire the lock on the resource. The monitor
is supposed to call this function while it is in possession
of the lock. Note that this call does not release the
resource. Returns true on success.


=head2 LIMITATIONS

Currently only works on systems that have a shared-memory
virtual filesystem in C</dev/shm>.

=head1 LICENSE AND COPYRIGHT

MIT License

Copyright (c) 2017, Marty O'Brien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
