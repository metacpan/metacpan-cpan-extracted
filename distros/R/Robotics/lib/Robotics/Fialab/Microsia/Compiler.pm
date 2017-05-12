
package Robotics::Fialab::Microsia::Compiler;

#
# FIALab MicroSIA
# Compiler to generate hardware commands
#

use warnings;
use strict;

use YAML::XS;
use Moose::Role; # within Robotics::Fialab::Microsia
use Carp;

=head1 NAME

Robotics::Fialab::Microsia::Compiler - (Internal module)
Compiles commands from Perl method to peripheral hardware tokens


=head2 All Functions

Internal functions.  Data communications for this hardware.

Returns 0 on error, status string if OK.

=over 4

=item FIALab Microsia the following types of commands ("ascii commands"):

=over 4

=item Syringe Pump commands

=item Peristaltic Pump commands

=item External IO commands

=item Valve commands

=back

Each subsystem in the peripheral is addressed prior to commands.

=back

=cut

my $Debug = 1;

# The below vars should be made into attributes related to 'datapath'
# for current setup, redundancy must always be 1 (contrary to docs)
my $IGNORE_REDUNDANCY = 1;  
# for current setup, addressing must be disabled (contrary to docs)
my $IGNORE_SUBSYS_ADDRESS = 1;


sub compile {
    my $self    = shift;
    my $cmd     = shift;
    my %userdata = @_;
    
    # Get the subsystem
    # Allow application to specify module => 'syringe' or get from HWTYPE
    my $subsys  = $userdata{"address"} || 
            $self->DATAPATH()->WRITE_ADDRESS() || 
            "";
        
    # Look up the command
    my $subsys_address = $Robotics::Fialab::Microsia::comm_ydata->{"address"}->{$subsys};
    
    if (!$subsys || !$subsys_address) {
        warn "no address '$subsys' for $cmd; try setting 'address'!\n";
        return;
    }
    $self->DATAPATH()->WRITE_ADDRESS( $subsys );
    
    my $cmdsref = $Robotics::Fialab::Microsia::comm_ydata->{$subsys};
    my $cmdref = $cmdsref->{"send"}->{$cmd};
    if (!$cmdref) {
        carp "no cmdref for $cmd with address '$subsys' => ignoring";
        return;
    }
    if ($cmdsref->{"send"}->{$cmd}->{"dangerous"}) { 
        carp __PACKAGE__." command $cmd is dangerous; ignoring";
        return "";
    }
    # Get the params & param names for the command
    # Perform argument matching and some checking
    my @validargs = @{$cmdref->{"args"}};
    my $opcode = $cmdref->{"opcode"};
    shift @validargs;
    print "\n$subsys:$cmd ". join(" "). " => $opcode, args: ".
            join("  ", @validargs). "\n" if $Debug;
    ## DEBUG ## print "\n---\n".YAML::XS::Dump($cmdref) if $Debug;
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
            if (($ptype =~ /optional/ || grep(/optional/, @flags))
                    && $userdata{$pname} == 0) { 
                # user specified zero for optional value so omit it 
                ## TODO Does this apply to this device firmware?
                #push(@output, "");
                #next;
            }
            if (!$userdata{$pname} && (@default = grep(/default=/, @flags))) { 
                # default is assigned and no user value => use default
                $default[0] =~ /default=(.*)/;
                push(@output, $1);
                next;
            }
            if ($ptype =~ m/([-]?\d+)-(\d+)/) {
                # Range, so do boundary check 
                my $min = $1;
                my $max = $2;
                if ($userdata{$pname} && 
                        $userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    carp "improper user value for parameter $arg ".
                            " when called with $cmd ".join(" ", @_). 
                            " => ignoring\n";
                    return "";
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
            # Unspecified argument; use zero
            # TODO Add state here to set defaults of named params
            push(@output, "0");
        }
    }

    
    my $data;
    # Create subsystem address
    if (!$IGNORE_SUBSYS_ADDRESS) { 
        $data = chr(27). chr(2). $subsys_address;
    }
    
    my $op;
    if ($output[0] =~ /\$/) { 
        # Use argument substitution to create mixed string opcode+operands
        my $re = $output[0];
        $output[0] =~ s/\$(\d)/$output[$1]/g;
        $op = $output[0];
    }
    else { 
        # concatenate opcode + operands
        $op = join("", @output);
    }
    
    # Insert args as tokens into command. add terminator. add redundancy.
    my $redundancy = $cmdref->{"redundancy"} || 1;
    if ($IGNORE_REDUNDANCY) { $redundancy = 1; }
    
    my $delay = $cmdref->{"delay"} || 0;
    $delay = $delay * $redundancy;
    for (1 .. $redundancy) { 
        $data .= join("", $op, chr(13));
    }
    
    # Save state for the write and expected reply
    my $recv = $self->{comm_ydata}->{$subsys}->{"send"}->{$cmd}->{"recv"} || "";
    $self->DATAPATH()->EXPECT_RECV( $recv );
    $self->DATAPATH()->WRITE_DELAY( $delay );
    
    return $data;
}

1;    # End of Robotics::Fialab::Microsia::Compiler


__END__

