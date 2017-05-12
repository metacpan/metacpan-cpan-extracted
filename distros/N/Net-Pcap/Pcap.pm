#
# Pcap.pm
#
# An interface to the LBL pcap(3) library.  This module simply
# bootstraps the extensions defined in Pcap.xs
#
# Copyright (C) 2005-2009 Sebastien Aperghis-Tramoni. All rights reserved.
# Copyright (C) 2003 Marco Carnut. All rights reserved. 
# Copyright (C) 1999, 2000 Tim Potter. All rights reserved. 
# Copyright (C) 1998 Bo Adler. All rights reserved. 
# Copyright (C) 1997 Peter Lister. All rights reserved. 
# 
# This program is free software; you can redistribute it and/or modify 
# it under the same terms as Perl itself.
#
package Net::Pcap;
use strict;
use warnings;
use Exporter ();
use Carp;


# functions names
my @func_short_names = qw(
    lookupdev  findalldevs  lookupnet
    open_live  open_dead  open_offline  loop  breakloop  close  dispatch
    next  next_ex  compile  compile_nopcap  setfilter  freecode
    offline_filter  setnonblock  getnonblock
    dump_open  dump  dump_file  dump_flush  dump_close
    datalink  set_datalink  datalink_name_to_val  datalink_val_to_name
    datalink_val_to_description
    snapshot  is_swapped  major_version  minor_version  stats
    file  fileno  get_selectable_fd  geterr  strerror  perror
    lib_version  createsrcstr  parsesrcstr  open  setbuff  setuserbuffer
    setmode  setmintocopy  getevent  sendpacket
    sendqueue_alloc  sendqueue_queue  sendqueue_transmit
);

my @func_long_names = map { "pcap_$_" } @func_short_names;


# functions aliases
{
    no strict "refs";
    for my $func (@func_short_names) {
        *{ __PACKAGE__ . "::pcap_$func" } = \&{ __PACKAGE__ . "::" . $func }
    }
}


{
    no strict "vars";
    $VERSION = '0.18';

    @ISA = qw(Exporter);

    %EXPORT_TAGS = (
        'bpf' => [qw(
            BPF_ALIGNMENT  BPF_MAJOR_VERSION  BPF_MAXBUFSIZE  BPF_MAXINSNS
            BPF_MEMWORDS  BPF_MINBUFSIZE  BPF_MINOR_VERSION  BPF_RELEASE
        )], 
        'datalink' => [qw(
            DLT_AIRONET_HEADER  DLT_APPLE_IP_OVER_IEEE1394  DLT_ARCNET
            DLT_ARCNET_LINUX  DLT_ATM_CLIP  DLT_ATM_RFC1483  DLT_AURORA
            DLT_AX25  DLT_CHAOS  DLT_CHDLC  DLT_CISCO_IOS  DLT_C_HDLC
            DLT_DOCSIS  DLT_ECONET  DLT_EN10MB  DLT_EN3MB  DLT_ENC  DLT_FDDI
            DLT_FRELAY  DLT_HHDLC  DLT_IBM_SN  DLT_IBM_SP  DLT_IEEE802
            DLT_IEEE802_11  DLT_IEEE802_11_RADIO  DLT_IEEE802_11_RADIO_AVS
            DLT_IPFILTER  DLT_IP_OVER_FC  DLT_JUNIPER_ATM1  DLT_JUNIPER_ATM2
            DLT_JUNIPER_ES  DLT_JUNIPER_GGSN  DLT_JUNIPER_MFR  DLT_JUNIPER_MLFR
            DLT_JUNIPER_MLPPP  DLT_JUNIPER_MONITOR  DLT_JUNIPER_SERVICES
            DLT_LINUX_IRDA  DLT_LINUX_SLL  DLT_LOOP  DLT_LTALK  DLT_NULL
            DLT_OLD_PFLOG  DLT_PCI_EXP  DLT_PFLOG  DLT_PFSYNC  DLT_PPP
            DLT_PPP_BSDOS  DLT_PPP_ETHER  DLT_PPP_SERIAL  DLT_PRISM_HEADER
            DLT_PRONET  DLT_RAW  DLT_RIO  DLT_SLIP  DLT_SLIP_BSDOS  DLT_SUNATM
            DLT_SYMANTEC_FIREWALL  DLT_TZSP  DLT_USER0  DLT_USER1  DLT_USER2
            DLT_USER3  DLT_USER4  DLT_USER5  DLT_USER6  DLT_USER7  DLT_USER8
            DLT_USER9  DLT_USER10  DLT_USER11  DLT_USER12  DLT_USER13
            DLT_USER14  DLT_USER15
        )], 
        mode => [qw(
            MODE_CAPT  MODE_MON  MODE_STAT
        )],
        openflag => [qw(
            OPENFLAG_PROMISCUOUS  OPENFLAG_DATATX_UDP  OPENFLAG_NOCAPTURE_RPCAP
        )],
        pcap => [qw(
            PCAP_ERRBUF_SIZE    PCAP_IF_LOOPBACK
            PCAP_VERSION_MAJOR  PCAP_VERSION_MINOR
        )], 
        rpcap => [qw(
            RMTAUTH_NULL  RMTAUTH_PWD
        )],
        sample => [qw(
            PCAP_SAMP_NOSAMP  PCAP_SAMP_1_EVERY_N  PCAP_SAMP_FIRST_AFTER_N_MS
        )],
        source => [qw(
            PCAP_SRC_FILE  PCAP_SRC_IFLOCAL  PCAP_SRC_IFREMOTE
        )],
        functions => [qw(
            lookupdev  findalldevs  lookupnet
            open_live  open_dead  open_offline
            dump_open  dump_close  dump_file  dump_flush
            compile  compile_nopcap  setfilter  freecode
            offline_filter  setnonblock  getnonblock
            dispatch  next_ex  loop  breakloop
            datalink  set_datalink  datalink_name_to_val  
            datalink_val_to_name  datalink_val_to_description
            snapshot  get_selectable_fd
            stats  is_swapped  major_version  minor_version
            geterr  strerror  perror  lib_version
            createsrcstr  parsesrcstr
            setbuff  setuserbuffer  setmode  setmintocopy  getevent  sendpacket
            sendqueue_alloc  sendqueue_queue  sendqueue_transmit
        )], 
    );

    @EXPORT = (
        @{$EXPORT_TAGS{pcap}}, 
        @{$EXPORT_TAGS{datalink}}, 
        @func_long_names,
        "UNSAFE_SIGNALS",
    );

    @EXPORT_OK = (
        @{$EXPORT_TAGS{functions}}, 
        @{$EXPORT_TAGS{mode}}, 
        @{$EXPORT_TAGS{openflag}}, 
        @{$EXPORT_TAGS{bpf}}, 
    );

    eval {
        require XSLoader;
        XSLoader::load('Net::Pcap', $VERSION);
        1
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        bootstrap Net::Pcap $VERSION;
    };
}


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    no strict "vars";
    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    return if $constname eq "DESTROY";
    croak "Net::Pcap::constant() not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }

    {
        no strict "refs";
	# Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    } else {
	    *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}


# pseudo-bloc to enable immediate (unsafe) signals delivery
sub UNSAFE_SIGNALS (&) {
    $_[0]->();
}


# Perl wrapper for DWIM
sub findalldevs {
    croak "Usage: pcap_findalldevs(devinfo, err)"
        unless @_ and @_ <= 2 and ref $_[0];

    # findalldevs(\$err), legacy from Marco Carnut 0.05
    my %devinfo = ();
    ( ref $_[0] eq 'SCALAR' and return findalldevs_xs(\%devinfo, $_[0]) ) 
        or croak "arg1 not a scalar ref"
        if @_ == 1;

    # findalldevs(\$err, \%devinfo), legacy from Jean-Louis Morel 0.04.02
    ref $_[0] eq 'SCALAR' and (
        ( ref $_[1] eq 'HASH' and return findalldevs_xs($_[1], $_[0]) )
        or croak "arg2 not a hash ref"
    );

    # findalldevs(\%devinfo, \$err), new, correct syntax, consistent with libpcap(3)
    ref $_[0] eq 'HASH' and (
        ( ref $_[1] eq 'SCALAR' and return findalldevs_xs($_[0], $_[1]) )
            or croak "arg2 not a scalar ref"
    );

    # if here, the function was called with incorrect arguments
    ref $_[0] ne 'HASH' and croak "arg1 not a hash ref";
}


1;

__END__

=encoding UTF-8

=head1 NAME

Net::Pcap - Interface to the pcap(3) LBL packet capture library

=head1 VERSION

Version 0.18

=head1 SYNOPSIS

    use Net::Pcap;

    my $err = '';
    my $dev = pcap_lookupdev(\$err);  # find a device

    # open the device for live listening
    my $pcap = pcap_open_live($dev, 1024, 1, 0, \$err);

    # loop over next 10 packets
    pcap_loop($pcap, 10, \&process_packet, "just for the demo");

    # close the device
    pcap_close($pcap);

    sub process_packet {
        my ($user_data, $header, $packet) = @_;
        # do something ...
    }


=head1 DESCRIPTION

C<Net::Pcap> is a Perl binding to the LBL pcap(3) library and its
Win32 counterpart, the WinPcap library. Pcap (packet capture) is 
a portable API to capture network packet: it allows applications 
to capture packets at link-layer, bypassing the normal protocol 
stack. It also provides features like kernel-level packet filtering
and access to internal statistics.

Common applications include network statistics collection, 
security monitoring, network debugging, etc.


=head1 NOTES

=head2 Signals handling

Since version 5.7.3, Perl uses a mechanism called "deferred signals"
to delay signals delivery until "safe" points in the interpreter. 
See L<perlipc/"Deferred Signals (Safe Signals)"> for a detailled
explanation.

Since C<Net::Pcap> version 0.08, released in October 2005, the module
modified the internal variable C<PL_signals> to re-enable immediate
signals delivery in Perl 5.8 and later within some XS functions
(CPAN-RT #6320). However, it can create situations where the Perl
interpreter is less stable and can crash (CPAN-RT #43308). Therefore,
as of version 0.17, C<Net::Pcap> no longer modifies C<PL_signals> by
itself, but provides facilities so the user has full control of how
signals are delivered.

First, the C<pcap_perl_settings()> function allows one to select how
signals are handled:

    pcap_perl_settings(PERL_SIGNALS_UNSAFE);
    pcap_loop($pcap, 10, \&process_packet, "");
    pcap_perl_settings(PERL_SIGNALS_SAFE);

Then, to easily make code interruptable, C<Net::Pcap> provides the
C<UNSAFE_SIGNALS> pseudo-bloc:

    UNSAFE_SIGNALS {
        pcap_loop($pcap, 10, \&process_packet, "");
    };

(Stolen from Rafael Garcia-Suarez's C<Perl::Unsafe::Signals>)


=head1 EXPORTS

C<Net::Pcap> supports the following C<Exporter> tags: 

=over

=item *

C<:bpf> exports a few BPF related constants: 

    BPF_ALIGNMENT  BPF_MAJOR_VERSION  BPF_MAXBUFSIZE  BPF_MAXINSNS
    BPF_MEMWORDS  BPF_MINBUFSIZE  BPF_MINOR_VERSION  BPF_RELEASE

=item *

C<:datalink> exports the data link types macros: 

    DLT_AIRONET_HEADER  DLT_APPLE_IP_OVER_IEEE1394  DLT_ARCNET
    DLT_ARCNET_LINUX  DLT_ATM_CLIP  DLT_ATM_RFC1483  DLT_AURORA
    DLT_AX25  DLT_CHAOS  DLT_CHDLC  DLT_CISCO_IOS  DLT_C_HDLC
    DLT_DOCSIS  DLT_ECONET  DLT_EN10MB  DLT_EN3MB  DLT_ENC  DLT_FDDI
    DLT_FRELAY  DLT_HHDLC  DLT_IBM_SN  DLT_IBM_SP  DLT_IEEE802
    DLT_IEEE802_11  DLT_IEEE802_11_RADIO DLT_IEEE802_11_RADIO_AVS
    DLT_IPFILTER  DLT_IP_OVER_FC  DLT_JUNIPER_ATM1 DLT_JUNIPER_ATM2
    DLT_JUNIPER_ES  DLT_JUNIPER_GGSN  DLT_JUNIPER_MFR DLT_JUNIPER_MLFR
    DLT_JUNIPER_MLPPP  DLT_JUNIPER_MONITOR  DLT_JUNIPER_SERVICES
    DLT_LINUX_IRDA  DLT_LINUX_SLL  DLT_LOOP  DLT_LTALK  DLT_NULL
    DLT_OLD_PFLOG  DLT_PCI_EXP  DLT_PFLOG  DLT_PFSYNC  DLT_PPP
    DLT_PPP_BSDOS  DLT_PPP_ETHER  DLT_PPP_SERIAL  DLT_PRISM_HEADER
    DLT_PRONET  DLT_RAW  DLT_RIO  DLT_SLIP  DLT_SLIP_BSDOS  DLT_SUNATM
    DLT_SYMANTEC_FIREWALL  DLT_TZSP  DLT_USER0  DLT_USER1  DLT_USER2
    DLT_USER3  DLT_USER4  DLT_USER5  DLT_USER6  DLT_USER7  DLT_USER8
    DLT_USER9  DLT_USER10  DLT_USER11  DLT_USER12  DLT_USER13
    DLT_USER14  DLT_USER15

=item *

C<:pcap> exports the following C<pcap> constants: 

    PCAP_ERRBUF_SIZE    PCAP_IF_LOOPBACK
    PCAP_VERSION_MAJOR  PCAP_VERSION_MINOR

=item *

C<:mode> exports the following constants:

    MODE_CAPT  MODE_MON  MODE_STAT

=item *

C<:openflag> exports the following constants:

    OPENFLAG_PROMISCUOUS  OPENFLAG_DATATX_UDP  OPENFLAG_NOCAPTURE_RPCAP

=item *

C<:source> exports the following constants:

    PCAP_SRC_FILE  PCAP_SRC_IFLOCAL  PCAP_SRC_IFREMOTE

=item *

C<:sample> exports the following constants:

    PCAP_SAMP_NOSAMP  PCAP_SAMP_1_EVERY_N  PCAP_SAMP_FIRST_AFTER_N_MS

=item *

C<:rpcap> exports the following constants:

    RMTAUTH_NULL  RMTAUTH_PWD

=item *

C<:functions> short names of the functions (without the C<"pcap_"> prefix) 
for those which would not cause a clash with an already defined name.
Namely, the following functions are not available in short form: 
C<open()>, C<close()>, C<next()>, C<dump()>, C<file()>, C<fileno()>. 
Using these short names is now discouraged, and may be removed in the future.

=back

By default, this module exports the symbols from the C<:datalink> and 
C<:pcap> tags, and all the functions, with the same names as the C library. 


=head1 FUNCTIONS

All functions defined by C<Net::Pcap> are direct mappings to the
libpcap functions.  Consult the pcap(3) documentation and source code
for more information.

Arguments that change a parameter, for example C<pcap_lookupdev()>,
are passed that parameter as a reference.  This is to retain
compatibility with previous versions of C<Net::Pcap>.

=head2 Lookup functions

=over

=item B<pcap_lookupdev(\$err)>

Returns the name of a network device that can be used with
C<pcap_open_live()> function.  On error, the C<$err> parameter 
is filled with an appropriate error message else it is undefined.

B<Example>

    $dev = pcap_lookupdev();


=item B<pcap_findalldevs(\%devinfo, \$err)>

Returns a list of all network device names that can be used with
C<pcap_open_live()> function.  On error, the C<$err> parameter 
is filled with an appropriate error message else it is undefined.

B<Example>

    @devs = pcap_findalldevs(\%devinfo, \$err);
    for my $dev (@devs) {
        print "$dev : $devinfo{$dev}\n"
    }

=over

=item B<Note> 

For backward compatibility reasons, this function can also 
be called using the following signatures: 

    @devs = pcap_findalldevs(\$err);

    @devs = pcap_findalldevs(\$err, \%devinfo);

The first form was introduced by Marco Carnut in C<Net::Pcap> version 0.05 
and kept intact in versions 0.06 and 0.07. 
The second form was introduced by Jean-Louis Morel for the Windows only, 
ActivePerl port of C<Net::Pcap>, in versions 0.04.01 and 0.04.02. 

The new syntax has been introduced for consistency with the rest of the Perl 
API and the C API of C<libpcap(3)>, where C<$err> is always the last argument. 

=back


=item B<pcap_lookupnet($dev, \$net, \$mask, \$err)>

Determine the network number and netmask for the device specified in
C<$dev>.  The function returns 0 on success and sets the C<$net> and
C<$mask> parameters with values.  On failure it returns -1 and the
C<$err> parameter is filled with an appropriate error message.

=back

=head2 Packet capture functions

=over

=item B<pcap_open_live($dev, $snaplen, $promisc, $to_ms, \$err)>

Returns a packet capture descriptor for looking at packets on the
network.  The C<$dev> parameter specifies which network interface to
capture packets from.  The C<$snaplen> and C<$promisc> parameters specify
the maximum number of bytes to capture from each packet, and whether
to put the interface into promiscuous mode, respectively.  The C<$to_ms>
parameter specifies a read timeout in milliseconds.  The packet descriptor 
will be undefined if an error occurs, and the C<$err> parameter will be 
set with an appropriate error message.

B<Example>

    $dev = pcap_lookupdev();
    $pcap = pcap_open_live($dev, 1024, 1, 0, \$err)
        or die "Can't open device $dev: $err\n";


=item B<pcap_open_dead($linktype, $snaplen)>

Creates and returns a new packet descriptor to use when calling the other 
functions in C<libpcap>. It is typically used when just using C<libpcap> 
for compiling BPF code. 

B<Example>

    $pcap = pcap_open_dead(0, 1024);


=item B<pcap_open_offline($filename, \$err)>

Return a packet capture descriptor to read from a previously created
"savefile".  The returned descriptor is undefined if there was an
error and in this case the C<$err> parameter will be filled.  Savefiles
are created using the C<pcap_dump_*> commands.

B<Example>

    $pcap = pcap_open_offline($dump, \$err)
        or die "Can't read '$dump': $err\n";


=item B<pcap_loop($pcap, $count, \&callback, $user_data)>

Read C<$count> packets from the packet capture descriptor C<$pcap> and call
the perl function C<&callback> with an argument of C<$user_data>.  
If C<$count> is negative, then the function loops forever or until an error 
occurs. Returns 0 if C<$count> is exhausted, -1 on error, and -2 if the 
loop terminated due to a call to pcap_breakloop() before any packets were 
processed. 

The callback function is also passed packet header information and
packet data like so:

    sub process_packet {
        my ($user_data, $header, $packet) = @_;

        ...
    }

The header information is a reference to a hash containing the
following fields.

=over

=item * 

C<len> - the total length of the packet.

=item * 

C<caplen> - the actual captured length of the packet data.  This corresponds 
to the snapshot length parameter passed to C<open_live()>.

=item *

C<tv_sec> - seconds value of the packet timestamp.

=item *

C<tv_usec> - microseconds value of the packet timestamp.

=back

B<Example>

    pcap_loop($pcap, 10, \&process_packet, "user data");

    sub process_packet {
        my ($user_data, $header, $packet) = @_;
        # ...
    }


=item B<pcap_breakloop($pcap)>

Sets a flag  that will force C<pcap_dispatch()> or C<pcap_loop()> 
to return rather than looping; they will return the number of packets that 
have been processed so far, or -2 if no packets have been processed so far. 

This routine is safe to use inside a signal handler on UNIX or a console 
control handler on Windows, as it merely sets a flag that is checked within 
the loop. 

Please see the section on C<pcap_breakloop()> in L<pcap(3)> for more 
information. 


=item B<pcap_close($pcap)>

Close the packet capture device associated with the descriptor C<$pcap>.


=item B<pcap_dispatch($pcap, $count, \&callback, $user_data)>

Collect C<$count> packets and process them with callback function
C<&callback>.  if C<$count> is -1, all packets currently buffered are
processed.  If C<$count> is 0, process all packets until an error occurs. 


=item B<pcap_next($pcap, \%header)>

Return the next available packet on the interface associated with
packet descriptor C<$pcap>.  Into the C<%header> hash is stored the received
packet header.  If not packet is available, the return value and
header is undefined.


=item B<pcap_next_ex($pcap, \%header, \$packet)>

Reads the next available packet on the interface associated with packet 
descriptor C<$pcap>, stores its header in C<\%header> and its data in 
C<\$packet> and returns a success/failure indication: 

=over

=item *

C<1> means that the packet was read without problems; 

=item *

C<0> means that packets are being read from a live capture, and the 
timeout expired;

=item *

C<-1> means that an error occurred while reading the packet;

=item *

C<-2> packets are being read from a dump file, and there are no more 
packets to read from the savefile.

=back


=item B<pcap_compile($pcap, \$filter, $filter_str, $optimize, $netmask)>

Compile the filter string contained in C<$filter_str> and store it in
C<$filter>.  A description of the filter language can be found in the
libpcap source code, or the manual page for tcpdump(8) .  The filter
is optimized if the C<$optimize> variable is true.  The netmask of the 
network device must be specified in the C<$netmask> parameter.  The 
function returns 0 if the compilation was successful, or -1 if there 
was a problem.


=item B<pcap_compile_nopcap($snaplen, $linktype, \$filter, $filter_str, $optimize, $netmask)>

Similar to C<compile()> except that instead of passing a C<$pcap> descriptor, 
one passes C<$snaplen> and C<$linktype> directly. Returns -1 if there was an 
error, but the error message is not available. 


=item B<pcap_setfilter($pcap, $filter)>

Associate the compiled filter stored in C<$filter> with the packet
capture descriptor C<$pcap>.


=item B<pcap_freecode($filter)>

Used to free the allocated memory used by a compiled filter, as created 
by C<pcap_compile()>. 


=item B<pcap_offline_filter($filter, \%header, $packet)>

Check whether C<$filter> matches the packet described by header C<%header>
and packet data C<$packet>. Returns true if the packet matches.


=item B<pcap_setnonblock($pcap, $mode, \$err)>

Set the I<non-blocking> mode of a live capture descriptor, depending on the 
value of C<$mode> (zero to activate and non-zero to deactivate). It has no 
effect on offline descriptors. If there is an error, it returns -1 and sets 
C<$err>. 

In non-blocking mode, an attempt to read from the capture descriptor with 
C<pcap_dispatch()> will, if no packets are currently available to be read, 
return 0  immediately rather than blocking waiting for packets to arrive. 
C<pcap_loop()> and C<pcap_next()> will not work in non-blocking mode. 


=item B<pcap_getnonblock($pcap, \$err)>

Returns the I<non-blocking> state of the capture descriptor C<$pcap>. 
Always returns 0 on savefiles. If there is an error, it returns -1 and 
sets C<$err>. 

=back

=head2 Savefile commands

=over

=item B<pcap_dump_open($pcap, $filename)>

Open a savefile for writing and return a descriptor for doing so.  If
C<$filename> is C<"-"> data is written to standard output.  On error, the
return value is undefined and C<pcap_geterr()> can be used to
retrieve the error text.


=item B<pcap_dump($dumper, \%header, $packet)>

Dump the packet described by header C<%header> and packet data C<$packet> 
to the savefile associated with C<$dumper>.  The packet header has the
same format as that passed to the C<pcap_loop()> callback.

B<Example>

    my $dump_file = 'network.dmp';
    my $dev = pcap_lookupdev();
    my $pcap = pcap_open_live($dev, 1024, 1, 0, \$err);

    my $dumper = pcap_dump_open($pcap, $dump_file);
    pcap_loop($pcap, 10, \&process_packet, '');
    pcap_dump_close($dumper);

    sub process_packet {
        my ($user_data, $header, $packet) = @_;
        pcap_dump($dumper, $header, $packet);
    }


=item B<pcap_dump_file($dumper)>

Returns the filehandle associated with a savefile opened with
C<pcap_dump_open()>.


=item B<pcap_dump_flush($dumper)>

Flushes the output buffer to the corresponding save file, so that any 
packets written with C<pcap_dump()> but not yet written to the save 
file will be written. Returns -1 on error, 0 on success.


=item B<pcap_dump_close($dumper)>

Close the savefile associated with the descriptor C<$dumper>.

=back

=head2 Status functions

=over


=item B<pcap_datalink($pcap)>

Returns the link layer type associated with the given pcap descriptor.

B<Example>

    $linktype = pcap_datalink($pcap);


=item B<pcap_set_datalink($pcap, $linktype)>

Sets the data link type of the given pcap descriptor to the type specified 
by C<$linktype>. Returns -1 on failure. 


=item B<pcap_datalink_name_to_val($name)>

Translates a data link type name, which is a C<DLT_> name with the C<DLT_> 
part removed, to the corresponding data link type value. The translation is 
case-insensitive. Returns -1 on failure. 

B<Example>

    $linktype = pcap_datalink_name_to_val('LTalk');  # returns DLT_LTALK


=item B<pcap_datalink_val_to_name($linktype)>

Translates a data link type value to the corresponding data link type name. 

B<Example>

    $name = pcap_datalink_val_to_name(DLT_LTALK);  # returns 'LTALK'


=item B<pcap_datalink_val_to_description($linktype)>

Translates a data link type value to a short description of that data link type.

B<Example>

    $descr = pcap_datalink_val_to_description(DLT_LTALK);  # returns 'Localtalk'


=item B<pcap_snapshot($pcap)>

Returns the snapshot length (snaplen) specified in the call to
C<pcap_open_live()>.


=item B<pcap_is_swapped($pcap)>

This function returns true if the endianness of the currently open
savefile is different from the endianness of the machine.


=item B<pcap_major_version($pcap)>

Return the major version number of the pcap library used to write the
currently open savefile.


=item B<pcap_minor_version($pcap)>

Return the minor version of the pcap library used to write the
currently open savefile.


=item B<pcap_stats($pcap, \%stats)>

Returns a hash containing information about the status of packet
capture device C<$pcap>.  The hash contains the following fields.

This function is supported only on live captures, not on savefiles; 
no statistics are stored in savefiles, so no statistics are available 
when reading from a savefile.

=over

=item *

C<ps_recv> - the number of packets received by the packet capture software.

=item *

C<ps_drop> - the number of packets dropped by the packet capture software.

=item *

C<ps_ifdrop> - the number of packets dropped by the network interface.

=back


=item B<pcap_file($pcap)>

Returns the filehandle associated with a savefile opened with
C<pcap_open_offline()> or C<undef> if the device was opened 
with C<pcap_open_live()>.


=item B<pcap_fileno($pcap)>

Returns the file number of the network device opened with C<pcap_open_live()>.


=item B<pcap_get_selectable_fd($pcap)>

Returns, on Unix, a file descriptor number for a file descriptor on which 
one can do a C<select()> or C<poll()> to wait for it to be possible to read 
packets without blocking, if such a descriptor exists, or -1, if no such 
descriptor exists. Some network devices opened with C<pcap_open_live()> 
do not support C<select()> or C<poll()>, so -1 is returned for those devices.
See L<pcap(3)> for more details. 

=back

=head2 Error handling

=over

=item B<pcap_geterr($pcap)>

Returns an error message for the last error associated with the packet
capture device C<$pcap>.


=item B<pcap_strerror($errno)>

Returns a string describing error number C<$errno>.


=item B<pcap_perror($pcap, $prefix)>

Prints the text of the last error associated with descriptor C<$pcap> on
standard error, prefixed by C<$prefix>.

=back

=head2 Information

=over

=item B<pcap_lib_version()>

Returns the name and version of the C<pcap> library the module was linked 
against. 

=back

=head2 Perl specific functions

The following functions are specific to the Perl binding of libpcap.

=over

=item B<pcap_perl_settings($setting)>

Modify internal behaviour of the Perl interpreter.

=over

=item *

C<PERL_SIGNALS_SAFE>, C<PERL_SIGNALS_UNSAFE> respectively enable safe
or unsafe signals delivery. Returns the previous value of C<PL_signals>.
See L<"Signals handling">.

B<Example:>

    local $SIG{ALRM} = sub { pcap_breakloop() };
    alarm 60;

    pcap_perl_settings(PERL_SIGNALS_UNSAFE);
    pcap_loop($pcap, 10, \&process_packet, "");
    pcap_perl_settings(PERL_SIGNALS_SAFE);

=back

=back

=head2 WinPcap specific functions

The following functions are only available with WinPcap, the Win32 port 
of the Pcap library.  If a called function is not available, it will cleanly 
C<croak()>. 

=over

=item B<pcap_createsrcstr(\$source, $type, $host, $port, $name, \$err)>

Accepts a set of strings (host name, port, ...), and stores the complete 
source string according to the new format (e.g. C<"rpcap://1.2.3.4/eth0">) 
in C<$source>.

This function is provided in order to help the user creating the source 
string according to the new format. An unique source string is used in 
order to make easy for old applications to use the remote facilities. 
Think about B<tcpdump(1)>, for example, which has only one way to specify 
the interface on which the capture has to be started. However, GUI-based 
programs can find more useful to specify hostname, port and interface name 
separately. In that case, they can use this function to create the source 
string before passing it to the C<pcap_open()> function.

Returns 0 if everything is fine, -1 if some errors occurred. The string 
containing the complete source is returned in the C<$source> variable.


=item B<pcap_parsesrcstr($source, \$type, \$host, \$port, \$name, \$err)>

Parse the source string and stores the pieces in which the source can be split 
in the corresponding variables.

This call is the other way round of C<pcap_createsrcstr()>. It accepts a 
null-terminated string and it returns the parameters related to the source. 
This includes:

=over

=item *

the type of the source (file, WinPcap on a remote adapter, WinPcap on local 
adapter), which is determined by the source prefix (C<PCAP_SRC_IF_STRING> 
and so on);

=item *

the host on which the capture has to be started (only for remote captures);

=item *

the raw name of the source (file name, name of the remote adapter, name of 
the local adapter), without the source prefix. The string returned does not 
include the type of the source itself (i.e. the string returned does not 
include C<"file://"> or C<"rpcap://"> or such).

=back

The user can omit some parameters in case it is not interested in them.

Returns 0 if everything is fine, -1 if some errors occurred. The requested 
values (host name, network port, type of the source) are returned into the 
proper variables passed by reference.


=item B<pcap_open($source, $snaplen, $flags, $read_timeout, \$auth, \$err)>

Open a generic source in order to capture / send (WinPcap only) traffic.

The C<pcap_open()> replaces all the C<pcap_open_xxx()> functions with a single 
call.

This function hides the differences between the different C<pcap_open_xxx()> 
functions so that the programmer does not have to manage different opening 
function. In this way, the I<true> C<open()> function is decided according 
to the source type, which is included into the source string (in the form of 
source prefix).

Returns a pointer to a pcap descriptor which can be used as a parameter to 
the following calls (C<compile()> and so on) and that specifies an opened 
WinPcap session. In case of problems, it returns C<undef> and the C<$err> 
variable keeps the error message.


=item B<pcap_setbuff($pcap, $dim)>

Sets the size of the kernel buffer associated with an adapter.
C<$dim> specifies the size of the buffer in bytes.
The return value is 0 when the call succeeds, -1 otherwise.

If an old buffer was already created with a previous call to
C<setbuff()>, it is deleted and its content is discarded.
C<open_live()> creates a S<1 MB> buffer by default.


=item B<pcap_setmode($pcap, $mode)>

Sets the working mode of the interface C<$pcap> to C<$mode>.
Valid values for C<$mode> are C<MODE_CAPT> (default capture mode) and
C<MODE_STAT> (statistical mode).


=item B<pcap_setmintocopy($pcap_t, $size)>

Changes the minimum amount of data in the kernel buffer that causes a read
from the application to return (unless the timeout expires).


=item B<pcap_getevent($pcap)>

Returns the C<Win32::Event> object associated with the interface 
C<$pcap>. Can be used to wait until the driver's buffer contains some 
data without performing a read. See L<Win32::Event>.


=item B<pcap_sendpacket($pcap, $packet)>

Send a raw packet to the network. C<$pcap> is the interface that will be
used to send the packet, C<$packet> contains the data of the packet to send
(including the various protocol headers). The MAC CRC doesn't need to be
included, because it is transparently calculated and added by the network
interface driver. The return value is 0 if the packet is successfully sent,
-1 otherwise.


=item B<pcap_sendqueue_alloc($memsize)>

This function allocates and returns a send queue, i.e. a buffer containing 
a set of raw packets that will be transmitted on the network with 
C<sendqueue_transmit()>.

C<$memsize> is the size, in bytes, of the queue, therefore it determines 
the maximum amount of data that the queue will contain. This memory is 
automatically deallocated when the queue ceases to exist.


=item B<pcap_sendqueue_queue($queue, \%header, $packet)>

Adds a packet at the end of the send queue pointed by C<$queue>. The packet
header C<%header> has the same format as that passed to the C<loop()> 
callback. C<$ackekt> is a buffer with the data of the packet.

The C<%headerr> header structure is the same used by WinPcap and libpcap to
store the packets in a file, therefore sending a capture file is
straightforward. "Raw packet" means that the sending application will have
to include the protocol headers, since every packet is sent to the network
I<as is>. The CRC of the packets needs not to be calculated, because it will
be transparently added by the network interface.


=item B<pcap_sendqueue_transmit($pcap, $queue, $sync)>

This function transmits the content of a queue to the wire. C<$pcapt> is
the interface on which the packets will be sent, C<$queue> is to a
C<send_queue> containing the packets to send, C<$sync> determines if the
send operation must be synchronized: if it is non-zero, the packets are
sent respecting the timestamps, otherwise they are sent as fast as
possible.

The return value is the amount of bytes actually sent. If it is smaller
than the size parameter, an error occurred during the send. The error can
be caused by a driver/adapter problem or by an inconsistent/bogus send
queue.

=back


=head1 CONSTANTS

C<Net::Pcap> exports by default the names of several constants in order to 
ease the development of programs. See L</"EXPORTS"> for details about which 
constants are exported. 

Here are the descriptions of a few data link types. See L<pcap(3)> for a more 
complete description and semantics associated with each data link. 

=over

=item *

C<DLT_NULL> - BSD loopback encapsulation

=item *

C<DLT_EN10MB> - Ethernet (10Mb, 100Mb, 1000Mb, and up)

=item *

C<DLT_RAW> - raw IP

=item *

C<DLT_IEEE802> - IEEE 802.5 Token Ring

=item *

C<DLT_IEEE802_11> - IEEE 802.11 wireless LAN

=item *

C<DLT_FRELAY> - Frame Relay

=item *

C<DLT_FDDI> - FDDI

=item *

C<DLT_SLIP> - Serial Line IP

=item *

C<DLT_PPP> - PPP (Point-to-point Protocol)

=item *

C<DLT_PPP_SERIAL> - PPP over serial with HDLC encapsulation

=item *

C<DLT_PPP_ETHER> - PPP over Ethernet

=item *

C<DLT_IP_OVER_FC> - RFC  2625  IP-over-Fibre  Channel

=item *

C<DLT_AX25> - Amateur Radio AX.25

=item *

C<DLT_LINUX_IRDA> - Linux-IrDA

=item *

C<DLT_LTALK> - Apple  LocalTalk

=item *

C<DLT_APPLE_IP_OVER_IEEE1394> - Apple IP-over-IEEE 1394 (a.k.a. Firewire)

=back


=head1 DIAGNOSTICS

=over

=item C<arg%d not a scalar ref>

=item C<arg%d not a hash ref>

=item C<arg%d not a reference>

B<(F)> These errors occur if you forgot to give a reference to a function 
which expect one or more of its arguments to be references.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Net-Pcap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Net-Pcap>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

Currently known bugs: 

=over

=item *

the C<ps_recv> field is not correctly set; see F<t/07-stats.t>

=item *

C<pcap_file()> seems to always returns C<undef> for live 
connection and causes segmentation fault for dump files; 
see F<t/10-fileno.t>

=item *

C<pcap_fileno()> is documented to return -1 when called 
on save file, but seems to always return an actual file number. 
See F<t/10-fileno.t>


=item *

C<pcap_dump_file()> seems to corrupt something somewhere, 
and makes scripts dump core. See F<t/05-dump.t>

=back


=head1 EXAMPLES

See the F<eg/> and F<t/> directories of the C<Net::Pcap> distribution 
for examples on using this module.


=head1 SEE ALSO

=head2 Perl Modules

the L<NetPacket> or L<Net::Frame> modules to assemble and disassemble packets.

L<Net::Pcap::Reassemble> for reassembly of TCP/IP fragments.

L<POE::Component::Pcap> for using C<Net::Pcap> within POE-based programs.

L<AnyEvent::Pcap> for using C<Net::Pcap> within AnyEvent-based programs.

L<Net::Packet> or L<NetPacket> for decoding and creating network packets.

L<Net::Pcap::Easy> is a module which provides an easier, more Perl-ish
API than C<Net::Pcap> and integrates some facilities from L<Net::Netmask>
and L<NetPacket>.

=head2 Base Libraries

L<pcap(3)>, L<tcpdump(8)>

The source code for the C<pcap(3)> library is available from 
L<http://www.tcpdump.org/>

The source code and binary for the Win32 version of the pcap library, 
WinPcap, is available from L<http://www.winpcap.org/>

=head2 Articles

I<Hacking Linux Exposed: Sniffing with Net::Pcap to stealthily managing iptables 
rules remotely>, L<http://www.hackinglinuxexposed.com/articles/20030730.html>

I<PerlMonks node about Net::Pcap>, L<http://perlmonks.org/?node_id=170648>


=head1 AUTHORS

Current maintainer is Sébastien Aperghis-Tramoni (SAPER) with the help
of Tim Wilde (TWILDE).

Complete list of authors & contributors:

=over

=item * Bo Adler (BOADLER) E<lt>thumper (at) alumni.caltech.eduE<gt>

=item * Craig Davison

=item * David Farrell

=item * David N. Blank-Edelman E<lt>dnb (at) ccs.neu.eduE<gt>

=item * James Rouzier (ROUZIER)

=item * Jean-Louis Morel (JLMOREL) E<lt>jl_morel (at) bribes.orgE<gt>

=item * Marco Carnut (KCARNUT) E<lt>kiko (at) tempest.com.brE<gt>

=item * Patrice Auffret (GOMOR)

=item * Peter Lister (PLISTER) E<lt>p.lister (at) cranfield.ac.ukE<gt>

=item * Rafaël Garcia-Suarez (RGARCIA)

=item * Sébastien Aperghis-Tramoni (SAPER) E<lt>sebastien (at) aperghis.netE<gt>

=item * Tim Potter (TIMPOTTER) E<lt>tpot (at) frungy.orgE<gt>

=item * Tim Wilde (TWILDE)

=back


=head1 HISTORY

The original version of C<Net::Pcap>, version 0.01, was written by
Peter Lister using SWIG.

Version 0.02 was created by Bo Adler with a few bugfixes but not
uploaded to CPAN. It could be found at:
L<http://www.buttsoft.com/~thumper/software/perl/Net-Pcap/>

Versions 0.03 and 0.04 were created by Tim Potter who entirely
rewrote C<Net::Pcap> using XS and wrote the documentation, with
the help of David N. Blank-Edelman for testing and general polishing.

Version 0.05 was released by Marco Carnut with fixes to make it
work with Cygwin and WinPcap.

Version 0.04.02 was independantly created by Jean-Louis Morel
but not uploaded on the CPAN. It can be found here:
L<http://www.bribes.org/perl/wnetpcap.html>

Based on Tim Potter's version 0.04, it included fixes for WinPcap
and added wrappers for several new libpcap functions as well as
WinPcap specific functions.


=head1 ACKNOWLEDGEMENTS

To Paul Johnson for his module L<Devel::Cover> and his patience for
helping me using it with XS code, which revealed very useful for
writing more tests.

To the beta-testers: Jean-Louis Morel, Max Maischen, Philippe Bruhat,
David Morel, Scott Lanning, Rafael Garcia-Suarez, Karl Y. Pradene.


=head1 COPYRIGHT & LICENSE

Copyright (C) 2005-2016 Sébastien Aperghis-Tramoni and contributors.
All rights reserved. 

Copyright (C) 2003 Marco Carnut. All rights reserved. 

Copyright (C) 1999, 2000 Tim Potter. All rights reserved. 

Copyright (C) 1998 Bo Adler. All rights reserved. 

Copyright (C) 1997 Peter Lister. All rights reserved. 

This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
