#
# OSDial.pm
#
## Copyright (C) 2010-2011  Lott Caskey  <lottcaskey@gmail.com>    LICENSE: AGPLv3
##
##     This file is part of OSDial.
##
##     OSDial is free software: you can redistribute it and/or modify
##     it under the terms of the GNU Affero General Public License as
##     published by the Free Software Foundation, either version 3 of
##     the License, or (at your option) any later version.
##
##     OSDial is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU Affero General Public License for more details.
##
##     You should have received a copy of the GNU Affero General Public
##     License along with OSDial.  If not, see <http://www.gnu.org/licenses/>.
##
#
package OSDial;

use 5.008000;
use strict;
use warnings;

use DBI;
use Asterisk::AGI;
use Digest::MD5 qw(md5_hex); 
use Email::Stuffer;
use Email::Sender::Transport::SMTP;
use Proc::Exists ('pexists');
use Data::Dumper;

our $VERSION = '3.0.2.124';

my %vars;

=head1 NAME

OSDial - Perl extension for interfacing with OSDial 

=head1 SYNOPSIS

  use strict;
  use OSDial;

  my $osdial = OSDial->new('DB'=>1);

  # Database example
  while ( my $rec = $osdial->sql_query("SELECT * FROM servers;") ) {
    print $rec->{server_ip} . ": " . $rec->{server_name} . "\n";

    # Secondary connection and query
    while ( my $rec2 = $osdial->sql_query( sprintf('SELECT * FROM osdial_log WHERE server_ip=%s;', $rec->quote($rec->{server_ip}) ) ) {
      print "    " . $rec2->{lead_id} . ": " . $rec2->{call_date} . ": " . $rec2->{status} . "\n";
    }
    
  }

  # Asterisk::AGI example
  $osdial->AGI('myscript.pl');
  $osdial->AGI->verbose("OSDial Rocks",1);
  $osdial->AGI->hangup();
  

=head1 DESCRIPTION

This module is inteded to provided quick and easy access to common functions
in OSDial.  The module will read existing configuration files, connect to
the OSDial database, and interface with Asterisk as needed.


=head1 CONSTRUCTOR

=over 4

=item B<new()> - create a new OSDial object.

Creates a new C<OSDial> object.  C<new> optionally takes arguments in the form
of key value pairs.

Examples:

   $osdial = OSDial->new( DB => 1);

   $osdial = new OSDial( DB => 1);

   $osdial = OSDial->new( VARDB_server   => '127.0.0.1',
                          VARDB_database => 'osdial',
                          VARDB_user     => 'osdial',
                          VARDB_pass     => 'osdial1234' );

=cut

sub new {
        my ($proto,%options) = @_;
        my $class = ref($proto) || $proto;

	&_set_defaults();

        my $self = {%vars};
        foreach my $key (keys %options) {
                $self->{$key} = $options{$key};
        }
	$self->{DB} = 0 unless ($self->{DB});
        bless $self, $class;

	$self->debug(1,'new',"Initializing OSDial module, debug-level is %s.",$self->{DB});
	
	# Load osdial.conf and database settings.
        $self->load_config();

        return $self;
}

sub clone {
	my $self = shift;
	my $copy = bless { %$self }, ref $self;
	return $copy;
}

=head2 B<Contructor Arguments and Defaults>

   DB                               => '0'
   
   PATHconf                         => '/etc/osdial.conf'
   PATHdocs                         => '/usr/share/doc/osdial-3.0.2.124'
   PATHhome                         => '/opt/osdial/bin'
   PATHlogs                         => '/var/log/osdial'
   PATHagi                          => '/var/lib/asterisk/agi-bin'
   PATHweb                          => '/opt/osdial/html'
   PATHsounds                       => '/var/lib/asterisk/sounds'
   PATHmonitor                      => '/var/spool/asterisk/VDmonitor'
   PATHDONEmonitor                  => '/var/spool/asterisk/VDmonitor'
   PATHarchive_home                 => '/opt/osdial/recordings'
   PATHarchive_unmixed              => 'processing/unmixed'
   PATHarchive_mixed                => 'processing/mixed'
   PATHarchive_sorted               => 'completed'
   PATHarchive_backup               => '/opt/osdial/backups/recordings'
   
   VARserver_ip                     => '127.0.0.1'
   VARactive_keepalives             => 'X'
   
   VARDB_server                     => '127.0.0.1'
   VARDB_database                   => 'osdial'
   VARDB_user                       => 'osdial'
   VARDB_pass                       => 'osdial1234'
   VARDB_port                       => '3306'
   
   VARfastagi_log_min_servers       => '3'
   VARfastagi_log_max_servers       => '16'
   VARfastagi_log_min_spare_servers => '2'
   VARfastagi_log_max_spare_servers => '8'
   VARfastagi_log_max_requests      => '1000'
   VARfastagi_log_checkfordead      => '30'
   VARfastagi_log_checkforwait      => '60'
   
   VARFTP_host                      => '127.0.0.1'
   VARFTP_user                      => 'osdial'
   VARFTP_pass                      => 'osdialftp1234'
   VARFTP_port                      => '21'
   VARFTP_dir                       => 'recordings/processing/unmixed'
   VARHTTP_path                     => '/'
   
   VARREPORT_host                   => '127.0.0.1'
   VARREPORT_user                   => 'osdial'
   VARREPORT_pass                   => 'osdialftp1234'
   VARREPORT_port                   => '21'
   VARREPORT_dir                    => 'reports'
   
   VARcps                           => '9'
   VARadapt_min_level               => '1.5'
   VARadapt_overlimit_mod           => '20'
   VARflush_hopper_each_run         => '0'
   VARflush_hopper_manual           => '1'


=back

=cut

sub _set_defaults {
	%vars = (
        	'DB'                   => 0,

        	'PATHconf'             => '/etc/osdial.conf',
		'PATHdocs'             => '/usr/share/doc/osdial-3.0.2.124',
		'PATHhome'             => '/opt/osdial/bin',
		'PATHlogs'             => '/var/log/osdial',
		'PATHagi'              => '/var/lib/asterisk/agi-bin',
		'PATHweb'              => '/opt/osdial/html',
		'PATHsounds'           => '/var/lib/asterisk/sounds',
		'PATHmonitor'          => '/var/spool/asterisk/VDmonitor',
		'PATHDONEmonitor'      => '/var/spool/asterisk/VDmonitor',
		'PATHarchive_home'     => '/opt/osdial/recordings',
		'PATHarchive_unmixed'  => 'processing/unmixed',
		'PATHarchive_mixed'    => 'processing/mixed',
		'PATHarchive_sorted'   => 'completed',
		'PATHarchive_backup'    => '/opt/osdial/backups/recordings',

        	'VARserver_ip'         => '127.0.0.1',
        	'VARactive_keepalives' => 'X',

        	'VARDB_server'         => '127.0.0.1',
        	'VARDB_database'       => 'osdial',
        	'VARDB_user'           => 'osdial',
        	'VARDB_pass'           => 'osdial1234',
        	'VARDB_port'           => '3306',
        	'VARDB_onfail'         => 'die',

		'VARfastagi_log_min_servers'       => '3',
		'VARfastagi_log_max_servers'       => '16',
		'VARfastagi_log_min_spare_servers' => '2',
		'VARfastagi_log_max_spare_servers' => '8',
		'VARfastagi_log_max_requests'      => '1000',
		'VARfastagi_log_checkfordead'      => '30',
		'VARfastagi_log_checkforwait'      => '60',

		'VARFTP_host'    => '127.0.0.1',
		'VARFTP_user'    => 'osdial',
		'VARFTP_pass'    => 'osdialftp1234',
		'VARFTP_port'    => '21',
		'VARFTP_dir'     => 'recordings/processing/unmixed',
		'VARHTTP_path'   => '/',

		'VARREPORT_host' => '127.0.0.1',
		'VARREPORT_user' => 'osdial',
		'VARREPORT_pass' => 'osdialftp1234',
		'VARREPORT_port' => '21',
		'VARREPORT_dir'  => 'reports',

		'VARcps'                   => '9',
		'VARadapt_min_level'       => '1.5',
		'VARadapt_overlimit_mod'   => '20',
		'VARflush_hopper_each_run' => '0',
		'VARflush_hopper_manual'   => '1',

		'_sql'  => { },

		'_mimemap' => {
        		'g722'    => 'audio/G722',
        		'g729'    => 'audio/G729',
        		'gsm'     => 'audio/GSM',
        		'ogg'     => 'audio/ogg',
        		'ulaw'    => 'audio/PCMU',
        		'alaw'    => 'audio/PCMA',
        		'siren7'  => 'audio/siren7',
        		'siren14' => 'audio/siren14',
        		'sln'     => 'audio/sln',
        		'sln16'   => 'audio/sln-16',
        		'mp3'     => 'audio/mpeg',
        		'wav'     => 'audio/x-wav'
		},
	);
}

=item B<load_config()> - load configuration.

Loads in the configuration from /etc/osdial.conf, global and server specific
database settings.

   # Read /etc/osdial.conf setting.
   $osdial->{VARserver_ip}

   # Read setting from system_settings table.
   $osdial->{settings}{company_name}

   # Read setting for this specific server.
   $osdial->{server}{server_id}

   # Read a setting in from the configuration table.
   $osdial->{configuration}{ArchiveHost}

=cut

sub load_config {
	my $self = shift;
        if (-e $self->{PATHconf}) {
		$self->debug(4,'load_config',"Loading configuration file (%s).",$self->{PATHconf});
        	open(CONF, $self->{PATHconf}) or die 'OSDial: Error opening ' . $self->{PATHconf} . "\n";
        	while (my $line = <CONF>) {
        	        $line =~ s/ |>|"|'|\n|\r|\t|\#.*|;.*//gi;
        	        if ($line =~ /=|:/) {
        	                my($key,$val) = split /=|:/, $line, 2;
        	                $self->{$key} = $val;
				$self->debug(4,'load_config',"    %-40s => %-40s.",$key,$val);
        	        }
        	}

		$self->sql_max_packet();

		# Load system settings.
        	$self->{settings} = $self->sql_query("SELECT * FROM system_settings LIMIT 1;");
		foreach my $st (keys %{$self->{settings}}) {
			$self->debug(4,'new','    %-30s => %-30s.',$st,$self->{settings}{$st});	
		}

		# Load this servers settings.
        	$self->{server} = $self->sql_query(sprintf("SELECT * FROM servers WHERE server_ip='%s' LIMIT 1;", $self->{VARserver_ip}));
		foreach my $st (keys %{$self->{server}}) {
			$self->debug(4,'new','    %-30s => %-30s.',$st,$self->{server}{$st});	
		}

		# Parse in settings from configuration table.
        	while (my $sret = $self->sql_query(sprintf("SELECT name,data FROM configuration WHERE fk_id='';"))) {
			$self->{configuration}{$sret->{name}} = $sret->{data};
			$self->debug(4,'new','    %-30s => %-30s.',$sret->{name},$sret->{data});	
		}

	} else {
		$self->debug(0,'load_config',"Configuration file (%s) does not exist.",$self->{PATHconf});
	}
}

=head1 METHODS - AGI

This method overloads the C<Asterisk::AGI> module, parsing C<AGI> variable into the OSDial
object and allowing direct access to C<AGI> functions.

The B<AGI()> method must first be called with the name of the current script or instance.
After the initial call, B<AGI()> will return the C<AGI> object for execution of C<AGI> events.

=over 4

=item B<AGI( [script_name] )> - starts the AGI component.

When called the first time, it will initialize the C<AGI> obeject.

   $osdial = new OSDial;
   $osdial->AGI('agi-script_name.agi');

Subsequent calls to B<AGI()> will return a reference to the C<AGI> object.  This reference can
be used to call C<Asterisk::AGI> functions or be assigned to another variable to be called.

   $osdial->AGI->verbose("OSDial Rocks",1);
   $osdial->AGI->hangup();
   
   $AGI = $osdial->AGI();
   $AGI->verbose("OSDial Rocks",1);
   $AGI->hangup();

=back

=cut

sub AGI {
	my ($self,$mod) = @_;
	if (!defined $self->{_agi}) {
		die "  -- OSDial [AGI]: Function must be passed the name of the calling module." unless ($mod);

		$self->{_agi} = new Asterisk::AGI;
		my %aout = $self->{_agi}->ReadParse();
		$self->agi_output("AGI Environment Dump:");
		foreach my $i (sort keys %aout) {
		        $self->{_agi}{$i} = $aout{$i};
		        $self->agi_output(" -- $i = " . $self->{_agi}{$i});
		}
		$self->{_agi}{mod} = $mod;
		return 1;
	}
	return $self->{_agi};
}

=over 4

=item B<agi_output($string, [$extended_info])> - AGI logging method.

This method outputs a given I<$string> to the C<AGI> log file if C<AGI> logging is
enabled for the server as defined by I<VARserver_ip>.  The file is stored in the
directory specified by the OSDial object variable I<PATHlogs> in a file called
I<agiout.YYYY-MM-DD>. The I<$extended_info> variable is an optional boolean flag which
instructs the routine to log the I<channel>, I<extension>, I<priority>, I<type>,
and I<account_code> C<AGI> channel variables;

   $osdial->agi_output("An AGI event occurred");
   
   $osdial->agi_output("Event occurred with additional channel variables",1);

=back

=cut


sub agi_output {
	my ($self,$agi_string,$extinfo) = @_;
	if ($self->{server}{agi_output} and $self->{_agi}{mod} and $self->{_agi} and $agi_string) {
		$agi_string .= '|' . $self->{_agi}{uniqueid} if ($self->{_agi}{uniqueid});
		$agi_string .= '|' . $self->{_agi}{CIDlead_id} if ($self->{_agi}{CIDlead_id});
		$agi_string .= '|' . join('|',$self->{_agi}{channel},$self->{_agi}{extension},$self->{_agi}{priority},$self->{_agi}{type},$self->{_agi}{accountcode}) if ($extinfo);
		if ($self->{server}{agi_output} =~ /FILE|BOTH/) {
			### open the log file for writing ###
        		my $logfile = $self->{PATHlogs} . '/agiout.' . $self->get_date();
			open(Lout, '>>' . $logfile) or die '  -- OSDial: agi_output:  Error opening ' . $logfile . "\n";
			print Lout sprintf("\%s|\%s|\%s|\%s\n",$self->get_datetime(),$self->{_agi}{mod},$$,$agi_string);
			close(Lout);
		}
		### send to STDERR writing ###
		$self->debug(2,'agi_output','%s|%s|%s|%s',$self->get_datetime(),$self->{_agi}{mod},$$,$agi_string) if ($self->{server}{agi_output} =~ /STDERR|BOTH/);
	}
}

sub agi_tts_sayphrase {
	my ($self,$phrase,$voice,$data) = @_;
	if (defined $self->{_agi}) {
		foreach my $seg ($self->tts_osdial_parse($phrase,$data)){
			my $ttsfile = $self->tts_generate($seg,$voice);
			$self->AGI->stream_file($ttsfile) if ($ttsfile);
		}
	}
}

sub tts_osdial_parse {
	my ($self,$phrase,$data) = @_;
	$phrase =~ s/(\[\[[^\s]*\]\])/|||$1|||/g;
	$phrase =~ s/(\{\{[^\s]*\}\})/|||$1|||/g;
	my @splits;
	foreach my $var (split('\|\|\|', $phrase)) {
		my $tsdata;
		if ($var =~ /\{\{[^\s]*\}\}/) {
			my $fld = $var;
			$fld =~ s/\{\{|\}\}//g;
			$tsdata = '%'.$fld.'%';
		} elsif ($var =~ /\[\[[^\s]*\]\]/) {
			my $fld = $var;
			$fld =~ s/\[\[|\]\]//g;
			if (!defined($data->{$fld})) {
				$tsdata = 'DATA_MISSING';
			} else {
				$tsdata = $data->{$fld};
			}
		} else {
			$tsdata = $var;
		}
		$tsdata =~ s/^\s*$//g;
		push @splits, $tsdata if ($tsdata ne '');
	}
	return @splits;
}

sub tts_generate {
	my ($self,$phrase,$voice) = @_;
	$voice = 'voice_nitech_us_rms_arctic_hts' unless ($voice);
	my $cachedir = "/opt/osdial/tts";
	my $sdir1 = "/mnt/ramdisk/sounds";
	my $sdir2 = "/var/lib/asterisk/sounds";

	if ($phrase =~ /^%.*%$/) {
		$phrase =~ s/^%(.*)%$/$1/;
		$phrase =~ s/^osdial\///;
		return $phrase;
	} else {
		my $hash = md5_hex($voice.':'.$phrase);
		my $base = 'tts-'.$hash; 
		if (! -f $cachedir.'/'.$base.'.wav') {
			open(TXT, '>'.$cachedir.'/'.$base.'.txt');
			print TXT $phrase . "\n";
			close(TXT);
			system("/usr/bin/text2wave -eval \"($voice)\" -F 8000 -o $cachedir/$base.wav $cachedir/$base.txt");
			unlink($cachedir.'/'.$base.'.txt');
		} else {
			$self->debug(1,'tts_generate','%s/%s.wav already exists.',$cachedir,$base);
		}

		if(-f $cachedir.'/'.$base.'.wav') {
			if (-d $sdir1 and -w $sdir1) {
				if (! -d $sdir1.'/tts') {
					$self->debug(1,'tts_generate','Making directory %s/tts.',$sdir1);
					mkdir($sdir1.'/tts',oct('0777'));
				}
				if (! -f $sdir1.'/tts/'.$base.'.wav') {
					$self->debug(1,'tts_generate','Copying %s/%s.wav to %s/tts.',$cachedir,$base,$sdir1);
					system('/bin/cp -au '.$cachedir.'/'.$base.'.wav '.$sdir1.'/tts') unless (-f $sdir1.'/tts/'.$base.'.wav');
				}
			}
			if (-d $sdir2 and -w $sdir2) {
				if (! -d $sdir2.'/tts') {
					$self->debug(1,'tts_generate','Making directory %s/tts.',$sdir2);
					mkdir($sdir2.'/tts',oct('0777'));
				}
				if (! -f $sdir2.'/tts/'.$base.'.wav') {
					$self->debug(1,'tts_generate','Copying %s/%s.wav to %s/tts.',$cachedir,$base,$sdir2);
					system('/bin/cp -au '.$cachedir.'/'.$base.'.wav '.$sdir2.'/tts') unless (-f $sdir2.'/tts/'.$base.'.wav');
				}
			}
		}
		return 'tts/'.$base;
	}
}

=head1 METHODS - SQL

These methods provide quick and easy access to the OSDial Database by way of its configuration files.  

Every method has a definable I<$DBhandle> scalar variable.  This variable is a text representation
of the handle being accessed.  If not given, this always defaults to "A".  This is very useful for
running nested queries, as you only need to call the nested statement with a different I<$DBhandle>.
Every SQL method will first check to see if the I<$DBhandle> exists and a connection to that database
has already been established.  If a I<$DBhandle>, has not yet been opened, B<sql_connect> will
automatically be called.

   # Create a connection to DBhandle "A".
   $osdial->sql_connect();
   # Run given query against DBhandle "A".
   $row = $osdial->sql_query("SELECT * FROM servers LIMIT 1;");
   print $row->{"server_ip"} . "\n";
   
   # Create a connection to DBhandle "SVR".
   $osdial->sql_connect("SVR");
   # Run given query against DBhandle "SVR".
   while ($row = $osdial->sql_query("SELECT * FROM servers;","SVR")) {
       # Run given query against DBhandle "OSDL", automatically connecting to handle.
       $subrow = $osdial->sql_query("SELECT * FROM osdial_log WHERE server_ip='" . $row->{"server_ip"} . "';","OSDL");
       print $subrow->{"call_date"} . "\n";
   }

=over 4

=item B<sql_connect( [$DBhandle],  [$DBname, [$DBserver]. [$DBport], [$DBuser], [$DBpass]] )> - connect to SQL server.

Connects to SQL server using sting label in I<$DBhandle>, if not given default to "A".
If I<$DBname> is given, B<sql_connect> will allow you to override the respective default
server values for this connection.

   $osdial->sql_connect("B");

=back

=cut

sub sql_connect {
	my ($self, $dbh, $dbname, $dbsrvr, $dbport, $dbuser, $dbpass) = @_;
	$dbh = 'A' unless ($dbh);
	unless ($dbname) {
		$dbname = $self->{VARDB_database};
		$dbsrvr = $self->{VARDB_server};
		$dbport = $self->{VARDB_port};
		$dbuser = $self->{VARDB_user};
		$dbpass = $self->{VARDB_pass};
	}
	$self->{_sql}{$dbh} = {'connected'=>0} if (!defined $self->{_sql}{$dbh});
	if ($self->{_sql}{$dbh}{connected}<1) {
		my $dsn = 'DBI:mysql:' . $dbname . ':' . $dbsrvr . ':' . $dbport;
		$self->debug(5,'sql_connect',"Connecting to dbh %s at DSN: %s.",$dbh,$dsn);
		$self->{_sql}{$dbh}{dbh} = DBI->connect($dsn,$dbuser,$dbpass);
		my $myerr = DBI::errstr;
		if ($myerr) {
			$self->{_sql}{$dbh}{dbh}{mysql_auto_reconnect} = 0;
			$self->{_sql}{$dbh}{connected} = 0;
			if ($dbh eq 'A') {
				$self->sql_onfail('  -- OSDial: sql_connect:  ERROR ' . $myerr);
			} else {
				warn '  -- OSDial: sql_connect:  ERROR ' . $myerr;
			}
		} else {
			$self->{_sql}{$dbh}{dbh}{PrintError} = 0;
			$self->{_sql}{$dbh}{dbh}{mysql_auto_reconnect} = 1;
			$self->{_sql}{$dbh}{connected} = 1;
		}
	}
	return $self->{_sql}{$dbh}{connected};
}



=over 4

=item B<sql_disconnect( [$DBhandle] )> - disconnect from SQL server.

Disconnects from the database connection referenced by I<$DBhandle>.
If I<$DBhandle> is not given, it defaults to "A".

   $osdial->sql_disconnect("B");

=back

=cut

sub sql_disconnect {
	my ($self, $dbh) = @_;
	$dbh = 'A' unless ($dbh);
	$self->{_sql}{$dbh} = {'connected'=>0} if (!defined $self->{_sql}{$dbh});
	if ($self->{_sql}{$dbh}{connected}>0) {
		$self->debug(5,'sql_disconnect',"Disconnecting from dbh %s.",$dbh);
		$self->{_sql}{$dbh}{dbh}->disconnect() if ($self->{_sql}{$dbh}{dbh});
		$self->{_sql}{$dbh}{connected} = 0;
	}
}


=over 4

=item B<sql_query( $query, [$DBhandle] )> - Issues an SQL query.

The B<sql_query()> method allows you to execute SQL statments.  The
result is a HASHREF containing the key value pairs of a queried row.
This method will retain its iterative position within the running current
running query and will output each row on subsequent calls.  If it is run
with a new and different query, while a previous query is currently buffered,
it will flush the buffer and start the new query.  Just be mindful to start
sub-queries with a different I<$DBhandle> to avoid clearing the current buffer
of the parent query.

   # Called in a single iteration, yeilds row #1.
   $row = $osdial->sql_query('SELECT * FROM servers;');
   
   # Called again with same query, yeilds row #2.
   $row = $osdial->sql_query('SELECT * FROM servers;');
   
   # Called again with diffent query, flushes buffer and yeilds row #1.
   $row = $osdial->sql_query('SELECT * FROM server_stats;');
   
   # Called in while loop, will cycle through all rows returned by query.
   while ($row = $osdial->sql_query('SELECT * FROM servers;')) {
      print $row->{"server_ip"} . "\n";
   }

If an C<INSERT>, C<UPDATE>, or C<DELETE> query is given, options will automatically
be passed to B<sql_execute()>.

If I<$DBhandle> does not reference a current active database connection, B<sql_connect()>
will automatically by called.

=back

=cut

sub sql_query {
        my ($self,$opt1,$opt2) = @_;
	my $row;

	my $opts = {};

	if (ref($opt1) eq "HASH") {
		$opts = $opt1;
	} elsif (ref($opt2) eq "HASH") {
		$opts = $opt2;
		$opts->{stmt} = $opt1;
	} else {
		$opts->{stmt} = $opt1;
		$opts->{dbh}  = $opt2;
	}
	# Set some defaults...
	$opts->{stmt} = '' if (!defined $opts->{stmt});   # The query to execute.
	$opts->{dbh} = 'A' if (!defined $opts->{dbh});    # the label used for dbh indentification.
	$opts->{init} = 0 if (!defined $opts->{init});    # If 1, Stop before attempting first record grab.

	my $stmt = $opts->{stmt};
	my $dbh  = $opts->{dbh};

	# If dbh has not been defined, connect to DB.
	$self->sql_connect($dbh) if (!defined $self->{_sql}{$dbh} or $self->{_sql}{$dbh}{connected}<1);

	return $self->sql_execute($opts) if ($stmt =~ /^update|^insert|^delete/i);

	# Check if this run is an iteration.
	if (defined $self->{_sql}{$dbh}{last_stmt}) {

		# Last stmt is set is but no sth, must have finished...
		if (!defined $self->{_sql}{$dbh}{sth}) {
			# stmt is not blank, and statement differs from last_stmt, clear and move on.
			if ($stmt ne '' and $stmt ne $self->{_sql}{$dbh}{last_stmt}) {
				delete $self->{_sql}{$dbh}{last_stmt};
				delete $self->{_sql}{$dbh}{rows};
				delete $self->{_sql}{$dbh}{row};
				delete $self->{_sql}{$dbh}{sth};

			# stmt is blank or same, but query already finished, clear and exit.
			} elsif ($stmt eq '' or $stmt eq $self->{_sql}{$dbh}{last_stmt}) {
				$self->debug(9,'sql_query',"DBH %-6s  [iteration]  already sent last row for this query, sending undef and exiting.",$dbh);
				delete $self->{_sql}{$dbh}{last_stmt};
				delete $self->{_sql}{$dbh}{rows};
				delete $self->{_sql}{$dbh}{row};
				return undef;
			}
		}

		if (defined $self->{_sql}{$dbh}{sth}) {
			# They current and previous run differ, clear and run new stmt.
			if ($stmt ne '' and $stmt ne $self->{_sql}{$dbh}{last_stmt}) {
				$self->debug(9,'sql_query',"DBH %-6s  [iteration]  last_stmt and stmt differ, clearing and moving on.",$dbh);
				$self->{_sql}{$dbh}{sth}->finish();
				delete $self->{_sql}{$dbh}{last_stmt};
				delete $self->{_sql}{$dbh}{rows};
				delete $self->{_sql}{$dbh}{row};
				delete $self->{_sql}{$dbh}{sth};

			# stmt is blank, so lets set it to the last_stmt.
			} elsif ($stmt eq '' or $stmt eq $self->{_sql}{$dbh}{last_stmt}) {
				$self->debug(9,'sql_query',"DBH %-6s  [iteration]  stmt blank or same as last_stmt, moving on.",$dbh);
				$self->{_sql}{$dbh}{last_stmt} = $stmt;
			}
		}
	}

	# If connected to DB and sth has not been defined, issue query.
	if (defined $self->{_sql}{$dbh}{dbh} and !defined $self->{_sql}{$dbh}{sth}) {
		$self->debug(5,'sql_query',"DBH %-6s  [execute]  STMT:  %s",$dbh, $stmt);
        	$self->{_sql}{$dbh}{sth} = $self->{_sql}{$dbh}{dbh}->prepare($stmt) or $self->sql_onfail("  -- OSDial: sql_query $dbh:  ERROR " . $self->{_sql}{$dbh}{dbh}->errstr);
        	$self->{_sql}{$dbh}{sth}->execute or $self->sql_onfail("  -- OSDial: sql_query $dbh:  ERROR " . $self->{_sql}{$dbh}{dbh}->errstr);
		$self->{_sql}{$dbh}{rows} = 0;
		$self->{_sql}{$dbh}{last_stmt} = $stmt;
		delete $self->{_sql}{$dbh}{row};
	}

	# If sth is defined, start record grab.
	if (defined $self->{_sql}{$dbh}{sth}) {
		# Get row counts if we havent yet.
		if (!defined $self->{_sql}{$dbh}{row}) {
			$self->{_sql}{$dbh}{row} = 0;
			$self->{_sql}{$dbh}{rows} = $self->{_sql}{$dbh}{sth}->rows();
			$self->debug(5,'sql_query',"DBH %-6s  [row_count]  %s",$dbh, $self->{_sql}{$dbh}{row});
		}

		# Test if we were just initializing or if we are running.
		if ($opts->{init} > 0) {
			$self->debug(9,'sql_query',"DBH %-6s  [init]  Init is set, returning before getting first row.",$dbh);
			return $self->{_sql}{$dbh}{rows};
		} else {
			# Get the record and increment count if we find one.
			$self->debug(6,'sql_query',"DBH %-6s  [fetch_row]  Getting row, iteration # %s.",$dbh, $self->{_sql}{$dbh}{row});
        		$row = $self->{_sql}{$dbh}{sth}->fetchrow_hashref;
			$row->{ROW} = ++$self->{_sql}{$dbh}{row} if ($row);
		}

		# If row count and current row are equal destroy sth and return row if there is one.
		if ($self->{_sql}{$dbh}{row} == $self->{_sql}{$dbh}{rows}) {
			$self->debug(7,'sql_query',"DBH %-6s  [last_row]  Reached last row, exiting.",$dbh);
			$self->{_sql}{$dbh}{sth}->finish();
			delete $self->{_sql}{$dbh}{sth};
		}
	}
	return $row;
}



=over 4

=item B<sql_execute( $query, [$DBhandle] )> - disconnect from SQL server.

Execute the given statement in I<$query>.

   # Example Insert.
   $osdial->sql_execute("INSERT INTO table SET row='value';");
   
   # Example Update.
   $osdial->sql_execute("UPDATE table SET row='value' WHERE key='id';");

   # Example Delete.
   $osdial->sql_execute("DELETE FROM table WHERE key='id';");

If an C<SELECT> or C<SHOW> query is given, options will automatically
be passed to B<sql_query()>.

If I<$DBhandle> does not reference a current active database connection, B<sql_connect()>
will automatically by called.

=back

=cut

sub sql_execute {
        my ($self,$opt1,$opt2) = @_;
	my $row;

	my $opts = {};

	if (ref($opt1) eq "HASH") {
		$opts = $opt1;
	} elsif (ref($opt2) eq "HASH") {
		$opts = $opt2;
		$opts->{stmt} = $opt1;
	} else {
		$opts->{stmt} = $opt1;
		$opts->{dbh}  = $opt2;
	}
	# Set some defaults...
	$opts->{stmt} = '' if (!defined $opts->{stmt});  # The query to execute.
	$opts->{dbh} = 'A' if (!defined $opts->{dbh});   # the label used for dbh indentification.
	$opts->{init} = 0 if (!defined $opts->{init});   # If 1, Stop before attempting first record grab.

	my $stmt = $opts->{stmt};
	my $dbh  = $opts->{dbh};

	# If dbh has not been defined, connect to DB.
	$self->sql_connect($dbh) if (!defined $self->{_sql}{$dbh} or $self->{_sql}{$dbh}{connected}<1);

	return $self->sql_query($opts) if ($stmt =~ /^select|^show/i);

	$self->debug(5,'sql_query',"DBH %-6s  [execute]  STMT:  %s",$dbh, $stmt);
	$self->{_sql}{$dbh}{rows} = $self->{_sql}{$dbh}{dbh}->do($stmt) or $self->sql_onfail("  -- OSDial: sql_execute $dbh:  ERROR " . $self->{_sql}{$dbh}{dbh}->errstr);
	return $self->{_sql}{$dbh}{rows};
}



=over 4

=item B<sql_quote( $string )> - returns properly escaped string in single-quotes.

Returns escaped strings for inclusion in queries.  Returned string is already enclosed
within single-quotes.

   $test = $osdial->sql_quote("Here's a test.");
   # Result: $test = "'Here\'s a test.'";

Aliases for B<sql_quote( $string )> include B<quote( $string )> and B<mres( $string )>.

=back

=cut

sub sql_quote {
        my ($self,$string) = @_;
	my $dbh = 'A';
	# If dbh has not been defined, connect to DB.
	$self->sql_connect($dbh) if (!defined $self->{_sql}{$dbh} or $self->{_sql}{$dbh}{connected}<1);
	return $self->{_sql}{$dbh}{dbh}->quote($string);
}
sub quote { return sql_quote(@_); }
sub mres {
	my $dequote = sql_quote(@_);
	$dequote =~ s/^'|'$//g;
	return $dequote;
}


sub sql_onfail {
        my ($self,$string) = @_;
	if ($self->{VARDB_onfail} eq 'warn') {
		warn $string;
	} else {
		die $string;
	}
}


=over 4

=item B<sql_dbh( $dbh )> - returns the dbh handle.

Returns the maximum allowed packet size that the SQL server will except.

   $dbhandle = $osdial->sql_dbh($dbh);

=back

=cut

sub sql_dbh {
	my ($self, $dbh) = @_;
	$dbh = 'A' unless ($dbh);
	# If dbh has not been defined, connect to DB.
	$self->sql_connect($dbh) if (!defined $self->{_sql}{$dbh} or $self->{_sql}{$dbh}{connected}<1);
	return $self->{_sql}{$dbh}{dbh};
}


=over 4

=item B<sql_last_insert_id( $dbh )> - returns the last insert id.
=item B<sql_last_insertid( $dbh )> - returns the last insert id.
=item B<sql_last_id( $dbh )> - returns the last insert id.
=item B<sql_insert_id( $dbh )> - returns the last insert id.

Returns the last insert ID.

   $insertid = $osdial->sql_last_insert_id($dbh);
   $insertid = $osdial->sql_last_insertid($dbh);
   $insertid = $osdial->sql_last_id($dbh);
   $insertid = $osdial->sql_insert_id($dbh);

=back

=cut

sub sql_last_insert_id {
	my ($self, $dbh) = @_;
	$dbh = 'A' unless ($dbh);
	# If dbh has not been defined, connect to DB.
	$self->sql_connect($dbh) if (!defined $self->{_sql}{$dbh} or $self->{_sql}{$dbh}{connected}<1);
	return $self->sql_dbh($dbh)->{'mysql_insertid'};
}
sub sql_last_insertid { return sql_last_insert_id(@_); }
sub sql_last_id { return sql_last_insert_id(@_); }
sub sql_insert_id { return sql_last_insert_id(@_); }


=over 4

=item B<sql_max_packet( )> - returns maximum packet allowed.

Returns the maximum allowed packet size that the SQL server will except.

   $max_packet = $osdial->sql_max_packet();

=back

=cut

sub sql_max_packet {
	my ($self) = @_;
	if (!defined $self->{_sql_max_allowed_packet}) {
		my $sret = $self->sql_query("SHOW variables LIKE 'max_allowed_packet';");
		$self->{_sql_max_allowed_packet} = $sret->{'Value'};
	}
	$self->debug(5,'sql_max_packet',"SQL Max Packet Size: %s",$self->{_sql_max_allowed_packet});
	return $self->{_sql_max_allowed_packet};
}



=head1 METHODS - OSDial

General methods for OSDial that help with everyday functions.

=over 4

=item B<debug( $level, $module, $sprintf_string, @sprintf_params )> - Send debug output to STDERR.

If I<$level> matches the current Debug Level set by I<DB>, then output a debug statement to STDERR.
The name of the calling module should be specified in I<$module>.  The outputted string is taken
in the same format as B<sprintf()> in the form of I<$sprintf_string> and I<@sprintf_params>.

   $osdial->debug(1,'main', 'The %s function failed!', $var);

=back

=cut

sub debug {
	my ($self, $lev, $mod, $string, @params) = @_;
	if($self->{DB}>=$lev) {
		my $p = 2+$lev;
		my @sprint = (' ',$mod,@params);
		$string .= "\n" unless($string =~ /\n$/);
		print STDERR sprintf('%'.$p.'s-- OSDial [%s]:  '.$string,@sprint);
	}
}



=over 4

=item B<event_logger( $logname, $string )> - Send event to logfile.

Sends an event, I<$string>, to the logfile in C<PATHlogs>, named I<$logfile>.YYYY-MM-DD.

   $osdial->event_logger('eventlog','An event was triggered.');

=back

=cut

sub event_logger {
        my ($self,$type,$string) = @_;
	if ($type and $string) {
        	my $logfile = $self->{PATHlogs} . '/' . $type . '.' . $self->get_date();
        	open(LOG, '>>' . $logfile) or die '  -- OSDial: event_logger:  Error opening ' . $logfile . "\n";
        	print LOG sprintf("\%s|\%s|\%s\n",$self->get_datetime(),$$,$string);
        	close(LOG);
	}
}



=over 4

=item B<get_datetime( [$time] )>

Returns B<time()> or I<$time>, if given, in the format: YYYY-MM-DD HH:MM:SS

   $osdial->get_datetime();

=back

=cut

sub get_datetime {
	my($self,$tms) = @_;
	$tms = time() unless ($tms);
	my ($s,$m,$h,$D,$M,$Y,$wday,$yday,$isdst) = localtime($tms);
	$Y += 1900;
	return sprintf('%.4d-%.2d-%.2d %.2d:%.2d:%.2d', $Y, ++$M, $D, $h, $m, $s);
}



=over 4

=item B<get_date( $time )>

Returns B<time()> or I<$time>, if given, in the format: YYYY-MM-DD

   $osdial->get_date();

=back

=cut

sub get_date {
	my($self,$tms) = @_;
	return substr($self->get_datetime($tms),0,10);
}




=over 4

=item B<media_add_files( $directory, [$pattern], [$update_data] )>

All files in I<$directory> are scaned and loaded into the databsae if they do not already exist in it.

The I<$pattern> variable allows for a regex expression to be applied against the filename.  The default I<$patter> is C<.*>.

If the file exists in the database and I<$update_data> is true, the data is updated.  The default action
is to skip files which are already present.

=back

=cut

sub media_add_files {
	my ($self,$dir,$pattern,$updatedata) = @_;
	$dir = '.' unless ($dir);
	$updatedata = 0 unless ($updatedata);
	$pattern = '.*' unless ($pattern);

	$self->debug(3,'media_add_files',"Adding Directory:%s  Pattern:%s  Update:%s",$dir,$pattern, $updatedata);
	my @files;
	return @files if (!-d $dir );
	opendir(MAFDIR,$dir);
	foreach my $filename (readdir(MAFDIR)) {
		if ($filename ne '.' and $filename ne '..' and $filename =~ /$pattern/ and not -d $filename) {
			my $file = $dir.'/'.$filename;

			my $mime = $filename;
			$mime =~ s/.*\.//;

			my $extension = $filename;
			$extension =~ s/.*\/|\..*$//;
			$extension = '' unless ($extension =~ /^\d+$/);

			my $addfile = $self->media_add_file($file, $self->{'_mimemap'}{lc($mime)}, $filename, $extension, $updatedata);
			push @files, $addfile if ($addfile);
		}
	}
	closedir(MAFDIR);
	return @files;
}



=over 4

=item B<media_add_file( $filepath, [$mimetype], [$description], [$extension], [$update_data] )>

This function opens the media file I<$filepath> and splits the binary data into segments which are
small enough to be sent to the SQL server without exceeding the C<max_allowed_packet> size.

If I<$mimetype> is not given, it will be guessed using the extension of I<$filepath>.

   g722    => 'audio/G722'
   g729    => 'audio/G729'
   gsm     => 'audio/GSM'
   ogg     => 'audio/ogg'
   ulaw    => 'audio/PCMU'
   alaw    => 'audio/PCMA'
   siren7  => 'audio/siren7'
   siren14 => 'audio/siren14'
   sln     => 'audio/sln'
   sln16   => 'audio/sln-16'
   mp3     => 'audio/mpeg'
   wav     => 'audio/x-wav'

If I<$description> is not given, the filename is stripped off of I<$filepath> and used.

If I<$extension> is not given and the filename is not numeric, it is left blank.  If the filename will
be used if it is numeric.

If the file exists in the database and I<$update_data> is true, the data is updated.  The default action
is to skip files which are already present.

=back

=cut

sub media_add_file {
	my ($self,$file,$mimetype,$description,$extension,$updatedata) = @_;
	my $filename=$file;
	$filename =~ s/.*\///;
	unless ($mimetype) {
		my $mime = $filename;
		$mime =~ s/.*\.//;
		$mimetype = $self->{'_mimemap'}{lc($mime)};
	}
	$description = $filename unless ($description);
	unless ($extension) {
		$extension = $filename;
		$extension =~ s/.*\/|\..*$//;
		$extension = '' unless ($extension =~ /^\d+$/);
	}
	$updatedata = 0 unless ($updatedata);

	$self->debug(3,'media_add_file',"  Adding File:%s  Name:%s  Mime:%s  Desc:%s  Ext:%s  Update:%s", $file, $filename, $mimetype, $description, $extension, $updatedata);
	return '!'.$filename unless (-e $file);


	my $sret = $self->sql_query(sprintf('SELECT count(*) fncnt FROM osdial_media WHERE filename=%s;',$self->quote($filename)),'MAF');
	if ($sret->{fncnt}==0) {
		$self->sql_execute(
			sprintf('INSERT INTO osdial_media SET filename=%s,mimetype=%s,description=%s,extension=%s;',
				$self->quote($filename), $self->quote($mimetype), $self->quote($description), $self->quote($extension) ),'MAF' );
	} else {
		my $sret = $self->sql_query(sprintf('SELECT count(*) fncnt FROM osdial_media_data WHERE filename=%s;',$self->quote($filename)),'MAF');
		if ($sret->{fncnt}>0) {
			if ($updatedata>0) {
				$self->media_delete_filedata($filename);
			} else {
				$self->sql_disconnect('MAF');
				return '*'.$filename;
			}
		}
	}


	my $data="";
	my $max_packet = $self->sql_max_packet() - 120_000;
	open(MAF, '<'.$file);
	binmode(MAF);
	while (read(MAF, $data, $max_packet ) ) {
		$self->sql_execute( sprintf('INSERT INTO osdial_media_data SET filename=%s,filedata=%s;', $self->quote($filename), $self->quote($data) ),'MAF' ) if ($data);
	}
	close(MAF);
	$self->sql_disconnect('MAF');
	return '='.$filename if ($updatedata);
	return '+'.$filename;
}



=over 4

=item B<media_delete_filedata( $filename )>

Removes all entries in the C<osdial_media_data> table associated with I<$filename>.

=back

=cut

sub media_delete_filedata {
	my ($self, $filename) = @_;
	$self->debug(3,'media_delete_filedata',"    Deleting Filedata:%s", $filename);
	$self->sql_execute( sprintf('DELETE FROM osdial_media_data WHERE filename=%s;', $self->quote($filename) ),'MDFD' );
	$self->sql_disconnect('MDFD');
}



=over 4

=item B<media_get_filedata( $filename )>

Combines all of the entries in the C<osdial_media_data> table associated with I<$filename> and returns the binary data.

=back

=cut

sub media_get_filedata {
	my ($self, $filename) = @_;
	$self->debug(3,'media_get_filedata',"    Get Filedata:%s", $filename);
	my $filedata;
	while (my $sret = $self->sql_query( sprintf("SELECT filedata FROM osdial_media_data WHERE filename=%s;", $self->quote($filename) ), 'MGFD' ) ) {
		$filedata .= $sret->{filedata};
	}
	$self->sql_disconnect('MGFD');
	return $filedata;
}



=over 4

=item B<media_save_file( $directory, $filename, [$overwrite] )>

Export entry matching I<$filename> and save into the given I<$directory>.
File is skipped and is not overwitten unless I<$overwrite> is true.

=back

=cut

sub media_save_file {
	my ($self,$dir,$filename,$overwrite) = @_;
	$dir = '.' unless ($dir);
	$overwrite = 0 unless ($overwrite);
	unless (-e $dir) {
		mkdir($dir,oct('0777'));
		my ($login,$pass,$uid,$gid) = getpwnam('asterisk');
		chown($uid,$gid,$dir);
	}
	chmod(oct('0777'),$dir);

	my $file = $dir.'/'.$filename;
	$self->debug(3,'media_save_file',"  Adding File:%s  Dir:%s  Name:%s  Overwrite:%s", $file, $dir, $filename, $overwrite);
	return '*'.$filename if (-e $file and $overwrite==0);

	my $filedata = $self->media_get_filedata($filename);
	return '!'.$filename unless ($filedata);

	open(MSF, '>'.$file);
	binmode(MSF);
	print MSF $filedata;
	close(MSF);
	my ($login,$pass,$uid,$gid) = getpwnam('asterisk');
	chown($uid,$gid,$file);
	chmod(oct('0666'),$file);

	return '='.$filename if ($overwrite);
	return '+'.$filename;
}



=over 4

=item B<media_save_files( $directory, [$pattern], [$overwrite] )>

All files matching the regex I<$patten> are exported and saved into the given I<$directory>.
The default I<$pattern> is C<.*>.  Files are skipped and not overwitten unless I<$overwrite> is true.

=back

=cut

sub media_save_files {
	my ($self,$dir,$pattern,$overwrite) = @_;
	$dir = '.' unless ($dir);
	$overwrite = 0 unless ($overwrite);
	$pattern = '.*' unless ($pattern);
	$self->debug(3,'media_save_files',"Adding Files:%s  Pattern:%s  Overwrite:%s", $dir, $pattern, $overwrite);
	unless (-e $dir) {
		mkdir($dir,oct('0777'));
		my ($login,$pass,$uid,$gid) = getpwnam('asterisk');
		chown($uid,$gid,$dir);
	}
	chmod(oct('0777'),$dir);

	my @files;
	while (my $sret = $self->sql_query("SELECT * FROM osdial_media;", "MSF")) {
		if ($sret->{filename} =~ /$pattern/) {
			push @files, $self->media_save_file($dir, $sret->{filename}, $overwrite);
			chmod(oct('0666'),$dir.'/'.$sret->{filename});
		}
	}
	$self->sql_disconnect('MSF');
	return @files;
}



=over 4

=item B<send_email( $host, $port, $user, $pass, $to, $from, $subject, $html, $text )>
=item B<send_email({ host=>$host, port=>$port, user=>$user, pass=>$pass, to=>$to, from=>$from, subject=>$subject, $html=>$html, text=>$text })>

Sends out an email using the given parameters. Returns 1 on success, 0 on failure.

=back

=cut

sub send_email {
	my ($self, $opt1, $port, $user, $pass, $to, $from, $subject, $html, $text) = @_;

	my $host='';

	if (ref($opt1) =~ /HASH/) {
		$host = $opt1->{'host'} if (exists($opt1->{'host'}));
		$port = $opt1->{'port'} if (exists($opt1->{'port'}));
		$user = $opt1->{'user'} if (exists($opt1->{'user'}));
		$pass = $opt1->{'pass'} if (exists($opt1->{'pass'}));
		$to = $opt1->{'to'} if (exists($opt1->{'to'}));
		$from = $opt1->{'from'} if (exists($opt1->{'from'}));
		$subject = $opt1->{'subject'} if (exists($opt1->{'subject'}));
		if (exists($opt1->{'message'})) {
			$text=$opt1->{'message'};
			$html="<pre style=\"font-family:'DejaVu Sans mono','Lucida Console',monospace;\">".$text.'</pre>';
		} else {
			$html = $opt1->{'html'} if (exists($opt1->{'html'}));
			$text = $opt1->{'text'} if (exists($opt1->{'text'}));
		}
	} else {
		$host = $opt1;
	}

	$host='localhost' if (!defined($host) or $host eq '');
	$port='25' if (!defined($port) or $port eq '');

	my $transparams = { 'host' => $host, 'port' => $port };
	if (defined($user) and $user ne '') {
		$transparams->{'sasl_username'} = $user;
		$transparams->{'sasl_password'} = $pass;
	}

	my $transport = Email::Sender::Transport::SMTP->new($transparams);

	my $email = Email::Stuffer->to($to)
		->from($from)
		->subject($subject)
		->text_body($text)
		->html_body($html)
		->transport($transport);

	my $eres = $email->send();

	return 1 if (ref($eres) =~ /^Email::Sender::Success/);
	return 0;
}



=over 4

=item B<osdevent({ server_ip=>$server_ip, unqiueid=>$unqiueid, callerid=>$callerid, user=>$user, campaign_id=>$campaign_id, group_id=>$group_id, lead_id=>$lead_id, event=>$event, data1=>$data1, data2=>$data2, data3=>$data3, data4=>$data4, data5=>$data5, data6=>$data6 })>

Records the given data into the osdial_events table.

=back

=cut

sub osdevent {
        my ($self,$optref) = @_;
	my $opts = {};
	if (ref($optref) eq "HASH") {
		$opts = $optref;
	}
	my $oelsql = '';
	foreach my $opt (sort keys %{$opts}) {
		$oelsql .= sprintf("%s=%s,",$opt,$self->quote($opts->{$opt}));
	}
	chop($oelsql);
	if (length($oelsql)>0) {
		$self->sql_execute(sprintf('INSERT INTO osdial_events SET %s;', $oelsql),'OEL');
		return $self->sql_last_insert_id('OEL');
	}
	return 0;
}



sub server_process_tracker {
	my ($self,$prog,$server_ip,$pid,$allow_multiple) = @_;
	my $pcount=0;
	my $ret=1;
	my $procs = {};
	while (my $sret = $self->sql_query(sprintf("SELECT id,name,server_ip,pid,IF(UNIX_TIMESTAMP(last_checkin)>UNIX_TIMESTAMP()-180 AND pid>0,1,0) AS is_alive FROM server_keepalive_processes WHERE name='%s' ORDER BY last_checkin DESC;",$self->mres($prog)))) {
		if (!defined($procs->{$prog})) {
			$procs->{$prog} = { 'id'=>$sret->{id}, 'server_ip' => $sret->{server_ip}, 'pid' => $sret->{pid}, 'is_alive' => $sret->{is_alive} };
		}
		$pcount++;
	}
	if ($pcount==0) {
		my $sret = $self->sql_query(sprintf("SELECT id FROM server_keepalive_processes WHERE name='%s' AND server_ip='%s' ORDER BY last_checkin DESC LIMIT 1;",$self->mres($prog),$self->mres($server_ip)));
		if (defined($sret->{ROW}) and $sret->{ROW} > 0) {
			$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($sret->{id})));
		} else {
			$self->sql_execute(sprintf("INSERT INTO server_keepalive_processes SET server_ip='%s',name='%s',pid='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid)));
		}
		$ret=0;
	} else {
		foreach my $name (keys %{$procs}) {
			if ($procs->{$name}{is_alive}>0) {
				if ($procs->{$name}{server_ip} eq $server_ip) {
					if ($procs->{$name}{pid} eq $pid) {
						if ($procs->{$name}{pid}>0 and pexists($procs->{$name}{pid})) {
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($procs->{$name}{id})));
						} else {
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres('0'),$self->mres($procs->{$name}{id})));
						}
						$ret=0;
					} else {
						if ($procs->{$name}{pid}>0 and pexists($procs->{$name}{pid})) {
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($procs->{$name}{pid}),$self->mres($procs->{$name}{id})));
						} else {
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($procs->{$name}{id})));
						}
						$ret=0;
					}
				} else {
					if ($allow_multiple>0) {
						my $sret = $self->sql_query(sprintf("SELECT id FROM server_keepalive_processes WHERE name='%s' AND server_ip='%s' ORDER BY last_checkin DESC LIMIT 1;",$self->mres($prog),$self->mres($server_ip)));
						if (defined($sret->{ROW}) and $sret->{ROW} > 0) {
	
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($sret->{id})));
						} else {
							$self->sql_execute(sprintf("INSERT INTO server_keepalive_processes SET server_ip='%s',name='%s',pid='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid)));
						}
						$ret=0;
					}
				}
			} else {
				if ($procs->{$name}{server_ip} eq $server_ip) {
					$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($procs->{$name}{id})));
					$ret=0;
				} else {
					if ($allow_multiple>0) {
						my $sret = $self->sql_query(sprintf("SELECT id FROM server_keepalive_processes WHERE name='%s' AND server_ip='%s' ORDER BY last_checkin DESC LIMIT 1;",$self->mres($prog),$self->mres($server_ip)));
						if (defined($sret->{ROW}) and $sret->{ROW} > 0) {
							$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($sret->{id})));
						} else {
							$self->sql_execute(sprintf("INSERT INTO server_keepalive_processes SET server_ip='%s',name='%s',pid='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid)));
						}
						$ret=0;
					} else {
						$self->sql_execute(sprintf("UPDATE server_keepalive_processes SET server_ip='%s',name='%s',pid='%s',last_checkin=NOW() WHERE id='%s';",$self->mres($server_ip),$self->mres($prog),$self->mres($pid),$self->mres($procs->{$name}{id})));
						$ret=0;
					}
				}
			}
		}
	}
	return $ret;
}





# Make sure we do a little cleanup before exiting.
sub DESTROY {
	my $self = shift;
	foreach my $dbh (keys %{$self->{_sql}}) {
		$self->sql_disconnect($dbh) if ($self->{_sql}{$dbh}{connected}>0);
	}
}


1;
__END__


=head1 SEE ALSO

Official OSDial support is available through Call Center Service Group: L<http://www.callcentersg.com/>

OSDial website: L<http://www.osdial.org/>
OSDial at SourceForce: L<http://sourceforge.net/projects/osdial/>

RPMs available through the Fugitol RPM Repository: L<http://rpm.fugitol.com/>


The definitive AGI Module: L<Asterisk::AGI>  Website: L<http://asterisk.gnuinter.net/>

DBI Module: L<DBI>  Website: L<http://dbi.perl.org/>

MySQL Module: L<DBD::mysql>


=head1 AUTHOR

Lott Caskey, <lottcaskey@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2010-2011  Lott Caskey <lottcaskey@gmail.com>

=head1 LICENSE

AGPLv3

This file is part of OSDial.

OSDial is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

OSDial is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with OSDial.  If not, see L<http://www.gnu.org/licenses/>.

=cut
