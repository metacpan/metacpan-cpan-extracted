#!perl
use strict;
use warnings;

# Local customization
#########################################################################

my $community   = "public";         # Default SNMP community
my $defbits     = 32;               # Default OID bits: 32/64
my $output      = "targets.cfg";    # Output target file name
my $router_file = "routers";        # Input list of devices to poll
my $conf_file   = "rtg.conf";       # RTGpoll and RTGplot configurations
my $INFO        = 1;                # Print informational messages
my $DEBUG       = 0;                # Print debug messages
my $DBOFF       = 0;                # Turn database queries off (debug)

# No edits needed beyond this point
#########################################################################

# cpan modules
use DBIx::Simple;
use Net::SNMP;
use Data::Dumper;

my @data_tables = qw/ ifInOctets ifOutOctets ifInUcastPkts ifOutUcastPkts /;
my %bw_mibs = (
   "ifInOctets_32"     => ".1.3.6.1.2.1.2.2.1.10.",
   "ifOutOctets_32"    => ".1.3.6.1.2.1.2.2.1.16.",
   "ifInUcastPkts_32"  => ".1.3.6.1.2.1.2.2.1.11.",
   "ifOutUcastPkts_32" => ".1.3.6.1.2.1.2.2.1.17.",
#  "ifInErrors_32"     => ".1.3.6.1.2.1.2.2.1.14.",

   "ifInOctets_64"     => ".1.3.6.1.2.1.31.1.1.1.6.",
   "ifOutOctets_64"    => ".1.3.6.1.2.1.31.1.1.1.10.",
   "ifInUcastPkts_64"  => ".1.3.6.1.2.1.31.1.1.1.7.",
   "ifOutUcastPkts_64" => ".1.3.6.1.2.1.31.1.1.1.11.",
#  "ifInErrors_64"     => ".1.3.6.1.2.1.2.2.1.14."
);

my @reserved_interfaces = (
# interfaces we don't care to monitor (includes only Cisco/Juniper)
    "tap",  "pimd", "pime", "ipip",
    "lo0",  "gre",  "pd-",  "pe-",  "gr-", "ip-",
    "vt-",  "mt-",  "mtun", "Null", "Loopback", "aal5",
    "-atm", "sc0", 'unrouted VLAN',
);


my ($db_host, $db_user, $db_pass, $db_db, $interval) = get_conf();
print "db host: $db_host\n" if $DEBUG;

my $dsn = "DBI:mysql:database=$db_db;host=$db_host;port=3306";
my $db  = DBIx::Simple->connect( $dsn, $db_user, $db_pass) 
            or die "couldn't connect to database: $!\n";

my $router;

main();
exit;

sub main {

    $interval *= 1.2; # Minor offset w/ 1.2

    my ($routers, $communities, $counterBits) = get_routers();

    if ( $routers->[0] eq "rtr-1.my.net" ) {
        print "\n** Error, $0 is not yet configured\n\n";
        print "Please edit the \"$router_file\" file and add network devices\n";
        exit(-1);
    }           

    # print targets file header
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime( time() );

    open CFG, ">", $output or die "Could not open file: $!";
    printf CFG "# Generated %02d/%02d/%02d %02d:%02d by $0\n", $mon + 1, $mday,
      $year + 1900, $hour, $min;
    print CFG "# Host\tOID\tBits\tCommunity\tTable\tID\tDescription\n";

    # iterate over each router from the routers file
    foreach $router (@$routers) {

        my $bits = $counterBits->{$router};
        $bits = $defbits if ( ( $bits != 32 ) && ( $bits != 64 ) ); # Sanity check

        print "Poking $router ($communities->{$router}) ($bits bit)..." if $INFO;

        my ($session, $error) = Net::SNMP->session(
                        -hostname    => $router,
                        -port        => 161,
                        -version     => 2,
                        -maxmsgsize => 65535,
                        -community   => $communities->{$router},
                    );

        if (!defined($session)) {
            warn sprintf("\tERROR: %s.\n", $error);
            next;
        }

        my $sysDescrOid = '1.3.6.1.2.1.1.1.0';
        my $result = $session->get_request( -varbindlist  => [$sysDescrOid] );
        my $sysDescr = $result->{$sysDescrOid};
        #print "sysDescr: $sysDescr\n" if $DEBUG;

        process_interfaces(
            $session, $router, $communities->{$router}, $bits, $sysDescr);

        $session->close;
    }
    close CFG;
    print "Done.\n";

    # Tells rtgpoll to reread it's config file. 
#    kill -s HUP `cat /tmp/rtgpoll.pid` ;
};

sub process_interfaces {

    my ($session, $router, $community, $bits, $system) = @_;

    # the oids used to collect info from the router
    my $ifIndexOid       = '1.3.6.1.2.1.2.2.1.1';
    my $ifDescrOid       = '1.3.6.1.2.1.2.2.1.2';
    my $ifSpeedOid       = '1.3.6.1.2.1.2.2.1.5';        
    my $ifAliasOid       = '1.3.6.1.2.1.31.1.1.1.18';
    my $ifAdminStatusOid = '1.3.6.1.2.1.2.2.1.7';
    my $ifOperStatusOid  = '1.3.6.1.2.1.2.2.1.8';

    if ( $system =~ /Cisco.*WS-/ ) {   # a Cisco Catalyst
        $ifDescrOid = '1.3.6.1.2.1.31.1.1.1.1';
        $ifAliasOid = '1.3.6.1.4.1.9.5.1.4.1.1.4';
    };

    # get a list of interface index numbers
    my $result = $session->get_table( -baseoid=>$ifIndexOid );
    if (!defined($result)) {
        warn sprintf("ERROR: %s.\n", $session->error);
        return;
    }
    my @indexes = map { $_ } values %$result;
    print " found " . scalar @indexes . " interfaces.\n" if $INFO;
#    print join(' ', @indexes) . "\n" if $DEBUG;

    # get/add the router id from the RTG database
    my $rid = find_router_id($router);
    print "\trouter id: $rid\n" if $DEBUG;

    foreach my $index ( sort {$a <=> $b} @indexes ) {

        my $result = $session->get_request( -varbindlist=>[
                    $ifDescrOid       . '.' . $index,
                    $ifSpeedOid       . '.' . $index,
                    $ifAliasOid       . '.' . $index,
                    $ifAdminStatusOid . '.' . $index,
                    $ifOperStatusOid  . '.' . $index,
                ]
            );

        my $ifdescr       = $result->{$ifDescrOid.'.'.$index};
        my $ifspeed       = $result->{$ifSpeedOid.'.'.$index}; 
        my $ifalias       = $result->{$ifAliasOid.'.'.$index}; 
        my $ifadminstatus = $result->{$ifAdminStatusOid.'.'.$index};
        my $ifoperstatus  = $result->{$ifOperStatusOid.'.'.$index};

        my $reserved = 0;
        foreach my $resv (@reserved_interfaces) {
            $reserved = 1 if ( $ifdescr && $ifdescr =~ /$resv/i );
        }

        my $err = undef;
        if ( !$ifdescr           ) { $err .= " [descr = blank]"  };
        if ( $ifadminstatus != 1 ) { $err .= " [admin = down]"   };
        if ( $ifoperstatus  != 1 ) { $err .= " [oper = down]"    };
        if ( $reserved      != 0 ) { $err .= " [reserved = yes]" };

        if ($err) {
            printf "\tIgnoring %-16s port %3s: %-25s (%-20s) - $err\n", 
                    $router, $index, $ifalias, $ifdescr if $INFO;
            next;
        }

        print_line($router,$community,$bits,$rid,$index,$ifdescr,$ifspeed,$ifalias);
    };
};

sub print_line {

    my ($router,$community,$bits,$rid,$index,$ifdescr,$ifspeed,$ifalias) = @_;

    my $iid = find_interface_id( $rid, $ifdescr, $ifalias, $ifspeed );
    if ( !$iid ) {
        print "\tIID not found, skipping..\n";
        return;
    }

    if ($ifspeed ne "") {
        $ifspeed *= $interval;
        $ifspeed = int($ifspeed);
    }

    foreach my $mib ( sort keys %bw_mibs ) {

        next unless $mib =~ /^(.*)_$bits$/;
        $mib =~ s/_$bits//g;

        print CFG "$router\t";
        print CFG "$bw_mibs{$mib.'_'.$bits}";
        print CFG "$index\t";
        print CFG "$bits\t";
        print CFG "$community\t";
        print CFG "$mib" . "_$rid\t";
        print CFG "$iid\t";
        print CFG "$ifspeed\t";
        print CFG "$ifalias ($ifdescr) \n";
    }
}

sub get_routers {

    my $fullpath_router_file;
    foreach my $file (  $router_file, 
                        "/usr/local/etc/rtg/$router_file", 
                        "/etc/$router_file",
                    ) 
    {
        if ( -f $file ) {
            print "using routers file $file\n" if $DEBUG;
            $fullpath_router_file = $file;
            last;
        };
    }
    die "could not find routers file ($router_file).\n" if !-f $fullpath_router_file;

    open ROUTERS, "<", $fullpath_router_file 
        or die "couldn't read $fullpath_router_file\n";

    my (@routers, %communities, %counterBits);
    while (<ROUTERS>) {
        chomp;
        s/\s+$//g;    #remove space at the end of the line
        next if /^ *\#/;    #ignore comment lines
        next if /^ *$/;     #ignore empty lines
        if ( $_ =~ /(.+):(.+):(.+)/ ) {   # router, $community, $bits
            $communities{$1} = $2;
            $counterBits{$1} = $3; 
            push @routers, $1;
        } 
        elsif ( $_ =~ /(.+):(.+)/ ) {   # router, $community
            $communities{$1} = $2;
            push @routers, $1;
        } 
        else {
            $communities{$_} = $community;
            push @routers, $_;
        }       
    }       
    close ROUTERS;
    return \@routers, \%communities, \%counterBits;
};

sub find_interface_id {

    my ($rid, $name, $desc, $speed) = @_;

    $desc =~ s/\s+$//g;    # remove trailing whitespace

    my $query = "SELECT id, description,speed FROM interface WHERE rid=? AND name=?";
    #print "SQL: $query\n" if $DEBUG;
    my ($if_id,$if_desc,$if_speed) = $db->query($query,$rid,$name)->list;

    if ( $if_id ) {
        if ( $if_desc ne $desc ) {
            print "NOTICE: interface description changed.\n";
            print "Was: \"$if_desc\"\tNow: \"$desc\"\n";
            $query = "UPDATE interface SET description=? WHERE id=$if_id";
            if ( $DBOFF ) { print "DBOFF disabled: $query\n";  } 
            else          { $db->query($query, $desc);  }
        }
        if ( $if_speed != $speed ) {
            print "NOTICE: interface speed changed from $speed to $if_speed.\n";
            $query = "UPDATE interface SET speed=$speed WHERE id=$if_id";
            if ( $DBOFF ) { print "DBOFF disabled: $query\n"; }
            else          { $db->query($query);        };
        };
    }
    else {
        print "No id found for $name on device $rid...adding.\n";
        $desc =~ s/\"/\\\"/g;    # Fix " in desc
        $query = "INSERT INTO interface (name, rid, speed, description) VALUES (?,?,?,?)";
        if ( $DBOFF ) { print "DBOFF enabled: $query\n"; }
        else {
            if ( $db->query($query, $name, $rid, $speed, $desc) ) {
                $if_id = find_interface_id( $rid, $name, $desc, $speed );
            }
            else {
                print "$query, $name, $rid, $speed, $desc\n";
                print "\tinsert failed! " .$db->error ."\n";
            };
        };
    }
    return $if_id;
}

sub find_router_id {

# Find a RTG router id (rid) in the MySQL database.  If it doesn't
# exist, create a new entry and corresponding tables.

    my $l_router = shift;
    my $query = "SELECT DISTINCT rid FROM router WHERE name=?";
    print "SQL: $query\n" if $DEBUG;

    $db->query($query, $l_router)->into(my $rid);

    return $rid if $rid;

    print "No router id found for $l_router...adding.\n" if $INFO;
    $query = "INSERT INTO router (name) VALUES(?)";
    if ( !$DBOFF) {
        $db->query($query, $l_router) or die "failed to add router $l_router\n";
        $rid = find_router_id($l_router);
    };

    foreach my $table ( @data_tables ) {
        my $table_name = $table . '_' . $rid;
        $query = "CREATE TABLE $table_name 
                (id INT NOT NULL, 
                 dtime DATETIME NOT NULL, 
                 counter BIGINT NOT NULL, 
                   KEY ".$table_name."_".$rid."_idx (dtime))";
        if ( !$DBOFF) {
            $db->query($query) or die "couldn't create table $table_name\n";
        };
    }
    return $rid;
}

sub get_conf {
    my ($file,$host,$user,$pass,$db,$interval);

    my @configs = ("rtg.conf", "/usr/local/etc/rtg/rtg.conf", "/etc/rtg.conf");
    foreach my $conf (@configs) {
        $file = $conf if -f $conf;
    }
    die "no rtg.conf file found!\n" unless $file;

    if (open CONF, "<", $file) {
        print "Reading [$file].\n" if $DEBUG;
        while (my $line = <CONF>) {
            my @cVals = split /\s+/, $line;
            if    ($cVals[0] =~ /DB_Host/)     { $host=$cVals[1];  } 
            elsif ($cVals[0] =~ /DB_User/)     { $user=$cVals[1];  } 
            elsif ($cVals[0] =~ /DB_Pass/)     { $pass=$cVals[1];  } 
            elsif ($cVals[0] =~ /DB_Database/) { $db  =$cVals[1];  } 
            elsif ($cVals[0] =~ /Interval/)    { $interval=$cVals[1]; }
        }
    }
    return $host, $user, $pass, $db, $interval;
}


