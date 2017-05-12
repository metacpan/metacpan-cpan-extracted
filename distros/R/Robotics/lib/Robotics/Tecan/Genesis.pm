
package Robotics::Tecan::Genesis;

# vim:set shiftwidth=4 tabstop=4 expandtab 

use warnings;
use strict;

use Moose;
use Robotics::Tecan::Gemini;

with 'Robotics::Tecan::Genesis::Compiler';
with 'Robotics::Tecan::Genesis::Session';
with 'Robotics::Tecan::Genesis::Roma';
with 'Robotics::Tecan::Genesis::Liha';

has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Tecan]' );


my $Debug = 1;


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
        unless $comm_ydata->{"type2commands"}->{"send"}->{"GET_VERSION"};
}

sub probe {
    my %list;
    return \%list;
}

sub _getAxisNames { 
    my ($self, $name) = @_;    
    
    if ($name =~ /roma/i) { 
        my @axis = ("x", "y", "z", "r", "g");
        my @axisalias = ();
        return @axis;
    }
    elsif ($name =~ /liha/i) { 
        my @axis = ("x", "y", "ys", "z1", "z2", "z3", "z4", "z5", "z6", "z7", "z8");
        return @axis;
    }
    return ();
}


=head1 NAME

Robotics::Tecan::Genesis - (Internal module) Control of Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';



=head1 SYNOPSIS

Genesis hardware support for Robotics::Tecan.


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

    perldoc Robotics::Tecan


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

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of Robotics::Tecan::Genesis

__DATA__
%YAML 1.1
--- # Tecan-Genesis+Gemini # See Gem_Pipe.pdf and gemfirm.html
type2commands: # system named-pipe commands, see Gem_Pipe.pdf
    send: # args separated by ;
        SET_DITI:
            args:
                - 4
                - type:1-4 
                - grid:1-99 
                - site:0-63 
                - position:0-95
            recv:
                ok: 0
                err: 3,4
        SET_PNP_BARCODE:
            args:
                - 1
                - barcode
            recv:
                ok: 0
                err: 3,6
        SET_PNPNO:
            args:
                - 1
                - pnpnum
            recv:
                ok: 0
                err: 3
        SET_RACK:
            args:
                - 4
                - racknum:0-n 
                - barcode:optional 
                - location 
                - zero:zero
            recv:
                ok: 0
                err: 4
        SET_RACK_EXT:
            args:
                - 3
                - racknum:0-99 
                - barcode:optional 
                - location
            recv:
                ok: 0
                err: 4
        SET_ROMA_BARCODE:
            args:
              - 1
              - barcode
            recv:
                ok: 0
                err: 3,6
        SET_ROMANO:
            args:
              - 1
              - romanum
            recv:
                ok: 0
                err: 3
        SET_VARIABLE:
            args:
              - 2
              - varname 
              - varvalue:float
            recv:
                ok: 0
                err: 3,10
        SET_VARIABLE_EXT:
            args:
              - 2
              - varname 
              - varvalue:float
            recv:
                ok: 0
                err: 3
        GET_DITI:
            args:
              - 1
              - dititype:1-4
            recv:
                ok: 0
                err: 3,4
        GET_MAX_VARIABLES:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_MAXRACKS:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_PNPNO:
            args:
              - 0
            recv:
                ok: 0-1
                err: 3
        GET_RACK:
            args:
              - 1
              - racknum
            recv:
                ok: 0
                err: 2,3,4
        GET_RACK_EXT:
            args:
              - 1
              - racknum
            recv:
                ok: 0
                err: 3,4
        GET_ROMANO:
            args:
              - 0
            recv:
                ok: 0-1
                err: 3
        GET_RSP:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        GET_STATUS:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        GET_USED_DITIS:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4
        GET_VARIABLE:
            args:
              - 1
              - varname
            recv:
                ok: 0
                err: 3,14
        GET_VARIABLE_NAME:
            args:
              - 1
              - varindex:0-n
            recv:
                ok: 0
                err: 2,3,4
        GET_VERSION:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_WINDOW_HANDLES:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        ABORT_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,11
        COMMAND:
            args:
              - 1
              - command
            recv:
                ok: 0
                err: 3
        CONTINUE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9
        EDIT_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,9,12,13
        EDIT_VECTOR:
            args:
              - 2
              - vectorname 
              - sitemax
            recv:
                ok: 0
                err: 2,3,6
        EXECUTE_TEMO_SCRIPT:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4,6
        EXECUTE_WORKLIST:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4,10
        FILL_SYSTEM:
            args:
              - 3
              - volume:ml 
              - grid:1-99 
              - site:0-63
            recv:
                ok: 0
                err: 3,4,5,6
        INIT_RSP:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        LIHA_PARK:
            args:
              - 1
              - lihanum
            recv:
                ok: 0
                err: 3,4,5,6
        LOAD_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,9,12,13
        LOAD_TEMO_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,4
        LOAD_WORKLIST:
            args:
              - 1
              - command
            recv:
                ok: 0
                err: 3,4,19
        LOGIN:
            args:
              - 2
              - username 
              - password:encrypted
            recv:
                ok: 0
                err: 3
        MAG_S:
            args:
              - 8
              - device:0-7 
              - action:0-5 
              - timeout:0 
              - position:0-3 
              - moveback:0-1 
              - time:1-999 
              - temperature:15-80 
              - cycles:1-99
            recv:
                ok: 0
                err: 3
        OPEN_LOGPIPE:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        PAUSE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,11
        PNP_GRIP:
            args:
              - 4
              - distance:7-28 
              - speed:zero 
              - force:zero 
              - strategy:0-1
            recv:
                ok: 0
                err: 3,4,5,6,15
        PNP_MOVE:
            args:
              - 8
              - vectorname 
              - site:0-n 
              - position:0-n 
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400 
              - direction:0-1 
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,7,8,15
        PNP_PARK:
            args:
              - 1
              - gripcommand:0-1
            recv:
                ok: 0
                err: 3,4,5,6
        PNP_RELATIVE:
            args:
              - 4
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400 
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,15
        PREPARE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9
        READ_LIQUID_CLASSES:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        ROMA_GRIP:
            args:
              - 4
              - distance:60-140 
              - speed:0.1-150 
              - force:1-249 
              - gripcommand:0-1
            recv:
                ok: 0
                err: 3,4,5,6,15
        ROMA_MOVE:
            args:
              - 8
              - vectorname 
              - site:0-n 
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400
              - direction:0-1 
              - xyzspeed:1-400:optional
              - rotatorspeed:1-400:optional
            recv:
                ok: 0
                err: 3,4,5,6,7,8,15
        ROMA_PARK:
            args:
              - 1
              - grippos:0-1
            recv:
                ok: 0
                err: 3,4,5,6
        ROMA_RELATIVE:
            args:
              - 4
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,15
        SAVE_SCRIPT:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9,13
        SHAKER:
            args:
              - 7
              - devicenum:0-7 
              - action:0-5 
              - rpm:100-1500 
              - time:1-9999 
              - direction:0-2 
              - alttime:1-999 
              - temperature:15-90
            recv:
                ok: 0
                err: 3,4,6,17
        STACKER:
            args:
              - 5
              - devicenum:0-3 
              - action:0-2 
              - stack:0-1 
              - platetype:1-25
              - scan:0-1
            recv:
                ok: 0
                err: 3,4,6
        START_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,10
        TEMO_DROP_PLATE:
            args:
              - 3
              - grid:1-99 
              - site:0-14 
              - platetype:1-25
            recv:
                ok: 0
                err: 3,4,6
        TEMO_MOVE:
            args:
              - 2
              - site:0-14 
              - command:0-1
            recv:
                ok: 0
                err: 3,4,6,15
        TEMO_PICKUP_PLATE:
            args:
              - 3
              - grid:1-99 
              - site:0-14 
              - platetype:1-25
            recv:
                ok: 0
                err: 3,4,6
        VAC_S:
            args:
              - 7
              - devicenum:0-7 
              - action:0-9 
              - time:0-1000 
              - pressure:30-700
              - position:0-3 
              - repositionernum:1-2 
              - opentime:1-60
            recv:
                ok: 0
                err: 3,4,6,15,17,18
        WASH:
            args:
              - 14
              - volume1:ml 
              - delay1:ms 
              - volume2:ml 
              - delay2:ms 
              - grid1:1-99 
              - site1:0-63 
              - grid2:1-99 
              - site2:0-63
              - option_mpo:0-1 
              - retractspeed:1-999 
              - volumeairgap:ul 
              - speedairgap:1-999 
              - volumeopt:0-1 
              - frequency:50-5000
            recv:
                ok: 0
                err: 3,6
        CAROUSEL_SCAN_BARCODE:
            args:
              - 3
              - devicenum:0-3 
              - action:0-1 
              - towernum:1-9
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_RETRIEVE:
            args:
              - 5
              - devicenum:0-3 
              - action:0-1 
              - barcode:optional 
              - tower:1-9 
              - position:1-27
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_RETURN:
            args:
              - 4
              - devicenum:0-3 
              - action:0-1 
              - towernum:1-9 
              - position:1-21
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_DIRECT_MOVEMENTS:
            args:
              - 4 
              - devicenum:0-3 
              - action:0-3 
              - towernum:1-9 
              - command
            recv:
                ok: 0
                err: 3,4,6
                
    recv:
        ok:
           0: ok
        error:
           1: E_command
           2: E_unexpected
           3: E_num_operands
           4: E_operand
           5: E_hw_error_reported
           6: E_hw_not_init
           7: E_roma_vector_not_defined
           8: E_roma_vector_site_not_defined
           9: E_hw_still_active
           10: E_hw_not_active
           11: E_hw_not_active
           12: E_cancelled
           13: E_script_load_save
           14: E_varible_not_defined
           15: E_requires_advanced_version
           16: E_roma_grip_fail
           17: E_device_not_found
           18: E_timeout
           19: E_worklist_already_loaded
            
type1commands: # system low level commands, see gemfirm.html ; args separated by ,
    address:
        machine: M
        roma: R
        roma0: 1
        liha: A
        liha0: 1
    send-machine:  # "#M1____"
        PIS: 
            desc:     "Position warm init"
            args:
                - 0
            recv:
                ok: 0
                err: 1,3,5
        ACX: 
            desc: calibrate ROMA X
            args:
                - 0
            recv:
                ok: none
                err: 1,3,5
        ARS: 
            desc: scan IO RS 485
            args: 
                - 0
            recv:
                ok: none
                err: none
        ALO: 
            desc: doorlock
            args:
                - 1
                - lockenable
            recv:
                ok: none
                err: 3,18,19
        SMA: 
            desc: set soft x limit in 0.1mm
            args:
                - 1
                - distance
            recv:
                ok: none
                err: 3
        SOW: 
            desc: write to eeprom non-volatile permanent
            dangerous: 
                - yes
            args:
                - 0
            recv:
                ok: none
                err: 13
        SHB: 
            desc: set comm rate
            args:
                - 1
                - rate:0-5
            recv:
                ok: none
                err: 3
        SOF: 
            desc: firmware download
            dangerous:
                - yes
            args: 
                - 0
            recv:
                ok: none
                err: none
        SNV: 
            desc: set node address
            args:
                - 1
                - address:1-8
            recv:
                ok: none
                err: 3,20,21
        SDO: 
            desc: set i/o digital out
            args:
                - 2
                - port:1-3
                - level:0-1
            recv:
                ok: none
                err: 3
        RFV: 
            desc:  get firmware version string, 2=serial number
            args:
                - 1
                - select:0-2:optional
            recv:
                ok: string
                err: none
        RMA: 
            desc: get machine limit x-axis
            args:
                - 0
            recv:
                ok: int
                err: none
        REE: 
            desc: get extended error string; machine
            args:
                - 0
            recv:
                ok: string
                err: none
        RSD: 
            desc: report system devices connected, format:0=binary, 1=decimal
            args:
                - 2
                - selector:0-7
                - format:0-1
            recv:
                ok: int
                err: 3
        RNV: 
            desc: report new device detected. ok:0=no devices, 1=new devices
            args:
                - 0
            recv:
                ok: int
                err: none
        ROW: 
            desc: read eeprom into ram
            args:
                - 0
            recv:
                ok: none
                err: 13
        RDF: 
            desc: report diag functions
            args:
                - 1
                - valuenum:0-5
            recv:
                ok: int
                err: 3,16
        RDO: 
            desc: read i/o digital out
            args: 
                - 1
                - portnum:1-3
            recv:
                ok: 0-1
                err: 3
        RLO: 
            desc: read door lock output
            args:
                - 1
                - doornum:1-2
            recv:
                ok: 0-1
                err: 3
        RDI: 
            desc: read i/o digital input
            args:
                - 1
                - portnum:1-4
            recv:
                ok: 0-1
                err: 3
        RLI: 
            desc: read door lock input
            args:
                - 1
                - doornum:1-2
            recv:
                ok: 0-1
                err: 3 
        RVM: 
            desc: report volt meter service channel, ch0=0..5v @ 10mV units, ch1=0..24v @ 100mV units
            args:
                - 1
                - channelnum:0-1
            recv:
                ok: int
                err: none
        RRS: 
            desc: report i/o rs483 address
            args:
                - 1
                - channelnum:1-2
            recv:
                ok: int
                err: 3
        GFC: 
            desc: group command load (batch commands)
            args:
                - 0
            recv:
                ok: none
                err: none
        GSC: 
            desc: group command start (loaded commands)
            args:
                - 0
            recv:
                ok: none
                err: none
        
    send-liha: # "#A1____"
        PIA: 
            desc: position init x/y/z
            args:
                - 0
            recv:
                ok: none
                err: 1,3,5
        PIF: 
            desc: fake init x/y/z
            dangerous: yes
            args:
                - 0
            recv:
                ok: none
                err: none
        PIX: 
            desc: position init x only
            args:
                - 1
                - speed:5-1500:optional # 0.1mm/s unit
            recv:
                ok: none
                err: 1,3,5
        PIY: 
            desc: position init y only
            args:
                - 1
                - speed:5-1500:optional # 0.1mm/s unit
            recv:
                ok: none
                err: 1,3,5
        PIZ: 
            desc: position init z only
            args:
                - 2
                - tipmask:0-255
                - speed:5-1500:optional # default 270
            recv:
                ok: none
                err: 1,3,5
        PAA: 
            desc: position absolute all axis, 0.1mm unit, Zi=tips
            args: 
                - 11
                - x
                - y
                - yspace:90-380    # spacing distance
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3,7,10,13,17
        PAX: 
            desc: position absolute x-axis, 0.1mm unit
            args:
                - 1
                - x
            recv:
                ok: none
                err: 3,7,10,13,17
        PAY: 
            desc: position absolute y, 0.1mm unit
            args:
                - 2
                - y
                - yspace:90-380 # spacing distance
            recv:
                ok: none
                err: 3,7,10,13
        PSY: 
            desc: y-spacing, 0.1mm unit
            args:
                - 1
                - yspace:90-380 # spacing distance
            recv:
                ok: none
                err: 3,7,10
        PAZ: 
            desc: position absolute z, 0.1mm unit
            args:
                - 8
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3,7,10
        PRX: 
            desc: position relative x, 0.1mm unit
            args:
                - 1
                - x
            recv:
                ok: none
                err: 3,7,10,13,17
        PRY: 
            desc: position relative y, 0.1mm unit
            args:
                - 1
                - y
            recv:
                ok: none
                err: 3,7,10,13
        PRZ: 
            desc: position relative z, 0.1mm unit
            args:
                - 8
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3,7,10
        MAX: 
            desc: position absolute slow x, 0.1mm unit
            args:
                - 2
                - x
                - speed:1-4000 # 0.1mm/sec, default 1000
            recv:
                ok: none
                err: 3,7,10,13,17
        MAY: 
            desc: position absolute slow y, 0.1mm unit
            args:
                - 3
                - y
                - yspace:90-380
                - speed:1-4000 # 0.1mm/sec, default 350
            recv:
                ok: none
                err: 3,7,10,13
        MAZ: 
            desc: position absolute slow z, 0.1mm/s unit
            args:
                - 9
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
                - speed:1-4000 # 0.1mm/s unit, default 400
            recv:
                ok: none
                err: 3,7,10
        MRX: 
            desc: position relative slow x, 0.1mm unit
            args:
                - 2
                - x
                - speed:1-4000 # 0.1mm/s unit, default 1000
            recv:
                ok: none
                err: 3,7,10,13,17
        MRY: 
            desc: position relative slow y, 0.1mm unit
            args: 
                - 2
                - y
                - speed:1-4000 # 0.1mm/s unit, default 350
            recv:
                ok: none
                err: 3,7,10,13
        MRZ: 
            desc: position relative slow z, 0.1mm unit
            args:
                - 9
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
                - speed:1-4000 # 0.1mm/s unit, default 400
        MHZ: 
            desc: move to z-travel
            args: 
                - 2
                - tipmask:0-255
                - z
            recv:
                ok: none
                err: 3,7,10
        MDT: 
            desc: move tip, detect liquid, submerge
            args:
                - 5
                - tipmask:0-255
                - submerge
                - zstart
                - zmax
                - zadd
            recv:
                ok: none
                err: 3,5,7,9,10,11,20,24
        MET: 
            desc: move tip, detect liquid, submerge, remain at zmax on error
            args:
                - 5
                - tipmask:0-255
                - submerge
                - zstart
                - zmax
                - zadd
            recv:
                ok: none
                err: 3,5,7,9,10,12,20,24
        MCT: 
            desc: detect clot on tipmask
            args:
                - 4
                - tipmask:0-255
                - zdistance         # default 50
                - zspeed:0-1500     # default 200
                - limit
            recv:
                ok: none
                err: 3,5,7,10,18,19,24
        APT: 
            desc: pierce tipmask, start to max
            args: 
                - 3
                - tipmask:0-255
                - zstart
                - zmax
            recv:
                ok: none
                err: none # TODO Verify; doc is missing info here
        AGT: 
            desc: get disposable tip on tipmask
            args:
                - 3
                - tipmask:0-255
                - zstart
                - zdelta
            recv:
                ok: none
                err: 3,5,7,10,25,26,27
        ADT: 
            desc: discard disposable tip on tipmask @ current xyz
            args: 
                - 1
                - tipmask:0-255
            recv:
                ok: none
                err: 1,3,5,7,10,27
        BMX: 
            desc: stop x movement immediately
            args: 
                - 0
            recv:
                ok: none
                err: none
        BMY: 
            desc: stop y movement immediately
            args:
                - 0
            recv:
                ok: none
                err: none
        BMZ: 
            desc: stop z movement immediately
            args: 
                - 0
            recv:
                ok: none
                err: none
        SRA: 
            desc: set absolute range xyz
            args: 
                - 10
                - x     # default 1000
                - y        # default 1000
                - z1    # defaults: 1000
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SYS: 
            desc: set min y distance
            args:
                - 1
                - yspace:90-380        # default: 90
            recv:
                ok: none
                err: 3
        SHZ: 
            desc: set ztravels
            args:
                - 8
                - ztravel1:default=1000   # defaults: 1000
                - ztravel2:default=1000
                - ztravel3:default=1000
                - ztravel4:default=1000
                - ztravel5:default=1000
                - ztravel6:default=1000
                - ztravel7:default=1000
                - ztravel8:default=1000
        SSL: 
            desc: set search speed for liquid commands, 0.1mm/s unit
            args:
                - 8
                - zspeed1     # defaults: 400
                - zspeed2
                - zspeed3
                - zspeed4
                - zspeed5
                - zspeed6
                - zspeed7
                - zspeed8
            recv:
                ok: none
                err: 3
        SSX: 
            desc: "set slow speed x, 0.1mm/s unit"
            args: 
                - 1
                - speed:1-4000     # default: 1000
            recv:
                ok: none
                err: 3
        SSY: 
            desc: "set slow speed y, 0.1mm/s unit"
            args:
                - 1
                - speed:1-4000     # default: 350
            recv:
                ok: none
                err: 3
        SSS: 
            desc: set slow speed z, 0.1mm/s unit
            args: 
                - 1
                - z1:1-4000        # defaults: 400
                - z2:1-4000
                - z3:1-4000
                - z4:1-4000
                - z5:1-4000
                - z6:1-4000
                - z7:1-4000
                - z8:1-4000
            recv:
                ok: none
                err: 3
        SPS: 
            desc: set pierce speed
            args:
                - 3
                - speed:1-1500        # default: 200
                - pwmlimit:0-249:optional
                - currentlimit:0-3:optional
            recv:
                ok: none
                err: 3
        SSP: 
            desc: set pick speed when moving zstart to zmax
            args:
                - 3
                - speed:1-1500         # default: 800      
                - pwmlimit:0-249:optional    # default: 60                 
                - currentlimit:0-3:optional    # default: 0
            recv:
                ok: none
                err: 3
                
        SSD: 
            desc: set discard speed when moving zstart to zmax
            args:
                - 3
                - speed:1-1500        # default:200
                - pwmlimit:0-249:optional    # default: 160
                - currentlimit:0-3:optional    # default: 0
            recv:
                ok: none
                err: 3
        STL: 
            desc: set liquid search zstart for MDT, MET
            args:
                - 8
                - z1        # defaults: 1000
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
        SML: 
            desc: set liquid search zmax
            args:
                - 8
                - z1        # defaults: 0
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SBL: 
            desc: set liquid search submerge for MDT, MET
            args:
                - 8
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SDL: 
            desc: set liquid search retract for MDT, MET
            args: 
                - 8
                - z1        # defaults: 0
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SDR: 
            desc: set clot detection retract for MCT
            args: 
                - 8
                - z1        # defaults: 50
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SSR: 
            desc: set clot detection retract speed for MCT
            args: 
                - 8
                - z1:0-1500        # defaults: 200
                - z2:0-1500
                - z3:0-1500
                - z4:0-1500
                - z5:0-1500
                - z6:0-1500
                - z7:0-1500
                - z8:0-1500
        SLR: 
            desc: set clot detect limit
            args:
                - 8
                - z1        # default: 40
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SDM: 
            desc: set liquid detection mode
            args: 
                - 5
                - detectmode:0-7    # default:1
                - sensitivity:0-2:optional    # default:0, 0=normal, high, 2=very high
                - phase:0-1:optional        # default:0, 0=same, 1=against
                - dipin:0-1:optional        # default:0, 0=enable, 1=disable
                - dipout:0-1:optional        # default:0, 0=enable, 1=disable
            recv:
                ok: none
                err: 3
        SFX: 
            desc: set xramp
            args:
                - 2
                - speedend:50-11500        # default:10000
                - acceleration:380-11500    # default:1800
            recv:
                ok: none
                err: 3
        SFY: 
            desc: set yramp
            args: 
                - 2
                - speedend:50-13500        # default: 3500
                - acceleration:430-13500    # default:2400
            recv:
                ok: none
                err: 3
        SFZ: 
            desc: set zramp
            args: 
                - 2
                - speedend:50-8000        # default:4000
                - acceleration:250-8000    # default: 2000
            recv:
                ok: none
                err: 3
        SOX: 
            desc: set init offset x
            args: 
                - 1
                - xoffset        # default:150
            recv:
                ok: none
                err: 3
        SOY: 
            desc: set init offset y
            args:
                - 2
                - yoffset        # default:900
                - yspacing        # default:910
            recv:
                ok: none
                err: 3
        SOZ: 
            desc: set init offset z
            args: 
                - 8
                - z1
                - z2
                - z3
                - z4
                - z5
                - z6
                - z7
                - z8
            recv:
                ok: none
                err: 3
        SAX: 
            desc: set scale adjust x
            args:
                - 1
                - scale        # default: 10000
            recv:
                ok: none
                err: 3
        SAY: 
            desc: set scale adjust y
            args: 
                - 1
                - scale        # default: 10000
            recv:
                ok: none
                err: 3
        SCL: 
            desc: set collision avoidance liha-posid
            args:
                - 1
                - enable:0-1    # default:1, 0=off
            recv:
                ok: none
                err: none
        RNT: 
            desc: report number of tips on arm
            args:
                - 1
                - format:0-1        # 0=binary, 1=decimal
            recv:
                ok: int
                err: none
        RYS: 
            desc: report min yspacing
            args:
                - 0
            recv:
                ok: int
                err: none
        RPX: 
            desc: report parameter on x
            args:
                - 1
                - parameter:0-10
            recv:
                ok: int
                err: 3
        RPY: 
            desc: report parameter on y
            args:
                - 1
                - parameter:0-10
            recv:
                ok: int
                err: 3
        RPZ: 
            desc: report parameter on z
            args:
                - 1
                - parameter:0-10
            recv:
                ok: int
                err: 3
        RVZ: 
            desc: report parameter on z
            args:
                - 1
                - parameter:0-4
            recv:
                ok: int
                err: 3
        RGZ: 
            desc: report global parameter on z for SPS, SSP, SSD
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: int
                err: 3
        RTL: 
            desc: report liquid search zstart for MDT, MET
            args:
                - 0
            recv:
                ok: string
                err: 3
        RML: 
            desc: report liquid search zmax for MDT, MET
            args: 
                - 0
            recv:
                ok: string
                err: 3
        RBL: 
            desc: report liquid search submerge
            args: 
                - 0
            recv:
                ok: string
                err: 3
        RDL: 
            desc: report liquid search retract
            args: 
                - 0
            recv:
                ok: string
                err: 3
        RDR: 
            desc: report clot detect retract
            args: 
                - 0
            recv:
                ok: string
                err: 3
        RSR: 
            desc: report clot detect retract speed
            args:
                - 0
            recv:
                ok: string
                err: 3
        RLR: 
            desc: report clot detect retract limit
            args: 
                - 0
            recv: 
                ok: string
                err: 3
        RDM: 
            desc: report liquid detect mode
            args: 
                - 0
            recv: 
                ok: string
                err: 3
        RTS: 
            desc: report tip status mounted
            args: 
                - 0
            recv: 
                ok: tipmask
                err: 7
        RCL: 
            desc: report collision avoidance liha-posid
            args: 
                - 0
            recv:
                ok: 0-1
                err: none
        RRX: 
            desc: report absolute distance between liha-roma
            args: 
                - 0
            recv:
                ok: int
                err: none
        REE: 
            desc: report extended axis status/error; liha
            args: 
                - 0
            recv:
                ok: string
                err: none
        RDX: 
            desc: report diagnostic x
            args:
                - 1
                - parameter:0-2
            recv:
                ok: int
                err: 3,16
        RDY: 
            desc: report diagnostic y
            args:
                - 1
                - parameter:0-2
            recv:
                ok: int
                err: 3,16
        RDZ: 
            desc: report diagnostic z
            args: 
                - 1
                - parameter:0-4
            recv:
                ok: int
                err: 3,16
    send-roma:    #  "#R1____", axis: xyz rotator gripper
        PIF:
            dangerous: yes
            desc:  fake init, bypass, set zero xyzrg
            args:
                - 0 
            recv:
                ok: none
                err: none
        PIA:
            desc: position init xyzrg
            args: 
                - 0
            recv:
                ok: none
                err: 1,3,5
        PIX: 
            desc: position init x
            args:
                - 1
                - speed:5-1500:default=400
            recv:
                ok: none
                err: 1,3,5
        PIY:
            desc: position init y
            args:
                - 1
                - speed:5-1500:default=350
            recv:
                ok: none
                err: 1,3,5
        PIZ:
            desc: position init z
            args:
                - 1
                - speed:5-1500:default=270
        PIR:
            desc: position init r
            args:
                - 1
                - speed:5-1500:default=270
            recv:
                ok: none
                err: 1,3,5
        PIG: 
            desc: position init g
            args: 
                - 1
                - speed:5-1500:default=270
            recv:
                ok: none
                err: 1,3,5
        AAA:
            desc: drive start
            args: 
                - 0
            recv:
                ok: none
                err: 3,5,7,10,17
        PAX:
            desc: absolute position x
            args:
                - 1
                - x
            recv:
                ok: none
                err: 3,7,10,17
        PAY: 
            desc: absolute position y
            args:
                - 1
                - y
            recv:
                ok: none
                err: 3,7,10
        PAZ:
            desc: absolute position z
            args:
                - 1
                - z
            recv:
                ok: none
                err: 3,7,10
        PAR:
            desc: absolute position r
            args:
                - 1
                - r
            recv:
                ok: none
                err: 3,7,10,17
        PAG:
            desc: absolute position g
            args:
                - 1
                - g
            recv: 
                ok: none
                err: 3,7,10    
        PRX:
            desc: relative position x
            args:
                - 1
                - x
            recv:
                ok: none
                err: 3,7,10,17
        PRY:
            desc: relative position y
            args:
                - 1
                - y
            recv:
                ok: none
                err: 3,7,10
        PRZ:
            desc: relative position z
            args:
                - 1
                - y
            recv:
                ok: none
                err: 3,7,10            
        PRR:
            desc: relative position r
            args:
                - 1
                - r
            recv:
                ok: none
                err: 3,7,10,17
        PRG:
            desc: relative position g
            args:
                - 1
                - g
            recv:
                ok: none
                err: 3,7,10
        MAX:
            desc: position absolute speed x
            args:
                - 2
                - x
                - speed:1-4000:default=1000
            recv:
                ok: none
                err: 3,7,10,17
        MAY:
            desc: position absolute speed y
            args:
                - 2
                - y
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10
        MAZ:
            desc: position absolute speed z
            args:
                - 2
                - z
                - speed:1-4000:default=200
            recv:
                ok: none
                err: 3,7,10
        MAR:
            desc: position absolute speed r
            args:
                - 2
                - r
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10,17
        MAG:
            desc: position absolute speed g
            args:
                - 2
                - g
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10
        MRX:
            desc: position relative speed x
            args:
                - 2
                - x
                - speed:1-4000:default=1000
            recv:
                ok: none
                err: 3,7,10,17
        MRY:
            desc: position relative speed y
            args:
                - 2
                - y
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10
        MRZ:
            desc: position relative speed z
            args:
                - 2
                - z
                - speed:1-4000:default=400
            recv:
                ok: none
                err: 3,7,10
        MRR:
            desc: position relative speed r
            args:
                - 2
                - r
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10,17
        MRG:
            desc: position relative speed g
            args:
                - 2
                - g
                - speed:1-4000:default=350
            recv:
                ok: none
                err: 3,7,10
        ARP:
            desc: position angle r; angle=2=180 degrees
            args:
                - 1
                - angle:0-3
            recv:
                ok: none
                err: 3,7,10,17
        AGR:
            desc: grip distance, 0.1mm
            args:
                - 1
                - distance
            recv:
                ok: none
                err: 3,7,9,10
        BMX:
            desc: stop immediately x
            args:
                - 0
            recv:
                ok: none
                err: none
        BMY:
            desc: stop immediately y
            args:
                - 0
            recv:
                ok: none
                err: none
        BMZ:
            desc: stop immediately z
            args:
                - 0
            recv:
                ok: none
                err: none
        BMG:
            desc: stop immediately g
            args:
                - 0
            recv:
                ok: none
                err: none
        BMA:
            desc: stop immediately all axis xyzrg
            args:
                - 0
            recv:
                ok: none
                err: none
        SRA:
            desc: set axis range
            args:
                - 5
                - x
                - y:0-1000000:default=1000
                - z:0-1000000:default=1000
                - r:0-1000000:default=1000:optional
                - g:0-1000000:default=1000:optional
            recv:
                ok: none
                err: none    
        SAA:
            desc: set position into index table. speed=0=slow.
            args:
                - 7
                - index:1-100
                - x
                - y
                - z
                - r:0-1000000:default=1000:optional
                - g:0-1000000:default=1000:optional
                - speed:0-1:default=0
            recv:
                ok: none
                err: none    
        SGG:
            desc: set parameter g
            args:
                - 3
                - speed:0-1500:default=100
                - pwmlimit:0-249:default=75:optional
                - currentlimit:0-3:default=0:optional
            recv:
                ok: none
                err: 3
        SOD:
            desc: set outrigger distance g, distance in 0.1mm
            args:
                - 1
                - distance:1100-3000:default=100
            recv:
                ok: none
                err: 3
        SFX:
            desc: set ramp parameter x
            args:
                - 2
                - speed:50-5000:default=5000
                - acceleration:380-11500:default=400
            recv:
                ok: none
                err: 3  
        SFY:
            desc: set ramp parameter y
            args:
                - 2
                - speed:50-10000:default=3500
                - acceleration:320-10000:default=1000
            recv:
                ok: none
                err: 3                
        SFZ:
            desc: set ramp parameter z
            args:
                - 2
                - speed:50-2900:default=1000
                - acceleration:100-2900:default=250
            recv:
                ok: none
                err: 3                
        SFR:
            desc: set ramp parameter r
            args:
                - 2
                - speed:50-20000:default=1000
                - acceleration:100-20000:default=480
            recv:
                ok: none
                err: 3                
        SFG:
            desc: set ramp parameter g
            args:
                - 2
                - speed:50-3700:default=400
                - acceleration:130-3700:default=200
            recv:
                ok: none
                err: 3                
        SAX:
            desc: set scale adjust x
            args:
                - 1
                - scale:8000-12000:default=10000
            recv:
                ok: none
                err: 3                
        SAY:
            desc: set scale adjust y
            args:
                - 1
                - scale:8000-12000:default=10000
            recv:
                ok: none
                err: 3    
        SSX:
            desc: set slow speed x, 0.1mm/s
            args:
                - 1
                - speed:1-4000:default=1500
            recv:
                ok: none
                err: 3
        SSY:
            desc: set slow speed y, 0.1mm/s
            args:
                - 1
                - speed:1-4000:default=1500
            recv:
                ok: none
                err: 3
        SSZ:
            desc: set slow speed z, 0.1mm/s
            args:
                - 1
                - speed:1-4000:default=500
            recv:
                ok: none
                err: 3
        SSR:
            desc: set slow speed r, 0.1mm/s
            args:
                - 1
                - speed:1-4000:default=600
            recv:
                ok: none
                err: 3
        SSG:
            desc: set slow speed g, 0.1mm/s
            args:
                - 1
                - speed:1-4000:default=100
            recv:
                ok: none
                err: 3
        SOX:
            desc: set init offset x, 0.1mm
            args:
                - 1
                - distance:10-10000:default=100
            recv:
                ok: none
                err: 3
        SOY:
            desc: set init offset y, 0.1mm
            args:
                - 1
                - distance:10-10000:default=30
            recv:
                ok: none
                err: 3
        SOZ:
            desc: set init offset z, 0.1mm
            args:
                - 1
                - distance:10-10000:default=100
            recv:
                ok: none
                err: 3
        SOR:
            desc: set init offset r, 0.1degree
            args:
                - 1
                - distance:10-3600:default=50
            recv:
                ok: none
                err: 3
        SOG:
            desc: set init offset g, 0.1mm
            args:
                - 2
                - distance:10-10000:default=100
                - real:0-32000:default=560
            recv:
                ok: none
                err: 3
        SIZ:
            desc: set force z, force=0=low, 1=high
            args:
                - 1
                - force:0-1:default=0
            recv:
                ok: none
                err: 3
        #SMX: #CAUTION!: Wrong gear definition causes malfunction of the instrument.
            #dangerous: yes
            #desc: set gear type x, type=0=1:1 gear, 1=1:2 gear
            #args:
            #    - 1
            #    - type:0-1
            #recv:
            #    ok: none
            #    err: 3
        #SMG: #CAUTION!: Wrong encoder definition causes malfunction of the instrument.
            #dangerous: yes
            #desc: set gripper encoder type; 0=30 steps, 1=15 steps
            #args:
            #    - 1
            #    - type:0-1
            #recv:
            #    ok: none
            #    err: 3   
        RAA: 
            desc: report coord programmed with SAA
            args: 
                - 1
                - index:1-100
            recv:
                ok: string
                err: 3      
        RAE:
            desc: report current index of AAA, if abnormal halt; 0=all complete
            args: 
                - 1
                - type:1-100
            recv:
                ok: 0
                err: 3
        RPX: 
            desc: report current x parameter in 1/10mm, 0=position, 1=acceleration, 2=end speed, 3=init speed, 4=init offset, 5=machine range, 6=error steps, 7=travel position, 8=scale factor, 9=slow speed
            args:
                - 1
                - parameter:0-9
            recv:
                ok: int
                err: 3
        RPY: 
            desc: report current y parameter (see RPX)
            args: 
                - 1
                - parameter:0-9
            recv:
                ok: 0
                err: 3
        RPZ: 
            desc: report current z parameter (see RPX)
            args: 
                - 1
                - parameter:0-9
            recv:
                ok: 0
                err: 3
        RPR: 
            desc: report current r parameter in 1/10degree, 0=position, 1=acceleration, 2=end speed, 3=init speed, 4=init offset, 5=machine range, 6=init error steps, 7=travel position, 8=scale factor, 9=slow speed
            args: 
                - 1
                - parameter:0-9
            recv:
                ok: 0
                err: 3
        RPG: 
            desc: report current g parameter (see RPX)
            args: 
                - 1
                - parameter:0-9
            recv:
                ok: 0
                err: 3
        RGG: 
            desc: report g parameter; speed, pwmlimit, currentlimit
            args: 
                - 0
            recv:
                #ok: int,int,int
                ok: string 
                err: 3
        ROD: 
            desc: report g outrigger distance for arm avoidance
            args: 
                - 0
            recv:
                ok: int
                err: none
        RIZ: 
            desc: report z force set by SIZ (0=low force/default, 1=high force)
            args: 
                - 0
            recv:
                ok: int
                err: 3
        RRX: 
            desc: report absolute rest movement distance to other arm, 1/10mm
            args: 
                - 0
            recv:
                ok: int
                err: none
        REE: 
            desc: report extended axis status/error; liha
            args: 
                - 0
            recv:
                ok: string
                err: none
        RDX: 
            desc: report x diagnostic (0=move counter, 1=distance counter in meters, 2=no load counter)
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: int
                err: 3,16
        RDY: 
            desc: report report y diagnostic (see RDX)
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: 0
                err: 3
        RDZ: 
            desc: report z diagnostic (see RDX)
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: 0
                err: 3       
        RDR: 
            desc: report r diagnostic (0=move coutner, 1=distance counter in 1000deg, 2=no load counter)
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: 0
                err: 3       
        RGD: 
            desc: report g diagnostic (0=move counter, 1=distance counter in meters, 2=no load counter, 3=number of gripped plates)
            args: 
                - 1
                - parameter:0-2
            recv:
                ok: 0
                err: 3       
               
    send-vcc:       
    # GENESIS RSP VCC "Volume Control Center" syringe/aspirator/diluter, "COMMAND SET VCC STYLE"
        RFV:
            desc: Report firmware version, type=0=firmware, 1=bootloader, 2=serialnum
            args:
                - 1
                - type:0-2:default=0
            recv:
                ok: string
                err: 3
        RFP:
            desc: Report piezo module firmware version
            args:
                - 0
            recv:
                ok: string
                err: 3
        RSD:
            desc: Report system devices, type=0=low volume, 1=piezo module
            args:
                - 1
                - type:0-1:default=0:optional
            recv:
                ok: string
                err: 3   
        RYV:
            desc: Report syringe volume in microliters
            args:
                - 0
            recv:
                ok: int
                err: none
                
                               
    recv-device:
        ok:
           0: ok
           error:
               1: E_init
               2: E_command
               3: E_args
               4: E_sequence
               5: E_device_not_implemented
               6: E_timeout
               7: E_device_not_init
               8: E_command_overflow_cu
               15: E_command_overflow_device
               
    recv-machine:
        ok:
           0: ok
        error:
            13: E_device_no_eeprom_access
            16: E_device_power_fail
            18: E_door_lock1_fail
            19: E_door_lock2_fail
            20: E_device_new_not_found
            21: E_device_already_defined
               
    recv-liha:
        ok:
            0: ok
        error:
            9: E_no_liquid_detected
            10: E_drive_no_load
            11: E_MDT_not_enough_liquid
            12: E_MET_not_enough_liquid
            13: E_arm_collision_avoided_with_posid
            16: E_power_fail
            17: E_arm_collision_avoided_with_roma
            18: E_MCT_clot_limit
            19: E_MCT_no_clot_exit
            20: E_MET_no_liquid_exit
            24: E_MET_MCT_ilid_pulse
            25: E_AGT_ADT_tip_not_fetched
            26: E_AGT_ADT_tip_not_mounted
            27: E_AGT_ADT_tip_already_mounted
            
    recv-roma:
        ok:
            0: ok
        err:
            9: E_AGR_plate_not_fetched
            10: E_drive_no_load
            16: E_power_fail
            17: E_arm_collision_avoided_with_liha
           
           
type0commands: # device-specific lowest level commands
    send-xp3000:  # Compatible with VCC or XP3000V1, "Cavro".  See "vcc or xp3000 V1.pdf"
        # GENESIS RSP VCC "Volume Control Center" syringe/aspirator/diluter, "Command Set XP style". 
        # Commands concatenate and end with 'R' to execute, example: D1IV5400P3000OA0R
        GET_STATUS:
            desc: report parameter
            opcode: Q
            args:
                - 1
                - parameter:0-29:default=0:optional
            recv:
                ok: string:int
                err: 3
        INIT:
            desc: init plunger and valve drive normal polarity. force=0=full, 1=half, 2=quarter
            opcode: Z
            args:
                - 1
                - force:0-2:default=0
            recv:
                ok: none
                err: 1,3,10
        INIT_REVERSE:
            desc: init plunger and valve drive reverse polarity. force=0=full, 1=half, 2=quarter
            opcode: Y
            args:
                - 1
                - force:0-2:default=0
            recv:
                ok: none
                err: 1,3,10   
        INIT_DRIVE:
            desc: init plunger drive. force=0=full, 1=half, 2=quarter
            opcode: W
            args:
                - 1
                - force:0-2:default=0
            recv:
                ok: none
                err: 1,3
        RESET:
            desc: reset plunger to recovery after overload
            opcode: z
            args:
                - 0
            recv:
                ok: none
                err: none
        SET_SPEED_CODE:
            desc: set plunger speed, coded unit
            opcode: S
            args:
                - 1
                - speed:0-40:default=11
            recv:
                ok: none
                err: 3
        SET_SPEED_END:
            desc: set plunger end speed, half steps per second
            opcode: V
            args:
                - 1
                - speed:5-6000:default=1400
            recv:
                ok: none
                err: 3
        SET_SPEED_START:
            desc: set plunger start speed, half steps per second
            opcode: v
            args:
                - 1
                - speed:50-1000:default=900
            recv:
                ok: none
                err: 3
        SET_SPEED:
            desc: set plunger start & end speed, half steps per second
            opcode: V$1v$2
            args:
                - 2
                - speedstart:50-1000:default=900
                - speedend:50-1000:default=900
            recv:
                ok: none
                err: 3
        SET_CUTOFF_STEPS:
            desc: set plunger cutoff steps, used in dispensing; steps
            opcode: C
            args:
                - 1
                - steps:0-25:default=1400
            recv:
                ok: none
                err: 3
        SET_CUTOFF:
            desc: set plunger cutoff speed, used in dispensing; half steps per second
            opcode: c
            args:
                - 1
                - steps:50-2700:default=900
            recv:
                ok: none
                err: 3
        SET_SLOPE:
            desc: set plunger slope; 2500 half steps per second units; slope=10=25000 steps
            opcode: L
            args:
                - 1
                - slope:0-20:default=7
            recv:
                ok: none
                err: 3
        SET_BACKLASH:
            desc: set plunger backlash; steps
            opcode: K
            args:
                - 1
                - steps:0-31:default=0
            recv:
                ok: none
                err: 3
        SET_VALVE_INPUT:
            desc: set value to input; mode=0=normal, mode=1=reactivate after W initialization
            opcode: I
            args:
                - 1
                - mode:0-1:default=0
            recv:
                ok: none
                err: 10
        SET_VALVE_OUTPUT:
            desc: set value to output; mode=0=normal, mode=1=reactivate after W initialization
            opcode: O
            args:
                - 1
                - mode:0-1:default=0
            recv:
                ok: none
                err: 10
        SET_VALVE_BYPASS:
            desc: set value to bypass; mode=0=normal, mode=1=reactivate after W initialization
            opcode: B
            args:
                - 1
                - mode:0-1:default=0
            recv:
                ok: none
                err: 10
        SET_POS:
            desc: set plunger absolute position, if valve not bypassed; full steps
            opcode: A
            args:
                - 1
                - position:0-3150
            recv:
                ok: none
                err: 3,7,9,10,11
        ASPIRATE:
            desc: set plunger relative position (PICK LIQUID), if valve not bypassed; full steps
            opcode: P
            args:
                - 1
                - position:0-3150
            recv:
                ok: none
                err: 3,7,9,10,11
        DISPENSE:
            desc: set plunger relative position (DISPENSE LIQUID), if valve not bypassed; full steps
            opcode: D
            args:
                - 1
                - position:0-3150
            recv:
                ok: none
                err: 3,7,9,10,11
        EXECUTE:
            desc: execute immediate
            opcode: R
            args:
                - 0
            recv:
                ok: none
                err: none
        REPEAT:
            desc: repeat previous command immediate
            opcode: R
            args:
                - 0
            recv:
                ok: none
                err: none
        DELAY:
            desc: delay, milliseconds
            opcode: M
            args:
                - 1
                - msec:0-30000
            recv:
                ok: none
                err: 3
    address:
        # Map the tip number to command's device address
        # tip:xp_command_address
        1: 1
        2: 2
        3: 3
        4: 4
        5: 5
        6: 6
        7: 7
        8: 8
    recv-vcc:
        ok:
            0: ok
        err:
            1: E_init
            2: E_command
            3: E_operand
            5: E_device_not_implemented
            7: E_not_initialized
            9: E_plunger_overload
            10: E_valve_overload
            11: E_valve_is_bypassed
            12: E_eeprom_no_access
            15: E_command_overflow
            
            
__END__

