package Net::Nessus::ScanLite;

use 5.008;
use strict;
use warnings;

use IO::Socket::SSL;
use Config::IniFiles;
use Net::Nessus::Client;
use Net::Nessus::Message;


require Exporter;

our @ISA = qw(Exporter IO::Socket::SSL Net::Nessus::Client Net::Nessus::Message );

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.01';

sub new
        {
        my $class = shift;
	$class = ref($class) || $class;
        my %args = @_;
        my $self = bless {
                _code           => 0,
                _error          => "",
                ntp_version     => '1.2',
                host            => undef,
                port            => 1241,
                user            => undef,
                password        => undef,
                ssl_version     => 'TLSv1',
                timeout         => 1,
		ssl		=> 1,
		debug		=> 1,
                _cfg            => undef,
                _section        => 'nessus',
		_duration	=> 0,
                _prefsect	=> 'preferences',
		_defsection	=> 'defaults',
                _holes          => [],
                _info           => [],
                preferences     => {},

        },$class;
	# Handle ini config handle or path
	if( $args{Cfg} )
		{
		$self->cfg($args{Cfg});
		if( ref($self->cfg) )
                        { $self->init_cfg; }  # assume handle
                else
                        { $self->init_cfg_path; }
                }
	@{$self}{keys %args} = values %args;
        return($self);
        }

#----------------------------------------------------#
# IniFiles methods
#----------------------------------------------------#
sub init_cfg_path
        {
        my $this = shift;
        my $file = $this->cfg;
        my $cfg = new Config::IniFiles( -file => $file, -default => $this->ini_default );
        return($this->set_error(100,"Config file error for $file ($!)")) unless($cfg);
        $this->cfg($cfg);
        $this->ok("Config file $file is ok.");
        $this->init_cfg;
        }
sub init_cfg
        {
        my $this = shift;
        my $cfg = $this->cfg;
	# Get host/login defaults from nessus section override keys in main class.
        init_section($cfg,$this,$this->section);
	# Get preferences from preferences section put them under preferences. 
        init_section($cfg,$this->{preferences},$this->pref_section);
        }
sub init_section
        {
        my ($cfg,$hash,$section) = @_;
        if( $cfg->SectionExists( $section ) )
                {
                foreach( $cfg->Parameters($section)  )
                        {
                        $hash->{$_} = $cfg->val($section,$_);
                        }
                }
        }
sub pref_section
        {
        my $this = shift;
        my $key = '_prefsect';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub ini_default
        {
        my $this = shift;
        my $key = '_defsection';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }


#----------------------------------------------------#
# Nessus methods
#----------------------------------------------------#
sub plugin_set
        {
        my $this = shift;
        my $class = 'preferences';
        my $key = 'plugin_set';
        $this->preference($key,shift) if( @_ );
        return($this->preference($key));
        }
sub preferences
        {
        my $this = shift;
        my $class = 'preferences';
        $this->{$class} = shift if( @_ );
        return($this->{$class});
        }

sub preference
        {
        my ($this,$key,$value) = @_;
        my $class = 'preferences';
        return(undef) unless($key);
        $this->{$class}->{$key} = $value if($value);
        return(undef) unless($this->{$class}->{$key});
        return($this->{$class}->{$key});
        }
sub login
        {
        my $this = shift;
        my $i = 0;
        $this->user(shift) if( @_ );
        $this->password(shift) if( @_ );
        $this->__connect;
        return(0) if( $this->code );
        my $ssl = $this->socket;
        $ssl->autoflush();
        $ssl->print($this->ntp_fast);
         my $r = join(' ',$ssl->getline);
        chomp($r);
        if( $r ne $this->ntp_proto )
                {
                $this->set_error(1,"Protocol error $r");
                return(0);
                }
        $ssl->print( $this->user . "\n");
        $ssl->print( $this->password . "\n");
        $ssl->print( "CLIENT <|> NESSUS_VERSION  <|> CLIENT\n");
        $r = join(' ',$ssl->getline);
        chomp($r);
        if( $r =~ /Bad login/gis )
                {
                $this->set_error(1,"Bad login ".  $this->user);
                return(0);
                }
        return(1);
        }
sub setprefs
        {
        my $this = shift;
        my $p = "CLIENT <|> PREFERENCES <|>\n";
        $this->socket->flush;
        my $h = $this->preferences;
        foreach( sort keys %$h )
                { $p .= sprintf("%s <|> %s\n",$_,$h->{$_}); }
        $p .= " <|> CLIENT\n";
        $this->socket->print($p);
        my $msg = Net::Nessus::Message->new('socket' => $this->socket,
                                           'sender' => 'SERVER',
                                           'type' => 'PREFERENCES_ERRORS');
        }

sub __connect
        {
        my $this = shift;
	my $sock = undef;
	if( $this->ssl )
		{
        	# $IO::Socket::SSL::DEBUG = $this->{debug};
        	$sock = IO::Socket::SSL->new(
                        PeerAddr        => $this->host,
                        PeerPort        => $this->port,
                        SSL_version     => $this->ssl_version,
                        Timeout         => $this->timeout
                        )
		or $this->set_error(1,sprintf("Connect to %s failed. (%s)",$this->hostport,&IO::Socket::SSL::errstr()));	
		}
	else
		{
		$sock = IO::Socket::INET->new(
                        PeerAddr        => $this->host,
                        PeerPort        => $this->port,
                        Timeout         => $this->timeout
                        )
                or $this->set_error(2,sprintf("Connect to %s failed. ($!)",$this->hostport));      
                }
        $this->socket($sock) if($sock);
        return($this->code);
        }

sub ShowHOLE
        {
        my ($this,$msg) = @_;
        my $key = '_holes';
        push(@{$this->{$key}},$msg);
        }
sub ShowINFO
        {
        my ($this,$msg) = @_;
        my $key = '_info';
        push(@{$this->{$key}},$msg);
        }

sub total_holes
        {
        my $this = shift;
        my $key = '_holes';
        my $a = $this->{$key};
        return( scalar @$a);
        }
sub total_info
        {
        my $this = shift;
        my $key = '_info';
        my $a = $this->{$key};
        return(scalar @$a);
        }
sub holes
        {
        my $this = shift;
        my $key = '_holes';
        my $a = $this->{$key};
        return($a);
        }
sub info
        {
        my $this = shift;
        my $key = '_info';
        my $a = $this->{$key};
        return($a);
        }
sub info_list
        {
        my $this = shift;
        return(@{$this->info});
        }
sub hole_list
        {
        my $this = shift;
        return(@{$this->holes});
        }
sub holes2tmpl
        {
        my $this = shift;
        return(nessus2tmpl($this->holes));
        }
sub infos2tmpl
        {
        my $this = shift;
        return(nessus2tmpl($this->info));
        }

sub nessus2tmpl
        {
        my $list = shift;
        my $array = [];
        foreach( @$list )
                {
                my $msg = $_;
                push(@$array,
                        {
                        port            => $msg->Port,
                        host            => $msg->Host,
                        description     => $msg->Description,
                        service         => $msg->Service(),
                        proto           => $msg->Proto,
                        scanid          => $msg->ScanID,
                        });
                }
        return($array);
        }

sub ntp_fast
        {
        my $this = shift;
        return(sprintf("%s< fast_login >\n",$this->ntp_proto));
        }
sub ntp_version
        {
        my $this = shift;
        my $key = 'ntp_version';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

sub ntp_proto
        {
        my $this = shift;
        return(sprintf("< NTP/%s >",$this->ntp_version));
        }



sub attack
        {
        my ($this,$host) = @_;
	my $start = time;
        $this->setprefs;
        my @hosts = ( $host );
        my $status = $this->Attack(@hosts);
	$this->duration(time - $start);
        }
sub user
        {
        my $this = shift;
        my $key = 'user';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub password
        {
        my $this = shift;
        my $key = 'password';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub hostport
	{
	my $this = shift;
	return($this->host . ':' . $this->port);
	}
sub host
        {
        my $this = shift;
        my $key = 'host';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub port
        {
        my $this = shift;
        my $key = 'port';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

sub ssl
        {
        my $this = shift;
        my $key = 'ssl';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

# Note: Net::Nessus::Message is expecting $this->{socket} to be there
sub socket
        {
        my $this = shift;
        my $key = 'socket';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

sub ssl_version
        {
        my $this = shift;
        my $key = 'ssl_version';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub timeout
                {
        my $this = shift;
        my $key = 'timeout';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub cfg
        {
        my $this = shift;
        my $key = '_cfg';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub section
        {
        my $this = shift;
        my $key = '_section';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

sub duration
        {
        my $this = shift;
	my $key = '_duration';
	$this->{$key} = shift if( @_ );
        return($this->{$key});
        }



sub ok
        {
        my $this = shift;
        $this->error(shift) if( @_ );
        return($this->code(0));
        }

sub set_error
        {
        my ($this,$code,$msg) = @_;
        $this->error($msg);
        return($this->code($code));
        }


sub code
        {
        my $this = shift;
        my $key = '_code';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }
sub error
        {
        my $this = shift;
        my $key = '_error';
        $this->{$key} = shift if( @_ );
        return($this->{$key});
        }

# Fixes the GLOB reference when SSL.pm shuts down, recent?
sub DESTROY { $_[0]->socket->close if( $_[0]->socket ); }











	

		




# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Nessus::ScanLite - This module uses NTP 1.2 fast over SSL to perform nessus attacks on given host(s).

=head1 SYNOPSIS

   use Net::Nessus::ScanLite;
   my $nessus = Net::Nessus::ScanLite->new(
                                host            => "some.host.net"
                                port            => 1234,
				ssl		=> 1,
				);
   
   $nessus->preferences( { host_expansion => 'none', safe_checks => 'yes', checks_read_timeout => 1 });
   $nessus->plugin_set("10835;10861;11808;11921;11790");

  my $addr = "10.0.0.1";
  if( $nessus->login() )
        {
        $nessus->attack($addr);
        printf("Total info's = %d\n",$nessus->total_info);
        foreach( $nessus->info_list )
                {
                my $info = $_;
                printf("Info:\nID: %s\nPort: %s\nDessc: %s\n",
                        $info->ScanID,
                        $info->Port,
                        $info->Description);
                }
        printf("Total hole's = %d\n",$nessus->total_holes);
        foreach( $nessus->hole_list )
                {
                my $info = $_;
                printf("Info:\nID: %s\nPort: %s\nDessc: %s\n",
                        $info->ScanID,
                        $info->Port,
                        $info->Description);
                }

        }
   else
        {
        die("Nessus login failed %d: %s\n",$nessus->code,$nessus->error);
        }



=head1 DESCRIPTION

This module is primarily designed to run single host nessus attacks over a secure ssl connection.
Because is uses the nessus NTP 1.2 protocol's "fast_login" option, it can be used in real
time applications such as NetReg.

=head1 CONSTRUCTOR

=over 4

=item new ( [ OPTIONS ] )

Creates a new B<Net::Nessus::ScanLite> object. 
OPTIONS are a list of key-value pairs, valid options are : 

=over 4

=item host

Host running  nessusd daemon.

=item port

Port that the nessusd daemon is listning to.

=item ssl

Turn on/off using ssl to connect to nessusd.
(Default: 1)

=item user

Admin user setup using nessus rules.

=item password

Password for the admin account.

=item ntp_proto

NTP protocol version to use when connecting.
(Default: 1.2)

=item preferences

A hash ref of valid nessus preferences such as those in nessusd.conf.
 Example:  preferences     => { plugin_set => "10835", safe_checks => 'no' }

=item timeout

Timeout passed to L<IO::Socket> when connecting the remote server.
(Default: 3)


=item cfg ( PATH | REF )

This can be a path to an ini config file or a L<Config::IniFiles> object.

=over 4

Example: new( Cfg => "/path/to/inifile" );

Example: my $ini = Config::IniFiles->new( -file => "/path/to/inifile" );
         new( Cfg => $ini );

=back

=over 4



=head1 METHODS


=over 4

=item login( [ USER, PASSWORD ] )

Performs a nessus fast login using a given or preset user/password pair.
Resurns 1 upon success, sets  L<code> and L<error> methods.

=item attack( IP, [,IP] )

Performs a nessus attack on a given hostname or ip address.
Sets  L<code> and L<error> methods.

=item plugin_set( SCALAR )

Sets the plugin set for the  L<attack> method to use.
Example: $nessus->plugin_set("10835;10861;11808;11921;11790");

=item preferences( HASH )

Sets the preferences sent to the nessesd daemon. Useful to override defaults.
Example: $nessus->preferences( { host_expansion => 'none', safe_checks => 'yes', checks_read_timeout => 1 });

=item ssl( [ BOOLEAN ] )

Tells the class to use ssl or not. 0 = off, 1 = on.
(Default: 1)
Only tested using TLSV1 see L<ssl_version> to change this.

=item host ( [ HOSTNAME | IP ] )

Points the class at the server running the nessus daemon.

=item port ( [ PORT ] )

Points the class at the port the nessus daemon is listning to.
(Default: 1241 )

=item user ( [ NAME ] )

Name of the account you set up using B<nessus-adduser>

=item password ( [ PWD ] )

Password assigned to the account above.

=item ntp_version ( [ VER ] )

NTP version sent at login time. This can change results so use with care.
(Default: 1.2)

=item ssl_version ( [ VER ] )

Version of ssl nessusd is using. I've not done much with this passed directly to IO::Socket::SSL::SSL_version

=item socket ( [ GLOB ] )

Returns or sets the current IO::Socket handle.

=item timeout ( [ VALUE ] )

Timeout sent to  IO::Socket;
(Default: 3)

=item total_holes
	
Returns the number of HOLES found in the scan.

=item total_info
        
Returns the number of INFO found in the scan.

=item holes

Returns a reference to an array of L<Net::Nessus::Message::HOLE> objects.

=item info

Sane as hole but holds info.

=item hole_list

Returns an array of  L<Net::Nessus::Message::HOLE> objects.

=item info_list

Returns an array of  L<Net::Nessus::Message::INFO> objects.

=item holes2tmpl

Returns an array hash results suitable for use with an L<HTML::Template> object.

The following keys are seeded for each L<Net::Nessus::Message> objects;

port
host
description
service
proto
scanid


=item infos2tmpl

Sane as holes2tmpl but holds info.



=item code

Returns the error code from last operation, non zero means error.

=item error

Returns an error message.

=item hostport

Returns the "host:port" of the server your connected to.


=item cfg

The path or handle of the L<Config::IniFiles> configuration file if used.

=item section ( [ SECT ] )

Sets or gets the section in the ini file to get the nessus host/login infomation.
(Default: nessus)

=item pref_section ( [ SECT ] )

Sets or gets the section in the ini file to get the nessus preferences.
(Default: preferences)

=item ini_default ( [ SECT ] )

Sets or gets the section in the ini file to use as default in case it can't find something.
(Default: defaults)

=back 

=head1 PREREQUISITES

Note that this module has been tested using nessusd (Nessus) 2.0.9 for SunOS. 

=head1 TODO

Perhaps configuration from a .nessusrc. Could be gnarly.

=head1 ACKNOWLEDGEMENTS

This class relies heavily on work done by Jochen Wiedmann's L<Net::Nessus> bundle.


=head1 SEE ALSO

L<IO::Socket::SSL> L<Config::IniFiles> L<Net::Nessus::Client> L<Net::Nessus::Message>

=head1 AUTHOR

John Ballem, E<lt>jpb@brown.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by John Ballem

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
