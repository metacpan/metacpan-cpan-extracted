#!/usr/bin/perl

#BEGIN { $Exporter::Verbose=1 }

package Spread::Message;
our $VERSION = 0.21;
use Spread qw(:SP :ERROR :MESS);
use Data::Dumper;
use Carp qw/cluck/;
use Sys::Hostname;

use strict;
use constant REJECT_MESS => 0x00400000;

sub logit (@);
our($Program_Name, $Command);
$Command = "$0 @ARGV";
@_ = split(/\/+/, $0);
$Program_Name = pop(@_);

=head1 NAME

Spread::Message - provide messaging using the Spread toolkit

This product uses software developed by Spread Concepts LLC for use in
the Spread toolkit. For more information about Spread see
http://www.spread.org

=head1 SYNOPSIS

    use Spread::Message;

    my $mbox = Message->new(
        spread_name => '4803@host',
        name  => "down$$",
        group => ['devices-down'],
        #debug => 1,
        member_sub  => \&process_control,
        message_sub => \&process_data,
        timeout_sub => \&heartbeat,
    );

    sub process_control
    {
        my $mbox = shift;
        my $loop = shift;
        # Process membership messages here. See examples
    }

    sub process_data
    {
        my $mbox = shift;
        my $loop = shift;
        # Process the data here. See examples
    }

    sub heartbeat
    {
        my $mbox = shift;
        my $loop = shift;
        # Process any timeouts here. See examples
    }

    while(1)
    {
        # Process different data as required
        $mbox->rx(10,$loop);
        $loop++;

        # Extra processing of side effects created by the callbacks
    }
    $mbox->disconnect();

Other possibilites are:

    # Connection
    $mbox->connect;
    $mbox->disconnect;

    # Config
    $mbox->configure(%config);
    $spread_daemon = $mbox->spread_name;
    $mbox->spread_name('3480@1.1.1.1');
    $seed_name = $mbox->name;
    $mbox->name('test');
    $rv = $mbox->debug(); 
    $mbox->debug(1);

    # tx/rx messages
    $mbox->send(@grps,$msg);
    $mbox->sends(@grps,\%perlhash);
    $hashref = $mbox->decode;
    $msg_size = $mbox->poll;
    $mbox->rx($timeout,@args);
    $regular_msg = $mbox->get;
    $msg = $mbox->getmsg($timeout);

    # Object/Message details
    $spread = $mbox->mbox;
    @grps = $mbox->grps;
    $sent_by = $mbox->sender;
    $service_type = $mbox->type;
    $message_type = $mbox->mess_type;
    $same_endian = $mbox->endian;
    $last_message = $mbox->msg;
    $last_hashref = $mbox->command;
    $is_new_message = $mbox->new_msg;
    $time_last_received = $mbox->tm;
    $timed_out = $mbox->timeout;
    $mysperrorno = $mbox->error;
    $whoami = $mbox->me;

    # Test message
    $mbox->control_msg;
    $mbox->aimed_at_me;
    $mbox->Is_unreliable_mess;
    $mbox->Is_reliable_mess;
    $mbox->Is_fifo_mess;
    $mbox->Is_causal_mess;
    $mbox->Is_agreed_mess;
    $mbox->Is_safe_mess;
    $mbox->Is_regular_mess;
    $mbox->Is_self_discard;
    $mbox->Is_reg_memb_mess;
    $mbox->Is_transition_mess;
    $mbox->Is_caused_join_mess;
    $mbox->Is_caused_leave_mess;
    $mbox->Is_caused_disconnect_mess;
    $mbox->Is_caused_network_mess;
    $mbox->Is_membership_mess;
    $mbox->Is_reject_mess;
    $mbox->Is_self_leave;

    # Supplied Callbacks
    $mbox->_member_sub
    $mbox->_message_sub
    $mbox->_error_sub
    $mbox->_timeout_sub
    $mbox->handle_commands_aimed_at_me

=head1 DESCRIPTION

The Spread package provides a simple wrapper around the spread toolkit.
We try to provide a much higher level wrapper. By providing:

    - Simple methods to send serialised Perl structures between programs
    - Callback registration
    - Extensible callbacks for command driven programs
    - Lots of accesor functions
    - Handling of incoming messages is supported via callbacks or
    via direct polling for input. Its your choice :-)

=head1 OBJECT CONFIGURATION


    group => is an array ref of groups to subscribe to
    debug => is a scalar variable the effects debugging output
    name  => is a scalar variable that defines a Spread name. Must
             be uniq.

    The following are the names of the callback config variables. Each
    must be a CODE reference.

    # These provide message gathering callbacks defined on the type of
    # message received.
    member_sub   =>  subroutine to handle membership messages.
    message_sub  =>  subroutine to hanlde normal data messages
    error_sub    =>  gets called when ever we find an error of some kind
    timeout_sub  =>  called in the event of any timeout.

    # If defined then this installs handle_commands_aimed_at_me() as the
    # call back for each of the above and allows you to override bits and
    # pieces. See CALLBACKS below
    commands     => {
        'default'  => subroutine to handle ALL default message
        'new'      => subroutine to handle 'new' command
        .
        .
    }


=head1 METHODS


=cut


=head2 B<new()>

Create a new object and get it configured.

	my $mbox = Spread::Message->new(
			name        => $name,
			spread_name => '4803@localhost',
			group       => ['polling-ctl', 'polling-data'],
			member_sub  => \&my_memeber_callback,
			message_sub => \&my_message_callback,
			error_sub   => \&my_error_callback,
			timeout_sub => \&my_timeout_callback,
			debug       => 1,
	);
	die "Can't create a new message object" unless $mbox;

or

	my $mbox = Spread::Message->new(
			name        => $name,
			spread_name => '4803@localhost',
			group       => ['polling-ctl', 'polling-data'],
			debug       => 1,
			commands    => {
				'default'   => \&myhandlecommands;
			},
	);
	die "Can't create a new message object" unless $mbox;

=cut

sub new
{
	 my $invocant    = shift;
	 my $class       = ref($invocant) || $invocant; # Object or class name

	 my $self = {};
	 bless($self, $class);

	 $self->configure(@_);
	 warn "$class new called\n" if($self->{'DEBUG'});
	 return $self;
}

# B<serialise()> used by sends()
#
#Takes a Perl variable (normally a hash reference) and returns a textual
#description of it. It uses Data::Dumper and is therfore constrained to
#its methods. We call serialise when we wish to send a Perl structure to
#another program and use B<eval> to rebirth the structure.
#
sub serialise
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $hashref = shift;
	my $data = Data::Dumper->new([$hashref],['msg']);
	$data->Indent(0);
	return $data->Dump;
}


=head2 B<configure()>

Configure an object before getting connected. You can change the
configuration of an object at anytime. But make sure you disconnect and
then B<connect()> again afterwards. The B<new> method calls configure for
you in the right order. So, normally you wont want to call this method.

However, you may want to, so here is what you can do.


	my $mbox = Spread::Message->new(
		name        => $name,
		spread_name => '4803@localhost',
		group       => ['polling-ctl', 'polling-data'],
		member_sub  => \&my_memeber_callback,
		message_sub => \&my_message_callback,
		error_sub   => \&my_error_callback,
		timeout_sub => \&my_timeout_callback,
		debug       => 0,
	);
	die "Can't create a new message object" unless $mbox;

	# stuff happens

	# Here we change the membership message call back at run time
	$mbox->configure(member_sub => \&new_callback);

	# more stuff happens and we eventually disconnect and reconnect
	# to a different spread daemon. Same groups and call backs
	$mbox->disconnect();
	$mbox->configure( spread_name => '4803@newhost' );
	$mbox->connect() || warn "Failed to attach to 4803@newhost";

	# Change the debugging on the fly
	$mbox->configure( debug => 1 );
	$mbox->debug(1);

Configure defaults to:

	name        => "pid$$"
	group       => ['info']
	debug       => 0
	spread_name => '4803@localhost
	member_sub  => sub { print something useful };
	message_sub => sub { print something useful };
	error_sub   => sub { print something useful };
	timeout_sub => sub { print something useful };

You dont have to have callbacks defined. You can still use B<get()> and
B<getmsg()> to collect messages. Callbacks are only used when B<rx()> is
called.

If you intend to use callbacks and B<sends()> then consider configuring
your own command callbacks that will get triggered when a particular
command is recieved.

    my $mbox = Spread::Message->new(
        name        => $name,
        spread_name => '4803@localhost',
        group       => ['polling-ctl', 'polling-data'],
        commands {
            'default' => \&mysub,
        },
        debug       => 0,
    );
    die "Can't create a new message object" unless $mbox;

    # stuff happens

    # Here we change the command control back to the bundled
    # handle_commands_aimed_at_me sub.
    $mbox->configure(
       commands => { 
         'override' => \&Spread::Message::handle_commands_aimed_at_me
       }
    );

=cut

sub configure
{
    my $self   = shift;
    my %config = @_;

    my @array_ref = qw/group logto/;
    my @scalar    = qw/debug name spread_name/;
    my @sub       = qw/member_sub message_sub error_sub timeout_sub/;
	my @hash      = qw/commands/;

    # Configure subroutine callbacks
    foreach (@sub)
    {
        if( defined $config{$_} && ref($config{$_}) ne 'CODE')
        {
            warn "config variable $_ should be a code reference. Skipping\n";
            next;
        }

		# Assign new call back if defined
        if(defined $config{$_})
		{
			$self->{$_} = $config{$_};
		}
		else # default to null sub unless one there already
		{
			unless(defined $self->{$_})
			{
				# Create a symbolic reference to each named sub and
				# assign it as a default.
				no strict 'refs';
				my $sub = "_".$_;
				$self->{$_} = \&$sub;
			}
		}
    }

	# Configure commands. Note: callbacks get overriden here!
    if(defined $config{'commands'})
    {
        if( defined $config{'commands'} && ref($config{'commands'}) ne 'HASH')
        {
            warn "config variable $_ should be a hash reference. Skipping\n";
            next;
        }

		my $hashref = $config{'commands'};
		# Assign new call back if defined
		for my $cmd (keys %$hashref)
		{
			if(ref($hashref->{$cmd}) eq 'CODE')
			{
				$self->{'commands'}{$cmd} = $hashref->{$cmd};
			}
			else # default to null sub unless one there already
			{
				warn "commands hash key: $cmd needs a ref to CODE";
			}
		}
		foreach (@sub)
		{
			$self->{$_} = \&handle_commands_aimed_at_me;
		}
    }

    # Configure array reference variables
    foreach (@array_ref)
    {
        if( defined $config{$_} && ref($config{$_}) ne 'ARRAY')
        {
            warn "config variable $_ should be an array reference. Skipping\n";
            next;
        }
        $self->{$_} = $config{$_} if defined $config{$_};

        # Make sure array reference variables have reasonable vaules
        $self->{$_} = [] unless defined $self->{$_};
    }

    # Configure scalar variables
    foreach (@scalar)
    {
        if( defined $config{$_} && ref($config{$_}))
        {
            warn "config variable $_ shouldn't be a reference. Skipping\n";
            next;
        }
        $self->{$_} = $config{$_} if defined $config{$_};
    }

    # Some reasonable defaults
    $self->{'name'}     = "pid$$"  unless defined $self->{'name'};
    $self->{'debug'}    = 0        unless defined $self->{'debug'};
    $self->{'group'}    = ['info'] unless defined $self->{'group'};
    $self->{'logto'}    = ['info'] unless defined $self->{'logto'};
	$self->{'mbox'}     = 0;

	# Need a daemon to connect to.
	$self->{'spread_name'} = '4803@localhost' unless defined $self->{'spread_name'};
    # Do a simple test on configuration details handed in. Are they valid?
    foreach my $ckey (keys %config)
    {
        next if grep($ckey eq $_, @array_ref, @scalar, @sub, @hash);
        warn "configure: unknown configuration variable $ckey\n";
    }

    return %$self;
}


=head2 B<connect()>

Connect an Spread::Message object to a Spread Daemon and join any groups
that have been configured. You almost need to use this method. It
is called by you after B<new()> when you first create an object.

	$mbox->connect();

You may wish to call this method if you B<disconnet()> and later wish to
reconnect to the same or another Spread daemon.

=cut

sub connect
{
	my $self = shift;
	my $name = $self->name;

	#$sperrno = undef;
	my($mbox, $private_group) = Spread::connect(
		{
			spread_name => $self->spread_name,
			private_name => $name,
		}
	);
	if($sperrno)
	{
		warn  "Failed to connect to Spread daemon: $sperrno\n";
		$self->mbox(0);
		return 0;
	}

	$self->{'private_group'} = $private_group;
	$self->mbox($mbox);

	# Join into our groups if we have some to join
	$self->join();

	return $mbox;
}


=head2 B<join()>

Join any groups that have been configured.

	$mbox->join(); # Joins configured groups
	$mbox->join('test'); # Joins the test group

Note: connect will join groups configured for you. So don't call
join unless you need to.

To find out what groups you have already joined use 

	my @joined_grps = $mbox->joined;

=cut

sub join
{
	my $self = shift;
	my @groups = @_;
	my $mbox = $self->mbox();

	@groups = @{$self->{'group'}} unless @groups;
	my @current = $self->joined;

	# Join into our groups if we have some to join
	if(@groups && $mbox)
	{
		my(@joined_groups) = grep( Spread::join($mbox,$_), @groups);

		unless($#groups == $#joined_groups)
		{
			warn  "Failed to join one or more groups: $sperrno\n";
		}

		@joined_groups = (@current, @joined_groups);
		$self->joined(\@joined_groups);

		return @joined_groups;
	}
	return wantarray ? () : 0;
}


=head2 B<leave()>

Leave one or more groups we have joined previously

	$mbox->leave(@grps);

=cut

sub leave
{
	my $self = shift;
	my @groups = @_;
	
	@groups = @{$self->{'group'}} unless @groups;

	my $mbox = $self->mbox() || return 0;

	my @joined = $self->joined();
	return 0 unless @joined;

	# Leave the groups
	my @left = ();
	for my $g (@groups)
	{
		unless(grep($_ eq $g,@joined))
		{
			warn "Can't leave $g. Not joined!\n";
			next;
		}
		if(Spread::leave($mbox,$g))
		{
			push(@left,$g);
			delete $self->{'members'}{$g} if defined $self->{'members'}{$g};
			@joined = grep( $_ ne $g, @joined);  # Remove group
		}
		else
		{
			warn  "Failed to leave group $g: $sperrno\n";
		}
	}
	$self->joined(\@joined);  # Update what is left
	return @left;
}


=head2 B<send()>

Send a message to set of group/s

	$mbox->send(@grps,$msg);

=cut

# sends all the messages to the recipient in such a manner that a
# large message can be concatenated back together
sub sendall
{
	my($self,$msg,@grp) = @_;

	return undef unless $self->{'mbox'};

	my $num = $#{@$msg};

	# These are guarenteed to arrive in order. Thanks Spread :-)
	for(my $i=0; $i <= $num; $i++)
	{
		$self->logit("Sending partial message $i of $num to: ",CORE::join(",",@grp),"\n") if $self->debug;
		$self->send(@grp,"Spread::Message part $i of $num\n".$msg->[$i]);
	}
}

sub send
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $msg  = pop(@_); # Message is last param
	my @grps = @_;
	unless(@grps)
	{
		warn "Nothing sent as no groups to send to";
		return 0;
	}

	my $mbox = $self->mbox;

	# Use agreed ordering and we don;t want to see what was sent
	my $type = AGREED_MESS | SELF_DISCARD; 

	# Check to see if they DO want to see the message
	if(grep($self->me eq $_,@grps))
	{
		$type = AGREED_MESS;
	}

	my $rtn = 0;
	if(length($msg) > 100 * 1024)
	{
		warn "send -- message big [", length($msg), "] chopping\n" if $self->debug;

		my $size = 90 * 1024;
		# Chop into 90K chunks and gather left overs as well :-)
		my @chunks = unpack("A$size" x (length($msg)/$size + 1), $msg);
		return $self->sendall(\@chunks,@grps);
	}

	if(@grps > 1)
	{
		$rtn = Spread::multicast($mbox, $type, [@grps], 0,$msg);
	}
	else
	{
		$rtn = Spread::multicast($mbox, $type, $grps[0], 0,$msg);
	}

	unless(defined $rtn)
	{
		warn "Failed to send data - $sperrno\n";
		return 0;
	}

	if($self->debug)
	{
		warn "Sent ", $msg,"\n";
	}

	return $rtn;
}


=head2 B<sends()>

Send a message to set of group/s

	$mbox->sends(@grps,$msg);

Note $msg is run through B<serialise()> so that B<sends()> can be used to send
Perl code between processes.

=cut


sub sends
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $ref  = pop(@_); # Message is last param
	my @grps = @_;

	my $mbox = $self->mbox;
	my $msg = $self->serialise($ref);

	return $self->send(@grps,$msg);
}

=head2 B<logit()>

Send a message to set of logto group/s

	$mbox->config( logto => ['a','b'] );
	or
	$mbox->logto('a','b');

	$mbox->logit($msg); # Send the txt message

You set the groups/addresses you want the messages sent to by configuring
the B<logto> variable.

The message is formatted such that the process id and hostname are
prepended to the message. Much like this:

	Tue Jul 29 18:12:20 2003:[19239@localhost] Got status message

=cut


sub logit (@)
{
	my $self = shift;
	my $h = hostname;

	my $prepend = scalar(localtime).":[$$" . '@' . "$h]:$Program_Name" .
	              "{" . $self->me . "} ";
	my @to = $self->logto;
	unless(@to)
	{
		warn $prepend,@_;
		return;
	}
	
	$self->send(@to,CORE::join("",($prepend,@_)));
}



=head2 B<decode()>

decode a message that has been sent using B<sends()>.

	my $msg = $mbox->decode() || die "Can't decode';
	print "The command is: ", $msg->{'cmd'}, "\n";
	print "The structure is: ", Dumper($mbox->command), "\n";

As a side effect the variable $mbox->command() is set to hold the Perl
structure returned as a result of the decode.

See FINE GRAINED CALLBACKS below for further details.

=cut

sub decode
{
    my $self = shift;
	return undef unless $self->{'mbox'};

    my $msg = $self->msg;

    # Decode message
    eval $msg; if($@) { cluck "Bad perl code seen $msg"; return; }
	$self->command($msg);
	return $msg;
}

=head2 B<disconnect()>

Disconnect from the Spread Daemon and reset internal states. The Basic
configuration remains however all details of the Spread connection are
lost.

	$mbox->disconnect();

=cut



sub disconnect
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $mbox = $self->mbox;

	unless(Spread::disconnect($mbox))
	{
		warn "disconnect -- $sperrno\n";
	}
	$self->mbox(0);
	delete $self->{'members'} if defined $self->{'members'};
	$self->type(0);
	$self->sender(0);

	my @grps = ();
	$self->grps(\@grps);
	$self->mess_type(0);
	$self->endian(0);
	$self->error(0);
	$self->timeout(0);
	$self->msg('');
	$self->new_msg(0);
	$self->joined(\@grps);
}

=head2 B<poll()>

Poll to see if there is a new message waiting for picking up. Returns the
size of the message waiting.

	if($mbox->poll())
	{
		#  Have a message to pick up
	}
	else
	{
		#  Have NO message to pick up
	}


=cut


sub poll
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my($messsize) = Spread::poll($self->mbox);
	if(defined($messsize))
	{
		return $messsize;
	}
	else
	{
		warn "poll -- $sperrno\n";
	}
}


=head2 B<get()>

Pick up the next data message in the queue. B<get()> will loop until a
regular data message has been received. It calls B<getmsg()>.

	# wait for a data message - this could be a while
	my $msg = $mbox->get();

=cut

sub get
{
	my $self = shift;
	return undef unless $self->{'mbox'};


	my($message) = $self->getmsg(1);

	until($self->new_msg && $self->Is_regular_mess())
	{
		$message = $self->getmsg(1);
	}

	return $message;
}

# Set all acessor slots  and handle multi part messages
sub setstate
{
	my $s = shift;
	return undef unless $s->{'mbox'};

	my ($service_type, $sender, $groups, $mess_type, $endian, $message) = @_;

	$s->tm(time());

	# Check for timeout
	if ($sperrno == 3)
	{
		$s->error($sperrno);
		$s->new_msg(0);
		$s->timeout(1);
		$sperrno = 0;
		return;
	}

	unless(defined $service_type && defined $sender && defined $groups &&
	       defined $mess_type    && defined $endian && defined $message
		 )
	{
		$s->error($sperrno);
		$s->timeout(0);
		$s->new_msg(0);
		return;
	}

	my @grps = ();
	if( ref($groups) eq "SCALAR" )
	{
		@grps = ( $$groups );
	} 
	else
	{
		@grps = @$groups;
	}

	# Is it a partial message
	if( $message =~ /^Spread::Message part (\d+) of (\d+)\s*$/m)
	{
		my($part,$total) = ($1,$2);

		# Remove the header details
		$message =~ s/^Spread::Message part \d+ of \d+\n//s;
		$s->logit("Got partial message part $part of $total from $sender\n") if $s->debug;

		# Is it the final message?
		if($part == $total)
		{
			$s->{'partial'}{$sender} .= $message;
			$s->msg($s->{'partial'}{$sender});
			delete $s->{'partial'}{$sender};
			$s->new_msg(1);
			$s->type($service_type);
			$s->sender($sender);
			$s->grps(\@grps);
			$s->mess_type($mess_type);
			$s->endian($endian);
			$s->error(0);
			$s->timeout(0);

			return;
		}
		else # Just store away this piece
		{
			$s->{'partial'}{$sender} = '' if $part == 0;
			$s->{'partial'}{$sender} .= $message;
			$s->new_msg(0);
			$s->timeout(0);
			return;
		}
	}
	else # Normal complete message
	{
		$s->type($service_type);
		$s->sender($sender);
		$s->grps(\@grps);
		$s->mess_type($mess_type);
		$s->endian($endian);
		$s->error(0);
		$s->timeout(0);

		$s->msg($message);
		$s->new_msg(1);
	}

}



=head2 B<rx()>

receive next bunch of messages and trigger any call backs as
required. Also pass all other arguments to any called routines.

	$mbox->rx($timeout,"loop 20");

Will have B<rx> wait for $timeout seconds and call any of the defined
callback methods with a copy of $mbox and "loop 20" in this example.

Every callback function can expect to receive at least one paramater
which is a copy of the B<mbox> and then any further paramters as defined
in the call to B<rx>.

B<rx> will return whatever the callback returns.

=cut

sub rx
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $timeout = shift;

	my($message) = $self->getmsg($timeout);

	#print Dumper($self);

	# Check for timeouts first
	if($self->timeout)
	{
		return $self->{'timeout_sub'}->($self,@_);
	}

	# handle member messages first
	if($self->Is_membership_mess)
	{
		return $self->{'member_sub'}->($self,@_);
	}
	# handle Regular message
	elsif($self->Is_regular_mess)
	{
		return $self->{'message_sub'}->($self,@_);
	}
	# Only have errors left
	else
	{
		return $self->{'error_sub'}->($self,@_);
	}
}



=head2 B<getmsg()>

get the next mesage from our queue and set the current state details
accordingly. All the ACCESSOR functions below will be updated.

	my $msg = $mbox->getmsg($timeout)

	or

	$mbox->getmsg($timeout);
	my $msg = $mbox->msg;

	or

	$mbox->getmsg($timeout);
	if($mbox->new_msg)
	{
		my $msg = $mbox->msg;
	}

B<getmsg> will return the next message only if there is one to return.
Otherwise it returns a null string.

With debugging turned on getmsg will also print details of messages
received.

=cut

sub getmsg
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $wait = shift || 5;

	$self->setstate(Spread::receive($self->{'mbox'},$wait));
	if($self->debug && $self->new_msg)
	{
		my @grps = $self->grps;
		@grps = (' ') unless defined $grps[0];
		# Regular message?
		if($self->Is_regular_mess)
		{
			warn "** Regular Message received **\n";
			warn "Service Type     : ",$self->type,"\n";
			warn "Sender           : ",$self->sender,"\n";
			warn "Sent to          : ", CORE::join(",",@grps),"\n";
			warn "Message Type     : ",$self->mess_type,"\n";
			warn "Endian Missmatch : ",$self->endian ? "Yes" : "No" ,"\n";
			warn "I am             : ",$self->me,"\n";
			warn "Message          : ",$self->msg,"\n" if $self->debug > 1;
		}
		elsif($self->Is_membership_mess) # membership message
		{
			
			warn "** Membership Message received **\n";
			warn "Service Type     : ",$self->type,"\n";
			warn "For group        : ",$self->sender,"\n";
			warn "Sent to          : ", CORE::join(",",@grps),"\n";
			warn "I member number  : ",$self->mess_type,"\n";
			warn "Endian Missmatch : ",$self->endian ? "Yes" : "No" ,"\n";
			warn "I am             : ",$self->me,"\n";
		}
		else
		{
			warn "** Unknown Message received **\n";
			warn "Service Type     : ",$self->type,"\n";
			warn "Sender           : ",$self->sender,"\n";
			warn "Sent to          : ", CORE::join(",",@grps),"\n";
			warn "Message Type     : ",$self->mess_type,"\n";
			warn "Endian Missmatch : ",$self->endian ? "Yes" : "No" ,"\n";
			print "I am             : ",$self->me,"\n";
			warn "Message          : ",$self->msg,"\n" if $self->debug > 1;
		}
	}

	# Why this message
	my $txt = '';

	# grps holds the complete memebership list for this sender. So store
	# it away for later query by members() function
	if($self->Is_reg_memb_mess) # Regular membership message
	{
		my $group = $self->sender;    # Group it affects
		my @membership = $self->grps; # Who got the message
		$self->{'members'}{$group} = \@membership;

		# Also store away other stuff that is contained in the message
		# groupID, numGroups, Groups
		# 12bytes, 4bytes,    sit on MAX_GROUP_NAME boundaries terminated by 0
		my $mgn = 32; # MAX_GROUP_NAME
		my $msg = $self->msg;
		my @gid = ();
		my $numg = 0;
		my $who;
		($gid[0],$gid[1],$gid[2],$numg,$who) = unpack("IIIIa*",$msg);

		$who =~ s/[[:cntrl:]]+/ /go; # Just to clean it up
		$who =~ s/\s+$/ /go;         # No space at end thanks

		# Establish why this message was recieved
		$txt = "$who joining"       if $self->Is_caused_join_mess;
		$txt = "$who leaving"       if $self->Is_caused_leave_mess;
		$txt = "$who disconnecting" if $self->Is_caused_disconnect_mess;
		$txt = "Network change"     if $self->Is_caused_network_mess;
		if($self->debug)
		{
			warn "groupID = @gid, Num grps in msg = $numg\n";
			warn $txt,"\n";
		}
	}
	elsif($self->Is_transition_mess)
	{
		$txt = 'Transition for group '.$self->sender."\n";
	}
	elsif($self->Is_caused_leave_mess)
	{
		$txt = 'membership message that left group '.$self->sender."\n";
	}
	elsif($self->Is_reject_mess)
	{
		$txt = 'Reject from '.$self->sender."\n";
	}
	elsif($self->Is_regular_mess)
	{
		$txt = "regular message\n";
	}
	else
	{
		$txt = "Error unknown message\n";
	}
	$self->reason($txt);

	return $self->new_msg ? $self->msg : '';
}

sub to_int
{
	my($buf,$offset) = @_;
	my @ints = ((substr($buf,$offset++,1) & 0xFF) x 4);
	return ($ints[0] << 24) | ($ints[1] << 16) | ($ints[2] << 8) | $ints[3];
}

sub members
{
	my $self = shift;
	my @grps = @_;

	my @rtn = ();

	if(@grps)
	{
		foreach(@grps)
		{
			if(defined($self->{'members'}{$_}))
			{
				push(@rtn,@{$self->{'members'}{$_}});
			}
		}
	}
	else # Return everything
	{
		foreach(keys %{$self->{'members'}})
		{
			push(@rtn,@{$self->{'members'}{$_}});
		}
	}
	return @rtn;
}

=head1 ACCESSORS

=over

=item B<mbox()> - return the current Spread Mailbox connection id

=cut

sub mbox 
{ 
	$_[0]->{'mbox'} = $_[1] if defined $_[1];
	return $_[0]->{'mbox'}; 
}

=item B<grps()> - return the current groups the last message was sent to

=cut

sub grps 
{ 
	$_[0]->{'last_groups'} = $_[1] if defined $_[1];
	return defined $_[0]->{'last_groups'} ? @{$_[0]->{'last_groups'}} : (); 
}


=item B<joined()> - return the current groups we have joined succesfully

=cut

sub joined 
{ 
	$_[0]->{'joined'} = $_[1] if defined $_[1];
	return defined $_[0]->{'joined'} ? @{$_[0]->{'joined'}} : (); 
}

=item B<logto()> - return the current groups we will log to

=cut

sub logto 
{ 
	$_[0]->{'logto'} = $_[1] if defined $_[1];
	return @{$_[0]->{'logto'}}; 
}

=item B<sender()> - return the sender of the last message.

=cut

sub sender 
{ 
	$_[0]->{'last_sender'} = $_[1] if defined $_[1];
	return $_[0]->{'last_sender'}; 
}

=item B<type()> - return the service type of the last message.

=cut

sub type 
{ 
	$_[0]->{'last_service_type'} = $_[1] if defined $_[1];
	my $s = shift;

	return 'no type defined' unless defined $s->{'last_service_type'};

	if($s->Is_regular_mess)
	{
		return 'Is_regular_mess';
	}
	elsif($s->Is_transition_mess) # membership transistion
	{
		# sender will be set to the name of the group for which the
		# membership change is occuring.
		# The  importance  of the TRANS_MEMB_MESS is that it
		# tells the application that  all messages  received  after
		# it and before the REG_MEMB_MESS for the same group are
		# 'clean up' messages to put the messages  in a consistant
		# state before actually changing memberships.
		return 'Is_transition_mess';
	}
	elsif($s->Is_reg_memb_mess) # Regular membership message
	{
		# groups array will be set to the private group names of all
		#  members of this group in the new membership
		return 'Is_reg_memb_mess';
	}
	elsif($s->Is_self_leave)
	{
		return 'Is_self_leave';
	}
	return $s->{'last_service_type'}; 
}

=item B<mess_type()> - return the message type of the last message.

=cut

sub mess_type 
{ 
	$_[0]->{'last_mess_type'} = $_[1] if defined $_[1];
	return $_[0]->{'last_mess_type'}; 
}


=item B<reason()> - return the reason we got the last message

		"$who joining"
		"$who leaving"
		"$who disconnecting"
		"Network change"
		'Transition for group '.$self->sender
		'membership message that left group '.$self->sender
		'Reject from '.$self->sender
		"regular message"
		"Error unknown message"
=cut

sub reason 
{ 
	$_[0]->{'reason'} = $_[1] if defined $_[1];
	return $_[0]->{'reason'}; 
}

=item B<endian()> - return true if the last message has same endian

=cut

sub endian 
{ 
	$_[0]->{'last_endian'} = $_[1] if defined $_[1];
	return $_[0]->{'last_endian'}; 
}

=item B<msg()> - return the last message.

=cut

sub msg 
{ 
	$_[0]->{'last_message'} = $_[1] if defined $_[1];
	return $_[0]->{'last_message'}; 
}

=item B<command()> - return the last Perl structure decoded using the
B<decode()> method.

=cut

sub command 
{ 
	$_[0]->{'command'} = $_[1] if defined $_[1];
	return $_[0]->{'command'}; 
}

=item B<new_msg()> - return true if the last message was a new message
indicates and error when false

=cut

sub new_msg 
{ 
	$_[0]->{'new_message'} = $_[1] if defined $_[1];
	return $_[0]->{'new_message'} == 1; 
}

=item B<tm()> - return the time the last message was received

=cut

sub tm 
{ 
	$_[0]->{'last_time'} = $_[1] if defined $_[1];
	return $_[0]->{'last_time'}; 
}

=item B<timeout()> - did the last rx() call time out?

=cut

sub timeout 
{ 
	$_[0]->{'timeout'} = $_[1] if defined $_[1];
	return $_[0]->{'timeout'};
}


=item B<error()> - return the last error as defined by Spread B<sperror>

=cut

sub error 
{ 
	$_[0]->{'error'} = $_[1] if defined $_[1];
	return $_[0]->{'error'};
}

=item B<me()> - return my name as Spread knows it. This is needed to work out
if a message was sent to me directly rather than via a group. It is
effectively my private group name.

=cut

# private group
sub me 
{ 
	$_[0]->{'private_group'} = $_[1] if defined $_[1];
	return $_[0]->{'private_group'}; 
}   

=item B<spread_name()> - return the Spread daemon details

=cut

# Spread daemon to connect to
sub spread_name 
{ 
	$_[0]->{'spread_name'} = $_[1] if defined $_[1];
	return $_[0]->{'spread_name'}; 
}

=item B<name()> - return our defined name used when we first connected.

=cut

sub name 
{ 
	$_[0]->{'name'} = $_[1] if defined $_[1];
	return $_[0]->{'name'}; 
}

=item B<debug()> - return our debug level

=cut

sub debug 
{ 
	$_[0]->{'debug'} = $_[1] if defined $_[1];
	return $_[0]->{'debug'}; 
}


=item B<control_msg()> - Is the current message a control message for
me.

That is, does this message eminate from a .*-ctl group that I am joined
to OR is it directed specifically at me.

=cut

sub control_msg
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $me = $self->me;

	# True if it is a regular message and from a control group or my
	# private group
	return $self->Is_regular_mess && 
	       (grep(/-ctl$/,$self->grps) || grep($_ eq $me,$self->grps));
}


=item B<aimed_at_me> - Is the previous message aimed specifically at me

=cut

sub aimed_at_me
{
	my $self = shift;
	return undef unless $self->{'mbox'};

	my $me   = $self->me;

	return grep($_ eq $me,$self->grps);
}

=back

These methods return details of the current message. See the Spread
documentation for further details.

=over

=item B<Is_unreliable_mess()>

=item B<Is_reliable_mess()>

=item B<Is_fifo_mess()>

=item B<Is_causal_mess()>

=item B<Is_agreed_mess()>

=item B<Is_safe_mess()>

=item B<Is_regular_mess()>

=item B<Is_self_discard()>

=item B<Is_reg_memb_mess()>

=item B<Is_transition_mess()>

=item B<Is_caused_join_mess()>

=item B<Is_caused_leave_mess()>

=item B<Is_caused_disconnect_mess()>

=item B<Is_caused_network_mess()>

=item B<Is_membership_mess()>

=item B<Is_reject_mess()>

=item B<Is_self_leave()>

=back

=cut

sub Is_unreliable_mess { $_[0]->{'last_service_type'} & UNRELIABLE_MESS }
sub Is_reliable_mess { $_[0]->{'last_service_type'} & RELIABLE_MESS }
sub Is_fifo_mess { $_[0]->{'last_service_type'} & FIFO_MESS }
sub Is_causal_mess { $_[0]->{'last_service_type'} & CAUSAL_MESS }
sub Is_agreed_mess { $_[0]->{'last_service_type'} & AGREED_MESS }
sub Is_safe_mess { $_[0]->{'last_service_type'} & SAFE_MESS }
sub Is_regular_mess { ($_[0]->{'last_service_type'} & REGULAR_MESS) && !($_[0]->{'last_service_type'} & REJECT_MESS) }
sub Is_self_discard { $_[0]->{'last_service_type'} & SELF_DISCARD }
sub Is_reg_memb_mess { $_[0]->{'last_service_type'} &  REG_MEMB_MESS }
sub Is_transition_mess { $_[0]->{'last_service_type'} & TRANSITION_MESS }
sub Is_caused_join_mess { $_[0]->{'last_service_type'} & CAUSED_BY_JOIN }
sub Is_caused_leave_mess { $_[0]->{'last_service_type'} & CAUSED_BY_LEAVE }
sub Is_caused_disconnect_mess { $_[0]->{'last_service_type'} &  CAUSED_BY_DISCONNECT }
sub Is_caused_network_mess { $_[0]->{'last_service_type'} & CAUSED_BY_NETWORK }
sub Is_membership_mess  { ($_[0]->{'last_service_type'} & MEMBERSHIP_MESS) && !($_[0]->{'last_service_type'} & REJECT_MESS)  }
sub Is_reject_mess { $_[0]->{'last_service_type'} & REJECT_MESS }
sub Is_self_leave { ($_[0]->{'last_service_type'} & CAUSED_BY_LEAVE) && !($_[0]->{'last_service_type'} & (REG_MEMB_MESS | TRANSITION_MESS)) }

=head1 CALLBACKS

Some very simple call back are provided. You should override these when
calling B<new()>.

They basically print out a little information and then return. These are
defined as:

	Spread::Message::_member_sub

	Spread::Message::_message_sub

	Spread::Message::_error_sub

	Spread::Message::_timeout_sub

You can use them if you like. But I wouldn't :-)

=cut


sub _member_sub
{
	my $mbox = shift;
	my @args = @_;

	print scalar(localtime),": recieved a membership message\n";
	print scalar(localtime),": Because ",$mbox->reason,"\n";
	my @grps = $mbox->grps;
	print "Current grps are: ", CORE::join(", ",@grps),"\n" if defined $grps[0];
	
	my @joined = $mbox->joined;
	print "I have joined these groups: @joined\n";
	print "\t$_ => ", CORE::join(", ",$mbox->members($_)), "\n" foreach @joined;
}

sub _message_sub
{
	my $mbox = shift;
	my @args = @_;

	print scalar(localtime),": recieved a message\n";
	print "Args are:", Dumper(\@args),"\n" if @args;
	print "Message was: >>",$mbox->msg,"<<\n";
}

sub _error_sub
{
	my $mbox = shift;
	my @args = @_;

	print scalar(localtime),": Error callback triggered\n";
	print "Args are:", Dumper(\@args),"\n" if @args;
	print "Message was: >>",$mbox->msg,"<<\n";
}

sub _timeout_sub
{
	my $mbox = shift;
	my @args = @_;

	print scalar(localtime),": Timeout callback triggered\n";
	print "Args are:", Dumper(\@args),"\n" if @args;
}


=head1 FINE GRAINED CALLBACKS

Some fine grained callback subs are provided that you can extend. This
makes creating Message programms a little easier. We provide a simple
command interpreter that can handle commands sent to us using the
B<sends> method. It assumes the messages sent are done in this form:

	%msg = (
		cmd   => 'some sort of command',
		.
		.
	);

The only requirement is that the hashref sent to B<sends()> has a key
called B<cmd>, and that B<cmd> contains a valid command name to call.
Also, you must B<sends()> the message to a specific Spread user not to a
group. That is, B<aimed_at_me()> must return true when the message is
received.

We automatically handle commands where cmd is:

	shut or stop or die    => program dies
	restart                => program restarts itself
	clone                  => program creates another copy of self
	status                 => program sends() status info

It assumes you have defined a 'default' function. If not then a message
is printed.

You can define your own commands to
override the ones we provide. Or you can provide a single 'override'
function. This is done like this:

In the receiving application:

    use Data::Dumper;

    sub new 
    { 
        # We get the Spread::Message object and any args sent to rx()
        my($mbox,@args) = @_;

        # pick up decode command
        my %msg = %{$mbox->command};
        
        print "new() called with args @args\n"; 
        print "and message >",$mbox->msg,"<\n";
    }

    sub mydefault 
    { 
        # We get the Spread::Message object and any args sent to rx()
        my($mbox,@args) = @_;

        # pick up decoded command
        my %msg = %{$mbox->command};
        
        print "mydefault() called with args @args\n"; 
        print "and message >",$mbox->msg,"<\n";
    }

    my $mbox = Message->new(
        .
        .
        name  => "fping$$",
        group => ['polling-ctl', 'polling-data'],
        .
        # This says use the fine grained commands
        commands    => {
            'new'       => \&new,       # handle 'new' commands
            'default'   => \&mydefault, # handle left over commands

            # Only define this if you want to catch ALL the commands
            #'override'  => \&myoverride,
        },
        .
        .
    );

    while(1)
    {
        # Process different data as required
        $mbox->rx(30,'arg1','arg2');
    }

In the sending application:

    sub process_control
    {
        my $mbox = shift;

        # A global array to hold stuff
        @Settings::pingers = grep(/fping/,$mbox->grps);
    }

    my $mbox = Message->new(
        .
        group => ['polling-ctl', 'polling-data'],
        member_sub  => \&process_control,
        .
    );

    my %msg = (
        cmd   => 'new'
        .
        .
    );

    # Use rx() to receive any membership messages and make sure you snarf
    # away the id of the receiving application. Should exist in
    # @Settings::pingers once a receiving application has joined a group
    # of ours
    $mbox->rx(30,undef);
    my $id = shift(@Settings::pingers);

    $mbox->sends($id,\%msg);   # Send new command specifically to $id
    $msg{'cmd'} = 'restart';
    $mbox->sends($id,\%msg);   # Send restart command specifically to $id
    $msg{'cmd'} = 'funny';
    $mbox->sends($id,\%msg);   # Send funny command, will call default
    $msg{'cmd'} = 'clone';
    $mbox->sends($id,\%msg);   # Send clone command specifically to $id
    $msg{'cmd'} = 'stop';
    $mbox->sends($id,\%msg);   # Send stop command specifically to $id

=cut

sub handle_commands_aimed_at_me
{
    my ($self,@args) = @_;
	return undef unless $self->{'mbox'};


	# Message must be regular, new and aimed at me. No group messages
	# allowed
    if($self->aimed_at_me && $self->new_msg && $self->Is_regular_mess)
    {
        $self->logit("Message for me :-)\n") if $self->debug;
    }
    else
    {
        return @args;
    }
    #logit("Got message >>", $msg, "<<\n");

    # Decode message
	my $msg = $self->decode || return;
	if( !defined $msg->{'cmd'})
	{
		$self->logit("Not a command message: no 'cmd' key in structure\n");
		return @args;
	}
    $_ = $msg->{'cmd'};

    $self->logit("Executing $_\n") if $self->debug;

	# Allow the user to override all our help!
	if(defined $self->{'commands'}{'override'})
	{
		$self->logit("Executing override()\n") if $self->debug;
		return $self->{'commands'}{'override'}->($self,@args);
	}

	# extract a command from the input and call its counterpart in the
	# %commands hash if it exists
	s/\s+.*//;    # Remove everything after any white space
	if(defined $self->{'commands'}{$_})
	{
		$self->logit("Executing $_ ()\n") if $self->debug;
		return $self->{'commands'}{$_}->($self,@args);
	}

	# We are here only if the user hasn't overriden us or hasn't provided
	# a specific command handler for the command. If we can't provide a
	# handler for the command then we print a message and return
    if(/^shut|^stop|^die/i)
    {
		$self->logit("Exiting - bye!\n") if $self->debug;
        $self->disconnect();
        exit;
    }
    elsif(/^restart/i)
    {
        $self->logit("Disconnecting from Spread and restarting\n") if $self->debug;
        $self->disconnect();
        exec "$Command";   # Just rerun ourselves
    }
    elsif(/^clone/i)
    {
        $self->logit("Cloning a new process\n")if $self->debug;
        clone();
    }
    elsif(/^noop/i)
    {
        $self->logit("noop message recieved - check the sender\n")if $self->debug;
    }
    elsif(/^status/i)
    {
        $self->logit("Object details:\n") if $self->debug;
        $self->logit(Dumper($self),"\n") if $self->debug;
        $self->logit("Settings::state\n") if $self->debug;
        $self->logit(Dumper(\%Settings::state),"\n") if $self->debug;
    }
    elsif(defined $self->{'commands'}{'default'})
    {
        $self->logit("Calling Default Handler for >$_<.\n") if $self->debug;
		return $self->{'commands'}{'default'}->($self,@args);
    }
	else
	{
        $self->logit("No Default Handler for >$_<.\n");
	}

    return @args;
}


# Utility Functions
sub clone
{
    my($pid) = fork;        # fork child
    if ($pid)       # return if parent
    {
        #warn("Parent: $$ forked child: $pid");
        return;
    }
    die "Couldn't fork: $!\n" unless defined($pid);

    # Child code from here
    # Become our own session leader
    POSIX::setsid() ||
        die "Can't start new session: $!\n";

        # Exec ourselves from scratch
        #warn("Cloning - $Command");
        exec "$Command";   # Just rerun ourselves
}


=head1 Bugs and other stuff

There are bound to be bugs in this code. It is first cut code that even
though used extensively hasn't been used broadly. By that I mean, the
bits of this code that I have used, works well for me, but my use isn't
your use, and you may stumble across bugs.

If you do find bugs, then please go to the effort of reporting it in a
manner in which I can get a good understanding of what your talking
about.

Please note: I have no affiliation with The Spread Group Communication
Toolkit. I also know next to nothing about messaging and group
communication, so dont' ask me about these things.

This module is offered in good faith as is.

=cut

=head1 TODO

Lots-n-lots

=cut

=head1 Copyright

Copyright 2003-2006, Mark Pfeiffer

This code may be copied only under the terms of the Artistic License or
the GNU General Public License, version 2 or later
which may be found in the Perl 5 source kit.

Use 'perldoc perlartistic' to see the Artistic License.
Use 'perldoc perlgpl' to see the GPL License.

Complete documentation for Perl, including FAQ lists, should be found on
this system using `man perl' or `perldoc perl'.  If you have access to the
Internet, point your browser at http://www.perl.org/, the Perl Home Page.

=cut


1;
