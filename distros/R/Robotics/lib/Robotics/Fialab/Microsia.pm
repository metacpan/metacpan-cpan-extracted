
package Robotics::Fialab::Microsia;

use warnings;
use strict;

use Moose;

with 'Robotics::Fialab::Microsia::Compiler';
#with 'Robotics::Fialab::Microsia::Session';

my $Debug = 1;

has 'connection' => ( is => 'rw' );
has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Fialab::Microsia]' );
has 'EXPECT_RECV' => ( is => 'rw', isa => 'Maybe[Str]' );


our $comm_ydata;

# Read the YAML-formatted 'translator data' from __DATA__
# Maybe use File::ShareDir & Module::Install to store yaml in a separate file
if (!$comm_ydata) {
    my $comm_yamlstring;
    {
        local( $/ ) = ( undef );
        $comm_yamlstring = <DATA>;    
        $comm_yamlstring =~ s/__END__//;
    }
    
    $comm_ydata = YAML::XS::Load($comm_yamlstring);
    die "Config data empty" 
        unless $comm_ydata->{"address"}->{"valve"};
}

sub probe {
    my %list;
    return \%list;
}

=head1 NAME

Robotics::Tecan::Microsia - (Internal module) Control of Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

Microsia hardware support for Robotics::Fialab.  
This hardware includes a syring pump, multi-position valve (8 positions),
peristaltic pump, and external output logic pin.  It uses a serial 
communications port with ascii commands for control.


=head1 EXPORT


=head1 FUNCTIONS

=head2 new


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Fialab::Microsia


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

1; # End of Robotics::Tecan::Microsia

__DATA__
%YAML 1.1
--- # Fialab-Microsia
address:
    syringe: A
    valve: C
    peristaltic: D
    external: B
valve:
    send: # delay after cmds 100ms - 1 sec
        NP_SET:
            desc: set number of physical ports
            opcode: NP
            args:
                - 1
                - numport:4-12
            redundancy: 2 # send cmd twice
            delay: 100 # ms
            recv:
                ok: ~
                err: ~
        NP_GET:
            desc: get number of physical ports
            opcode: NP
            args:
                - 0
            redundancy: 2 # send cmd twice
            delay: 100 # ms
            recv:
                ok: ~
                err: ~
        MOVE_DIRECT:
            desc: move to position via shortest route
            opcode: GO
            args:
                - 1
                - pos:1-12
            redundancy: 2 # send cmd twice
            recv:
                ok: ~
                err: ~
        MOVE_CCW:
            desc: move to position counter-clockwise
            opcode: CC
            args:
                - 1
                - pos:1-12
            redundancy: 2 # send cmd twice
            recv:
                ok: ~
                err: ~      
        MOVE_CW:
            desc: move to position clockwise
            opcode: CW
            args:
                - 1
                - pos:1-12
            redundancy: 2 # send cmd twice
            recv:
                ok: ~
                err: ~
        GET_POS:
            desc: get position
            opcode: CP
            args:
                - 0
            redundancy: 2 # send cmd twice
            recv:
                ok: string
                err: ~   
peristaltic:
    send: # delay after cmds 100ms - 1 sec
        SET_SPEED:
            desc: set pump speed
            opcode: G
            args:
                - 1
                - speed:0-100
            delay: 100
            recv:
                ok: ~
                err: ~       
        SET_DIRECTION:
            desc: set pump direction, direction:1=counterclockwise or 2=clockwise
            opcode: W
            args:
                - 1
                - direction:1-2:default=1
            delay: 5000
            recv:
                ok: ~
                err: ~        
        STOP:
            desc: stop pump
            opcode: W7
            args:
                - 0
            delay: 100
            recv:
                ok: ~
                err: ~
syringe:
    send: # delay after cmds 100ms - 1 sec
        INIT_ALL:
            desc: init all (both) pumps
            opcode: _Z0R
            args:
                - 0
            delay: 100
            recv:
                ok: ~
                err: ~     
        INIT:
            desc: init given pump
            opcode: /$1Z$2R
            args:
                - 2
                - pumpnum:1-2:default=1
                - force:0-1:optional:default=0
            delay: 100
            recv:
                ok: ~
                err: ~   
        SET_INPUT:
            desc: position valve in for given pump
            opcode: /$1IR
            args:
                - 1
                - pumpnum:1-2:default=1
            delay: 100
            recv:
                ok: ~
                err: ~                 
        SET_OUTPUT:
            desc: position valve out for given pump
            opcode: /$1OR
            args:
                - 1
                - pumpnum:1-2:default=1
            delay: 100
            recv:
                ok: ~
                err: ~         
        BYPASS:
            desc: bypass given pump
            opcode: /$1BR
            args:
                - 1
                - pumpnum:1-2:default=1
            delay: 100
            recv:
                ok: ~
                err: ~           
        SET_POS:
            desc: set absolute position
            opcode: /$1A$2R
            args:
                - 1
                - pumpnum:1-2:default=1
                - position:0-3000:default=1500
            delay: 100
            recv:
                ok: ~
                err: ~  
        ASPIRATE:
            desc: aspirate to relative step position
            opcode: /$1P$2R
            args:
                - 1
                - pumpnum:1-2:default=1
                - steps:0-3000:default=3000
            delay: 100
            recv:
                ok: ~
                err: ~  
        DISPENSE:
            desc: dispense to relative step position
            opcode: /$1D$2R
            args:
                - 1
                - pumpnum:1-2:default=1
                - steps:0-3000:default=3000
            delay: 100
            recv:
                ok: ~
                err: ~  
        SET_SPEED:
            desc: set speed in 0.5 steps/sec
            opcode: /$1V$2R
            args:
                - 1
                - pumpnum:1-2:default=1
                - speed:5-5800:default=1400
            delay: 100
            recv:
                ok: ~
                err: ~  
        GET_STATUS:
            desc: set absolute position
            opcode: /$1Q
            args:
                - 1
                - pumpnum:1-2:default=1
            delay: 100
            recv:
                ok: ~
                err: ~ 
recv:
    ok:
       0: ok
    error:
       1: E_unknown
__END__

