package Sys::Info::Driver::Windows::Device::CPU::WMI::Conf;
use strict;
use warnings;
use vars            qw( $VERSION @EXPORT %CONF );
use base            qw( Exporter );
use Config::General qw();

$VERSION = '0.78';
@EXPORT  = qw( %CONF );

%CONF = Config::General::ParseConfig( -String => <<'RAW' );
<info>
    <CpuStatus>
        0 = Unknown
        1 = CPU Enabled
        2 = CPU Disabled by User via BIOS Setup
        3 = CPU Disabled By BIOS (POST Error)
        4 = CPU is Idle
        5 = Reserved
        6 = Reserved
        7 = Other
    </CpuStatus>
    <StatusInfo>
        1 = Other
        2 = Unknown
        3 = Enabled
        4 = Disabled
        5 = Not Applicable
    </StatusInfo>
    <Architecture>
        0 = x86
        1 = MIPS
        2 = Alpha
        3 = PowerPC
        6 = Intel Itanium Processor Family (IPF)
        9 = x64
    </Architecture>
    <ProcessorType>
        1 = Other
        2 = Unknown
        3 = Central Processor
        4 = Math Processor
        5 = DSP Processor
        6 = Video Processor
    </ProcessorType>
    <Availability>
        1 = Other
        2 = Unknown
        3 = Running/Full Power
        4 = Warning
        5 = In Test
        6 = Not Applicable
        7 = Power Off
        8 = Off Line
        9 = Off Duty
       10 = Degraded
       11 = Not Installed
       12 = Install Error
       13 = Power Save - Unknown        # The device is known to be in a power save state, but its exact status is unknown.
       14 = Power Save - Low Power Mode # The device is in a power save state, but is still functioning, and may exhibit decreased performance.
       15 = Power Save - Standby        # The device is not functioning, but can be brought to full power quickly.
       16 = Power Cycle
       17 = Power Save - Warning        # The device is in a warning state, though also in a power save state.
    </Availability>
    <UpgradeMethod>
        1 = Other
        2 = Unknown
        3 = Daughter Board
        4 = ZIF Socket
        5 = Replacement/Piggy Back
        6 = None
        7 = LIF Socket
        8 = Slot 1
        9 = Slot 2
       10 = 370 Pin Socket
       11 = Slot A
       12 = Slot M
       13 = Socket 423
       14 = Socket A (Socket 462)
       15 = Socket 478
       16 = Socket 754
       17 = Socket 940
       18 = Socket 939
    </UpgradeMethod>
    <Family>
        1 = Other
        2 = Unknown
        3 = 8086
        4 = 80286
        5 = Intel386(TM) processor
        6 = Intel486(TM) processor
        7 = 8087
        8 = 80287
        9 = 80387
       10 = 80487
       11 = Pentium brand
       12 = Pentium Pro
       13 = Pentium II
       14 = Pentium processor with MMX(TM) technology
       15 = Celeron(TM)
       16 = Pentium II Xeon(TM)
       17 = Pentium III
       18 = M1 Family
       19 = M2 Family
       24 = AMD Duron(TM) Processor Family
       25 = K5 Family
       26 = K6 Family
       27 = K6-2
       28 = K6-3
       29 = AMD Athlon(TM) Processor Family
       30 = AMD2900 Family
       31 = K6-2+
       32 = Power PC Family
       33 = Power PC 601
       34 = Power PC 603
       35 = Power PC 603+
       36 = Power PC 604
       37 = Power PC 620
       38 = Power PC X704
       39 = Power PC 750
       48 = Alpha Family
       49 = Alpha 21064
       50 = Alpha 21066
       51 = Alpha 21164
       52 = Alpha 21164PC
       53 = Alpha 21164a
       54 = Alpha 21264
       55 = Alpha 21364
       64 = MIPS Family
       65 = MIPS R4000
       66 = MIPS R4200
       67 = MIPS R4400
       68 = MIPS R4600
       69 = MIPS R10000
       80 = SPARC Family
       81 = SuperSPARC
       82 = microSPARC II
       83 = microSPARC IIep
       84 = UltraSPARC
       85 = UltraSPARC II
       86 = UltraSPARC IIi
       87 = UltraSPARC III
       88 = UltraSPARC IIIi
       96 = 68040
       97 = 68xxx Family
       98 = 68000
       99 = 68010
      100 = 68020
      101 = 68030
      112 = Hobbit Family
      120 = Crusoe(TM) TM5000 Family
      121 = Crusoe(TM) TM3000 Family
      122 = Efficeon(TM) TM8000 Family
      128 = Weitek
      130 = Itanium(TM) Processor
      131 = AMD Athlon(TM) 64 Processor Famiily
      132 = AMD Opteron(TM) Processor Family
      144 = PA-RISC Family
      145 = PA-RISC 8500
      146 = PA-RISC 8000
      147 = PA-RISC 7300LC
      148 = PA-RISC 7200
      149 = PA-RISC 7100LC
      150 = PA-RISC 7100
      160 = V30 Family
      176 = Pentium III Xeon(TM) processor
      177 = Pentium III Processor with Intel SpeedStep(TM) Technology
      178 = Pentium 4
      179 = Intel Xeon(TM)
      180 = AS400 Family
      181 = Intel Xeon(TM) processor MP
      182 = AMD Athlon(TM) XP Family
      183 = AMD Athlon(TM) MP Family
      184 = Intel Itanium 2
      185 = Intel Pentium M Processor
      190 = K7
      200 = IBM390 Family
      201 = G4
      202 = G5
      203 = G6
      204 = z/Architecture base
      250 = i860
      251 = i960
      260 = SH-3
      261 = SH-4
      280 = ARM
      281 = StrongARM
      300 = 6x86
      301 = MediaGX
      302 = MII
      320 = WinChip
      350 = DSP
      500 = Video Processor
    </Family>
</info>

<rename>
    <cpu>
        DataWidth                  = data_width
        CurrentClockSpeed          = speed
        MaxClockSpeed              = max_speed
        ExtClock                   = bus_speed
        AddressWidth               = address_width
        Name                       = name
        LoadPercentage             = load
        DeviceID                   = device_id
        SocketDesignation          = socket_designation
        Status                     = status_string
        CpuStatus                  = status
        StatusInfo                 = status_info

        Description                = description
        Manufacturer               = manufacturer
        Caption                    = caption
        Version                    = version
        Revision                   = revision
        Stepping                   = stepping
        Level                      = level
        Family                     = family

        Architecture               = architecture
        ProcessorType              = processor_type
        ProcessorId                = processor_id
        CurrentVoltage             = current_voltage
        UpgradeMethod              = upgrade_method
        Availability               = availability

        NumberOfCores              = number_of_cores
        NumberOfLogicalProcessors  = number_of_logical_processors
    </cpu>

    <cache_memory>
        DeviceID                   = device_id
        Associativity              = associativity
        Availability               = availability
        BlockSize                  = block_size
        CacheType                  = cache_type
        Caption                    = caption
        ErrorCorrectType           = error_correct_type
        InstalledSize              = installed_size
        Level                      = level
        MaxCacheSize               = max_cache_size
        Name                       = name
        NumberOfBlocks             = number_of_blocks
        Purpose                    = purpose
        Status                     = status
        StatusInfo                 = status_info
    </cache_memory>

    <lcache>
        L1-Cache                   = L1_cache
        L2-Cache                   = L2_cache
        L3-Cache                   = L3_cache
    </lcache>
</rename>
RAW

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Windows::Device::CPU::WMI::Conf - Distro configuration

=head1 SYNOPSIS

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows::Device::CPU::WMI::Conf>
released on C<17 April 2011>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
