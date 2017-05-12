#!/usr/bin/perl
#
# assumptions
#  1. only SNMPv1 will be supported initially
#  2. only mib-2, host-resources-mib and printer-mib will be supported initially
#  3. SNMPv2 support might be added later
#  4. private mib support will be added after printmib support is complete
#
use strict;

$::VERSION= '1.0';
$::CVSver= '$Id: npadmin.pl,v 1.7 2002/11/15 04:03:09 bozzio Exp $';

use lib qw: . :;
use vars qw/ $s %options /;

use SNMP::NPAdmin;
use Getopt::Long;

##################################### options

GetOptions( \%options, qw/
	usage|help
	version
	printer|host=s
	community=s
	port|connection=i
	timeout=i
	retries|retry=i
	debugsnmp
	debug
	verbose
	all
	name

	vendor
	model
	contact
	netconfig
	printmib
	hostmib

	memory
	storage
	status

	mediapath
	duplex
	enginespeed
	maxpapersize
	minpapersize

	inputtray
	tabloid
	a4
	b4
	executive
	a3
	b5
	letter
	legal

	display
	covers

	languages
	pjl
	hpgl
	psprint
	autolang
	pcl
	postscript

	marker
	pagecount
	colors
	resolution
	minmargin

	protocol
	appletalk
	lpd
	netware
	port9100

	supplies
	cfgsrc
	alerts
	reboot
	/);

##################################### bad options

do {
  my( @why, @E);

  if ( ! ( $options{printer} || @ARGV ) && ! ( $options{version} || $options{usage} )) {
  push @why, "No printer was specified\n";
}
  push @why, "No options were specified\n" if ! %options;

  if ( @why || $options{usage} )
  {
    print STDERR @why, usage(), "\n";
    exit -1;
  }

  $options{printer}= shift @ARGV;
};

##################################### version

if ( $options{version} )
{
  print @{format_report( { version => $::VERSION } )};
  exit;
}

##################################################

SNMP::NPAdmin->verbose()	if $options{verbose};
SNMP::NPAdmin->debug()		if $options{debug};
SNMP::NPAdmin->debugsnmp()	if $options{debugsnmp};

$s= SNMP::NPAdmin->new(
		       printer => $options{printer},
		       boolean => [ qw/ N Y / ],
		       );

die "SNMP::NPAdmin constructor failed" if ! $s;

	#################################

my @x;
push @x, $s->contact()		if $options{contact};
push @x, $s->vendor()		if $options{vendor};
push @x, $s->model()		if $options{model};
push @x, $s->printmib()		if $options{printmib};
push @x, $s->hostmib()		if $options{hostmib};
push @x, $s->status()		if $options{status};
push @x, $s->memory()		if $options{memory};
push @x, $s->netconfig()	if $options{netconfig};
push @x, $s->storage()		if $options{storage};
push @x, $s->display()		if $options{display};
push @x, $s->languages()	if $options{languages};
push @x, $s->pjl()		if $options{pjl};
push @x, $s->hpgl()		if $options{hpgl};
push @x, $s->pcl()		if $options{pcl};
push @x, $s->postscript()	if $options{postscript};
push @x, $s->psprint()		if $options{psprint};
push @x, $s->autolang()		if $options{autolang};
push @x, $s->covers()		if $options{covers};
push @x, $s->mediapath()	if $options{mediapath};
push @x, $s->maxpapersize()	if $options{maxpapersize};
push @x, $s->enginespeed()	if $options{enginespeed};
push @x, $s->duplex()		if $options{duplex};
push @x, $s->minpapersize()	if $options{minpapersize};
push @x, $s->inputtray()	if $options{inputtray};
push @x, $s->tabloid()		if $options{tabloid};
push @x, $s->a4()		if $options{a4};
push @x, $s->b3()		if $options{b3};
push @x, $s->executive()	if $options{executive};
push @x, $s->a3()		if $options{a3};
push @x, $s->b5()		if $options{b5};
push @x, $s->letter()		if $options{letter};
push @x, $s->legal()		if $options{legal};
push @x, $s->marker()		if $options{marker};
push @x, $s->pagecount()	if $options{pagecount};
push @x, $s->colors()		if $options{colors};
push @x, $s->resolution()	if $options{resolution};
push @x, $s->minmargin()	if $options{minmargin};
push @x, $s->protocol()		if $options{protocol};
push @x, $s->lpd()		if $options{lpd};
push @x, $s->appletalk()	if $options{appletalk};
push @x, $s->netware()		if $options{netware};
push @x, $s->port9100()		if $options{port9100};
push @x, $s->supplies()		if $options{supplies};
push @x, $s->alerts()		if $options{alerts};
push @x, $s->cfgsrc()		if $options{cfgsrc};

print format_report( @x);

##################################################

sub format_report
{
  my @x= @_;
  my @report;

  my %str;
  foreach my $x ( @x )
  {
    next if ( ref $x eq 'ARRAY' ) && ( $#$x > 0 );

    $x= $x->[0] if ref $x eq 'ARRAY';
    map { $str{$_}= $x->{$_} } keys %$x;
  }

  if ( %str ) {
    push @report,
      join ';', ( map { sprintf( "%s=\"%s\"", $_, $str{$_}) } keys %str ),
	"\n";
  }

  foreach my $y ( @x )
  {
    next if ref $y ne 'ARRAY';

    foreach my $x ( @$y )
    {
      my $str1;

      $str1= sprintf "%s\n", ( join ';', ( map { sprintf( "%s=\"%s\"", $_, $x->{$_}) } keys %$x ));
      push @report, $str1;# if $str1;
    }
  }

  return @report;
}

##################################################

sub usage
{
  return q/
usage:  npadmin.pl
	[ --usage | --help ]
	[ --version ]
	[ --printer | --host <printer> ]
	[ --community <community> ]
	[ --port | --connection <port> ]
	[ --timeout <integer> ]
	[ --retries | --retry <integer> ]
	[ --debugsnmp ]
	[ --debug ]
	[ --verbose ]
	[ --all ]

	[ --vendor ]
	[ --model ]
	[ --contact ]
	[ --netconfig ]
	[ --printmib ]
	[ --hostmib ]

	[ --memory ]
	[ --storage ]
	[ --status ]

	[ --mediapath ]
	[ --duplex ]
	[ --enginespeed ]
	[ --maxpapersize ]
	[ --minpapersize ]

	[ --inputtray ]
	[ --letter ]
	[ --legal ]
	[ --tabloid ]
	[ --executive ]
	[ --a3 ]
	[ --a4 ]
	[ --b5 ]
	[ --b4 ]

	[ --display ]
	[ --covers ]

	[ --languages ]
	[ --pjl ]
	[ --pcl ]
	[ --hpgl ]
	[ --psprint ]
	[ --postscript ]
	[ --autolang ]

	[ --marker ]
	[ --colors ]
	[ --pagecount ]
	[ --resolution ]
	[ --minmargin ]

	[ --protocol ]
	[ --lpd ]
	[ --netware ]
	[ --appletalk ]
	[ --port9100 ]

	[ --supplies ]
	[ --cfgsrc ]
	[ --alerts ]
	[ --reboot ]
	/;
}

##################################################
#
# $Id: npadmin.pl,v 1.7 2002/11/15 04:03:09 bozzio Exp $
#
