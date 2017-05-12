package Net::Telnet::Netscreen;

#-----------------------------------------------------------------
#
# Net::Telnet::Netscreen - Control Netscreen firewalls 
#
# by Marcus Ramberg <m@songsolutions.no>
# Lots of code ripped from Net::Telnet::Cisco;
#
#-----------------------------------------------------------------

use strict;
use Net::Telnet 3.02;
use Carp;

use vars qw($AUTOLOAD @ISA $VERSION);

@ISA      = qw (Net::Telnet);
$VERSION  = '1.2';


#------------------------------
# New Methods
#------------------------------


# ping a host, return true if can be reached
sub ping {
    my ($self,$host)=@_;
    if ($self->cmd('ping '.$host)) {
      my $l=$self->lastline;
      if ($l =~ /Success Rate is (\d+) percent/) {
        return $1;
      } else { print "FOO", $l };
    }
    return 0;  
}

# Displays the last prompt.
sub last_prompt {
    my $self = shift;
    my $stream = $ {*$self}{net_telnet_Netscreen};
    exists $stream->{last_prompt} ? $stream->{last_prompt} : undef;
}


# Displays the last command.
sub last_cmd {
    my $self = shift;
    my $stream = $ {*$self}{net_telnet_Netscreen};
    exists $stream->{last_cmd} ? $stream->{last_cmd} : undef;
}

# Displays the current vsys
sub current_vsys { 
  my ($self) =@_;
  if ($self->ha_mode ne '') {
    $self->last_prompt =~ /\(([\w.-]+)\)\(\w+\)/ ? $1 : '';
  } else {
    $self->last_prompt =~ /\(([\w.-]+)\)/ ? $1 : '';
  }
}

# enter a vsys
sub enter_vsys { 
  my ($self, $vsys) = @_;
  if ($self->current_vsys) {
     return $self->error('Already in a vsys');
  }
  my %vsys = $self->get_vsys();
  if (exists $vsys{$vsys}) {
    if ($self->cmd('enter vsys '.$vsys)) {
      return 1;
    } else {
      return $self->error('Error entering vsys');
    }
  } else { return $self->error("Vsys not found");}
}

sub ha_mode {
  my ($self) = @_;
  my $stream = $ {*$self}{net_telnet_Netscreen};
  return $stream->{ha_mode};
}

# exit a vsys or main {
sub exit { 
  my ($self,$save) =@_;
  my $stream = $ {*$self}{net_telnet_Netscreen};
  if ($self->current_vsys) {
    $self->cmd('save') if $stream->{changed};
    $self->cmd('exit');
    $stream->{changed}=0;
  } else {
    $self->cmd('save') if $stream->{changed};
    $self->close;
  }
}

#get a hash of the vsys in existence.
sub get_vsys {
  my $self = shift;
  my (%vsys,$result,$backupsys);
  if ($self->current_vsys) {
    $backupsys=$self->current_vsys;
    $self->cmd('exit');
  }
  my @results = $self->getValue("vsys");
  if ($backupsys) {$self->enter_vsys($backupsys);}
  foreach $result (@results) {
    if ($result=~/([\w.-]+)\s+(\d+)\s+/) {
      $vsys{$1}=$2;
    }
  }
  return %vsys;
}

#get a value from the ns box
sub getValue {
  my ($self, $setting) = @_;
  return $self->error("No setting specified") unless $setting;
  my @result= $self->cmd("get ".$setting); 
  if ($self->lastline =~ /\$\$Ambigious command!!/) {
    return $self->error("Ambigious command");
  }
  return @result;
}

#set a value in ns box
sub setValue {
  my ($self,$setting, $value) = @_;
  return $self->error("No setting specified") unless $setting;
  return $self->error("No value specified") unless $value;

  my @results=$self->cmd("set ".$setting." ".$value);
  foreach my $result (@results) {
    if ($result =~ /\w+/) { return $self->error($result); }
  }
  return 1;
}

#------------------------------------------
# Overridden Methods
#------------------------------------------

#destructor!

sub DESTROY {
  my $self=shift;
  if ($self->current_vsys()) {
    $self->exit;
  }
  $self->exit;
}

#set the prompt to that of a Netscreen box..
sub new {
    my $class = shift;

    # There's a new cmd_prompt in town.
    my $self = $class->SUPER::new(
       	prompt => '/[\w().-]*\(?([\w.-])?\)?\s*->\s*$/',
	@_,			# user's additional arguments
    ) or return;

    *$self->{net_telnet_Netscreen} = {
	last_prompt  => '',
        last_cmd     => '',
	ha_mode	     => '',
	changed      => 0,
    };

    $self
} # end sub new

# The new prompt() stores the last matched prompt for later
# fun 'n amusement. You can access this string via $self->last_prompt.
#
# It also parses out any router errors and stores them in the
# correct place, where they can be acccessed/handled by the
# Net::Telnet error methods.
#
# No POD docs for prompt(); these changes should be transparent to
# the end-user.
sub prompt {
    my( $self, $prompt ) = @_;
    my( $prev, $stream );

    $stream  = ${*$self}{net_telnet_Netscreen};
    $prev    = $self->SUPER::prompt;

    ## Parse args.
    if ( @_ == 2 ) {
        defined $prompt or $prompt = '';

        return $self->error('bad match operator: ',
                            "opening delimiter missing: $prompt")
            unless $prompt =~ m|^\s*/|;

	$self->SUPER::prompt($prompt);

    } elsif (@_ > 2) {
        return $self->error('usage: $obj->prompt($match_op)');
    }

    return $prev;
} # end sub prompt



sub scrolling_cmd {
    my ($self, @args) = @_;
    my (
	$arg,
	$buf,
	$cmd_remove_mode,
	$firstpos,
	$lastpos,
	$lines,
	$orig_errmode,
	$orig_prompt,
	$orig_timeout,
	$output,
	$output_ref,
	$prompt,
	$remove_echo,
	$rs,
	$rs_len,
	$telopt_echo,
	$timeout,
	@cmd,
	);
    local $_;

    ## Init vars.
    $output = [];
    $cmd_remove_mode = $self->SUPER::cmd_remove_mode;
    $timeout = $self->SUPER::timeout;
    $self->SUPER::timed_out('');
    return if $self->SUPER::eof;

    ## Parse args.
    if (@_ == 2) {  # one positional arg given
	push @cmd, $_[1];
    }
    elsif (@_ > 2) {  # named args given
	## Parse the named args.
	while (($_, $arg) = splice @args, 0, 2) {
	    if (/^-?cmd_remove/i) {
		$cmd_remove_mode = $arg;
		$cmd_remove_mode = "auto"
		    if $cmd_remove_mode =~ /^auto/i;
	    }
	    elsif (/^-?output$/i) {
		$output_ref = $arg;
		if (defined($output_ref) and ref($output_ref) eq "ARRAY") {
		    $output = $output_ref;
		}
	    }
	    elsif (/^-?prompt$/i) {
		$prompt = $arg;
	    }
	    elsif (/^-?string$/i) {
		push @cmd, $arg;
	    }
	    elsif (/^-?timeout$/i) {
		$timeout = &_parse_timeout($arg);
	    }
	    else {
		return $self->SUPER::error('usage: $obj->cmd(',
				    '[Cmd_remove => $boolean,] ',
				    '[Output => $ref,] ',
				    '[Prompt => $match,] ',
				    '[String => $string,] ',
				    '[Timeout => $secs,])');
	    }
	}
    }

    ## Override some user settings.
    $orig_errmode = $self->SUPER::errmode('return');
    $orig_timeout = $self->SUPER::timeout(&_endtime($timeout));
    $orig_prompt  = $self->SUPER::prompt($prompt) if defined $prompt;
    $self->SUPER::errmsg('');

    ## Send command and wait for the prompt.
    $self->print(@cmd);
     my ($input,$match) = $self->SUPER::waitfor(Match=>$self->prompt,
           			         String=>"\n--- more ---");
     while ($match) {
      $lines=$lines.$input;
      last if (eval "\$match =~ ".$self->prompt);
      $self->SUPER::print("");
     ($input,$match) = $self->SUPER::waitfor(Match=>$self->prompt,
           		              String=>"\n--- more ---");
    }
    chomp($lines); # Cleanup output
    ## Restore user settings.
    $self->SUPER::errmode($orig_errmode);
    $self->SUPER::timeout($orig_timeout);
    $self->SUPER::prompt($orig_prompt) if defined $orig_prompt;

    ## Check for failure.
    return $self->SUPER::error("command timed-out") if $self->SUPER::timed_out;
    return $self->error($self->SUPER::errmsg) if $self->SUPER::errmsg ne '';
    return if $self->SUPER::eof;

    ## Split lines into an array, keeping record separator at end of line.
    $firstpos = 0;
    $rs = $self->SUPER::input_record_separator;
    $rs_len = length $rs;
    while (($lastpos = index($lines, $rs, $firstpos)) > -1) {
	push(@$output,
	     substr($lines, $firstpos, $lastpos - $firstpos + $rs_len));
	$firstpos = $lastpos + $rs_len;
    }

    if ($firstpos < length $lines) {
	push @$output, substr($lines, $firstpos);
    }

    ## Determine if we should remove the first line of output based
    ## on the assumption that it's an echoed back command.
    ## FIXME: I had to uncomment this for now. Hope it doesn't
    ## break stuff too badly for anyone ;>
#    if ($cmd_remove_mode eq "auto") {
#	## See if remote side told us they'd echo.
#	$telopt_echo = $self->SUPER::option_state(&TELOPT_ECHO);
#	$remove_echo = $telopt_echo->{remote_enabled};
#    }
#    else {  # user explicitly told us how many lines to remove.
#	$remove_echo = $cmd_remove_mode;
#    }

    ## Get rid of possible echo back command.
    while ($remove_echo--) {
	shift @$output;
    }

    ## Ensure at least a null string when there's no command output - so
    ## "true" is returned in a list context.
    unless (@$output) {
	@$output = ('');
    }

    ## Return command output via named arg, if requested.
    if (defined $output_ref) {
	if (ref($output_ref) eq "SCALAR") {
	    $$output_ref = join '', @$output;
	}
	elsif (ref($output_ref) eq "HASH") {
	    %$output_ref = @$output;
	}
    }

    wantarray ? @$output : 1;
} # end sub scrolling_cmd



sub cmd {
    my $self             = shift;
    my $ok               = 1;
    my $cmd;

    # Extract the command from arguments
    if ( @_ == 1 ) {
	$cmd = $_[0];
    } elsif ( @_ >= 2 ) {
	my @args = @_;
	while ( my ( $k, $v ) = splice @args, 0, 2 ) {
	    $cmd = $v if $k =~ /^-?[Ss]tring$/;
	}
    }

    $ {*$self}{net_telnet_Netscreen}{last_cmd} = $cmd;
    $ {*$self}{net_telnet_Netscreen}{changed} = 1 
      if $cmd =~ m/^\s*(set|unset)/;

    my @output = $self->scrolling_cmd(@_);

    for ( my ($i, $lastline) = (0, '');
	  $i <= $#output;
	  $lastline = $output[$i++] ) {

	# This may have to be a pattern match instead.
	if ( $output[$i] =~ /^\s*\^-+/ ) {

	    if ( $output[$i] =~ /unknown keyword (\w+)$/ ) { # Typo & bad arg errors
		chomp $lastline;
		$self->error( join "\n",
			             "Last command and firewall error: ",
			             ( $self->last_prompt . $cmd ),
			             $lastline,
			             "Unknown Keyword:" . $1,
			    );
		splice @output, $i - 1, 3;

	    } else { # All other errors.
		chomp $output[$i];
		$self->error( join "\n",
			      "Last command and firewall error: ",
			      ( $self->last_prompt . $cmd ),
			      $output[$i],
			    );
		splice @output, $i, 2;
	    }

	    $ok = undef;
	    last;
	}
    }
    return wantarray ? @output : $ok;
}

sub waitfor {
    my $self = shift;
    return unless @_;

    # $isa_prompt will be built into a regex that matches all currently
    # valid prompts.
    #
    # -Match args will be added to this regex. The current prompt will
    # be appended when all -Matches have been exhausted.
    my $isa_prompt;

    # Things that /may/ be prompt regexps.
    my $promptish = '^\s*(?:/|m\s*\W).*';


    # Parse the -Match => '/prompt \$' type options
    # waitfor can accept more than one -Match argument, so we can't just
    # hashify the args.
    if ( @_ >= 2 ) {
	my @args = @_;
	while ( my ( $k, $v ) = splice @args, 0, 2 ) {
	    if ( $k =~ /^-?[Mm]atch$/ && $v =~ /($promptish)/ ) {
		if ( my $addme = re_sans_delims($1) ) {
		    $isa_prompt .= $isa_prompt ? "|$addme" : $addme;
		} else {
		    return $self->error("Bad regexp '$1' passed to waitfor().");
		}
	    }
	}
    } elsif ( @_ == 1 ) {
	# A single argument is always a match.
	if ( $_[0] =~ /($promptish)/ and my $addme = re_sans_delims($1) ) {
	    $isa_prompt .= $isa_prompt ? "|$addme" : $addme;
	} else {
	    return $self->error("Bad regexp '$_[0]' passed to waitfor().");
	}
    }


    # Add the current prompt if it's not already there.
    if ( index($isa_prompt, $self->prompt) != -1
	 and my $addme = re_sans_delims($self->prompt) ) {
	$isa_prompt .= "|$addme";
    }

    # Call the real waitfor.
    my ( $prematch, $match ) = $self->SUPER::waitfor(@_);

    # If waitfor was, in fact, passed a prompt then find and store it.
    if ( $isa_prompt && defined $match ) {
	(${*$self}{net_telnet_Netscreen}{last_prompt})
	    = $match =~ /($isa_prompt)/;
    }
    return wantarray ? ( $prematch, $match ) : 1;
}


sub login {
    my($self) = @_;
    my(
       $cmd_prompt,
       $endtime,
       $error,
       $lastline,
       $match,
       $orig_errmode,
       $orig_timeout,
       $passwd,
       $prematch,
       $reset,
       $timeout,
       $usage,
       $username,
       %args,
       );
    local $_;

    ## Init vars.
    $timeout = $self->timeout;
    $self->timed_out('');
    return if $self->eof;
    $cmd_prompt = $self->prompt;
    $usage = 'usage: $obj->login(Name => $name, Password => $password, '
	   . '[Prompt => $match,] [Timeout => $secs,])';

    if (@_ == 3) {  # just username and passwd given
	($username, $passwd) = (@_[1,2]);
    }
    else {  # named args given
	# Get the named args.
	(undef, %args) = @_;

	# Parse the named args.
	foreach (keys %args) {
	    if (/^-?name$/i) {
		$username = $args{$_};
		defined($username)
		    or $username = "";
	    }
	    elsif (/^-?pass/i) {
		$passwd = $args{$_};
		defined($passwd)
		    or $passwd = "";
	    }
	    elsif (/^-?prompt$/i) {
		$cmd_prompt = $args{$_};
		defined $cmd_prompt
		    or $cmd_prompt = '';
		return $self->error("bad match operator: ",
				    "opening delimiter missing: $cmd_prompt")
		    unless ($cmd_prompt =~ m(^\s*/)
			    or $cmd_prompt =~ m(^\s*m\s*\W)
			   );
	    }
	    elsif (/^-?timeout$/i) {
		$timeout = _parse_timeout($args{$_});
	    }
	    else {
		return $self->error($usage);
	    }
	}
    }

    return $self->error($usage)
	unless defined($username) and defined($passwd);

    ## Override these user set-able values.
    $endtime = _endtime($timeout);
    $orig_timeout = $self->timeout($endtime);
    $orig_errmode = $self->errmode('return');

    ## Create a subroutine to reset to original values.
    $reset
	= sub {
	    $self->errmode($orig_errmode);
	    $self->timeout($orig_timeout);
	    1;
	};

    ## Create a subroutine to generate an error for user.
    $error
	= sub {
	    my($errmsg) = @_;

	    &$reset;
	    if ($self->timed_out) {
		return $self->error($errmsg);
	    }
	    elsif ($self->eof) {
		($lastline = $self->lastline) =~ s/\n+//;
		return $self->error($errmsg, ": ", $lastline);
	    }
	    else {
		return $self->error($self->errmsg);
	    }
	};

    ## Wait for login prompt.
    ($prematch, $match) = $self->waitfor(-match => '/[Ll]ogin[:\s]*$/',
					 -match => '/[Uu]sername[:\s]*$/',
					 -match => '/[Pp]assword[:\s]*$/')
	or do {
	    return &$error("read eof waiting for login or password prompt")
		if $self->eof;
	    return &$error("timed-out waiting for login or password prompt");
	};

    unless ( $match =~ /[Pp]ass/ ) {
	## Send login name.
	$self->print($username)
  	    or return &$error("login disconnected");

	## Wait for password prompt.
	$self->waitfor(-match => '/[Pp]assword[: ]*$/')
	    or do {
		return &$error("read eof waiting for password prompt")
		    if $self->eof;
		return &$error("timed-out waiting for password prompt");
	    };
    }
	
    # Send password.
    $self->print($passwd)
        or return &$error("login disconnected");

    # Wait for command prompt or another login prompt.
    ($prematch, $match) = $self->waitfor(-match => '/[Ll]ogin[:\s]*$/',
					 -match => '/[Uu]sername[:\s]*$/',
					 -match => '/[Pp]assword[:\s]*$/',
					 -match => $cmd_prompt)
	or do {
	    return &$error("read eof waiting for command prompt")
		if $self->eof;
	    return &$error("timed-out waiting for command prompt");
	};

    # Reset object to orig values.
    &$reset;

    # It's a bad login if we got another login prompt.
    return $self->error("login failed: access denied or bad name or password")
	if $match =~ /(?:[Ll]ogin|[Uu]sername|[Pp]assword)[: ]*$/;

   #if we have paranthesis at this point, box is in ha mode
    $ {*$self}{net_telnet_Netscreen}{ha_mode} = $1
        if $match =~/\((\w+)\)/;

    1;
} # end sub login

#------------------------------
# Class methods
#------------------------------

# Return a Net::Telnet regular expression without the delimiters.
sub re_sans_delims { ( $_[0] =~ m(^\s*m?\s*(\W)(.*)\1\s*$) )[1] }

# Look for subroutines in Net::Telnet if we can't find them here.
sub AUTOLOAD {
    my ($self) = @_;
    croak "$self is an [unexpected] object, aborting" if ref $self;
    $AUTOLOAD =~ s/.*::/Net::Telnet::/;
    goto &$AUTOLOAD;
}

=pod

=head1 NAME

Net::Telnet::Netscreen - interact with a Netscreen firewall

=head1 SYNOPSIS

use Net::Telnet::Netscreen;

my $fw = new Net::Telnet::Netscreen(host=>'192.168.1.1');
$fw->login('admin','password') or die $fw->error;
$fw->enter_vsys('wineasy.no');
print "We are now in: ".$fw->current_vsys."\n";
my %vsys=$fw->get_vsys;
   foreach $key (sort (keys %vsys)) {
     print $key,'=', $vsys{$key},"\n";
   }
print @results;

=head1 DESCRIPTION

Net::Telnet::Netscreen is mostly a pure rippoff of Net::Telnet::Cisco, with
adaptations to make it work on the Netscreen firewalls.
It also has some additional commands, but for basic functionality, 
see Net::Telnet and Net::Telnet::Cisco documentation.

=head1 FIRST

Before you use Net::Telnet::Netscreen, you should probably have a good
understanding of Net::Telnet, so perldoc Net::Telnet first, and then
come back to Net::Telnet::Netscreen to see where the improvements are.

Some things are easier to accomplish with Net::SNMP. SNMP has three
advantages: it's faster, handles errors better, and doesn't use any
vtys on the router. SNMP does have some limitations, so for anything
you can't accomplish with SNMP, there's Net::Telnet::Netscreen.

=head1 METHODS

New methods not found in Net::Telnet follow:





=head2 enter_vsys - enter a virtual system

Enter a virtual system in the firewall.
parameter is system you want to enter .
You may enter another vsys even if you are
in a vsys. Note that we will save your changes
for you if you do.
(only works for ns-500+)


=head2 exit_vsys - exit from the level you are on

exit from the vsys you are in, or from the system
if you are on the top. takes one parameter.
if you should save any changes or not.
(only works for ns-500+)


=head2 current_vsys - show current vsys

return the vsys you currently are in.
returns blank if you're not in a vsys.
(only works for ns-500+)


=head2 get_vsys - return vsys.

returns a hash of all the virtual systems
on your system, with system id's for values
(only works for ns-500+)

=head2 ha_mode - return high availability mode.

return the HA mode, if your system is in a HA cluster,
or false if it isn't.

=head2 ping - ping a system.

Returns percentage of success (0-100).

  $sucess=$fw->ping('192.168.1.1');

=head2 exit - Exit system

use this command to exit system, or exit current
vsys

=head2 getValue - Set a value from the box.

Will return a value from the firewall, or from
the vsys you are in, if you aren't in root.

=head2 setValue - Set a Value in the box.

Set a value in the box, returns true if set successfully.
(guess what it returns if you fuck up? ;)

=head2 lastPrompt - Show the last prompt returned.

Shows the last prompt returned by your netscreen
device.

=head2 lastCmd - Show the last command executed.

Shows the last command executed on your netscreen
device.

=head1 OVERRIDEN METHODS

=head2 last_cmd

=head2 cmd

=head2 last_prompt

=head2 login

=head2 new

=head2 re_sans_delims

=head2 scrolling_cmd

=head2 waitfor

See L<Net::Telnet> for documentation on these methods.

=head1 AUTHOR

The basic functionality was ripped from
Joshua_Keroes@eli.net $Date: 2002/07/18 10:45:12 $
Modifications and additions to suit Netscreen was
done by
m.ramberg@wineasy.no $Date: 2002/07/18 10:45:12 $

=head1 SEE ALSO

Net::Telnet, Net::SNMP

=head1 COPYRIGHT

Copyright (c) 2001 Marcus Ramberg, Song Networks Norway.
All rights reserved. This program is free software; you
can redistribute it and/or modify it under the same terms
as Perl itself.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1;

__END__
