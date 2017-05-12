package Ovirt::Display;

use Ovirt::VM;
use Carp;
use Moo;

with 'Ovirt';
our $VERSION = '0.01';

=head1 NAME

Ovirt::Display - Generate display config for remote viewer 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

 use Ovirt::Display;

 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            id                      => 'e20cc93c-f526-4682-a250-924fa953f57b',
            expiry                  => 300,
 );

 my $display = Ovirt::Display->new(%con);
 print $display->generate();

 sample spice configuration output :
 [virt-viewer]
    type=spice
    host=192.168.1.152
    port=-1
    password=+cnsq458Oq6T
    # Password is valid for 300 seconds.
    tls-port=5902
    fullscreen=0
    title=C1 : %d - Press SHIFT+F12 to Release Cursor
    enable-smartcard=0
    enable-usb-autoshare=1
    delete-this-file=1
    usb-filter=-1,-1,-1,-1,0
    tls-ciphers=DEFAULT
    host-subject=O=example.com,CN=192.168.1.152
    ca=-----BEGIN CERTIFICATE-----\n -- output removed -- S2fE=\n-----END CERTIFICATE-----\n
    toggle-fullscreen=shift+f11
    release-cursor=shift+f12
    secure-attention=ctrl+alt+end
    secure-channels=main;inputs;cursor;playback;record;display;usbredir;smartcard

 you can save it to a file then use remote viewer to open it:
 $ remote-viewer [your saved file].vv

=head1 Attributes

 Other attributes is also inherited from Ovirt.pm
 Check 'perldoc Ovirt' for detail
 
 notes :
 ro                     = read only, can be specified only during initialization
 rw                     = read write, user can set this attribute
 rwp                    = read write protected, for internal class 
 
 expiry                 = (rw) specify password expiry in seconds, default is 120s
 ca                     = (rwp) store ca contents
=cut

has 'expiry'        => ( is => 'rw', default => 120 );
has 'ca'            => ( is => 'rwp' );

=head1 SUBROUTINES/METHODS

=head2 BUILD

 The Constructor, build logging, call pass_log_obj method from Ovirt.pm
 get and set ca certificate
 
=cut

sub BUILD {
    my $self = shift;
    
    $self->pass_log_obj;
    
    my $ca_url  = $self->base_url . "/ca.crt";
    my $ua      = LWP::UserAgent->new();
    my $ca      = $ua->get($ca_url);
    
    $ca         = $ca->decoded_content;
    my @line    = split '\n' => $ca;
    
    $ca         = join '\n' => @line;
    
    $ca =~ s/-----END CERTIFICATE-----/-----END CERTIFICATE-----\\n/;
    chomp $ca;
    
    $self->_set_ca($ca);
}

=head2 generate

 $display->generate($expire, $vmid);
 we can also set it during initialization (it's recommended to specify id for efficiency)
 my %con = (
            username                => 'admin',
            password                => 'password',
            manager                 => 'ovirt-mgr.example.com',
            expiry                  => 300,
            id                      => 'e20cc93c-f526-4682-a250-924fa953f57b'
 );
 
 my $display = Ovirt::Display->new(%con);
 $display->generate(); 
 
=cut

sub generate {
    my $self    = shift;
    
    my $expiry  = shift || $self->expiry;
    my $vmid    = $self->id || shift || croak "vm id required";   
    $self->log->debug("expiry: $expiry, vmid: $vmid");
    
    my $displayinfo = $self->get_display_info($vmid);
    
    my $vmname                  = @$displayinfo[1];
    my $display_type            = @$displayinfo[3];
    my $display_address         = @$displayinfo[4];
    my $display_port            = @$displayinfo[5];
    my $display_host_subject    = @$displayinfo[6];
    
    my $password = $self->set_ticket($expiry, $vmid);
    
    if ($display_type eq 'spice') {
        return $self->get_spice_template($vmname,$password,$expiry,$display_address,$display_port,$display_host_subject);
    }
    elsif ($display_type eq 'vnc') {
        return $self->get_vnc_template($vmname,$password,$expiry,$display_address,$display_port);
    }
    else {
        croak "display type not supported\n";
    }
}

=head2 get_vnc_template

 get_vnc_template($vmname,$password,$expiry,$display_address,$display_port);
 internal method, will return vnc template for Remote Viewer
=cut

sub get_vnc_template {
    my $self = shift;
    
    my ($vmname,$password,$expiry,$display_address,$display_port) = @_;
    
    my $template = <<EOF;
[virt-viewer]
type=vnc
host=$display_address
port=$display_port
password=$password
# Password is valid for $expiry seconds.
delete-this-file=1
title=$vmname:%d - Press SHIFT+F12 to Release Cursor
toggle-fullscreen=shift+f11
release-cursor=shift+f12
secure-attention=ctrl+alt+end    
EOF

    return $template;
}

=head2 get_spice_template

 get_spice_template($vmname,$password,$expiry,$display_address,$display_port,$display_host_subject);
 internal method, will return spice template for Remote Viewer

=cut

sub get_spice_template {
    my $self    = shift;
    
    my ($vmname,$password,$expiry,$display_address,$display_port,$display_host_subject) = @_;
    
    my $ca = $self->ca;
    my $template = <<EOF;
[virt-viewer]
type=spice
host=$display_address
port=-1
password=$password
# Password is valid for $expiry seconds.
tls-port=$display_port
fullscreen=0
title=$vmname : %d - Press SHIFT+F12 to Release Cursor
enable-smartcard=0
enable-usb-autoshare=1
delete-this-file=1
usb-filter=-1,-1,-1,-1,0
tls-ciphers=DEFAULT
host-subject=$display_host_subject
ca=$ca
toggle-fullscreen=shift+f11
release-cursor=shift+f12
secure-attention=ctrl+alt+end
secure-channels=main;inputs;cursor;playback;record;display;usbredir;smartcard    
EOF

    return $template;
}

=head2 set_ticket

 set_ticket($expire, $vmid);
 this method will set the password expiry and will return the password

=cut

sub set_ticket {
    my $self            = shift;
    my ($expiry, $vmid) = @_;
    
    my $ticketurl   = $self->base_url . "/api/vms/$vmid/ticket";
    my $xml = <<EOF;
<action>
    <ticket>
        <expiry>$expiry</expiry>
    </ticket>
</action>    
EOF

    $self->log->debug("ticket url : $ticketurl");

    # set user agent
    my $ua      = LWP::UserAgent->new();
    my $action  = $ua->post($ticketurl, Content_Type => 'application/xml', Content => $xml);
    
    my $parser = XML::LibXML->new();
    my $output = $parser->parse_string($action->decoded_content);
    
    $self->log->debug($output);
    
    my $status    = $output->findnodes('/action/status/state');
    if ($action->is_success) {
        croak "status not completed"
            unless $status eq 'complete';
        
        my $password = $output->findnodes('/action/ticket/value');
        return $password;
    }
    else {
        $self->log->debug("LWP Error : " . $action->status_line);
        
        return $status;
    }
}

=head2 get_display_info

 get_display_info($vmid);
 
 internal method to query vm display information.
 this will croak if vm state is not up.
 By default will return vmid,name,state,display_type,display_address,display_port,display_host_subject.
 check Ovirt::VM for more information

=cut

sub get_display_info {
    my $self    = shift;
    
    my $vmid    = shift;
    
    my %vmcon = (
                username        => $self->username,
                password        => $self->password,
                manager         => $self->manager,
                id              => $vmid,
                vm_output_attrs => 'id,name,state,display_type,display_address,display_port,display_host_subject',
    );
    
    my $vminfo  = Ovirt::VM->new(%vmcon);
    
    my $attrs   = $vminfo->list;
    chomp $attrs;
    
    $self->log->debug("Attributes: " . $attrs);
     
    # if state is not up, not interested
    $self->log->debug("Delimiter is " . $vminfo->vm_output_delimiter() );
    
    my $delimiter;
    if ($vminfo->vm_output_delimiter() eq '|') {
        $delimiter = '\|';
    }
    elsif ($vminfo->vm_output_delimiter() eq '||') {
        $delimiter = '\|\|';
    }
    else {
        $delimiter = $vminfo->vm_output_delimiter();
    }
    
    my @state = split $delimiter => $attrs;
    for my $attr (@state) {
        $self->log->debug($attr);
    }
    
    if ($state[2] ne 'up') {
        croak "vm state is $state[2], it need to be in up state";
    } 
    
    return \@state;
}

=head1 AUTHOR

 "Heince Kurniawan", C<< <"heince at cpan.org"> >>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-ovirt at rt.cpan.org>, or through
 the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ovirt::Display>.  I will be notified, and then you'll
 automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

    perldoc Ovirt::Display

 You can also look for information at:

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 "Heince Kurniawan".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;