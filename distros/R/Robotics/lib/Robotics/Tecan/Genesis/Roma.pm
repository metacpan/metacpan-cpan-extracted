
package Robotics::Tecan::Genesis::Roma;

#
# Tecan Genesis
# Motor commands
#

use warnings;
use strict;
use Moose::Role;
use Carp;

my $Debug = 1;

#extends 'Robotics::Tecan::Genesis';


=head1 NAME

Robotics::Tecan::Genesis::Roma - (Internal module)
Handler for low level robotic movement arm hardware

=head2 CheckMotorOK

Internal function.  Verifies named motor is OK to move or prior move was
successful.

Returns 0 on error, status string if OK.

=cut

sub CheckMotorOK {
	my $self         = shift;
    my $motorname    = shift;
    my $motornum     = shift;

    my $reply;
    my $code;
    my $token;

    $code = $self->compile1("REE",
        motorname => $motorname);
    if (!$code) { 
        carp __PACKAGE__. " bad motorname '$motorname'?";
        return 0;
    }
    $self->DATAPATH()->write($code);
    $reply = $self->DATAPATH()->read();
    my $replytxt = $self->decompile1_reply($reply);
    if ($replytxt =~ /^E/) { 
        # command error
        carp __PACKAGE__." Robotics cmd error: $replytxt\n";
        return 0;       
    }
    # set reply to only result string, strip '0;'
    $reply = substr($reply, 2);
    if (!($reply =~ m/^@@@@/)) {
        # TODO: Add gripper check; for now, gripper status is ignored 
        warn __PACKAGE__." Robotics error found: $reply\n"; 
        return 0;
    }
    warn __PACKAGE__. " $motorname$motornum status: $reply\n" if $Debug;
    return $reply;
}

1;    # End of Robotics::Tecan::Genesis::Roma

__END__

