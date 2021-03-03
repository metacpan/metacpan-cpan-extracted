use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

############################################################################
# BEWARE! complex stuff!
# to aid with debugging problems:
# - switch on debug mode
# - to see whats going on in direction dir part p:
#   grep for '[dir][p]'
# - to see whats transfering out of direction dir part p into next part/up:
#   grep for '[dir][p>'
#
# basic design
# - we do not have lots of member variables, instead we put everything into
#   new_analyzer as normal variables and declare various $sub = sub ... which
#   use these variables. Thus the variables get bound once to the sub and we
#   don't need to access it with $self->{field}... or so all the time
# - subs and data structures are described in new_analyzer, the most important
#   are
#   - $global_in - this is the sub data method
#   - $part_in   - called from global_in, itself and callbacks to put data
#     into a specific part. Feeds the data in the associated analyzer
#   - $imp_callback - callback for the analyzer of a specific part

############################################################################

package Net::IMP::Cascade;
use base 'Net::IMP::Base';
use fields (
    'parts',    # analyzer objects
    # we do everything with closures inside new_analyzer here, so that the
    # object has only fields for accessing some closures from subs
    'dataf',    # called from sub data
    'closef',   # called from DESTROY
);

use Net::IMP; # constants
use Carp 'croak';
use Scalar::Util 'weaken';
use Hash::Util qw(lock_ref_keys);
use Net::IMP::Debug;
use Data::Dumper;

my %rtypes_implemented_myself = map { $_ => 1 } (
    IMP_PASS,
    IMP_PREPASS,
    IMP_REPLACE,
    IMP_REPLACE_LATER,
    IMP_DENY,
    IMP_DROP,
    #IMP_TOSENDER, # not supported yet
    IMP_LOG,
    IMP_ACCTFIELD,
    IMP_FATAL,
);

sub get_interface {
    my Net::IMP::Cascade $factory = shift;
    my $parts = $factory->{factory_args}{parts};

    # collect interfaces by part
    my @if4part;
    for my $p ( @$parts ) {
	my @if;
	for my $if ( $p->get_interface(@_)) {
	    # $if should require only return types I support
	    push @if,$if
		if ! grep { ! $rtypes_implemented_myself{$_} } @{ $if->[1] };
	}
	@if or return; # nothing in common
	push @if4part,\@if
    }

    # find interfaces which are supported by all parts
    my @common;
    for( my $i=0;$i<@if4part;$i++ ) {
	for my $if_i ( @{ $if4part[$i] } ) {
	    my ($in_i,$out_i) = @$if_i;
	    # check if $if_i matches at least on interface description in
	    # all other parts, e.g. $if_i is same or included in $if_k
	    # - data type/proto: $in_k should be undef or same as $in_i
	    # - return types: $out_i should include $out_k
	    for( my $k=0;$k<@if4part;$k++ ) {
		next if $i == $k; # same
		for my $if_k ( @{  $if4part[$k] } ) {
		    my ($in_k,$out_k) = @$if_k;
		    # should be same data type or $in_k undef
		    next if $in_k and ( ! $in_i or $in_k != $in_i );
		    # $out_i should include all of $out_k
		    my %out_k = map { $_ => 1 } @$out_k;
		    delete @out_k{ @$out_i };
		    next if %out_k; # some in k are not in i

		    # junction if i and k
		    push @common,[ $in_k,$out_i ];
		}
	    }
	}
    }

    # remove duplicates from match
    my (@uniq,%m);
    for( @common ) {
	my $key = ( $_->[0] // '<undef>' )."\0".join("\0",sort @{$_->[1]});
	push @uniq,$_ if ! $m{$key}++;
    }
    return @uniq;
}

sub set_interface {
    my Net::IMP::Cascade $factory = shift;
    my @if = @_;
    my $parts = $factory->{factory_args}{parts};

    my @new_parts;
    for(my $i=0;$i<@$parts;$i++) {
	my $np = $parts->[$i]->set_interface(@if)
	    or return; # cannot use interface
	$np == $parts->[$i] and next; # no change of part
	$new_parts[$i] = $np; # got new factory for part
    }

    return $factory if ! @new_parts; # interface supported by original factory

    # some parts changed, create new factory for this cascade
    for(my $i=0;$i<@$parts;$i++) {
	$new_parts[$i] ||= $parts->[$i]; # copy parts which did not change
    }

    return ref($factory)->new_factory( parts => \@new_parts );
}

sub new_analyzer {
    my ($factory,%args) = @_;

    my $p     = $factory->{factory_args}{parts};
    my $self  = $factory->SUPER::new_analyzer(%args);
    my @imp = map { $_->new_analyzer(%args) } @$p;

    # $parts[$dir][$pi] is the part for direction $dir, analyzer $pi
    # if part is optimized away due to IMP_PASS with IMP_MAXOFFSET
    # $parts[$dir][$pi] contains instead an integer for adjustments
    # from this part
    my @parts;

    # pause/continue handling
    # maintains pause status per part
    my @pause;

    # to make sure we don't leak due to cross-references
    weaken( my $wself = $self );

    my $new_buf = sub {
	lock_ref_keys( my $buf = {
	    start   => 0,  # start of buf relativ to part
	    end     => 0,  # end of buf relativ to part
	    data    => '', # data or undef for replace_later
	    dtype   => 0,  # data type
	    rtype   => IMP_PASS,  # IMP_PASS < IMP_PREPASS < IMP_REPLACE
	    gap     => 0,  # size of gap before buf?
	    gstart  => 0,  # start of buf relativ to cascade
	    gend    => 0,  # end of buf relativ to cascade
	    eof     => 0   # flag if last buf in this direction
	});
	%$buf = ( %$buf, @_ ) if @_;
	return $buf;
    };

    my $new_part = sub {
	lock_ref_keys( my $p = {
	    ibuf => [ &$new_buf ], # buffers, at least one
	    pass          => 0,    # can pass up to ..
	    prepass       => 0,    # can prepass up to ..
	    replace_later => 0,    # will replace_later up to ..
	    adjust        => 0,    # total local adjustments from forwarded bufs
	});
	return $p;
    };

    # initialize @parts
    for( my $i=0;$i<@imp;$i++ ) {
	$parts[0][$i] = $new_part->();       # client -> server, flow 0>1>2>..
	$parts[1][$#imp-$i] = $new_part->(); # server -> client, flow 9>8>7>..
    }

    my $dump_bufs = sub {
	my $bufs = shift;
	my @out;
	for my $i (@_ ? @_: 0..$#$bufs) {
	    my $buf = $bufs->[$i];
	    my $str = ! defined( $buf->{data} ) ? '<undef>' : do {
		local $_ = $buf->{data};
		$_ = substr($_,0,27).'...' if length($_)>30;
		s{([\\\n\r\t[:^print:]])}{ sprintf("\\%03o",ord($1)) }esg;
		$_
	    };
	    push @out, sprintf("#%02d %d..%d%s%s%s %s %s [%d,%d] '%s'",
		$i,
		$buf->{start},$buf->{end}, $buf->{eof} ? '$':'',
		$buf->{gap} ? " +$buf->{gap}":"",
		defined($buf->{data}) ? '':' RL',
		$buf->{dtype},$buf->{rtype},
		$buf->{gstart},$buf->{gend},
		$str
	    );
	}
	return join("\n",@out);
    };
    my $dump_parts = sub {
	my $dir = shift;
	my $out = '';
	for my $pi (@_ ? @_ : 0..$#imp) {
	    my $part = $parts[$dir][$pi];
	    if ( ! $part ) {
		$out .= "part[$dir][$pi] - skip\n";
		next;
	    }
	    $out .= sprintf("part[%d][%d] p|pp|rl=%d|%d|%d ibuf:\n",
		$dir,$pi,$part->{pass},$part->{prepass},$part->{replace_later});
	    my $ib = $part->{ibuf};
	    $out .= $dump_bufs->( $part->{ibuf});
	}
	return $out;
    };

    my $split_buf = sub {
	my ($ibuf,$i,$fwd) = @_;
	my $buf = $ibuf->[$i];
	die "no split for packet types" if $buf->{dtype}>0;

	my $buf_before = $new_buf->(
	    %$buf,
	    eof => 0,
	    end => $buf->{start} + $fwd,  # adjust end
	    defined($buf->{data})
		? ( data => substr($buf->{data},0,$fwd,'') )  # real data
		: (),  # replacement promise
	);
	# gap in buf_before
	$buf->{gap} = 0;
	$buf->{start} = $buf_before->{end};

	# if buf was not changed gend..gstart should reflect the
	# original length of the data
	if ( $buf->{rtype} != IMP_REPLACE ) {
	    $buf_before->{gend} = ( $buf->{gstart} += $fwd );
	} else {
	    # split gstart..gend into full|0 per convention
	    $buf->{gstart} = $buf->{gend};
	}

	# put buf_before before buf in ibuf
	splice(@$ibuf,$i,0,$buf_before);
    };

    my $fwd_collect; # collect bufs which can be forwarded
    my $fwd_up;      # collect what can be passed up
    my $exec_fwd;    # do the collected forwarding to next part or up

    my $global_in;  # function where data gets fed into from outside (sub data)
    my $part_in;    # internal feed into each part

    my $imp_callback;   # synchronization wrapper around callback for analyzers
    my $_imp_callback;  # real callback for the analyzers

    # pass passable bufs in part starting with ibuf[i]
    # returns all bufs which can be passed and strips them from part.ibuf
    $fwd_collect = sub {
	my ($dir,$pi,$i,$r_passed) = @_;
	my $part = $parts[$dir][$pi];
	my $ibuf = $part->{ibuf};
	$DEBUG && debug(
	    "fwd_collect[$dir][$pi]: p=$part->{pass} pp=$part->{prepass} "
	    .$dump_bufs->($ibuf));
	my @fwd;
	for my $pp (qw(pass prepass)) {
	    my $pass = $part->{$pp} or next;
	    for( ;$i<@$ibuf;$i++ ) {
		my $buf = $ibuf->[$i];
		last if ! $buf->{dtype}; # dummy buf
		if ( $pass != IMP_MAXOFFSET and $buf->{start} >= $pass ) {
		    $DEBUG && debug(
			"fwd_collect[$dir][$pi]: reset $pp due to start[$i]($buf->{start})>=$pp($pass)");
		    $part->{$pp} = 0;
		    last;
		}
		die "cannot pass bufs with replace_later"
		    if ! defined $buf->{data};
		if ( $pass == IMP_MAXOFFSET or $buf->{end} <= $pass ) {
		    # whole buffer can be passed
		    $DEBUG && debug(
			"fwd_collect[$dir][$pi]: pass whole buffer[$i] $buf->{start}..$buf->{end}");
		    $buf->{rtype} = IMP_PREPASS if $pp eq 'prepass'
			and $buf->{rtype} == IMP_PASS;
		    push @fwd,[ $pi,$dir,$buf ];

		    # r_passed is set from part_in to track position if data
		    # are passed. In case of prepass we don't pass data but
		    # only put them into fwd
		    next if $r_passed && $pp eq 'prepass';

		    # track what got passed for part_in
		    $$r_passed = $buf->{end} if $r_passed;

		    # remove passed data from ibuf, if ! r_passed also prepassed
		    # data (called from imp_callback)
		    shift(@$ibuf);
		    $i--;

		    if ( ! @$ibuf ) {
			if ( $part->{pass} == IMP_MAXOFFSET || $buf->{eof} ) {
			    # part done, skip it in the future
			    push @fwd,[$pi,$dir,undef]; # buf = undef is special
			}
			# insert dummy
			@$ibuf = $new_buf->(
			    start  => $buf->{end},
			    end    => $buf->{end},
			    gstart => $buf->{gend},
			    gend   => $buf->{gend},
			    # keep type for streaming data
			    $buf->{dtype} < 0 ? ( dtype => $buf->{dtype} ):(),
			);
			last;
		    }

		} else {
		    # only part of buffer can be passed
		    # split buffer and re-enter loop, this will foreward the
		    # first part and keep the later part
		    $DEBUG && debug(
			"fwd_collect[$dir][$pi]: need to split buffer[$i]: $buf->{start}..$pass..$buf->{end}");
		    $split_buf->($ibuf,$i,$pass - $buf->{start});
		    redo; # don't increase $i!
		}
	    }
	}
	return @fwd;
    };

    $fwd_up = sub {
	my ($dir,$buf) = @_;
	if ( $buf->{gstart} == $buf->{gend} && ! $buf->{gap}
	    && $buf->{rtype} ~~ [ IMP_PASS, IMP_PREPASS ]) {
	    # don't repeat last (pre)pass because of empty buffer
	    return;
	}

	return [
	    $buf->{rtype},
	    $dir,
	    $buf->{gend},
	    ($buf->{rtype} == IMP_REPLACE) ? ( $buf->{data} ):()
	];
    };

    $exec_fwd = sub {
	my @fwd = @_;
	if (@fwd>1) {
	    $DEBUG && debug("trying to merge\n".join("\n", map {
		! defined $_->[0]
		    ? "<cb>"
		    : "fwd[$_->[1]][$_->[0]] " .
			( $_->[2] ? $dump_bufs->([$_->[2]]) : '<pass infinite>')
	    } @fwd));
	    # try to compress
	    my ($lpi,$ldir,$lbuf);
	    for( my $i=0;$i<@fwd;$i++ ) {
		if ( ! defined $fwd[$i][0] || ! defined $fwd[$i][2]) {
		    $lpi = undef;
		    next;
		}
		if ( ! defined $lpi
		    or $lpi  != $fwd[$i][0]
		    or $ldir != $fwd[$i][1] ) {
		    ($lpi,$ldir,$lbuf) = @{$fwd[$i]};
		    next;
		}

		my $buf = $fwd[$i][2];

		if ( not $buf->{gap}
		    and $buf->{dtype} < 0
		    and $buf->{start} == $lbuf->{end}
		    and $buf->{rtype} == $lbuf->{rtype}
		    and $buf->{dtype} == $lbuf->{dtype}
		) {
		    if ( $buf->{rtype} == IMP_REPLACE ) {
			if ( $lbuf->{gend} == $buf->{gend} ) {
			    # same global end, merge data
			    $lbuf->{data} .= $buf->{data};
			} elsif ( $buf->{data} ne '' or $lbuf->{data} ne '' ) {
			    # either one not empty, no merge
			    next;
			}
		    } else {
			# unchanged, append
			$lbuf->{data} .= $buf->{data};
		    }
		    $DEBUG && debug("merge bufs ".$dump_bufs->([$lbuf,$buf]));
		    $lbuf->{gend} = $buf->{gend};
		    $lbuf->{end}  = $buf->{end};
		    $lbuf->{eof}  = $buf->{eof};
		    splice(@fwd,$i,1,());
		    $i--;
		    next;

		} else {
		    ($lpi,$ldir,$lbuf) = @{$fwd[$i]};
		    next;
		}
	    }
	}
	while ( my $fwd = shift(@fwd)) {
	    my $npi = my $pi = shift(@$fwd);
	    if ( ! defined $npi ) {
		# propagate prepared IMP callback
		$wself->run_callback($fwd);
		next;
	    }

	    my ($dir,$buf) = @$fwd;

	    if ( $buf ) {
		my $np;
		my $adjust = 0;
		while (1) {
		    $npi += $dir?-1:+1;
		    last if $npi<0 or $npi>=@imp;
		    last if ref( $np = $parts[$dir][$npi] );
		    $adjust += $np;
		    $DEBUG && debug("skipping pi=$npi");
		}

		if ( $buf->{eof} ) {
		    # add pass infinite to fwd to propagate eof
		    push @fwd,[ $pi,$dir,undef ];
		}
		if ( $np ) {
		    # feed into next part
		    my $nib = $np->{ibuf};
		    # adjust start,end based on end of npi and gap
		    $buf->{start} = $nib->[-1]{end} + $buf->{gap} + $adjust;
		    $buf->{end} = $buf->{start} + length($buf->{data});
		    $DEBUG && debug(
			"fwd_next[$dir][$pi>$npi] ".$dump_bufs->([$buf]));
		    $part_in->($npi,$dir,$buf);
		} else {
		    # output from cascade
		    my $cb = $fwd_up->($dir,$buf) or next;
		    $DEBUG && debug(
			"fwd_up[$dir][$pi>>] ".$dump_bufs->([$buf]));
		    $wself->run_callback($cb);
		}

	    # special - part is done with IMP_PASS IMP_MAXOFFSET
	    } else {
		# skip if we had a pass infinite already
		next if ! ref $parts[$dir][$pi];

		$parts[$dir][$pi] = $parts[$dir][$pi]->{adjust};
		if ( grep { ref($_) } @{ $parts[$dir] } ) {
		    # we have other unfinished parts, skip only this part
		    $DEBUG && debug(
			"part[$dir][$pi>$npi] will be skipped in future, adjust=$parts[$dir][$pi]");
		} else {
		    # everything can be skipped
		    $DEBUG && debug(
			"part[$dir][$pi>>] all parts will be skipped in future");
		    # pass rest
		    $wself->run_callback([ IMP_PASS,$dir,IMP_MAXOFFSET ]);
		}
	    }
	}
    };

    # the data function
    # called from sub data on new data and from $process when data are finished
    # in on part and should be transferred into the next part
    #  $pi    - index into parts
    #  $dir   - direction (e.g. target part is $parts[$dir][$pi])
    #  $buf   - new buffer from $new_buf->() which might be merged with existing
    $part_in = sub {
	my ($pi,$dir,$buf) = @_;
	$DEBUG && debug( "part_in[$dir][$pi]: ".$dump_bufs->([$buf]));

	my $part = $parts[$dir][$pi];
	my $ibuf = $part->{ibuf};
	my $lbuf = $ibuf->[-1];
	my $lend = $lbuf->{end};

	# some sanity checks
	if(1) {
	    die "data after eof [$dir][$pi] ".$dump_bufs->([$lbuf,$buf])
		if $lbuf->{eof};
	    if ( $buf->{start} != $lend ) {
		if ( $buf->{start} < $lend ) {
		    die "overlapping data off($buf->{start})<last.end($lend) in part[$dir][$pi]";
		} elsif ( ! $buf->{gap} ) {
		    die "gap should be set because off($buf->{start})>last.end($lend) in part[$dir][$pi]"
		}
	    } elsif ( $buf->{gap} ) {
		die "gap specified even if off($buf->{start}) == last.end"
	    }
	    $part->{pass} == IMP_MAXOFFSET and die
		"pass infinite should have been optimized by removing part[$dir][$pi]";
	}

	# add data to buf
	if ( $lbuf->{data} eq '' and $lbuf->{rtype} == IMP_PASS ) {
	    # empty dummy buffer
	    $DEBUG && debug("part_in[$dir][$pi]: replace dummy buffer");
	    @$ibuf == 1 or die "empty dummy buffer should only be at beginning";
	    @$ibuf = $buf;

	} elsif ( ! $buf->{gap}
	    and $buf->{data} eq ''
	    and $buf->{rtype} == $lbuf->{rtype}
	    and $buf->{dtype} == $lbuf->{dtype}
	    and $buf->{dtype} < 0
	    and ! $buf->{eof}
	    ) {
	    # just update eof,[g]end of lbuf
	    $DEBUG && debug(
		"part_in[$dir][$pi]: set lbuf end=$buf->{end} gend=$buf->{gend}");
	    $lbuf->{end}  = $buf->{end};
	    $lbuf->{gend} = $buf->{gend};
	    # nothing to do with these empty data
	    $DEBUG && debug("part_in[$dir][$pi] nothing to do on empty buffer");
	    return;

	} else {
	    # add new buf
	    $DEBUG && debug("part_in[$dir][$pi]: add new buffer");
	    push @$ibuf,$buf;
	}

	# determine what can be forwarded immediatly
	my @fwd = $fwd_collect->($dir,$pi,$#$ibuf,\$lend);

	if ( $buf->{eof} ? $lend <= $buf->{end} : $lend < $buf->{end} ) {
	    # send new data to the analyzer
	    my $rl = $part->{replace_later};
	    for(@$ibuf) {
		next if $_->{start} < $lend;
		die "last_end should be on buffer boundary"
		    if $_->{start} > $lend;
		$lend = $_->{end};
		$DEBUG && debug(
		   "analyzer[$dir][$pi] << %d bytes %s \@%d%s -> last_end=%d",
		    $_->{end} - $_->{start},
		    $_->{dtype},
		    $_->{start},$_->{gap} ? "(+$_->{gap})":'',
		    $lend
		);
		$imp[$pi]->data($dir,
		    $_->{data},
		    $_->{gap} ? $_->{start}:0,
		    $_->{dtype}
		);
		$imp[$pi]->data($dir,'',0, $_->{dtype})
		    if $buf->{eof} && $_->{data} ne '';
		$rl or next;
		if ( $rl == IMP_MAXOFFSET or $rl>= $lend ) {
		    $buf->{data} = undef;
		} else {
		    $rl = $part->{replace_later} = 0; # reset
		}
	    }
	} else {
	    $DEBUG && debug(
		"nothing to analyze[$dir][$pi]: last_end($lend) < end($buf->{end})");
	}

	# forward data which can be (pre)passed
	$exec_fwd->(@fwd) if @fwd;
    };

    $_imp_callback = sub {
	my $pi = shift;

	my @fwd;
	for my $rv (@_) {
	    my $rtype = shift(@$rv);

	    if ( $rtype ~~ [ IMP_FATAL, IMP_DENY, IMP_DROP, IMP_ACCTFIELD ]) {
		$DEBUG && debug("callback[.][$pi] $rtype @$rv");
		$wself->run_callback([ $rtype, @$rv ]);

	    } elsif ( $rtype == IMP_LOG ) {
		my ($dir,$offset,$len,$level,$msg,@extmsg) = @$rv;
		$DEBUG && debug(
		    "callback[$dir][$pi] $rtype '$msg' off=$offset len=$len lvl=$level");
		# approximate offset to real position
		my $newoff = 0;
		my $part = $parts[$dir][$pi];
		for ( @{$part->{ibuf}} ) {
		    if ( $_->{start} <= $offset ) {
			$offset = ( $_->{rtype} == IMP_REPLACE )
			    ? $_->{gstart}
			    : $_->{gstart} - $_->{start} + $offset;
		    } else {
			last
		    }
		}
		$wself->run_callback([ IMP_LOG,$dir,$offset,$len,$level,$msg,@extmsg ]);

	    } elsif ( $rtype == IMP_PAUSE ) {
		my $dir = shift;
		$DEBUG && debug("callback[$dir][$pi] $rtype");
		next if $pause[$pi];
		$pause[$dir][$pi] = 1;
		$wself->run_callback([ IMP_PAUSE ]) if grep { $_ } @pause > 1;

	    } elsif ( $rtype == IMP_CONTINUE ) {
		my $dir = shift;
		$DEBUG && debug("callback[$dir][$pi] $rtype");
		delete $pause[$dir][$pi];
		$wself->run_callback([ IMP_CONTINUE ])
		    if not grep { $_ } @{$pause[$dir]};

	    } elsif ( $rtype ~~ [ IMP_PASS, IMP_PREPASS ] ) {
		my ($dir,$offset) = @$rv;
		$DEBUG && debug("callback[$dir][$pi] $rtype $offset");
		ref(my $part = $parts[$dir][$pi]) or next; # part skippable?
		if ( $rtype == IMP_PASS ) {
		    next if $part->{pass} == IMP_MAXOFFSET; # no change
		    if ( $offset == IMP_MAXOFFSET ) {
			$part->{pass} = IMP_MAXOFFSET;
			$part->{prepass} = 0; # pass >= prepass
		    } elsif ( $offset > $part->{pass} ) {
			$part->{pass} = $offset;
			if ( $part->{prepass} != IMP_MAXOFFSET
			    and $part->{prepass} <= $offset ) {
			    $part->{prepass} = 0; # pass >= prepass
			}
		    } else {
			next; # no change
		    }
		} else {  # IMP_PREPASS
		    next if $part->{prepass} == IMP_MAXOFFSET; # no change
		    if ( $offset == IMP_MAXOFFSET ) {
			$part->{prepass} = IMP_MAXOFFSET;
		    } elsif ( $offset > $part->{prepass} ) {
			$part->{prepass} = $offset;
		    } else {
			next; # no change
		    }
		}

		# pass/prepass got updated, so we might pass some more data
		push @fwd, $fwd_collect->($dir,$pi,0);

	    } elsif ( $rtype == IMP_REPLACE ) {
		my ($dir,$offset,$newdata) = @$rv;
		$DEBUG && debug(
		    "callback[$dir][$pi] $rtype $dir $offset len=%d",
		    length($newdata));
		ref(my $part = $parts[$dir][$pi])
		    or die "called replace for passed data";
		my $ibuf = $part->{ibuf};

		# sanity checks
		die "called replace although pass=IMP_MAXOFFSET" if ! $part;
		die "no replace with IMP_MAXOFFSET" if $offset == IMP_MAXOFFSET;
		die "called replace for already passed data"
		    if $ibuf->[0]{start} > $offset;

		while (@$ibuf) {
		    my $buf = $ibuf->[0];
		    if ( $offset >= $buf->{end} ) {
			# replace complete buffer
			$DEBUG && debug(
			    "replace complete buf $buf->{start}..$buf->{end}");
			if ( ! defined($buf->{data})
			    or $buf->{data} ne $newdata ) {
			    $buf->{rtype} = IMP_REPLACE;
			    $buf->{data} = $newdata;
			    $part->{adjust} +=
				length($newdata) - $buf->{end} + $buf->{start};
			    $newdata = ''; # in the next buffers replace with ''
			}
			push @fwd,[ $pi,$dir,$buf ];
			shift(@$ibuf);
			if ( ! @$ibuf ) {
			    # all bufs eaten
			    die "called replace for future data"
				if $buf->{end}<$offset;
			    @$ibuf = $new_buf->( %$buf,
				data   => '',
				start  => $buf->{end},
				end    => $buf->{end},
				gstart => $buf->{gend},
				# packet types cannot get partial replacement
				# at end
				$buf->{dtype} > 0 ? ( dtype => 0 ):()
			    );
			    # remove eof from buf in @fwd because we added
			    # new one
			    $fwd[-1][2]{eof} = 0;
			    last;
			}
			last if $buf->{end} == $offset;
		    } else {
			# split buffer and replace first part
			$DEBUG && debug(
			    "replace - split buf $buf->{start}..$offset..$buf->{end}");
			$split_buf->($ibuf,0,$offset-$buf->{start});
			redo;
		    }
		}

	    } elsif ( $rtype == IMP_REPLACE_LATER ) {
		my ($dir,$offset) = @$rv;
		$DEBUG && debug("callback[$dir][$pi] $rtype $offset");
		ref(my $part = $parts[$dir][$pi])
		    or die "called replace for passed data";
		my $ibuf = $part->{ibuf};
		$_->{replace_later} == IMP_MAXOFFSET and next; # no change

		# sanity checks
		die "called replace_later although pass=IMP_MAX_OFFSET"
		    if ! $part;
		die "called replace for already passed data" if
		    $offset != IMP_MAXOFFSET and
		    $ibuf->[0]{start} > $offset;

		if ( $offset == IMP_MAXOFFSET ) {
		    $_->{replace_later} = IMP_MAXOFFSET;
		    # change all to replace_later
		    $_->{data} = undef for(@$ibuf);
		    next;
		} elsif ( $offset <= $part->{replace_later} ) {
		    # no change
		} else {
		    $part->{replace_later} = $offset;
		    for(@$ibuf) {
			defined($_->{data}) or next; # already replace_later
			my $len = length($_->{data}) or last; # dummy buffer
			if ( $_->{start} + $len <= $offset ) {
			    $_->{data} = undef;
			} else {
			    $part->{replace_later} = 0;
			    last;
			}
		    }
		}
	    } else {
		$DEBUG && debug("callback[.][$pi] $rtype @$rv");
		die "don't know how to handle rtype $rtype";
	    }
	}

	# pass to next part/output
	$exec_fwd->(@fwd) if @fwd;
    };

    # While we are in $part_in function we will only spool callbacks and process
    # them at the end. Otherwise $dataf might cause call of callback which then
    # causes call of dataf etc - which makes debugging a nightmare.

    my $collect_callbacks;
    $global_in = sub {
	my ($dir,$data,$offset,$dtype) = @_;

	my %buf = (
	    data  => $data,
	    dtype => $dtype // IMP_DATA_STREAM,
	    rtype => IMP_PASS,
	    eof   => $data eq '',
	);

	my $adjust = 0;
	my $pi = $dir ? $#imp:0; # enter into first or last part
	my $np;
	while (1) {
	    ref( $np = $parts[$dir][$pi] ) and last;
	    $adjust += $np;
	    $pi += $dir?-1:1;
	    if ( $pi<0 or $pi>$#imp ) {
		$DEBUG && debug("all skipped");
		if ( my $cb = $fwd_up->($dir,$new_buf->(%buf))) {
		    $self->run_callback($cb);
		}
		return;
	    }
	}

	return if ! ref $np; # got IMP_PASS IMP_MAXOFFSET for all

	my $ibuf_end = $np->{ibuf}[-1]{gend};
	if ( ! $offset ) {
	    # no gap between data
	    $buf{gstart} = $ibuf_end;
	} elsif ( $offset < $ibuf_end ) {
	    die "overlapping data";
	} elsif ( $offset > $ibuf_end ) {
	    # gap between data
	    $buf{gstart} = $offset;
	    $buf{gap} = $offset - $ibuf_end;
	} else {
	    # there was no need for giving offset
	    $buf{gstart} = $ibuf_end;
	}
	$buf{gend}  = $buf{gstart} + length($data);
	$buf{start} = $buf{gstart} + $adjust;
	$buf{end}   = $buf{gend} + $adjust;

	$collect_callbacks ||= [];
	$part_in->( $pi,$dir, $new_buf->(%buf));

	while ( my $cb = shift(@$collect_callbacks)) {
	    $_imp_callback->(@$cb);
	}
	$collect_callbacks = undef
    };

    # wrapper which spools callbacks if within dataf
    $imp_callback = sub {
	if ( $collect_callbacks ) {
	    # only spool and execute later
	    push @$collect_callbacks, [ @_ ];
	    return;
	}
	return $_imp_callback->(@_)
    };

    # setup callbacks
    $imp[$_]->set_callback( $imp_callback,$_ ) for (0..$#imp);

    # make some closures available within methods
    $self->{dataf} = $global_in;
    $self->{closef} = sub {
	$global_in = $part_in = $imp_callback = $_imp_callback = undef;
	@parts = ();
    };
    return $self;
}

sub data {
    my $self = shift;
    $self->{dataf}(@_);
}

sub DESTROY {
    my $closef = shift->{closef};
    $closef->() if $closef;
}


1;

__END__

=head1 NAME

Net::IMP::Cascade - manages cascade of IMP filters

=head1 SYNOPSIS

    use Net::IMP::Cascade;
    use Net::IMP::Pattern;
    use Net::IMP::SessionLog;
    ...
    my $imp = Net::IMP::Cascade->new_factory( parts => [
	Net::IMP::Pattern->new_factory..,
	Net::IMP::SessionLog->new_factory..,
    ]);

=head1 DESCRIPTION

C<Net::IMP::Cascade> puts multiple IMP analyzers into a cascade.
Data get analyzed starting with part#0, then part#1... etc for direction 0
(client to server), while for direction 1 (server to client) the data get
analyzed the opposite way, ending in part#0.

The only argument special to C<new_factory> is C<parts>, which is an array
reference of L<Net::IMP> factory objects.
When C<new_analyzer> gets called on the L<Net::IMP::Cascade>> factory,
C<new_analyzer> will be called on the factory objects of the parts too, keeping
all arguments, except C<parts>.

=head1 TODO

Currently IMP_TOSENDER is not supported

=head1 BUGS

The code is way more complex than I originally hoped, even after a nearly
complete rewrite of the innards. So probably the problem itself is complex.
For debugging help see comments on top of code.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
