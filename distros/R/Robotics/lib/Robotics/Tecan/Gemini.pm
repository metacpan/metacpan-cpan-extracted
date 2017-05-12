package Robotics::Tecan::Gemini;
# vim:set ai shiftwidth=4 tabstop=4 expandtab:

use warnings;
use strict;

use Moose;
use Carp;

extends 'Robotics::Tecan', 'Robotics::Tecan::Genesis';

# This module is not meant for direct inclusion.
# Use it "with" Tecan::Genesis.

my $PIPENAME;
my $Debug = 1;

has 'attached' => ( is => 'rw', isa => 'Bool' );
has 'last_reply' => ( is => 'rw', isa => 'Str' );
has 'object' => ( is => 'ro', isa => 'Robotics::Tecan' );
has 'FID' => ( is => 'rw', isa => 'Maybe[Win32::Pipe]' );


=head1 NAME

Robotics::Tecan::Gemini - (Internal module)
Software-to-Software interface for Tecan Gemini Win32
Application for controlling robotics hardware

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Gemini software interface support for Robotics::Tecan.  
The Gemini software controls the Tecan robotics in legacy
environments.  In Perl Robotics environment, the Robotics
modules use this module to send (pipe) hardware commands
through Gemini software to the physical hardware.

Tecan has a separate software interface, EVOware, which is to
be implemented as a separate perl module in the future
(contact author).

This module is only useful in the framework of other Robotics
modules.  It probably should not be used on it's own.

This module may include (in the future) mechanisms for parsing
Gemini data files (*.gem or *.gwl files).

=head1 EXPORT


=head1 FUNCTIONS

=head2 new

=head1 FUNCTIONS

=head2 probe

Probe the local machine for a loaded/running(maybe) Gemini application to
communicate with as a software-software interface.

Finds the application only, does not find hardware (look at hardware modules
for that part).

Returns:

=item  Hash, with key:value as follows:  
key="Tecan-Genesis", 
value="not-started:name:token"  or "ok:name:token"
where name is the application-usable alias to use
for new()'s "unit" parameter, and token is an internal
reference for low level software.


=head2 openPipe

(Internal function) Do not call

Open communication to Gemini software<->software interface


=head2 startService

=item (Special method - Not normally used - Experimental)

Attempt to start the Windows GUI application associated with Tecan (such as
running "Gemini.exe").  Since this will occur under Win32, and there is no 
mechanism for forking, this call will likely never return.  Best not to
call this method if the Tecan application is already running: unexpected
Win32 results may occur.

This method should only be used when "Desktop" access to start the Tecan
application is unavailable (such as starting the service from a remote
machine over the network).  

Usage, for Tecan: 
Do query() first, to see if the robotics is "not started"; if it is not, use
this function to start Gemini, then query() again (the second time should find
the named pipe).


=cut


sub probe {
    my $class = shift;
    my %found;
    
=begin text
    #  Note: cygwin-perl cant
    #  access or test the named pipe.  If attempting to open a
    #  nonexistant pipe with Win32::Pipe and Gemini is not running, then
    #  Win32::Pipe will create it as a new pipe, thus the perl process will
    #  hang at the next read waiting for input from no one.  
    #  No good alternatives except to look for Gemini.exe in process
    #  list.

    # Pipe name begins with \\ to assure Win32 local server context.
	# It is created by Tecan 'Gemini' gui app at application start.

	# Win32 Incompatibility note:
	#  On Win32, the named pipe string is accessed differently running under
	#  cygwin-perl or running under cmd.exe+ActivePerl. cygwin-perl will 
	#  fail to open the pipe if open() or sysopen() is attempted. 
	#  cygwin+activestate perl
	#  will succeed (because apparently it handles the network path properly).
	#  Win32 Named Pipe "filename" format is: '\\\\SERVER/pipe/filename' 
	#       or use dot for local server '\\\\./pipe/filename' 
	#  '\\\\./pipe/gemini' or any combination does not work under cygwin+perl.
	#  '\\\\./pipe/gemini' works under cmd.exe+ActivePerl or cygwin+ActivePerl.
=cut

	if ($^O =~ m^cygwin^i || $^O =~ m^MSWin^i) {
	    # Found windows machine
	    if ($^O =~ m^MSWin^i) { 
	        # Activestate perl
	        warn "Recommend using cygwin-perl not Activestate Perl for Tecan named pipe: not tested\n";
	    }
	    else {
	        # found cygwin-perl
	    }
	    # Assume running under cygwin+ActiveState Perl or cmd.exe+ActiveState Perl
	    #  or cygwin+cygwin-perl
	    # Tested under: "This is perl, v5.10.0 built for MSWin32-x86-multi-thread"
	    # Tested under: "This is perl, v5.10.0 built for cygwin-thread-multi-64int"
	    $PIPENAME="\\\\.\\pipe\\gemini";
	    # For compatibility reasons, always use Win32::Pipe to access this pipe.
        if (-d "c:/Program Files/Tecan/Gemini") {
            # For Win32 support only
            my $incompatibility = "Win32::Process::List";
            eval "use $incompatibility";
            # -- end Win32 modules
    
            warn "Found Tecan Gemini, checking if running\n";
            # Found Gemini application however it may not be running.
            $found{"Tecan-Gemini"} = "not-started";
    
            # Must search for Gemini as running process or attempting to
            # open the pipe will permanentily hang the parent process.
            # But, no way to do this in Win32.
            my $obj = Win32::Process::List->new();
            if ($obj->GetProcessPid("gemini")) { 
                $found{"Tecan-Gemini"} = "ok";
                warn "Robotics.pm: Found Tecan Gemini, App is Running\n";
            }
            else { 
                warn "Robotics.pm: Found Tecan Gemini, App is NOT RUNNING\n";
            }
            # TODO Enhance this to return multiple machines with enumerated names
            my $index_name = "0";
            my $index_firmware = "1";
            $found{"Tecan-Gemini"} .= ",Robotics::Tecan::Genesis";
            $found{"Tecan-Gemini"} .= ",genesis$index_name,M$index_firmware";
	   }
	}
	else {
		# not on Win32 so assume for simulation/test only
		warn "!! Not on Win32 -- no local Tecan hardware is accessable\n";
		$PIPENAME = '/tmp/__gemini';
		unlink($PIPENAME);		# XXX: revisit this
		
		#$found{"Tecan-Gemini"} .= "network,Robotics::Tecan::Genesis,genesis0,M1";
	}

	return \%found;
}

sub BUILD { 
    my ($self) = shift;
    
    my $incompatibility = "Win32::Pipe";
    eval "use $incompatibility";

    my $pipename = $PIPENAME;
    if (!$pipename) { 
        die "no pipe name; notreached";
    }
    # Win32::Pipe constants:
    #   timeout = in millisec
    #   flags = PIPE_TYPE_BYTE(=0x0)  
    #   state = PIPE_READMODE_BYTE(=0x0)
    $| = 1;
    my $timeout = 0; # NMPWAIT_NOWAIT;
    my $flags = 0;
    my $pipe;
    my $data;

    # warn "!! Opening Win32::Pipe(".$pipename.")";
    $pipe = new Win32::Pipe($pipename, $timeout, $flags);
    if (!$pipe) { 
        warn "cant open named-pipe $pipename\n";
        return 0;
    }
    # warn "!! Got Win32::Pipe(), $pipe";

    if (0) {
        # test communication
        $pipe->Write("GET_VERSION\0");
        $data = $pipe->Read();
        if (!$data) { 
            # no reply
            $pipe->Close();
            warn "No response from hardware; pipe closed";
            return undef;
        }
    }

    # communication ok
    $self->FID( $pipe );
    $self->attached( 0 );
}

sub attach {
    my ($self, %params) = @_;
=begin text
    # Notes on gemini named pipe:
    #   * must run gemini application first
    #   * user must have installed "hardware key" (parallel port dongle)
    #   * login is required(?) sometimes(?)
    #   * must terminate commands with \0   (undocumented)
    #   * input terminated by \0
    #   * Big problem: can not use F_NOBLOCK on windows with activeperl so
    #   must read char at a time and check for \0 on input
    #       * Use CPAN Win32::Pipe to avoid issues
    #   * must use binmode() for pipe to look for the \0 and act unbuffered
    #       * Use CPAN Win32::Pipe to avoid issues
    #   * if command sent is not terminated by \0, then tecan s/w will
    #    send the same buffer as before, i.e. "GET_STATUSpreviousstuff"
    #	 or other buffer garbage
    #   * commands are case-insensitive
    #   * Use the gemini app "Gemini Log" window to view cmds/answers
    #   * The variables (like Set_RomaNo) use 0-based index (0,1,..) whereas
    #       the gemini GUI uses 1-based index (1,2,..)
=cut

    $self->attached( 1 );
    # Probe for Genesis
    # Fake the following 2 variables to probe
    $self->object()->HWTYPE( "GENESIS" ); 
    $self->object()->HWNAME( "M1" );
    # Probe for proper h/w compatibility
    $self->write("GET_VERSION");
    $self->object()->VERSION( $self->read() );
    print STDERR "\nVersion: ". $self->object()->VERSION(). "\n" if $Debug;
    $self->write("GET_RSP");
    $self->object()->HWTYPE( $self->read() );
    print STDERR "\nHardware: ". $self->object()->HWTYPE(). "\n" if $Debug;

    if (!($self->object()->HWTYPE() =~ /GENESIS/i)) {
        $self->detach();
        croak "Robotics is not Genesis; reports '".
                $self->object()->HWTYPE(). "': closed named-pipe\n";
        return 0;
    }

    # XXX assign this via arg to new, user discovers value from query
    # The HWALIAS and HWNAME should be set via hardware probe, user
    # discovers value from query
    $self->HWALIAS( "genesis0" );
    $self->HWNAME("M1");
    warn "ATTACHED via ". __PACKAGE__. "\n";

    my $m = $self->object()->HWNAME();
    my $reply;

    for my $addr ("M", "A", "P", "R") { 
        $self->write("COMMAND;". $addr. "1". "REE");
        $reply = $self->read();
        if ($reply =~ m/0;(.*)/) {
            my $status = $1;
            if (!$status) { 
                confess __PACKAGE__. " arm '$addr' status error!";
            }
            if ($status =~ m/[^@]/) { 
                warn __PACKAGE__. " arm '$addr' motor error!";
            }
        }
    }

    # Scan and get hardware device specifics
    # no. arms, diluters, options, posids, 
    # romas, uniports, options, voptions
    $self->write("COMMAND;A1RNT1");
    my $num_tips = $self->read();
    my @devices;
    if ($num_tips =~ m/0;(\d+)/) { 
        $num_tips = $1;
        for my $d (0 .. 7) { 
            $self->write("COMMAND;". $m."RSD".$d.",1");
            $reply = $self->read();
            if ($reply =~ m/0;(\d+)/) { 
                push(@devices, $1);
            }
            else { 
                push(@devices, 0);
            }
        }
    }
    else { 
        # technically speaking A1RNT1 num tips should
        # always equal the M1RSD num diluters (I assume)
        $num_tips = 0;
    }
    $self->object()->HWSPEC(
            "lihas=". $devices[0].
            ":diluters=". $devices[1].
            ":options=". $devices[2].
            ":posids=". $devices[3].
            ":romas=". $devices[4].
            ":uniports=". $devices[5].
            ":optionst=". $devices[6].
            ":optionsv=". $devices[7]         
            );
    print STDERR "\nHW Spec: ". $self->object()->HWSPEC(). "\n" if $Debug;
    # Get firmware revision of LIHA devices (syringe pumps)
    my $maxdev;
    my @dev_versions;
    for my $d (1 .. $num_tips) { 
        $self->write("COMMAND;D". $d. "Q23");
        $reply = $self->read();
        if ($reply =~ /^0;(.*)/) { 
            # found
            push(@dev_versions, "D". $d. "=". $1);

            $maxdev = $d;
        }
    }
    $self->object()->HWDEVICES( join(":", @dev_versions) );
    print STDERR "\nHW Liquid Devices: ". $self->object()->HWDEVICES(). "\n"
            if $Debug;
    $self->object()->TIP_MAX( $maxdev );

    # Scan and Get hardware options (optional i/o board)
    # "maximum two different devices accessible" using RRS
    @devices = ();
    if (0) { 
        # TODO
        # Needs test: currently hangs system (no io board attached on unit)

        $self->write($m."ARS");  # SCAN; no reply to this command
        ## no reply to ARS ## $reply = $self->read();
        for my $d (1 .. 2) { 
            $self->write($m."RRS".$d); # Report device on chN
            my $reply = $self->read();
            if ($reply =~ /^0;(.*)/) { 
                push(@devices, "D". $d. "=". $1);
            }
        }
        $self->HWOPTION( join(":", @devices) );
        print STDERR "\nHW Options: ". $self->HWOPTION(). "\n" if $Debug;
    }
    
}

sub startService {
    my $incompatibility = "Win32::Process";
    eval "use $incompatibility";

    my $exe = 'c:\\Program Files\\Tecan\\Gemini\\Gemini.exe';
    
    # Experimental code follows

    my $obj;
    if (0) { 
        return unless -x $exe;
        # This doesnt seem to work in winxp test
        Win32::Process::Create($obj,
                                $exe,
                                "",
                                0,
                                NORMAL_PRIORITY_CLASS,
                                ".") || die "Win32 process error with $exe\n";
    }
    if (0) {
        # Try this at some point in the future
        #use Win32::OLE;
        #use Win32::OLE::Variant;
        #$ex = Win32::OLE->new('Excel.Application', \&OleQuit) or die "oops\n";
        #$ex->{Visible} = 1;
        
    }
    return $obj;
}

sub write {
    my $self = shift;
    if ($self->attached()) {
        my $data = shift;
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        if ($self->{FID}) {
            $self->{FID}->Write($data . "\0");
            print STDERR ">$data\n" if $Debug;
        }
        else {
            warn "not reached";
        }
  }
  else {
      warn "! attempted write when not Attached";
      return "";
  }
}

sub read {
    my $self = shift;
    my $data;
    if ($self->{FID}) {
        my $byte;
        my $count;
        do { $byte = $self->{FID}->Read(); $data .= $byte if $byte; $count++; } 
            while ($byte && !($byte =~ m/\0/) && $count < 100);
        while (0) {  # XXX
            $byte = $self->{FID}->Read();
            last if $byte && $byte eq '\0';
            $count++;
            last if $count > 500;
            # sometimes undef is returned for $byte (blame Win32::Pipe)
            if ($byte) { $data .= $byte; }
        }
    }
    if ($data) { 
        print STDERR "<$data\n" if $Debug;
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        return $data;
    }
    else {
        return "";
    }
    return $data;
    
}        


sub close { 
    my ($self) = shift;
    $self->attached( 0 );  
    if ($self->FID()) { 
        $self->FID()->Close();
        $self->FID( undef );
    }    
    return;
}


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-robotics at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan::Gemini


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Robotics::Tecan::Gemini


__END__

