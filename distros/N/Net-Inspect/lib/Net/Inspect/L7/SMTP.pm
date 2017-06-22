############################################################################
# finds SMTP traffic in tcp connection
############################################################################
use strict;
use warnings;
package Net::Inspect::L7::SMTP;
use base 'Net::Inspect::Flow';
use Net::Inspect::Debug qw(:DEFAULT $DEBUG %TRACE);
use Hash::Util 'lock_ref_keys';
use Carp 'croak';
use Scalar::Util 'weaken';
use fields (
    'replay',   # collected and replayed in guess_protocol
    'meta',     # meta data from connection
    'error',    # connection has error like server sending data w/o request
    'connid',   # connection id
    'offset',   # offset in data stream
    'handler',  # handler sub for current state
    'indata',   # inside DATA section
    'cmd',      # list of open commands
);



sub guess_protocol {
    my ($self,$guess,$dir,$data,$eof,$time,$meta) = @_;

    if ($dir == 0) {
	# data from client w/o greeting from server
	debug("got data from client before getting greeting from server -> no SMTP");
	$guess->detach($self);
	return;
    }

    my $rp = $self->{replay} ||= [];
    push @$rp,[$data,$eof,$time];
    my $buf = join('',map { $_->[0] } @$rp);

    my $eol = index($buf,"\n");
    if ($eol == -1 && length($buf)>512 || $eol>512) {
	# maximum length of reply line is 512 octets: RFC5321, 4.5.3.1.5.
	debug("line to long -> no SMTP");
	$guess->detach($self);
	return;
    } elsif ($eol == -1) {
	# need more bytes
	return;
    }

    if ($buf !~ m{\A220[ -]}) {
	debug("not an SMTP greeting -> no SMTP");
	$guess->detach($self);
	return;
    }

    # looks like SMTP greeting
    my $obj =  $self->new_connection($meta);
    # replay as one piece
    my $n = $obj->in(1,$buf,$rp->[-1][1],$rp->[-1][2]);
    undef $self->{replay};
    $n += -length($buf) + length($data);
    $n<=0 and die "object $obj did not consume alle replayed bytes";
    debug("consumed $n of ".length($data)." bytes");
    return ($obj,$n);
}


{
    my $connid = 0;
    sub syn { 1 }; # in case it is attached to Net::Inspect::Tcp
    sub new_connection {
	my ($self,$meta,@args) = @_;
	my $obj = $self->new(@args);
	$obj->{upper_flow} = $obj->{upper_flow}->new_connection($meta)
	    or return;
	$obj->{meta} = $meta;
	$obj->{connid} = ++$connid;
	$obj->{offset} = [0,0];
	$obj->{handler} = [ \&_in0_command, \&_in1_response ];
	$obj->{cmd} = [ ':EXPECT-GREETING' ];
	return $obj;
    }
}

sub in {
    my ($self,$dir,$data,$eof,$time) = @_;
    return 0 if $data eq '' && ! $eof;
    defined($self->{error}) and return;

    $DEBUG && $self->xdebug("got %s bytes from %d, eof=%d",
	ref($data) ? join(":",@$data): length($data),
	$dir,$eof//0
    );
    my $bytes = 0;
    while (1) {
	my $sub = $self->{handler}[$dir];
	my @arg;
	($sub,@arg) = @$sub if ref($sub) ne 'CODE';
	my $n = $sub->($self,@arg,$data,$eof,$time) or last;
	$bytes += $n;
	substr($data,0,$n,'');
	last if $data eq '';
    }
    if ($DEBUG && $bytes < length($data)) {
	debug("unprocessed[%d]: %d/'%s'", $dir,
	    length($data)-$bytes,substr($data,$bytes));
    }
    return $bytes;
}

sub offset {
    my $self = shift;
    return @{ $self->{offset} }[wantarray ? @_:$_[0]];
}


sub _in1_response {
    my ($self,$data,$eof,$time) = @_;
    my ($code,$eom);
    while ($data =~m{\G([2345]\d\d)(?:\n|(-).*\n|\s.*\n)}gc) {
	return $self->fatal('SMTP response line too long',0,$time)
	    if $+[0]-$-[0]>1024;

	if (!defined $code) {
	    $code = $1;
	} elsif ($code != $1) {
	    return $self->fatal(
		'mixed status in multiline SMTP response',0,$time);
	}
	if (!$2) {
	    $eom = pos($data);
	    last;
	}
    }

    return $self->fatal('SMTP response line too long',0,$time)
	if length($data)-(pos($data)//0) > 1024;
    return if !$eom;

    $self->{offset}[1] += $eom;

    my $cmd = pop @{$self->{cmd}};
    return $self->fatal('SMTP response w/o command',0,$time)
	if !defined $cmd;

    if ($cmd eq ':EXPECT-GREETING') {
	$self->{upper_flow}->greeting(substr($data,0,$eom),$time);
    } else {
	my $resp = substr($data,0,$eom);
	if ($code =~m{^3}) {
	    if ($cmd eq 'DATA') {
		unshift @{$self->{cmd}}, \'DATA';
		$self->{handler}[0] = \&_in0_data;
		$self->{upper_flow}->response($resp,$time);
	    } elsif ($cmd eq 'AUTH' || ref($cmd) && $$cmd eq 'AUTH') {
		unshift @{$self->{cmd}}, \'AUTH';
		$self->{upper_flow}->response($resp,$time);
		$self->{handler}[0] = \&_in0_auth;
	    } else {
		return $self->fatal("$code response for $cmd",0,$time);
	    }
	} else {
	    $self->{handler}[0] = \&_in0_command if ref $cmd;
	    $self->{upper_flow}->response($resp,$time);
	}
    }
    return $eom;


    # TODO
    # check response to EHLO, i.e. allowed version used features
}


sub _in0_command {
    my ($self,$data,$eof,$time) = @_;
    $data =~m{^(\w+)(?:[ \t].*|\r|)\n}gc or do {
	return $self->fatal("invalid SMTP command '$data'",0,$time)
	    if length($data)>1024 || $data =~m{\n};
	return; # need more data
    };

    my $cmd = uc($1);
    $data = substr($data,0,pos($data));
    $self->{offset}[1] += length($data);

    if ($cmd eq 'BDAT') {
	my ($offset,$last) = $data =~m{^BDAT\s+(\d+)(\s+LAST)?\s+\z}i
	    or return $self->fatal("invalid BDAT syntax '$data'",0,$time);
	$self->{handler}[0] = [ \&_in0_bdat, \$offset, $last ];
    }
    push @{$self->{cmd}}, $cmd;
    $self->{upper_flow}->command($data);

    return length($data);
}

sub _in0_data {
    my ($self,$data,$eof,$time) = @_;
    my $rx = $self->{indata}++ ? qr{^\.}m : qr{\n\.};

    return $self->fatal('no data in DATA') if $data eq '';
    my $rxpre = $self->{indata}++ ? qr{(^)\.}m : qr{(\n)\.};
    my $eom;
    if ($data =~m{$rxpre\r?\n}gc) {
	substr($data,pos($data)) = '';
	$eom = 1;
    } elsif ((my $pos = rindex(substr($data,-4),"\n")) != -1) {
	substr($data,-4+$pos) = '';
    }

    my $len = length($data);
    if ($len) {
	$data =~s{$rxpre}{$1}g;
	$self->{upper_flow}->mail_data($data,$time) if $data ne '';
	if ($eom) {
	    $self->{upper_flow}->mail_data('',$time);
	    $self->{handler}[0] = \&_in0_command;
	}
    }
    return $len;
}

sub _in0_bdat {
    my ($self,$roffset,$last,$data,$eof,$time) = @_;
    my $len = length($data);
    if ($len <= $$roffset) {
	$$roffset -= $len;
    } else {
	$len -= $$roffset;
	$$roffset = 0;
	substr($data,0,$len,'');
    }

    $self->{upper_flow}->mail_data($data,$time) if $data ne '';
    if ($$roffset == 0) {
	$self->{upper_flow}->mail_data('',$time) if $last;
	$self->{handler}[0] = \&_in0_command;
    }
    return $len;
}

sub _in0_auth {
    my ($self,$data,$eof,$time) = @_;
    my $pos = index($data,"\n");
    substr($data,$pos+1) = '' if $pos>=0;
    return $self->fatal('SMTP AUTH response too long',0,$time)
	if length($data)>1024;
    return if $pos == -1;
    $self->{upper_flow}->auth_data($data,$time);
    return $pos+1;
}

sub fatal {
    my ($self,$reason,$dir,$time) = @_;
    %TRACE && $self->xtrace($reason);
    $self->{error} = $reason;
    $self->{upper_flow}->fatal($dir,$reason,$time);
    return;
}

sub xtrace {
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{connid} $msg";
    unshift @_,$msg;
    goto &trace;
}

sub xdebug {
    $DEBUG or return;
    my $self = shift;
    my $msg = shift;
    $msg = "$$.$self->{connid} $msg";
    unshift @_,$msg;
    goto &debug;
}


1;

__END__

=head1 NAME

Net::Inspect::L7::SMTP - guesses and handles SMTP traffic

=head1 SYNOPSIS

 my $conn = ...
 my $smtp = Net::Inspect::L7::SMTP->new($conn);
 my $guess = Net::Inspect::L5::GuessProtocol->new;
 $guess->attach($smtp);
 ...

=head1 DESCRIPTION

This class extracts SMTP traffic from TCP connections.
It provides all hooks required for C<Net::Inspect::L4::TCP> and is usually used
together with it.
It provides the C<guess_protocol> hook so it can be used with
C<Net::Inspect::L5::GuessProtocol>.

Hooks provided:

=over 4

=item guess_protocol($guess,$dir,$data,$eof,$time,$meta)

=item new_connection($meta)

This returns an object for the connection.

=item $connection->in($dir,$data,$eof,$time)

Processes new data and returns number of bytes processed.
Any data not processed must be sent again with the next call.

C<$data> are the data as string.
Gaps are currently not support.

=item $connection->fatal($reason,$dir,$time)

=back

The attached flow object needs to implement the following hooks:

=over 4

=item new_connection($meta)

Called on start of SMTP connection to initialize object.

=item $obj->greeting($msg,$time)

Called when the initial greeting is read.
$msg is the full greeting.

=item $obj->command($cmd,$time)

Called when a command is read.
$cmd is the full command line.

=item $obj->response($msg,$time)

Called when a response is read.
$msg is the full response.

=item $obj->mail_data($chunk,$time)

Called when a chunk is read inside DATA.
Dot-escaping will be removed before calling C<mail_data>
End of mail data will be signaled with an empty chunk.

=item $obj->auth_data($line,$time)

Called within the AUTH handshake for the data send from client to server. The
data (challenges) from server to client are delivered through C<response>.

=item $obj->fatal($dir,$reason,$time)

Called on fatal protocol errors.

=back
