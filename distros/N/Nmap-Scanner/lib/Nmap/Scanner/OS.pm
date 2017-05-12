
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::OS' => {
    qw(ports_used    @Nmap::Scanner::OS::PortUsed
       osmatches     @Nmap::Scanner::OS::Match
       osclasses     @Nmap::Scanner::OS::Class
       osfingerprint  Nmap::Scanner::OS::Fingerprint
       uptime         Nmap::Scanner::OS::Uptime
       tcpsequence    Nmap::Scanner::OS::TCPSequence
       tcptssequence  Nmap::Scanner::OS::TCPTSSequence
       ipidsequence   Nmap::Scanner::OS::IPIdSequence),
    '&add_port_used' => q!push(@{$self->{'ports_used'}}, $_[0]);!,
    '&add_os_match'  => q!push(@{$self->{'osmatches'}}, $_[0]);!,
    '&add_os_class'  => q!push(@{$self->{'osclasses'}}, $_[0]);!,
    '&as_xml'        => q!

    #  No fingerprinting happened if no ports found to fingerprint with.
    return unless scalar($self->ports_used()) > 0;

    my $xml = "<os>\n";

    for my $port ($self->ports_used()) {
        $xml .= $port->as_xml() . "\n";
    }

    for my $c ($self->osclasses()) {
        $xml .= $c->as_xml() . "\n";
    }

    for my $m ($self->osmatches()) {
        $xml .= $m->as_xml() . "\n";
    }

    $xml .= "</os>\n";

    $xml .= join("\n", 
        ($self->{'uptime'} ? $self->{'uptime'}->as_xml() : ''),
        ($self->{'osfingerprint'} ? $self->{'osfingerprint'}->as_xml() : ''),
        ($self->{'tcpsequence'} ? $self->{'tcpsequence'}->as_xml() : ''),
        ($self->{'tcptssequence'} ? $self->{'tcptssequence'}->as_xml() : ''),
        ($self->{'ipidsequence'} ? $self->{'ipidsequence'}->as_xml() : ''));

    return $xml;

    !
};

=pod

=head1 DESCRIPTION

This class represents an nmap OS deduction as output by nmap.  It is
generally returned as part of a host object, and only so if guess_os() 
is used as an option with the Nmap::Scanner::Scanner instance.

=head1 PROPERTIES

=head2 ports_used()

The open ports used to try and fingerprint the remote OS.

=head2 add_port_used()

Add a port to the list of ports used to try and fingerprint the remote hosts' OS.

=head2 osmatches()

Object representing nmaps' best attempt to fingerprint the remote OS.

=head2 uptime

Object representing uptime/last reboot time for this host.  
This MAY be available if guess_os() is called on the 
Nmap::Scanner::Scanner reference.  Not available for all hosts.

=cut
