use strict;
use warnings;

package Net::IMP::Pattern;
use base 'Net::IMP::Base';
use fields (
    'rx',       # Regexp from args rx|string
    'rxlen',    # max size rx can match
    'rxdir',    # only check this direction
    'action',   # deny|reject|replace
    'actdata',  # data for action
    'buf',      # locally buffered data to match rx, <rxlen and per dir
    'buftype',  # type of data in buffer
    'offset',   # buf[dir][0] is at offset in input stream dir
);

use Net::IMP; # import IMP_ constants
use Net::IMP::Debug;
use Carp 'croak';

sub INTERFACE {
    my Net::IMP::Pattern $factory = shift;
    my $action = $factory->{factory_args}{action};
    my @rv = IMP_PASS;
    push @rv,
	$action eq 'deny'    ? IMP_DENY :
	$action eq 'reject'  ? (IMP_REPLACE, IMP_TOSENDER) :
	$action eq 'replace' ? IMP_REPLACE :
	! $action            ? IMP_DENY :
	croak("invalid action $action");
    return [ undef, \@rv ];
};

my %_valid_act = map { $_ => 1 } qw(deny reject replace);
sub validate_cfg {
    my ($class,%args) = @_;

    my @err;
    my $rx = delete $args{rx};
    my $string = delete $args{string};
    my $rxdir = delete $args{rxdir};

    if ($rx) {
	my $rxlen = delete $args{rxlen};
	push @err, "rxlen must be given and >0" unless
	    $rxlen and $rxlen =~m{^\d+$} and $rxlen>0;
	if ( ref($rx) ne 'Regexp' ) {
	    push @err, "rx must be regex" if ref($rx) ne 'Regexp'
	} elsif ( '' =~ $rx ) {
	    push @err,"rx should not match empty string"
	}
    }

    if ( defined $string ) {
	push @err, "only rx or string should be given, not both" if $rx;
    } elsif ( ! $rx ) {
	push @err, "rx+rxlen or string need to be given for pattern";
    }

    push @err, "rxdir must be 0|1"
	if defined $rxdir && $rxdir != 0 && $rxdir != 1;

    my $act = delete $args{action};
    push @err, "action can only be deny|reject|replace" unless
	$act and $_valid_act{$act};
    push @err, "action $act needs actdata" if ! defined(delete $args{actdata});

    push @err, $class->SUPER::validate_cfg(%args);
    return @err;
}


# create new analyzer object
sub new_analyzer {
    my ($factory,%args) = @_;
    my $fargs = $factory->{factory_args};

    my $rxlen;
    my $rx = $fargs->{rx};
    if ($rx) {
	$rxlen = $fargs->{rxlen};
    } else {
	$rx = $fargs->{string};
	$rxlen = length($rx);
	$rx = qr/\Q$rx/;
    }

    my Net::IMP::Pattern $self = $factory->SUPER::new_analyzer(
	%args, # cb, meta
	rx      => $rx,
	rxlen   => $rxlen,
	rxdir   => $fargs->{rxdir},
	action  => $fargs->{action},
	actdata => $fargs->{actdata},
	buf     => ['',''],  # per direction
	buftype => [0,0],    # per direction
	offset  => [0,0],    # per direction
    );

    if ( defined $self->{rxdir} ) {
	# if rx is specified only for one direction immediatly issue PASS until
	# end for the other direction
	$self->run_callback([
	    IMP_PASS,
	    $self->{rxdir} ? 0:1,
	    IMP_MAXOFFSET,
	]);
    }

    return $self;
}

sub data {
    my Net::IMP::Pattern $self = shift;
    my ($dir,$data,$offset,$type) = @_;

    $offset and die "cannot deal with gaps in data";

    # if this is the wrong dir return, we already issued PASS
    return if defined $self->{rxdir} and $dir != $self->{rxdir};

    # accumulate results
    my @rv;

    my $buf;
    if ( $type > 0 or $type != $self->{buftype}[$dir] ) {
	# packet data or other streaming type
	$buf = $data;
	if ( $self->{buf}[$dir] ne '' ) {
	    # pass previous buffer and reset it
	    debug("reset buffer because type=$type, buftype=$self->{buftype}[$dir]");
	    $self->{offset}[$dir] += length($self->{buf}[$dir]);
	    $self->{buf}[$dir] = '';
	    push @rv, [ IMP_PASS,$dir,$self->{offset}[$dir] ];
	} elsif ( ! $self->{buftype}[$dir] and not $type > 0 ) {
	    # initial streaming buf
	    $self->{buf}[$dir] = $buf;
	}
	$self->{buftype}[$dir] = $type;
    } else {
	# streaming data, match can span multiple chunks
	$buf = ( $self->{buf}[$dir] .= $data );
    }

    $DEBUG && debug("got %d bytes $type on %d, bufsz=%d, rxlen=%d",
	length($data),$dir,length($buf),$self->{rxlen});

    # for packet types we accumulate datain newdata and set changed if newdata
    # are different from old
    my $changed = 0;
    my $newdata = '';

    while (1) {
	if ( my ($good,$match) = $buf =~m{\A(.*?)($self->{rx})}s ) {
	    # rx matched:
	    # - strip up to end of rx from buf
	    # - issue IMP_PASS for all data in front of rx
	    # - handle rx according to action
	    # - continue with buf after rx (e.g. redo loop)

	    if ( length($match)> $self->{rxlen} ) {
		# user specified a rx, which could match more than rxlen, e.g.
		# something like qr{\d+}. make sure we only match rxlen bytes
		if ( substr($match,0,$self->{rxlen}) =~m{\A($self->{rx})} ) {
		    $match = $1;
		} else {
		    # no match possible in rxlen bytes, reset match
		    # and add one char from original match to $good
		    # so that we don't try to match here again
		    $good .= substr($match,0,1);
		    $match = '';
		}
	    } else {
		# we checked in new_analyzer already that rx does not match
		# empty string, so we should be save here that rxlen>=match>0
	    }

	    if ( $good ne '' ) {
		$DEBUG && debug("pass %d bytes in front of match",
		    length($good));
		# pass everything before the match and advance offset
		$self->{offset}[$dir]+=length($good);
		if ( $type>0 ) {
		    # keep good
		    $newdata .= substr($buf,0,length($good),'');
		} else {
		    # pass good
		    push @rv, [ IMP_PASS, $dir, $self->{offset}[$dir] ];
		    substr($buf,0,length($good),'');
		}
	    }
	    # remove match
	    substr($buf,0,length($match),'');
	    $self->{offset}[$dir] += length($match);

	    if ( $match eq '' ) {
		# match got reset if >rxlen -> no action

	    # handle the matched pattern according to action
	    } elsif ( $self->{action} eq 'deny' ) {
		# deny everything after
		push @rv,[ IMP_DENY,$dir,$self->{actdata}//'' ];
		last; # deny is final

	    } elsif ( $self->{action} eq 'reject' ) {
		# forward nothing, send smthg back to sender
		if ( $type > 0 ) {
		    # no need to add nothing to $newdata :)
		    $changed = 1;
		} else {
		    push @rv,[
			IMP_REPLACE,
			$dir,
			$self->{offset}[$dir],
			'',
		    ];
		}
		push @rv,[ IMP_TOSENDER,$dir,$self->{actdata} ]
		    if $self->{actdata} ne '';

	    } elsif ( $self->{action} eq 'replace' ) {
		# forward something else
		if ( $type > 0 ) {
		    $newdata .= $self->{actdata}//'';
		    $changed = 1;
		} else {
		    push @rv,[
			IMP_REPLACE,
			$dir,
			$self->{offset}[$dir],
			$self->{actdata}//''
		    ];
		}

	    } else {
		# should not happen, because action was already checked
		die "invalid action $self->{action}";
	    }

	    last if $buf eq ''; # need more data

	} elsif ( $type > 0 ) {
	    # no matches across packets are allowed
	    $self->{offset}[$dir] += length($buf);
	    $newdata .= $buf if $changed;
	    last;

	} elsif ( (my $d = length($buf) - $self->{rxlen} + 1) > 0 ) {
	    # rx did not match, but >=rxlen bytes in buf:
	    # we can IMP_PASS some, but rxlen-1 data needs to be kept in buffer
	    # so that we retry rx when new data come in
	    $DEBUG && debug("can pass %d of %d bytes",$d,length($buf));
	    push @rv, [ IMP_PASS, $dir, $self->{offset}[$dir] += $d ];
	    substr($buf,0,$d,'');

	    last; # need more data

	} elsif ( $data eq '' ) {
	    # rx did not match, but eof:
	    # no more data will come which can match rx so we can pass the rest
	    $DEBUG && debug("pass rest of data on eof");
	    push @rv,[ IMP_PASS,$dir,IMP_MAXOFFSET ];
	    $buf = '';

	    last; # there will be no more matches because of no data

	} else {
	    # rx did not match, but no eof:
	    last; # need more data
	}
    }

    if ( $type > 0 ) {
	if ( grep { IMP_DENY == $_->[0] } @rv ) {
	    # leave deny alone
	} elsif ( $changed ) {
	    # replace whole packet
	    push @rv, [ IMP_REPLACE,$dir,$self->{offset}[$dir],$newdata ];
	} else {
	    # pass whole packet
	    push @rv, [ IMP_PASS,$dir,$self->{offset}[$dir] ];
	}
    }

    if ( @rv ) {
	$self->{buf}[$dir] = $buf unless $type > 0; # $buf got changed, put back
	debug("bufsize=".length($self->{buf}[$dir]));
	$self->run_callback(@rv);
    } else {
	$DEBUG && debug("need more data");
    }
}

sub str2cfg {
    my ($class,$str) = @_;
    my %cfg = $class->SUPER::str2cfg($str);
    if ($cfg{rx}) {
	$cfg{rx} = eval { qr/$cfg{rx}/ }
	    || croak("'$cfg{rx}' is no valid regex");
    }
    return %cfg;
}


1;

__END__

=head1 NAME

Net::IMP::Pattern - IMP plugin for reacting to matched pattern

=head1 SYNOPSIS

    my $factory = Net::IMP::Pattern->new_factory(
	rx       => qr/this|that/, # pattern
	rxlen    => 7,             # maximum length regex can match
	action   => 'replace',     # 'deny','reject'..
	actdata  => 'newdata',     # replace with newdata
    );

=head1 DESCRIPTION

C<Net::IMP::Pattern> implements an analyzer to match regular expressions and
replace or reject the data or cause a deny.
The behavior is specified in the arguments given to C<new_factory> or
C<new_analyzer>.

=over 4

=item rx Regex

The regular expression (as Regexp).

C<rx> should only match up to the number of bytes specified by C<rxlen>, e.g.
regular expressions like C</\d+/> should be avoided, better use C</\d{1,10}/>.
Although it will do its best to only match C<rxlen> in that case, these
kind of broad regular expressions are a sign, that the user does not really
know what should be matched.

Regular expressions which can match the empty buffer, like C</\d*/>, are not
allowed at all and it will croak when trying to use such a regular expression.

=item rxlen Integer

The maximum number of bytes the regex could match or is allowed to match.
This argument is necessary together with C<rx> because there is no way to
determine how many bytes an arbitrary regular expression might match.

=item string String

Instead of giving the regular expression C<rx> together with C<rxlen>, a fixed
string can be given.

=item rxdir 0|1

With this optional argument one can restrict the direction where C<rx> or
C<string> will be applied.
Data in the other direction will pass directly.

=item action String

The following actions are supported

=over 8

=item 'deny'

Causes a deny (e.g. close) of the connection, with the deny message specified in
C<actdata>

=item 'reject'

Rejects the data, e.g. replaces the data with C<''> and sends the string given
in C<actdata> back to the sender.

=item 'replace'

Replaces the data with the string given in C<actdata>

=back

=item actdata String

Meaning depends on C<action>. See there.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
