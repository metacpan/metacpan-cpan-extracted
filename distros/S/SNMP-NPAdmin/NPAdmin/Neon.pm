package SNMP::NPAdmin::Neon;

#
# assumptions
#  1. only SNMPv1 will be supported initially
#  2. only mib-2 and printmib will be supported initially
#  3. SNMPv2 support will be added later
#  4. private mib support will be added after printmib support is complete
#
#  a. found an HP JETDIRECT MIB; will incorporate that later.
#

use strict;
use vars qw/ $VERSION $CVSver $VERBOSE $DEBUG /;

$VERSION = '1.0';
$CVSver= '$Id: Neon.pm,v 1.6 2002/11/15 04:06:08 bozzio Exp $';

use SNMP;
$ENV{MIBS}='+Printer-MIB:JETDIRECT3-MIB';
$ENV{MIBDIRS}= sprintf '+%s/MIBs', ( $INC{'SNMP/NPAdmin/Neon.pm'} =~ m:(.+)/Neon.pm$: )[0];

use vars qw/
	 %defaults
	$list_code
	%list_map
	$table_code
	%table_map
	$mib2_str
	$hostmib_template
	$printmib_template
	/;

##################################### defaults

%defaults= (
	    timeout	=> 1000000,
	    port	=> 161,
	    retries	=> 5,
	    community	=> 'public'
	   );

##################################### MIB OID strings

use constant MIB_2		=> 0x1;
use constant HOST_MIB		=> 0x2;
use constant PRINTER_MIB	=> 0x4;

$mib2_str=		'.iso.org.dod.internet.mgmt.mib-2';
$hostmib_template=	"$mib2_str.host.%s.%sTable";
$printmib_template=	"$mib2_str.printmib.%s.%sTable";

##################################### table_code

%table_map= (
#	sub name			MIBs			template		resource			table
#	--------			--------		--------		--------			-----
	hrStorage		=> [	HOST_MIB,		\$hostmib_template,	'hrStorage',					],
	hrDevice		=> [	HOST_MIB,		\$hostmib_template,	'hrStorage',					],
	hrPrinter		=> [	HOST_MIB,		\$hostmib_template,	'hrDevice',			'hrPrinter'	],
	prtConsoleDisplayBuffer	=> [	PRINTER_MIB,		\$printmib_template,	'prtConsoleDisplayBuffer',			],
	prtInterpreter		=> [	PRINTER_MIB,		\$printmib_template,	'prtInterpreter',				],
	prtCover		=> [	PRINTER_MIB,		\$printmib_template,	'prtCover',					],
	prtMediaPath		=> [	PRINTER_MIB,		\$printmib_template,	'prtMediaPath',					],
	prtInput		=> [	PRINTER_MIB,		\$printmib_template,	'prtInput',					],
	prtMarker		=> [	PRINTER_MIB,		\$printmib_template,	'prtMarker',					],
	prtChannel		=> [	PRINTER_MIB,		\$printmib_template,	'prtChannel',					],
	prtMarkerSupplies	=> [	PRINTER_MIB,		\$printmib_template,	'prtMarkerSupplies',				],
	prtAlert		=> [	PRINTER_MIB,		\$printmib_template,	'prtAlert',					],
	);

$table_code= q[
	sub ##SUBNAME##
	{
#warn "##SUBNAME##";
	  my $self= shift;
	  my $name= '##RESOURCE##';
	  my $name2= '##TABLE##';
	  my $table= sprintf( "##TEMPLATE##", $name, $name2);

	  if ( ! $self->{$name} )
	  {
	    my $val= $self->_readTable( $table) if ! $self->{$name};
	    return undef if ! $val;

	    $self->{$name}= $self->_convertTable( $val);
	  }

	  $self->{MIBs} |= ##MIBS##;

	  return $self->{$name};
	}
	];

##################################### list_code

%list_map= (
	    #	sub name			oid list
	    #	--------			--------------------------------------------------------------------------------------------------------
	    mib2_system		=>	[ 0x0,
					  [ q{
					   [ '.iso.org.dod.internet.mgmt.mib-2.system.sysDescr', 0],
					   [ '.iso.org.dod.internet.mgmt.mib-2.system.sysUpTime', 0],
					   [ '.iso.org.dod.internet.mgmt.mib-2.system.sysContact', 0],
					   [ '.iso.org.dod.internet.mgmt.mib-2.system.sysLocation', 0]
					  } ],
					],
	    hrMemorySize	=>	[ HOST_MIB,
					  [ q{
					   [ '.iso.org.dod.internet.mgmt.mib-2.host.hrStorage.hrMemorySize', 0]
					  } ],
					],
	    hrPrinterStatus	=>	[ HOST_MIB,
					  [ q{
					   [ '.iso.org.dod.internet.mgmt.mib-2.host.hrDevice.hrPrinterTable.hrPrinterEntry.hrPrinterStatus', 1]
					  } ],
					],
	    hp_npCfgSource	=>	[ 0x0,
					  [ q{
					   [ '.iso.org.dod.internet.private.enterprises.hp.nm.interface.npCard.npCfg.npCfgSource', 0],
					  } ],
					],
	    hp_gdStatusId	=>	[ 0x0,
					  [ q{
					   [ '.iso.org.dod.internet.private.enterprises.hp.nm.system.net-peripheral.net-printer.generalDeviceStatus.gdStatusId', 0]
					  } ],
					],
	   );

$list_code= q{
	sub ##SUBNAME##
	{
#warn "##SUBNAME##";
	  my $self= shift;
	  my( $S, $vars);

	  $S= $self->{snmp};

	  $vars= SNMP::VarList->new( ##OIDLIST##);

	  if ( ! $self->{##SUBNAME##} )
	  {
	    my @vals= $S->get( $vars) if ! $self->{##SUBNAME##};
	    return undef if $S->{ErrorNum};

	    $self->{##SUBNAME##}= $self->_convertTable( $vars);
	  }

	  $self->{MIBs} |= ##MIBS##;

	  return $self->{##SUBNAME##};
	}
	};

##################################### AUTOLOAD

use vars '$AUTOLOAD';
sub AUTOLOAD
{
#warn "AUTOLOAD";
  my $autoload= ( $AUTOLOAD =~ /.*::(\w+)/ )[0];

  my( $sub, %tags);
  if ( defined $table_map{$autoload} )
  {
    my @map= @{$table_map{$autoload}};
    $sub= $table_code;
    %tags= (
	'##SUBNAME##'	=> $autoload,
	'##MIBS##'	=> $map[0],
	'##TEMPLATE##'	=> ${$map[1]},
	'##RESOURCE##'	=> $map[2],
	'##TABLE##'	=> $map[3] || $map[2],
	);
  }
  elsif ( defined $list_map{$autoload} )
  {
    my @map= @{$list_map{$autoload}};
    $sub= $list_code;
    %tags= (
	'##SUBNAME##'	=> $autoload,
	'##MIBS##'	=> $map[0],
	'##OIDLIST##'	=> @{$map[1]},
	);
  }

  if ( $sub )
  {
      map { $sub=~ s/\Q$_/$tags{$_}/g } keys %tags;
      eval $sub;
      die $@ if $@;
      goto &$autoload;
  }

  printf STDERR "Unimplemented method:\t'%s'\n", $AUTOLOAD;
  return undef;
}

##################################### _readTable

sub _readTable
{
#warn "_readTable";
  my( $self, $table)= @_;
  ( my $name = $table ) =~ s/^.*\.(\w+?)Table\..*$/$1/;
  my $vb= SNMP::Varbind->new( [ $table, 0 ] );
  my( $S, $vals);

  $S= $self->{snmp};

  for ( my $val= $S->getnext( $vb);
        ( $vb->[0] =~ /^${table}/ );
# removed regex 'o' option; want optimization but need to handle different tables
        $val= $S->getnext( $vb)
      )
  {
    return undef
      if $S->{ErrorNum};

    my( $oid, $iid)= (@$vb)[0,1];
    next if ! $iid;
    $oid =~ s/^${table}\.${name}Entry\.${name}(\w+)$/$1/o;
    push @{$vals->{$iid}}, SNMP::Varbind->new( [ @$vb ]);
  }

  return $vals;
}

##################################### _printTable

sub _printTable
{
#warn "_printTable";
  my( $self, $name, $vals)= @_;
  $vals= $self->{$name};

  foreach my $instance ( values %$vals )
  {
    my @x;
    foreach my $k ( keys %$instance )
    {
      my $n;
      ( $n= $k ) =~ s/^.*\.${name}(\w+)$/$1/;
      push @x, sprintf( "%s=\"%s\"", $n, $instance->{$k}->[2])
    };
    printf( "%s\n", join( ';', @x));
  }
}

##################################### DESTROY

sub DESTROY {};

##################################### version

sub version
{
#warn "version";
  return $VERSION;
}

##################################### verbose

sub verbose
{
#warn "verbose";
  $SNMP::debugging= 1;
}

##################################### debugsnmp

sub debugsnmp
{
#warn "debugsnmp";
  $SNMP::debugging= 2;
}

##################################### debug

sub debug
{
#warn "debug";
  my $class= shift;
  my $value= shift;

  if ( defined $value )
  {
    $DEBUG= $value;
  }
  else
  {
    $DEBUG |= 1;
  }
}

##################################### new

sub new
{
#warn "new";
  my $class= shift;
  my %options= @_;
  my $self;

  map { print "debug:\t$_ = $options{$_}\n" } keys %options if $DEBUG;

  $self->{snmp}= SNMP::Session->new(
    DestHost		=> $options{printer},
    RemotePort		=> $options{port}	|| $defaults{port},
    Community		=> $options{community}	|| $defaults{community},
    Timeout		=> $options{timeout}	|| $defaults{timeout},
    Retries		=> $options{retries}	|| $defaults{retries},
    UseLongNames	=> 1,
    UseEnums		=> 1,
#   UseNumeric		=> 1,
    );

  return undef if ! $self->{snmp};

  bless $self, $class;
  return $self;
}

##################################### reboot
#
# .iso.org.dod.internet.private.enterprises.hp.nm.interface.npCard.npCtl.npCtlReconfig
# .1.3.6.1.4.1.11.2.4.3.7.8
#

##################################### printmib

sub printmib
{
#warn "printmib";
  my $self= shift;
  my( $S, $vars);

  $S= $self->{snmp};

  do {
    my $vb= [ '.iso.org.dod.internet.mgmt.mib-2.printmib.prtMIBConformance', 0];
    $S->getnext( $vb);
    return undef if $S->{ErrorNum};
    $self->{MIBs} |= PRINTER_MIB if $vb->[0] =~ /^\.iso\.org\.dod\.internet\.mgmt\.mib-2\.printmib\..*$/;
  };

  return { printmib => ( $self->{MIBs} & PRINTER_MIB ) };
}

##################################### hostmib

sub hostmib
{
#warn "hostmib";
  my $self= shift;
  my( $S, $vars);

  $S= $self->{snmp};

  do {
    my $vb= [ '.iso.org.dod.internet.mgmt.mib-2.host.hrSystem.hrSystemUptime', 0];
    $S->getnext( $vb);
    return undef if $S->{ErrorNum};
    $self->{MIBs} |= HOST_MIB if $vb->[0] =~ /^\.iso\.org\.dod\.internet\.mgmt\.mib-2\.host\..*$/;
  };

  return { hostmib => ( $self->{MIBs} & HOST_MIB ) };
}

##################################### netconfig		(all mib-2)
#
# .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifType
# .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifPhysAddress
# .iso.org.dod.internet.mgmt.mib-2.ip.ipAddrTable.ipAddrEntry.ipAdEntAddr
# .iso.org.dod.internet.mgmt.mib-2.ip.ipAddrTable.ipAddrEntry.ipAdEntNetMask
# .iso.org.dod.internet.mgmt.mib-2.ip.ipRouteTable.ipRouteEntry.ipRouteNextHop
#

sub netconfig
{
#warn "netconfig";
  my $self= shift;
  my( $S, $vars);

  $S= $self->{snmp};
  $vars= SNMP::VarList->new(
    [ '.iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifType', 1],
    [ '.iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifPhysAddress', 1],
    );

  $S->get( $vars) || return undef;

  my $hex= '[0-9A-Ha-h]';
  $vars->[1]->[2]= unpack( "H12", $vars->[1]->[2]);
  $vars->[1]->[2] =~
    s/^(${hex}{2})(${hex}{2})(${hex}{2})(${hex}{2})(${hex}{2})(${hex}{2})$/$1:$2:$3:$4:$5:$6/o;

  do {
    my $vb= [ '.iso.org.dod.internet.mgmt.mib-2.ip.ipAddrTable.ipAddrEntry.ipAdEntAddr', 0];
    $S->getnext( $vb);
    return undef if $S->{ErrorNum};
    push @$vars, $vb;
  };

  do {
    my $vb= [ '.iso.org.dod.internet.mgmt.mib-2.ip.ipAddrTable.ipAddrEntry.ipAdEntNetMask', $vars->[$#$vars]->[2]];
    $S->get( $vb);
    return undef if $S->{ErrorNum};
    push @$vars, $vb;
  };

  do {
    my $vb= [ '.iso.org.dod.internet.mgmt.mib-2.ip.ipRouteTable.ipRouteEntry.ipRouteNextHop', '0.0.0.0'];
    $S->get( $vb);
    return undef if $S->{ErrorNum};
    push @$vars, $vb;
  };

  return $self->_convertTable( $vars);
}

##################################### _convertTable

sub _convertTable
{
#warn "_convertTable";
  my( $self, $data)= @_;
  my @xdata;

  my $x;
  if ( ref $data eq 'SNMP::VarList' )
  {
    my %x;
    foreach my $var ( @$data )
    {
      my $name;
      $name= ( $var->[0] =~ m/\.(\w+?)$/ )[0];
      $x{$name}= $var->[2];
    }
    $x= \%x;
  }
  else
  {
    foreach my $k ( sort keys %$data )
    {
      my %x;
      my $v= $data->{$k};

      foreach my $var ( @$v )
      {
        my $name;
        $name= ( $var->[0] =~ m/\.(\w+?)$/ )[0];
        $x{$name}= $var->[2];
      }

      push @$x, \%x;
    }
  }
## else
## {
##   die "uh, oh!  something went wrong:  unexpected data format!";
## }

  return $x;
}

##################################### the end
#
# $Id: Neon.pm,v 1.6 2002/11/15 04:06:08 bozzio Exp $
#

1;
