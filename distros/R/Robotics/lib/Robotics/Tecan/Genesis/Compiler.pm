
package Robotics::Tecan::Genesis::Compiler;

#
# Tecan Genesis
# Compiler to generate hardware commands
#

use warnings;
use strict;

use YAML::XS;
use Moose::Role;
use Carp;

=head1 NAME

Robotics::Tecan::Genesis::Compiler - (Internal module)
Compiles commands from Perl method to robotics hardware tokens


=head2 All Functions

Internal functions.  Data communications for this hardware.

Returns 0 on error, status string if OK.

=over 4

=item Tecan Genesis + Gemini software has (for the purposes of this module's design)
the following heirarchy of data communication:

=over 4

=item Gemini worklist commands (like: "A;...  D;...").
Not described in documentation.

=item Gemini *.gem script commands (like: "Aspirate(..)").
Not described in documentation.  Reverse engineer from the *.gem files.

=item Gemini script commands (like: "B;Aspirate(...)")

=item Gemini named pipe commands.  
Described in the thin documentation of "gem_pipe.pdf"

=item Low level single commands (like: "M1PIS").  
This is the raw robotics firmware command.
Described in the thin documentation of "gemfrm.hlp".
Sent through named pipe prefaced with "COMMAND;"

=back

Only the named pipe commands and low level single commands 
can be sent through the named pipe to control the robotics.  To run
the script commands, a dummy script file must be written to disk, and a pipe
command can be sent to execute the script file (like a bootstrap method).
Worklist commands can be executed using a double-bootstrap; to 
provide status of command completion, use the execute command to
run an external semaphore program to track script status.

Design note: To distinguish between command types, 
they are called 'type1' (firmware commands, single instruction) 
and 'type2' (multiple arguments with semicolon) in this code.

=back

=cut

my $Debug = 0;

sub compile1 {
	my $self    = shift;

    # Create command from "Single command" format (firmware style)
    my $cmd = shift;
    my %userdata = @_;
    
    # Assign subsystem / subdevice from 'unit' parameter ("machine", "roma", "liha", ...)
    my $subdev;
    my $subdev_addr;
    my $subdev_num;
    $subdev = $userdata{"unit"} || $userdata{"motorname"} || "machine";
    $subdev =~ s/genesis/machine/i;
    $subdev =~ s/(\d+)//;
    $subdev_num = $1 || 1;
    $subdev_addr = $Robotics::Tecan::Genesis::comm_ydata->{"type1commands"}->{"address"}->{$subdev};
    if (!$subdev_addr) {
        warn "no device address for unit '$subdev' for $cmd; check 'unit' parameter\n";
        carp;
        return;
    }
    
    # Look up the command
    my $cmdsref = $Robotics::Tecan::Genesis::comm_ydata->{"type1commands"};
    my $cmdref = $cmdsref->{"send-".$subdev}->{$cmd};
    if (!$cmdref) {
        warn "no cmdref on unit '$subdev' addr '$subdev_addr' for cmd '$cmd' args @_ => Sending dummy machine-command RFV";
        carp;
        $subdev = "machine";
        $subdev_addr = "M";
        $subdev_num = 1;
        $cmd = "RFV";
        $cmdref = $cmdsref->{"send-". $subdev}->{$cmd};
    }

    if ($cmdsref->{"send-". $subdev}->{$cmd}->{"dangerous"}) { 
        carp __PACKAGE__." '$subdev' command $cmd is dangerous; ignoring";
        return "";
    }
    
    # Get the params & param names for the command
    # Perform argument matching and some checking
    my $opcode = $cmdref->{"opcode"} || $cmd;
    my @validargs = @{$cmdref->{"args"}};
    shift @validargs;
    print "\nD$subdev,$cmd ". join(" "). " => $opcode, args: ".
        join("  ", @validargs). "\n" if $Debug;
    my @output = ( $opcode );
    my $arg;
    my @default;
    
    for $arg (@validargs) {
        my ($pname, $ptype, @flags) = split(":", $arg);
        if (!@flags) { @flags = (); }
        if (defined $ptype) {
            if ($ptype eq "zero") {
                # This param is always zero regardless of passed value
                push(@output, "0");
                next;
            }
            if (defined($pname) && !$userdata{$pname} && (@default = grep(/default=/, @flags))) {
                # default is assigned and no user value 
                if (grep(/optional/, @flags)) { 
                    # no user value to optional parameter => leave arg empty
                    push(@output, "");
                }
                else { 
                    # no user vlue to required parameter => use default
                    $default[0] =~ /default=(.*)/;
                    push(@output, $1);
                }
                next;
            }
            if (defined($ptype) && ($ptype =~ /optional/ || grep(/optional/, @flags))
                    && $userdata{$pname} == 0) { 
                # user specified zero for optional value so omit it (see docs)
                # Commands like "ABC,50,,,,," are allowed
                push(@output, "");
                next;
            }
            if (defined($ptype) && $ptype =~ m/([-]?\d+)-([\dn]+)/i) {
                # Range, so do boundary check 
                my $min = $1;
                my $max = $2;
                if ($max =~ m/n/i) {
                    $max = 255;
                }
                if (defined($userdata{$pname}) && 
                        $userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "out of bounds (min,max)=[$min,$max] user value for parameter $arg ".
                            "when called with $cmd ".join(" ", @_). 
                            " => ignoring\n";
                    return "";
                }
                warn "notreached";
            }
            # TODO Add unit conversion here to change user-given "1ml" to "1000ul"
            #  if ptype specifies different native units for hardware
            #    - won't that be cool.
        }
        if (defined $userdata{$pname}) { 
            # User set this parameter to user value
            push(@output, $userdata{$pname});
        }
        else {
            # Unspecified argument in opcode definition; die for type1commands
            confess ("missing parameter $arg in @_");
            # TODO: Force bad command
            return "";
        }
    }
    
    my $data;
    
    if ($output[0] =~ /\$/) { 
        # Use argument substitution to create mixed string opcode+operands
        $output[0] =~ s/\$(\d)/$output[$1]/g;
        $data = $output[0];
    }
    else { 
        # concatenate opcode + operands
        my $data_opcode = shift @output;
        $data = $data_opcode . join(",", @output);
    }
    
    # Join output parms to form pipe command
    $data = "COMMAND;". $subdev_addr. $subdev_num. $data;

    # Save state for the expected reply
    # TODO: Need to implement "pend for batch replies" for the "Group Feed" type commands
    my $replyref = $cmdref->{"recv"};
    my $replyref_chain = $self->DATAPATH()->EXPECT_RECV();
    if (defined($replyref)) { 
        if ($replyref->{"err"} eq "none" && $replyref->{"ok"} eq "none") { 
            # no special handling; this is handled inside decompile_reply1()
        }
    }
    else { 
        # Response to type1 command will always be at least the type2 response
        my $cmdsref = $Robotics::Tecan::Genesis::comm_ydata->{"type2commands"};
        my $cmdref = $cmdsref->{"send"}->{"COMMAND"};
        $replyref = $cmdref->{"recv"};
    }
    
    $self->DATAPATH()->EXPECT_RECV( $replyref );

    return $data;
}

sub compile {
	my $self    = shift;
    
    # Process Pipe commands    
    my $cmd = shift;
    my %userdata = @_;
    
    # Look up the command
    my $cmdsref = $Robotics::Tecan::Genesis::comm_ydata->{"type2commands"};
    my $cmdref = $cmdsref->{"send"}->{$cmd};
    if (!$cmdref) {
        warn "no cmdref for $cmd args @_ => Sending dummy command GET_STATUS";
        $cmdref = $cmdsref->{"send"}->{"GET_STATUS"};
    }
    if ($cmdsref->{"send"}->{$cmd}->{"dangerous"}) { 
        carp __PACKAGE__." command $cmd is dangerous; ignoring";
        return "";
    }
    # Get the params & param names for the command
    # Perform argument matching and some checking
    my @validargs = @{$cmdref->{"args"}};
    shift @validargs;
    print "\n$cmd ". join(" "). " => args: ".join("  ", @validargs). "\n" if $Debug;
    my @output = ( $cmd );
    my $arg;
    for $arg (@validargs) {
        my ($pname, $ptype, $flags) = split(":", $arg);
        if (!$flags) { $flags = ""; }
        if (defined $ptype) {
            if ($ptype eq "zero") {
                # This param is always zero regardless of passed value
                push(@output, "0");
                next;
            }
            if (($ptype =~ /optional/ || $flags =~ /optional/)
                    && $userdata{$pname} == 0) { 
                # user specified zero for optional value so omit it (see docs)
                #push(@output, "");
                next;
            }
            if ($ptype =~ m/([-]?\d+)-(\d+)/) {
                # Range, so do boundary check 
                my $min = $1;
                my $max = $2;
                if ($userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "improper user value $userdata{$pname} in $cmd ".join(" ", @_). 
                            " => sending dummy command GET_STATUS\n";
                    return $self->compile("GET_STATUS");
                }
                warn "notreached";
            }
            if ($ptype =~ m/([-]?\d+)-n/) {
                # Range, so do boundary check; assume max value (not in docs)
                my $min = $1;
                my $max = 255;
                if ($userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "improper user value $userdata{$pname} in $cmd ".join(" ", @_). 
                            " => sending dummy command GET_STATUS\n";
                    return $self->compile("GET_STATUS");
                }
                warn "notreached";
            }
            # TODO Add unit conversion here to change user-given "1ml" to "1000ul"
            #  if ptype specifies different native units for hardware
            #    - won't that be cool.
        }
        if (defined $userdata{$pname}) { 
            # User set this parameter to user value
            push(@output, $userdata{$pname});
        }
        else {
            # Unspecified argument; use zero
            # TODO Add state here to set defaults of named params
            push(@output, "0");
        }
    }
    
    # Join output parms with ';' to form pipe command
    my $data = join(";", @output);
    
    # Save state for the expected reply
    # TODO: Need to implement "pend for batch replies" for the "Group Feed" type commands
    my $replyref = $cmdref->{"recv"};
    if (defined($replyref)) { 
        if ($replyref->{"err"} eq "none" && $replyref->{"ok"} eq "none") { 
            $replyref = undef;
            warn "undef reply in cmdref";
        }
    }
    $self->DATAPATH()->EXPECT_RECV( $replyref );

    return $data;
}


sub decompile_reply {
    my ($self, %params) = shift;
    
    my $reply = $params{'reply'} || shift;
    if (!defined($reply)) { 
        warn __PACKAGE__. " no reply passed\n";
        return -1;
    }
    $reply =~ s/;$//;
    for my $refname ("recv") { 
        my $replyref = $Robotics::Tecan::Genesis::comm_ydata->{"type2commands"}->{$refname};
        my $eref = $replyref->{'err'};
        my $okref = $replyref->{'ok'};
    
        my $data;
        for $data (keys %{$okref}) { 
            if ($data eq $reply) { 
                return $okref->{$data};
            }
        }
        for $data (keys %{$eref}) { 
            if ($data eq $reply) { 
                return $eref->{$data};
            }
            my @list = split(/,/, $data);
            for my $arg (@list) { 
                if ($arg eq $reply) { 
                    return $arg;
                }
            }
        }   
    }
    carp __PACKAGE__. " no such reply '$reply'";
    return "";    
}

sub decompile1_reply {
    my ($self, %params) = shift;
    
    my $reply = $params{'reply'} || shift;
    if (!defined($reply)) { 
        warn __PACKAGE__. " no reply passed\n";
        return -1;
    }
    my $replyref = $self->DATAPATH()->EXPECT_RECV();
    if (defined($replyref)) { 
        # If reply is a literal string or literal int (may be
        # expected from successful command), then
        # pass the literal directly back
        my @types = split(":", $replyref->{"ok"});
        if (grep(/(string)|(int)/i, @types)) { 
            return $reply;
        }
        elsif (grep(/none/i, @types)) { 
            # No response expected from type1 command, so 
            # decode type2 response only.
            # Many type1 commands are listed as "Response: None".
            return decompile_reply(reply => $reply);
        }
        @types = split(":", $replyref->{"err"});
        if (grep(/(string)|(int)/i, @types)) { 
            return $reply;
        }
    }
    
    for my $refname ("recv-device", "recv-machine", "recv-roma", "recv-liha") { 
        my $replyref = $Robotics::Tecan::Genesis::comm_ydata->{"type1commands"}->{$refname};
        my $eref = $replyref->{'err'};
        my $okref = $replyref->{'ok'};
    
        my $data;
        for $data (keys %{$okref}) { 
            if ($data eq $reply) { 
                return $okref->{$data};
            }
        }
        for $data (keys %{$eref}) { 
            if ($data eq $reply) { 
                return $eref->{$data};
            }
            my @list = split(/,/, $data);
            for my $arg (@list) { 
                if ($arg eq $reply) { 
                    return $arg;
                }
            }
        }   
    }
    carp __PACKAGE__. " no such reply(1) '$reply'";
    return "";    
}

sub compile_xp {
    my $self = shift;
    
    # Create command from "Command Set XP style"
    my $cmd = shift;
    my %userdata = @_;
    
    #
    # This compiler has a 'chain' operation to allow concatenated commands
    # Commands are only terminated with "execute" opcode if user passes a
    #   the 'execute => true' parameter.
    
    # Assign subsystem / subdevice
    my $subdev;
    $subdev = $userdata{"tip"} || 0;
    if ($subdev < 1 || $subdev > 8) { 
        $subdev = "1";
    }
    my $subdev_addr = $Robotics::Tecan::Genesis::comm_ydata->{"type0commands"}->{"address"}->{$subdev};
    if (!$subdev_addr) {
        warn "no device address for tip '$subdev' for $cmd; check 'tip' parameter\n";
        return;
    }
    
    # Look up the command
    my $cmdsref = $Robotics::Tecan::Genesis::comm_ydata->{"type0commands"};
    my $cmdref = $cmdsref->{"send-xp3000"}->{$cmd};
    if (!$cmdref || !$subdev) {
        warn "no cmdref for $cmd or device $subdev args @_ => Sending dummy command GET_STATUS";
        $cmdref = $cmdsref->{"send-xp3000"}->{"GET_STATUS"};
        $subdev = 1;
    }

    # Prepare 'chain' data if specified, for prepending later
    my $chaindata = "";
    if ($userdata{"chain"}) { 
        # Verify 'chain' is destined for same device; otherwise die
        $chaindata = $userdata{"chain"};
        $chaindata =~ s/^(COMMAND;)D([\d])//g;
        my $chaindev = $2 || die;
        if ($chaindev != $subdev) { 
            carp("Must execute $chaindata to tip $chaindev ".
                "before Addressing tip $subdev with: ".join(" ", @_));
            return "";
        }
        $userdata{"chain"} = "";
    }
    if ($cmdsref->{"send"}->{$cmd}->{"dangerous"}) { 
        carp __PACKAGE__." command $cmd is dangerous; ignoring";
        return $userdata{"chain"};
    }
    # Terminate with 'execute' opcode if specified
    my $execute = "";
    if ($userdata{"execute"}) { 
        $execute = $cmdsref->{"send-xp3000"}->{"EXECUTE"}->{"opcode"};
        $userdata{"execute"} = "";
    }
    
    # Get the params & param names for the command
    # Perform argument matching and some checking
    my $opcode = $cmdref->{"opcode"};
    my @validargs = @{$cmdref->{"args"}};
    shift @validargs;
    print "\nD$subdev,$cmd ". join(" "). " => $opcode, args: ".
        join("  ", @validargs). "\n" if $Debug;
    my @output = ( $opcode );
    my $arg;
    my @default;
    
    for $arg (@validargs) {
        my ($pname, $ptype, @flags) = split(":", $arg);
        if (defined $ptype) {
            if ($ptype eq "zero") {
                # This param is always zero regardless of passed value
                push(@output, "0");
                next;
            }
            if (!$userdata{$pname} && (@default = grep(/default=/, @flags))) {
                # default is assigned and no user value => use default
                $default[0] =~ /default=(.*)/;
                push(@output, $1);
                next;
            }
            if (($ptype =~ /optional/ || grep(/optional/, @flags))
                    && $userdata{$pname} == 0) { 
                # user specified zero for optional value so omit it (see docs)
                #push(@output, "");
                next;
            }
            if ($ptype =~ m/([-]?\d+)-([\dn]+)/i) {
                # Range, so do boundary check 
                my $min = $1;
                my $max = $2;
                if ($max =~ m/n/i) {
                    $max = 255;
                }
                if (defined($userdata{$pname}) && 
                        $userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "out of bounds (min,max)=[$min,$max] user value for parameter $arg ".
                            "when called with $cmd ".join(" ", @_). 
                            " => sending dummy command GET_STATUS\n";
                    return $self->compile_xp("GET_STATUS");
                }
                warn "notreached";
            }
            # TODO Add unit conversion here to change user-given "1ml" to "1000ul"
            #  if ptype specifies different native units for hardware
            #    - won't that be cool.
        }
        if (defined $userdata{$pname}) { 
            # User set this parameter to user value
            push(@output, $userdata{$pname});
        }
        else {
            # Unspecified argument in opcode definition; ignore
        }
    }
    
    my $data;
    if ($output[0] =~ /\$/) { 
        # Use argument substitution to create mixed string opcode+operands
        $output[0] =~ s/\$(\d)/$output[$1]/g;
        $data = $output[0];
    }
    else { 
        # concatenate opcode + operands
        $data = join("", @output);
    }
    
    # Join output parms to form pipe command
    $data = "COMMAND;D". $subdev_addr. $chaindata. $data. $execute;

    # Save state for the expected reply
    my $replyref = $cmdref->{"recv"};
    my $replyref_chain = $self->DATAPATH()->EXPECT_RECV();
    if (defined($replyref)) { 
        if ($replyref->{"err"} eq "none" && $replyref->{"ok"} eq "none") { 
            $replyref = undef;
        }
        if ($chaindata && defined($replyref_chain)) { 
            # When chaining commands, expect the reply from first command
            # with valid expected reply.. the later commands are not error checked
            # (Tecan software seems to work the same)
            $replyref = $replyref_chain;
        } 
    }
    $self->DATAPATH()->EXPECT_RECV( $replyref );

    return $data;
}


sub decompile_reply_xp {
    my ($self, %params) = shift;
    
    my $reply = $params{'reply'} || shift;
    if (!defined($reply)) { 
        warn __PACKAGE__. " no reply passed\n";
        return -1;
    }
    
    my $replyref = $Robotics::Tecan::Genesis::comm_ydata->{"type0commands"}->{"recv-vcc"};
    my $eref = $replyref->{'err'};
    my $okref = $replyref->{'ok'};

    # The reply is likely in the form '\d;(reply)'
    my @replywords = split(";", $reply);
    if ($#replywords < 2) { 
        $reply = $replywords[0];
    }
    else {
        $reply = $replywords[1];
    }
    
    my $data;
    for $data (keys %{$okref}) { 
        if ($data eq $reply) { 
            return $okref->{$data};
        }
    }
    for $data (keys %{$eref}) { 
        if ($data eq $reply) { 
            return $eref->{$data};
        }
    }    
    carp __PACKAGE__. " no such reply(xp) '$reply'";
    return "";    
}

1;    # End of Robotics::Tecan::Genesis::Compiler

__END__

