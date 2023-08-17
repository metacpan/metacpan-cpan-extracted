#!/usr/bin/perl -w
######################################################################
### Get (Cisco) Router Power Usage
######################################################################
### Copyright (c) 2022, Simon Leinen.
###
### This program is free software; you can redistribute it under the
### "Artistic License" included in this distribution (file "Artistic").
######################################################################
### Author:       Simon Leinen  <simon.leinen@switch.ch>
### Date Created: 23-Nov-2022
###
### Compute total power draw from sensor readings.
###
### Description:
###
### Call this script with "-h" to learn about command usage.
###
### Basically you call this with a list of routers (hostnames or IP
### addresses), and the script will output the total power draw for
### each router (across all its power supplies), and then the total
### sum of those for gross total power usage.
###
### Method:
###
### Walk the entPhysicalTable augmented with columns from
### entitySensorValueTable.  Find the sensors pertaining to power
### usage, and add up consumption.
###
### Sounds easy, right? Except it isn't.  Cisco routers have many
### sensors that can be read in this way.  Their relationship to
### components ("physical entities") can be found in the
### entPhysicalTable, by means of the "entPhysicalContainedIn" column.
###
### What we typically want are sensors that measure the input power at
### the power supplies.  Power supplies can be found reliably(?) by
### looking for entPhysicalClass values of powerSupply(6).
###
### But then the complications start:
###
### Sensors may not be found *directly* under the power supply.  In
### some routers, the sensors are found inside modules inside the
### power supply.  We fix this by building the "transitive closure" of
### power supplies and their (recursive) submodules, and look at all
### sensors we found in all of those entities.
###
### There may be *more than one* power sensor.  Some routers expose
### both input and output power sensors for each power supply.  We're
### only interested in the input power, so we simply ignore the other
### ones.  The problem is to recognize them.  So far the best I have
### found is to look for the string "output power" in the name.
###
### There may be *no* power sensor, but separate current and voltage
### sensors.  It should be easy enough to multiply them together, but
### this doesn't quite fit with the current structure of the code.
### TODO!
###
### Some router/OS combinations have bugs (surprise!); for example on
### a rather new Cisco 8201 under IOS-XR 7.7.1, I couldn't find the
### power sensors at first, which I found odd.  My error was that I
### was looking for sensors with the "watts" data type.  But on those
### routers, the power supplies' power sensors are exposed with a data
### type of "dBm".  This unit is customary for monitoring optical
### modules such as transceivers.  Theoretically it would be possible,
### but very unconventional, to use dBm for measuring mains power
### usage.  But looking at the actual values, it is clear that those
### values must actually be in Watts, and the MIB implementation just
### wrongly marks them as "dBm".  Yay, another workaround required!
###
### There may be no power sensor and no subsitute sensors accessible
### over the ENTITY-MIB and CISCO-ENTITY-SENSOR-MIB.  So far this
### seems to be the case for (ancient) Cisco Catalyst 6500 routers,
### and small management routers (e.g. Cisco 890 series).  It's
### possible we find usable sensors in some other MIB.  Or not at all,
### which means we'll have a hard time getting at this data via SNMP.
######################################################################
### For patches and suggestions, please create issues on GitHub.

###
use strict;
use warnings;

use BER;
use SNMP_Session "0.96";	# requires map_table_4() and ipv4only

sub usage ($ );
sub get_power_usage ($$);

my $version = '2c';

my $port = 161;

my $max_repetitions = 0;

## Whether to select IPv4-only in open().  Can be set using `-4' option.
my $ipv4_only_p = 0;

my $debug = 0;

my @hosts;

my $community;

my $use_getbulk_p = 1;

# When we only have ampere/volt sensors, and the voltage value is low,
# we assume that these reflect *output* power.  In this case, we
# multiply the power by a factor >1 to reflect the (in)efficiency of
# the power supply.
my $ampere_volt_overhead = 1.15;

my $low_volt_threshold = 100.0;

my $entPhysicalIndex = [1,3,6,1,2,1,47,1,1,1,1,1];
my $entPhysicalDescr = [1,3,6,1,2,1,47,1,1,1,1,2];
my $entPhysicalVendorType = [1,3,6,1,2,1,47,1,1,1,1,3];
my $entPhysicalContainedIn = [1,3,6,1,2,1,47,1,1,1,1,4];
my $entPhysicalClass = [1,3,6,1,2,1,47,1,1,1,1,5];
my $entPhysicalParentRelPos = [1,3,6,1,2,1,47,1,1,1,1,6];
my $entPhysicalName = [1,3,6,1,2,1,47,1,1,1,1,7];
my $entPhysicalHardwareRev = [1,3,6,1,2,1,47,1,1,1,1,8];
my $entPhysicalFirmwareRev = [1,3,6,1,2,1,47,1,1,1,1,9];
my $entPhysicalSoftwareRev = [1,3,6,1,2,1,47,1,1,1,1,10];
my $entPhysicalSerialNum = [1,3,6,1,2,1,47,1,1,1,1,11];
my $entPhysicalMfgName = [1,3,6,1,2,1,47,1,1,1,1,12];
my $entPhysicalModelName = [1,3,6,1,2,1,47,1,1,1,1,13];
my $entPhysicalAlias = [1,3,6,1,2,1,47,1,1,1,1,14];
my $entPhysicalAssetID = [1,3,6,1,2,1,47,1,1,1,1,15];
my $entPhysicalIsFRU = [1,3,6,1,2,1,47,1,1,1,1,16];
my $entPhysicalMfgDate = [1,3,6,1,2,1,47,1,1,1,1,17];
my $entPhysicalUris = [1,3,6,1,2,1,47,1,1,1,1,18];

my $entSensorType = [1,3,6,1,4,1,9,9,91,1,1,1,1,1];
my $entSensorScale = [1,3,6,1,4,1,9,9,91,1,1,1,1,2];
my $entSensorPrecision = [1,3,6,1,4,1,9,9,91,1,1,1,1,3];
my $entSensorValue = [1,3,6,1,4,1,9,9,91,1,1,1,1,4];
my $entSensorStatus = [1,3,6,1,4,1,9,9,91,1,1,1,1,5];
my $entSensorValueTimeStamp = [1,3,6,1,4,1,9,9,91,1,1,1,1,6];
my $entSensorValueUpdateRate = [1,3,6,1,4,1,9,9,91,1,1,1,1,7];
my $entSensorMeasuredEntity = [1,3,6,1,4,1,9,9,91,1,1,1,1,8];

my $SENSOR_DATA_TYPE_other = 1;
my $SENSOR_DATA_TYPE_unknown = 2;
my $SENSOR_DATA_TYPE_volts_AC = 3;
my $SENSOR_DATA_TYPE_volts_DC = 4;
my $SENSOR_DATA_TYPE_amperes = 5;
my $SENSOR_DATA_TYPE_watts = 6;
my $SENSOR_DATA_TYPE_hertz = 7;
my $SENSOR_DATA_TYPE_celsius = 8;
my $SENSOR_DATA_TYPE_percent_RH = 9;
my $SENSOR_DATA_TYPE_rpm = 10;
my $SENSOR_DATA_TYPE_cmm = 11;
my $SENSOR_DATA_TYPE_truthvalue = 12;
my $SENSOR_DATA_TYPE_special_enum = 13;
my $SENSOR_DATA_TYPE_dBm = 14;

# : leinen@asama[leinen]; snmptable -v 2c -c $SECRET -Ci -Cb ls1 entSensorValueTable | grep -E '\b(4367|8463)\b'
#    4367   watts milli         0   196419     ok   0:0:00:00.00      10 seconds                4097
#    8463   watts milli         0   166576     ok   0:0:00:00.00      10 seconds                8193

while (defined $ARGV[0]) {
    if ($ARGV[0] =~ /^-v/) {
	if ($ARGV[0] eq '-v') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] eq '1') {
	    $version = '1';
	} elsif ($ARGV[0] eq '2c' or $ARGV[0] eq '2') {
	    $version = '2c';
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-m/) {
	if ($ARGV[0] eq '-m') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+$/) {
	    $max_repetitions = $ARGV[0];
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] =~ /^-p/) {
	if ($ARGV[0] eq '-p') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
	if ($ARGV[0] =~ /^[0-9]+$/) {
	    $port = $ARGV[0];
	} else {
	    usage (1);
	}
    } elsif ($ARGV[0] eq '-B') {
	$use_getbulk_p = 0;
    } elsif ($ARGV[0] eq '-d') {
	$debug = 1;
    } elsif ($ARGV[0] eq '-4') {
	$ipv4_only_p = 1;
    } elsif ($ARGV[0] =~ /^-c/) {
	if ($ARGV[0] eq '-c') {
	    shift @ARGV;
	    usage (1) unless defined $ARGV[0];
	} else {
	    $ARGV[0] = substr($ARGV[0], 2);
	}
        $community = $ARGV[0];
    } elsif ($ARGV[0] eq '-h') {
	usage (0);
	exit 0;
    } elsif ($ARGV[0] =~ /^-/) {
	usage (1);
    } else {
	push @hosts, $ARGV[0];
    }
    shift @ARGV;
}
# defined @hosts or usage (1);
defined $community or $community = 'public';
usage (1) if $#ARGV >= $[;

my $total_watts = 0;
foreach my $host (@hosts) {
    $total_watts += get_power_usage ($host, $community);
}

my %physical_entity;

sub get_power_usage ($$) {
    my ($host, $community) = @_;

    my $session =
        ($version eq '1' ? SNMPv1_Session->open ($host, $community, $port, undef, undef, undef, undef, $ipv4_only_p)
         : $version eq '2c' ? SNMPv2c_Session->open ($host, $community, $port, undef, undef, undef, undef, $ipv4_only_p)
         : die "Unknown SNMP version $version")
        || die "Opening SNMP_Session";

    $max_repetitions = $session->default_max_repetitions
        unless $max_repetitions;

    my @entity_oids = (
        $entPhysicalDescr,
        $entPhysicalVendorType,
        $entPhysicalContainedIn,
        $entPhysicalClass,
        $entPhysicalParentRelPos,
        $entPhysicalName,
        $entPhysicalHardwareRev,
        $entPhysicalFirmwareRev,
        $entPhysicalSoftwareRev,
        $entPhysicalSerialNum,
        $entPhysicalMfgName,
        $entPhysicalModelName,
        $entPhysicalAlias,
        $entPhysicalAssetID,
        $entPhysicalIsFRU,
        $entPhysicalMfgDate,
        $entPhysicalUris,
        $entSensorType,
        $entSensorScale,
        $entSensorPrecision,
        $entSensorValue,
        $entSensorStatus,
        $entSensorValueTimeStamp,
        $entSensorValueUpdateRate,
        $entSensorMeasuredEntity,
        );


    sub collect_physical_entity(@ ) {
        my ($index, $descr, $vendor_type, $contained_in, $class, $parent_rel_pos,
            $name, $hardware_rev, $firmare_rev, $software_rev, $serial_num,
            $mfg_name, $model_name, $alias, $asset_id, $is_fru, $mfg_date, $uris,
            $sensor_type, $sensor_scale, $sensor_precision,
            $sensor_value, $sensor_status,
            $sensor_value_time_stamp, $sensor_value_update_rate,
            $sensor_measured_entity) = @_;

        grep (defined $_ && ($_=pretty_print $_),
              ($descr, $contained_in, $class, $parent_rel_pos, $name, $alias,
               $sensor_type, $sensor_scale, $sensor_precision,
               $sensor_value, $sensor_status));

        my (%ent);
        %ent = (
            'index' => $index,
            'descr' => $descr,
            'class' => $class,
            'name' => $name,
            'alias' => $alias,
            'children' => {},
            'contained_in' => $contained_in,
            'parent_rel_pos' => $parent_rel_pos,
            );
        if ($class == 8) {
            $ent{'sensor_type'} = $sensor_type;
            $ent{'sensor_scale'} = $sensor_scale;
            $ent{'sensor_precision'} = $sensor_precision;
            $ent{'sensor_value'} = $sensor_value;
            $ent{'sensor_status'} = $sensor_status;
        };

        $physical_entity{$index} = \%ent;

        # warn("index: $index descr $descr alias $alias class $class\n")
        #     if $debug;
    }

    %physical_entity = ();
    my $calls = $session->map_table_4 (\@entity_oids, \&collect_physical_entity, $max_repetitions);
    $session->close();

    foreach my $index (keys %physical_entity) {
        my $ent = $physical_entity{$index};
        my $parent_index = $ent->{contained_in};
        if (exists $physical_entity{$parent_index}) {
            my $parent = $physical_entity{$parent_index};
            my $parent_rel_pos = $ent->{'parent_rel_pos'};
            $parent->{'children'}->{$parent_rel_pos} = $index;
        }
    }

    my %power_supplies = ();
    foreach my $index (sort keys %physical_entity) {
        my $ent = $physical_entity{$index};
        my $class = $ent->{class};
        next unless $class == 6;
        $power_supplies{$index} = 1;
        my $descr = $ent->{descr};
        my $alias = $ent->{alias};
        my $name = $ent->{name};
        warn "Found power supply: $index (descr \"$descr\" name \"$name\" alias \"$alias\" class $class)\n"
            if $debug;
    }

    my %power_supplies_modules_closure = %power_supplies;

    my $found_one = 0;
    do {
        foreach my $index (sort keys %physical_entity) {
            my $ent = $physical_entity{$index};
            my $contained_in = $ent->{contained_in};
            next unless exists $power_supplies_modules_closure{$contained_in};
            my $class = $ent->{class};
            next unless $class == 9; # We're only interested in modules(9)
            my $descr = $ent->{descr};
            my $alias = $ent->{alias};
            my $name = $ent->{name};
            warn "Found module child: $index (descr \"$descr\" name \"$name\" alias \"$alias\" class $class parent $contained_in)\n"
                if $debug;
            $power_supplies_modules_closure{$index} = 1;
        }
    } while ($found_one);

    my $total_watts = 0.0;

    foreach my $index (sort keys %power_supplies_modules_closure) {
        my $ps_ent = $physical_entity{$index};

        my ($amperes, $volts, $watts);

        foreach my $sub_pos (keys %{$ps_ent->{'children'}}) {
            my $sub_index = $ps_ent->{'children'}->{$sub_pos};
            my $ent = $physical_entity{$sub_index};
            my $class = $ent->{class};
            next unless $class == 8; # We're only interested in sensors(8)
            my $descr = $ent->{descr};
            my $name = $ent->{name};
            my $alias = $ent->{alias};
            my $sensor_type = $ent->{sensor_type};
            my $sensor_scale = $ent->{sensor_scale};
            my $sensor_precision = $ent->{sensor_precision};
            my $sensor_value = $ent->{sensor_value};
            my $sensor_status = $ent->{sensor_status};
            if ($sensor_type == $SENSOR_DATA_TYPE_watts
                and (! ($ent->{name} =~ /output power/i))
                and (! ($ent->{name} =~ /capacity/i))) {
                $watts = $sensor_value * 10.0**(($sensor_scale-9) * 3);
            } elsif ($sensor_type == $SENSOR_DATA_TYPE_dBm
                     and ($ent->{name} =~ //) # BUG BUG BUG: On Cisco 8201 under IOS-XR 7.7.1 report "dBm" (units) for the power supply power sensors.  But the values look like they are in Watts.
                and (! ($ent->{name} =~ /output power/i))
                and (! ($ent->{name} =~ /capacity/i))) {
                $watts = $sensor_value * 10.0**(($sensor_scale-9) * 3);
            } elsif (($sensor_type == $SENSOR_DATA_TYPE_volts_AC
                     or $sensor_type == $SENSOR_DATA_TYPE_volts_DC)
                     and !($name =~ /-Output_/)) {
                warn "already have volts!\n" if defined $volts and $debug;
                $volts = $sensor_value * 10.0**(($sensor_scale-9) * 3);
            } elsif ($sensor_type == $SENSOR_DATA_TYPE_amperes) {
                if ($name =~ /-Output_/) {
                    warn "IGNORING sensor child: $sub_index (descr \"$descr\" name \"$name\" alias \"$alias\" class $class parent $index sensor_type sensor: [type $sensor_type value $sensor_value scale $sensor_scale precision $sensor_precision value $sensor_value status $sensor_status)\n" if $debug;
                } else {
                    warn "already have amperes!\n" if defined $amperes and $debug;
                    $amperes = $sensor_value * 10.0**(($sensor_scale-9) * 3);
                }
            }
            warn "Found sensor child: $sub_index (descr \"$descr\" name \"$name\" alias \"$alias\" class $class parent $index sensor_type sensor: [type $sensor_type value $sensor_value scale $sensor_scale precision $sensor_precision value $sensor_value status $sensor_status)\n"
                if $debug;
        }
        if (defined $watts) {
            $total_watts += $watts;
        } elsif (defined $amperes and defined $volts) {
            warn "  computing watts from amperes ($amperes) and volts ($volts)\n"
                if $debug;
            my $watts += $amperes * $volts;
            $watts *= $ampere_volt_overhead
                if $volts < $low_volt_threshold;
            $total_watts += $watts;
        }
    }
    printf STDOUT ("router %s %6.1f\n", $host, $total_watts);
    return $total_watts;
}
printf STDOUT ("Total input power: %6.1fW\n", $total_watts);
1;


sub usage ($) {
    warn <<EOM;
Usage: $0 [-d] [-v (1|2c)] [-c] [-l] [-m max] [-4] [-p port] [-c community] host...
       $0 -h

  -c community SNMP community string to use.  Defaults to "public".

  -d           enable debugging output.

  -h           print this usage message and exit.

  -v version   can be used to select the SNMP version.  The default
   	       is SNMPv1, which is what most devices support.  If your box
   	       supports SNMPv2c, you should enable this by passing "-v 2c"
   	       to the script.  SNMPv2c is much more efficient for walking
   	       tables, which is what this tool does.

  -B           do not use get-bulk

  -m max       specifies the maxRepetitions value to use in getBulk requests
               (only relevant for SNMPv2c).

  -4           use only IPv4 addresses, even if host also has an IPv6
               address.  Use this for devices that are IPv6-capable
               but whose SNMP agent does not listen to IPv6 requests.

  -p port      can be used to specify a non-standard UDP port of the SNMP
               agent (the default is UDP port 161).

  host         hostname or IP address of a router
EOM
    exit (1) if $_[0];
}
