use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

package Net::IMP::ProtocolPinning;
use base 'Net::IMP::Base';
use fields (
    'buf',            # buffered data for each direction
    'off_buf',        # start of buf[dir] relativ to input stream
    'off_passed',     # offset up to which already passed
    'ruleset',        # active rules per dir
    'paused',         # if there is active IMP_PAUSE for dir
    # if allow_dup already matched packets are put with key md5(seed+packet)
    # and rule number as value into matched[dir]{...}
    'matched',        # hash of already matched packets
    'matched_seed',   # random seed for matched hash (new for each analyzer)
);

use Net::IMP; # import IMP_ constants
use Net::IMP::Debug;
use Storable 'dclone';
use Data::Dumper;
use Carp 'croak';
use Digest::MD5 'md5';

sub INTERFACE { return ([
    undef, # we can stream and packets, although they behave differently
    [
	IMP_PASS,   # pass data unchanged
	IMP_DENY,   # deny if rule is not matched
	# send pause/continue if last rule of dir is reached and
	# max_unbound is undef
	IMP_PAUSE,
	IMP_CONTINUE,
    ]
])}

sub _compile_cfg {
    my %args = @_;

    my $ignore_order = delete $args{ignore_order};
    my $allow_reorder = delete $args{allow_reorder};
    my $r = delete $args{rules} or die "rules need to be given\n";
    my $max_unbound  = delete $args{max_unbound};

    if ($max_unbound) {
	die "max_unbound should be [max0,max1]\n" if @$max_unbound>2;
	for (0,1) {
	    defined $max_unbound->[$_] or next;
	    die "max_unbound[$_] should be number >=0\n"
		if $max_unbound->[$_] !~m{^\d+$};
	}
    }

    # compile $args{rules} into list of rulesets per dir
    # $ruleset[$dir][$i] -> [r1,r2,.] | undef
    # - [ r1,r2.. ] - these rules can match, multiple rules at a time are only
    #   possible if reorder. The rules will be tried in the given order until
    #   one matches.
    # - undef - no data for this dir allowed at this stage. If ignore_order
    #   there can be rules for each dir at the same time, else not.
    # When processing data it will remove completely matched rules, but
    # put rules which might match more (e.g. data<rxlen) at the beginning.
    # If no more rules are open inside a ruleset it will remove the ruleset
    # and then
    # - if there is a next ruleset for the same dir continue with it
    #   (e.g no change after removing the done ruleset)
    # - if there is no next ruleset (e.g. all rules done or next is undef)
    #   remove any undef set from the other dir
    # It will remove the ruleset of no more open rules are inside.

    my @ruleset = ([],[]);
    my $lastdir;
    for (my $i=0;$i<@$r;$i++) {
	my $dir = $r->[$i]{dir};
	die "rule$i.dir must be 0|1\n" unless ($dir//-1 ) ~~ [0,1];
	die "rule$i.rxlen must be >0\n" unless ($r->[$i]{rxlen}||0)>0;
	my $rx = $r->[$i]{rx};
	die "rule$i.rx should be regex\n" if ref($rx) ne 'Regexp';
	die "rule$i.rx should not match empty string\n" if '' ~~ $rx;

	if ( ! $ignore_order ) {
	    # initial rule or direction change
	    $lastdir //= $dir ? 0:1;
	    if ( $lastdir != $dir ) {
		push @{ $ruleset[$dir] }, []; # new ruleset
		push @{ $ruleset[$lastdir] },undef; # no more allowd
		$lastdir = $dir;
	    }
	} elsif ( not @{ $ruleset[$dir] } ) {
	    # initialize when ignore_order
	    push @{ $ruleset[$dir] },[];
	}

	# set ruleset to this rule
	# if allow_reorder try to add it to existing ruleset
	if ( $allow_reorder
	    or ! @{ $ruleset[$dir][-1] } ) {
	    push @{ $ruleset[$dir][-1] },$i;
	} else {
	    push @{ $ruleset[$dir] },[ $i ];
	}
    }

    return (
	rules => $r,
	ruleset => \@ruleset,
	allow_dup => $args{allow_dup},
	max_unbound => $max_unbound,
	%args,
    );
}

sub new_factory {
    my $class = shift;
    return $class->SUPER::new_factory( _compile_cfg(@_));
}

sub validate_cfg {
    my ($class,%args) = @_;
    my @err;
    push @err,$@ if ! eval { my @x = _compile_cfg(%args) };
    delete @args{qw/rules max_unbound ignore_order allow_dup allow_reorder/};
    push @err,$class->SUPER::validate_cfg(%args);
    return @err;
}

# create new analyzer object
sub new_analyzer {
    my ($factory,%args) = @_;

    my $fargs = $factory->{factory_args};
    my Net::IMP::ProtocolPinning $self = $factory->SUPER::new_analyzer(
	%args,

	# buffer per direction
	buf => [ '','' ],

	# offset for buffer per direction
	off_buf => [0,0],

	# amount of data already passed
	off_passed => [0,0],

	# clone ruleset because we will modify it
	ruleset => dclone($fargs->{ruleset}),

	# hash of already matched packets (per dir) if allow_dup
	matched => $fargs->{allow_dup} ? [] : undef,
	# seed for hashing matched packets, gets initialized on first use
	matched_seed => undef,
    );

    return $self;
}


# matches buffer against rule
# if match impossible returns ()
# if no match, but might by possible if more data are added returns (0,0)
# if matched and data got removed because bufsize >=rxlen returns (size,size)
# if matched and data are still in buffer (match may be longer) returns (size,0)
sub _match_stream {
    my ($r,$rbuf) = @_;
    if ( $DEBUG ) {
	my ($pkg,undef,$line) = caller;
	debug("try match from=%s[%d] rxlen=%d rx=%s buf=%d/'%s'",
	    $pkg,$line, $r->{rxlen},$r->{rx},length($$rbuf),$$rbuf);
    }
    my $lbuf = length($$rbuf);
    if ($r->{rxlen} <= $lbuf ) {
	if ( substr($$rbuf,0,$r->{rxlen}) =~s{\A$r->{rx}}{} ) {
	    my $lm = $lbuf - length($$rbuf);
	    $DEBUG && debug("final match of $lm in $r->{rxlen} bytes");
	    return ($lm,$lm)  # (matched,removed=matched)
	}
	$DEBUG && debug("final failed match in $r->{rxlen} bytes");
	return; # could never match because rxlen reached
    } else {
	if ( $$rbuf =~m{\A$r->{rx}}g ) {
	    # might match later again and more
	    my $lm = pos($$rbuf);
	    $DEBUG && debug("preliminary match of $lm in $lbuf bytes");
	    return ($lm,0); # (matched,removed=0)
	}
	$DEBUG && debug("preliminary failed match in $lbuf bytes");
	return (0,0); # could match if more data
    }
}

# like _match_stream but matches rx against whole packet.
# result can either be final (size,size) or never ()
sub _match_packet {
    my ($r,$rbuf) = @_;
    # try to match full packet
    my $len = length($$rbuf);
    return if $r->{rxlen} < $len; # could not match full packet
    return $$rbuf =~m{\A$r->{rx}\Z} ? ($len,$len) : ();
}

sub data {
    my Net::IMP::ProtocolPinning $self = shift;
    my ($dir,$data,$offset,$type) = @_;

    # buf gets removed at final reply
    if ( ! $self->{buf} ) {
	# we gave already the final reply
	$DEBUG && debug("data[$dir] after final reply");
	return;
    }

    # never did IMP_PASS into future, so no offset allowed
    $offset and die "no offset allowed";

    my $rs = $self->{ruleset}[$dir];   # [r]ule[s]et
    my $rules = $self->{factory_args}{rules};
    my $match = $type>0 ? \&_match_packet:\&_match_stream;

    if ($data eq '' ) {
	# eof - remove leading rule with extendable match and then
	# check if all rules are done
	$DEBUG && debug("eof dir=%d rules=%s", $dir,
	    Data::Dumper->new([$self->{ruleset}])->Indent(0)->Terse(1)->Dump);

	if ( @$rs and my $match_in_progress =
	    $self->{off_passed}[$dir] - $self->{off_buf}[$dir] ) {
	    # rule done
	    $self->{off_buf}[$dir] = $self->{off_passed}[$dir];
	    $self->{buf}[$dir] = '';
	    # remove matched rule
	    # don't care for duplicates, they won't come anymore
	    shift(@{$rs->[0]});
	    # remove ruleset if empty
	    if (! @{$rs->[0]}) {
		shift(@$rs);
		# switch to other dir if this dir is done for now
		if ( ! @$rs || ! $rs->[0] ) {
		    my $ors = $self->{ruleset}[$dir?0:1];
		    shift @$ors if @$ors && ! $ors->[0];
		}
		goto CHECK_DONE if ! @$rs;
	    }
	}
	# still unmatched rules but we have eof, thus no more rules
	# can match on this dir
	if ( my ($r) = grep { $_ } @$rs ) {
	    $self->{buf} = undef;
	    $self->run_callback([
		IMP_DENY,
		$dir,
		"eof on $dir but unmatched rule#@{$r}"
	    ]);
	} else {
	    # no more rules on eof side
	    # as long as further rules on other side gets matched everything
	    # is fine
	}
	return;
    }

    # collect maximal offset to pass, will pass in PASS_AND_RETURN
    my $pass_until;

    NEXT_RULE:
    $DEBUG && debug("next rule dir=%d rules=%s |data=%d/'%s'",
	$dir,Data::Dumper->new([$self->{ruleset}])->Indent(0)->Terse(1)->Dump,
	length($data),substr($data,0,100));

    if ( ! @$rs ) {
	# no (more) rules for $dir, accumulate data until all rules for other
	# direction are completed
	$self->{buf}[$dir] eq '' or die "buffer should be empty";

	# check if other side has matched already with last rule
	my $odir = $dir ? 0:1;
	my $ors = $self->{ruleset}[$odir];
	if ( @$ors == 1 and @{$ors->[0]} == 1
	    and $self->{off_passed}[$odir] - $self->{off_buf}[$odir] >0 ) {
	    shift(@$ors);
	    goto CHECK_DONE;
	}

	$self->{off_buf}[$dir] += length($data);

	my $max_unbound = $self->{factory_args}{max_unbound};
	$max_unbound = $max_unbound && $max_unbound->[$dir];
	if ( ! defined $max_unbound ) {
	    $DEBUG && debug(
		"buffer data for dir $dir because buffering not bound");
	    if ( ! $self->{paused}[$dir] ) {
		# ask data provider to stop sending data
		$self->{paused}[$dir] = 1;
		$self->run_callback([ IMP_PAUSE, $dir ]);
	    }
	    # if pass_until>0 we had something to pass
	    goto PASS_AND_RETURN;
	}

	my $unbound = $self->{off_buf}[$dir] - $self->{off_passed}[$dir];
	$DEBUG && debug("dir=%d off=%d passed=%d -> unbound=%d",
	    $dir,$self->{off_buf}[$dir],$self->{off_passed}[$dir],$unbound);
	if ( $unbound <= $max_unbound ) {
	    $DEBUG && debug("buffer data for dir $dir because ".
		"unbound($unbound)<=max_unbound($max_unbound)");
	    goto PASS_AND_RETURN;
	}

	$self->{buf} = undef;
	$self->run_callback([
	    IMP_DENY,
	    $dir,
	    "unbound buffer size=$unbound > max_unbound($max_unbound)"
	]);
	return;
    }

    # append new data to buf, for packet data we work directly with $data
    unless ( $type > 0 ) {
	$self->{buf}[$dir] .= $data;
	$data = '';
    }

    my $crs = $rs->[0]; # crs - [c]urrent [r]ule[s]et
    if ( ! $crs ) {
	# data from $dir are not allowed at this stage

	# finish a preliminary match on the other side and then try again
	my $odir = $dir ? 0:1;
	my $ors = $self->{ruleset}[$odir];
	if ( @$ors and $ors->[0] and my $omatch_in_progress
	    = $self->{off_passed}[$odir] - $self->{off_buf}[$odir] ) {
	    $DEBUG && debug("finish preliminary match on $odir");
	    $self->{off_buf}[$odir] = $self->{off_passed}[$odir];
	    substr($self->{buf}[$odir],0,$omatch_in_progress,'');
	    shift(@{$ors->[0]});
	    if ( ! @{$ors->[0]} ) {
		shift(@$ors); # ruleset done
		shift(@$rs) if ! @$ors or ! $ors->[0]; # switch dir
		goto CHECK_DONE if ! @$ors && ! @$rs;
		goto NEXT_RULE; # and try again
	    }
	}

	# ignore if it is a duplicate packet
	# duplicate checking is only done for packet types
	if ( $type>0 and $self->{matched} and $self->{buf}[$dir] eq ''
	    and my $matched = $self->{matched}[$dir] ) {
	    my $hpkt = md5($self->{matched_seed} . $data);
	    if ( defined( my $r = $matched->{$hpkt} )) {
		$DEBUG && debug("ignored DUP[$dir] for rule $r");
		$pass_until = $self->{off_passed}[$dir]
		    = $self->{off_buf}[$dir] += length($data);
		goto PASS_AND_RETURN;
	    }
	}
	$DEBUG && debug("data[$dir] but <undef> rule -> DENY");
	$self->{buf} = undef;
	$self->run_callback([ IMP_DENY, $dir, "rule#"
	    .( $self->{ruleset}[$dir?0:1][0][0] )." data from wrong dir $dir"
	]);
	return;
    }

    # if there was a last match try to extend it or to mark rule as done
    if ( my $match_in_progress =
	$self->{off_passed}[$dir] - $self->{off_buf}[$dir] ) {
	# last rule matched already
	unless ( $type>0 ) {
	    # try to extend match for streams
	    my ($matched,$removed) =
		$match->($rules->[$crs->[0]],\$self->{buf}[$dir]);
	    die "expected $crs->[0] to match" if ! $matched;
	    if ( $removed ) {
		# rule finished, probably because rxlen reached
		$DEBUG && debug("completed preliminary match rule $crs->[0]");
		$self->{off_buf}[$dir] += $removed;
		if ( $removed > $match_in_progress ) {
		    $pass_until = $self->{off_passed}[$dir]
			= $self->{off_buf}[$dir];
		}
		# no return, might match more

	    } elsif ( $matched > $match_in_progress ) {
		# keep rule open but issue extended IMP_PASS
		$DEBUG && debug("extended preliminary match rule $crs->[0]");
		$pass_until = $self->{off_passed}[$dir]
		    = $self->{off_buf}[$dir]+$matched;
		goto PASS_AND_RETURN; # need more data
	    } else {
		# keep rule open waiting for more data
		$DEBUG && debug("still preliminary(?) match rule $crs->[0]");
		goto PASS_AND_RETURN; # need more data
	    }

	} else {
	    # stream followed by packet, so rule cannot be extended
	    # remove from buf until end of last match
	    $DEBUG && debug("finished match rule $crs->[0] on packet $type");
	    substr($self->{buf}[$dir],0,$match_in_progress,'');
	    $self->{off_buf}[$dir] = $self->{off_passed}[$dir];
	}

	# match of previously matching rule done
	# remove it and continue with next rule if there are more data
	shift(@$crs);
	if (! @$crs) {
	    shift(@$rs);
	    # switch to other dir if this dir is done for now
	    if ( ! @$rs || ! $rs->[0] ) {
		my $ors = $self->{ruleset}[$dir ? 0:1];
		shift @$ors if @$ors && ! $ors->[0];
		goto CHECK_DONE if ! @$ors && ! @$rs;
	    }
	}
	if ( $type>0 or $self->{buf}[$dir] ne '' ) {
	    # unmatched data exist in data/buf
	    if ( ! @$rs ) {
		# all rules done from this direction, put back all
		# from buf to $data before calling NEXT_RULE
		$data = $self->{buf}[$dir];
		$self->{buf}[$dir] = '';
	    }
	    goto NEXT_RULE;
	}
	goto PASS_AND_RETURN; # wait for more data
    }

    # check against current set
    if ( $type>0 ) {
	# packet data
	if ( $self->{buf}[$dir] ne '' ) {
	    $self->run_callback([
		IMP_DENY,
		$dir,
		"packet data after unmatched streaming data"
	    ]);
	}
	for( my $i=0;$i<@$crs;$i++ ) {
	    if ( my ($len) = $match->($rules->[$crs->[$i]],\$data)) {
		# match
		$pass_until = $self->{off_passed}[$dir] =
		    $self->{off_buf}[$dir] += $len;
		if ( $self->{matched} ) {
		    # preserve hash of matched packet so that duplicates are
		    # detected later
		    $self->{matched}[$dir]{ md5(
			( $self->{matched_seed} //= pack("N",rand(2**32)) ).
			$data
		    )} = $crs->[$i]
		}

		if (@$crs>1) {
		    # remove rule, keep rest in ruleset
		    $DEBUG && debug(
			"full match rule $crs->[$i] - remove from ruleset");
		    splice(@$crs,$i,1);
		} else {
		    # remove ruleset with last rule in it
		    $DEBUG && debug(
			"full match rule $crs->[$i] - remove ruleset");
		    shift(@$rs);
		    # switch to other dir if this dir is done for now
		    if ( ! @$rs || ! $rs->[0] ) {
			my $ors = $self->{ruleset}[$dir ? 0:1];
			shift @$ors if @$ors && ! $ors->[0];
		    }
		}

		# pass data
		goto CHECK_DONE if ! @$rs;
		goto PASS_AND_RETURN; # wait for more data
	    }
	}

	# no rule from ruleset matched, check for duplicates
	if ( $self->{matched} and my $dup = $self->{matched}[$dir] ) {
	    my $r = $dup->{ md5($self->{matched_seed} . $data ) };
	    if ( defined $r ) {
		# matched again - pass data
		$pass_until = $self->{off_passed}[$dir]
		    = $self->{off_buf}[$dir] += length($data);
		$DEBUG && debug("ignore DUP[$dir] for rule $r");
		goto PASS_AND_RETURN; # wait for more data
	    }
	}

	# no rule and no duplicates matched, must be bad data
	$DEBUG && debug("no matching rule for ${type}[$dir] - deny");
	$self->{buf} = undef;
	$self->run_callback([
	    IMP_DENY,
	    $dir,
	    "rule#@$crs did not match"
	]);
	return;

    } else {
	# streaming data
	my $temp_fail;
	my $final_match;
	for( my $i=0;$i<@$crs;$i++ ) {
	    my ($len,$removed)
		= $match->($rules->[$crs->[$i]],\$self->{buf}[$dir]);
	    if ( ! defined $len ) {
		# will never match against rule
		next;
	    } elsif ( ! $len ) {
		# note that it might match if buf gets longer but check other
		# rules in ruleset if they match better
		$temp_fail = 1;
		next;
	    }

	    if ( ! $removed and @$crs == 1 and @$rs == 1 ) {
		# last rule for dir - no need to extend preliminary matches
		# as long as max_unbound is not restrictive
		my $ma = $self->{factory_args}{max_unbound};
		if ( ! defined( $ma && $ma->[$dir] )) {
		    $removed = $len;
		    substr($self->{buf}[$dir],0,$removed,'');
		}
	    }

	    # rule matched
	    if ( ! $removed ) {
		# match might not be final, wait for more data but put rule
		# at the beginning of ruleset if it's not already there
		unshift @$crs,splice(@$crs,$i,1) if $i>0;

		# advance off_passed, but keep off_buf
		$pass_until = $self->{off_passed}[$dir]
		    = $self->{off_buf}[$dir] + $len;

		# if this is was the last completely open rule we don't need
		# to check if the matched could be extended
		if (@$crs == 1 and @$rs == 1 ) {
		    # last rule on this side
		    my $ors = $self->{ruleset}[$dir?0:1];
		    if (
			# other side has no rules
			! @$ors
			# other side has empty rule
			or @$ors == 1 and ! $ors->[0]
			# other side has single rule which matched already
			or @$ors == 1 and @{ $ors->[0] } == 1 and
			    $self->{off_passed}[$dir?0:1]
			    - $self->{off_buf}[$dir?0:1] > 0 ) {

			# we are done and there is no need to extend the match
			@$ors = @$rs = ();
			goto CHECK_DONE;
		    }
		}

	    } else {
		# final match of rule
		$pass_until = $self->{off_passed}[$dir]
		    = $self->{off_buf}[$dir] += $len;
		if (@$crs>1) {
		    # remove rule, keep rest in ruleset
		    $DEBUG && debug(
			"full match rule $crs->[$i] - remove from ruleset");
		    splice(@$crs,$i,1);
		} else {
		    # remove ruleset with last rule in it
		    $DEBUG && debug(
			"full match rule $crs->[$i] - remove ruleset");
		    shift(@$rs);
		    # switch to other dir if this dir is done for now
		    if ( ! @$rs || ! $rs->[0] ) {
			my $ors = $self->{ruleset}[$dir ? 0:1];
			shift @$ors if @$ors && ! $ors->[0];
			goto CHECK_DONE if ! @$ors && ! @$rs;
		    }
		}
		$final_match = 1;
		# no allow_dup for streaming
	    }

	    # pass data
	    if ( $final_match and $self->{buf}[$dir] ne '' ) {
		# try to match more
		$data = $self->{buf}[$dir];
		$self->{buf}[$dir] = '';
		goto NEXT_RULE;
	    }
	    goto CHECK_DONE if ! @$rs;
	    goto PASS_AND_RETURN;
	}

	if ( ! $temp_fail ) {
	    # no rule and no duplicates matched, must be bad data
	    $DEBUG && debug("no matching rule for ${type}[$dir] - deny");
	    $self->{buf} = undef;
	    $self->run_callback([
		IMP_DENY,
		$dir,
		"rule#@$crs did not match"
	    ]);
	}
	goto PASS_AND_RETURN;
    }

    CHECK_DONE:
    return if @$rs; # still unmatched rules

    # pass only current data
    goto PASS_AND_RETURN if @{$self->{ruleset}[ $dir ? 0:1 ] };

    # rulesets for both dirs are done, pass all data
    $DEBUG && debug("all rules done - pass rest");
    $self->{buf} = undef;
    my @rv = (
	[ IMP_PASS,0,IMP_MAXOFFSET ],
	[ IMP_PASS,1,IMP_MAXOFFSET ]
    );
    for(0,1) {
	$self->{paused}[$_] or next;
	$self->{paused}[$_] = 0;
	unshift @rv, [ IMP_CONTINUE,$_ ];
    }
    $self->run_callback(@rv);
    return;

    PASS_AND_RETURN:
    return if ! $pass_until;
    $self->run_callback([ IMP_PASS, $dir, $pass_until ]);
    return;
}

# cfg2str and str2cfg are redefined because our config hash is deeper
# nested due to rules and max_unbound
sub cfg2str {
    my Net::IMP::ProtocolPinning $self = shift;
    my %cfg = @_;

    my $rules = delete $cfg{rules} or croak("no rules defined");
    # re-insert [[dir,rxlen,rx],... ] as dir0,rxlen0,rx0,dir1,...
    for (my $i=0;$i<@$rules;$i++) {
	@cfg{ "dir$i","rxlen$i","rx$i" } = @{ $rules->[$i] }{qw( dir rxlen rx)};
    }
    if ( my $max_unbound = delete $cfg{max_unbound} ) {
	# re-insert [mo0,mo1] as max_unbound0,max_unbound1
	@cfg{ 'max_unbound0', 'max_unbound1' } = @$max_unbound;
    }
    return $self->SUPER::cfg2str(%cfg);
}

sub str2cfg {
    my Net::IMP::ProtocolPinning $self = shift;
    my %cfg = $self->SUPER::str2cfg(@_);
    my $rules = $cfg{rules} = [];
    for ( my $i=0;1;$i++ ) {
	defined( my $dir = delete $cfg{"dir$i"} ) or last;
	defined( my $rxlen = delete $cfg{"rxlen$i"} )
	    or croak("no rxlen$i defined but dir$i");
	defined( my $rx = delete $cfg{"rx$i"} )
	    or croak("no rx$i defined but dir$i");
	$rx = eval { qr/$rx/ } or croak("invalid regex rx$i");
	push @$rules, { dir => $dir, rxlen => $rxlen, rx => $rx };


    }
    @$rules or croak("no rules defined");
    my $max_unbound = $cfg{max_unbound} = [];
    for (0,1) {
	$max_unbound->[$_] = delete $cfg{"max_unbound$_"}
	    if exists $cfg{"max_unbound$_"};
    }

    # sanity check
    my %scfg = %cfg;
    delete @scfg{qw(rules max_unbound ignore_order allow_dup allow_reorder)};
    %scfg and croak("unhandled config keys: ".join(' ',sort keys %scfg));

    return %cfg;
}


1;

__END__

=head1 NAME

Net::IMP::ProtocolPinning - IMP plugin for simple protocol matching

=head1 SYNOPSIS

    my $factory = Net::IMP::ProtocolPinning->new_factory( rules => [
	# HTTP request from client (dir=0)
	[ 0,9,qr{(GET|POST|OPTIONS) \S} ],
    ]);

    my $factory = Net::IMP::ProtocolPinning->new_factory( rules => [
	# SSHv2 prompt from server
	[ 1,6,qr{SSH-2\.} ],
    ]);

    my $factory = Net::IMP::ProtocolPinning->new_factory(
	rules => [
	    # SMTP initial handshake
	    # greeting line from server
	    { dir => 1, rxlen => 512, rx => qr{220 [^\n]*\n} },
	    # HELO|EHLO from client
	    { dir => 0, rxlen => 512, rx => qr{(HELO|EHLO)[^\n]*\n}i },
	    # response to helo|ehlo
	    { dir => 1, rxlen => 512, rx => qr{250-?[^\n]*\n} },
	],
	# some clients send w/o initially waiting for server
	ignore_order => 1,
	max_unbound => [ 1024,0 ],
	# for UDP use this
	allow_dup => 1,
	allow_reorder => 1,
    );

=head1 DESCRIPTION

C<Net::IMP::ProtocolPinning> implements an analyzer for very simple protocol
verification using rules with regular expressions.
The idea is to only check the first data in the connection for protocol
conformance and then let the rest through without further checks.

Calls to C<new_factory> or C<new_analyzer> can contain the following arguments
specific to this module:

=over 4

=item rules ARRAY

Specifies the rules to use for protocol verification. Rules are an array
of direction specific rules, e.g. each rule consists of C<[dir,rxlen,rx]> with

=over 8

=item dir

the direction, e.g. 0 for data from client and 1 for data from server

=item rxlen

the length of data the regular expression might need for the match.
E.g. if the regex is C<qr/foo(?=bar)/> 6 bytes are needed for a successful
match, even if the regex matches only 3 bytes.

=item rx

the regular expression itself.
The regex will be applied against the not-yet-forwarded data with an implicit
C<\A> in front, so look-behind will not work.

=back

=item ignore_order BOOLEAN

If true, it will take the first rule for direction, when data for connection
arrive.
If false, it will cause DENY if data arrive from one direction, but the current
rule is for the other direction.

=item allow_dup BOOLEAN

If true, it will ignore if the last rule (or any previous rule with
C<allow_reorder>) matches again, instead of matching the next rule.
Only packet data will be checked for duplicates.

=item allow_reorder BOOLEAN

If true, it will ignore if the rules match in a different order.
Unless C<ignore_order> is given it will still enforce the order of data transfer
between the directions.

=item max_unbound [SIZE0,SIZE1]

If there are no more active rules for direction, and ignore_order is true, then
the application needs to buffer data, until all remaining rules for the other
direction are matched.
Using this parameter the amount of buffered data which cannot be bound to a rule
will be limited per direction.

If not set, a default of unlimited will be used.
In this case it will send IMP_PAUSE to the data provider if it is necessary to
buffer data, so that it can temporary stop receiving data.
If max_unbound is not unlimited it will not send IMP_PAUSE, so that it can
enforce the limit.

=back

=head2 Process of Matching Input Against Rules

When new data arrive from direction, it will try to match them against the rule
list as follows and stop as soon a rule matches:

=over 4

=item *

If there is a previously matching rule which might extend its match, it will be
tried first (only for stream data).

=item *

If the next rule in the list of rules matches the incoming direction, it will be
tried to match. If C<ignore_order> is true, the next rule for the incoming
direction will be used instead.

=item *

If C<allow_reorder> is true, then all other rules until the next direction
change in the rule list will be tried in the order of the rule list.
If C<ignore_order> is true, direction change in the rule list is ignored, e.g.
all remaining rules for the incoming direction are considered.

=item *

If C<allow_dup> is true, then all already matched rules from the incoming
direction are allowed to match again, but only if no other rules match.
To detect matches a hash over all matched packets will be saved and later
checked. To avoid targeted collisions the hash consists of the md5 of an
analyzer specific random seed and the data.

=back

If a rule matched the incoming data, they will be passed using IMP_PASS.
How the match gets executed and what happens if no rule matches depends on the
data type:

=over 4

=item Stream Data

For stream data it will match as much data as possible, e.g. the rule which
matched last will be considered again if new data arrive, in case the match
might be extended. The rule will only be considered done, if the C<rxlen> is
reached, a direction change occured and C<ignore_order> is false or if it is
the last rule for the direction.

The rules are matched after each other, e.g. the new match will start where the
last match finished.

A useful value for C<rxlen> is necessary to not buffer too much data, because it
is unable to detect if a rule does not even match the beginning of the incoming
data. If no rules match the incoming data, it will buffer up to the maximum
C<rxlen> and only fail matching, if it got more than C<rxlen> bytes of unmatched
data and still no rule matches.

C<allow_dup> and C<allow_reorder> will behave as documented, but because they
usually don't expect the behavior of the data they should be better kept false.

=item  Packet Data

For packet data each rule will be matched against the whole packet, e.g. with an
implicit C<\A> at the beginning and C<\Z> at the end of the regular expression.
So there cannot be multiple rules matching the same packet after each other, nor
can their be a rule spanning multiple packets.

If no rule matches the incoming packet, the matching will fail, e.g. no
buffering and waiting for more data.

If the packet stream is based on a protocol like UDP, it is recommended to set
C<allow_dup> and C<allow_reorder>, so that protocols match even if packets get
resubmitted or arrive out of order.

=back

Only if all rules are matched, the remaining data will be passed using IMP_PASS
with IMP_MAXOFFSET.
If the matching failed, an IMP_DENY is issued.

If only the rules from one direction matched so their are still outstanding
rules for the other connection, the data for the completed connection will not
be passed yet.
If the amount of unbound data should be limited C<max_unbound> should be set.
Buffering more data than C<max_unbound> for this direction will cause a DENY.
If C<max_unbound> is not set it will use flow control (e.g. IMP_PAUSE) to make
the data provide temporary stop receiving data.

=head2 Rules for Writing the Regular Expressions

Because the match will be tried whenever new data come in (e.g. the buffer might
have a size of less than, equal to or greater than C<rxlen>), care should be
taken, when constructing the regular expression and determining C<rxlen>.
It should not match data longer than C<rxlen>, e.g. instead of specifying
C<\d+> one should specify a fixed size with C<\d{1,10}>.

Care should also be taken if you have consecutive rules for the same direction
(e.g. either the next rule is for the same direction or C<ignore_order> is
true).
Here you need to make sure, that the first rule will not match data needed by
the next rule, e.g. C<\w{1,2}> followed by C<\d> will not work, while
C<[a-z]{1,2}> followed by C<\d> will be fine.

Please note also, that the regular expression in the rule will be implicitly
anchored at the beginning of the buffered data, e.g. C<\d> will only match if
the first character is a digit, not if any character but the first in the
buffer is a digit.
If you want the latter behavior, you have to explicitly allow other characters
and need to limit their amount, e.g. "(?s).{0,10}\d".

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
