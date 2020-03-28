# -*- perl -*-
##----------------------------------------------------------------------------
## Telegram API - ~/lib/Net/API/Telegram.pm
## Version 0.6
## Copyright(c) 2020 Jacques Deguest
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/05/29
## Modified 2020/03/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::Telegram;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
	use HTTP::Daemon;
	use HTTP::Daemon::SSL;
	use File::Temp;
	use File::Spec;
	use File::Basename ();
	use IO::File;
	use Data::UUID;
	use JSON;
	use Encode ();
	use TryCatch;
	use File::Map;
	use Class::Struct qw( struct );
	use Devel::StackTrace;
	use Time::HiRes;
	use DateTime;
	use DateTime::TimeZone;
	use Scalar::Util;
	use POSIX qw( :sys_wait_h );
	use Net::IP ();
	use Errno qw( EINTR );
	use LWP::UserAgent;
	use HTTP::Headers;
	use HTTP::Request;
	use HTTP::Request::Common;
	use HTTP::Response;
	## We load Net::API::Telegram::Update because we test the existence of its methods for the setup of handlers
	use Net::API::Telegram::Update;
	use Devel::Confess;
    our( $VERSION ) = '0.6';
	use constant TELEGRAM_BASE_API_URI => 'https://api.telegram.org/bot';
	use constant TELEGRAM_DL_FILE_URI => 'https://api.telegram.org/file/bot';
	## We do not use the port 80 or 880 by default, because they are commonly used for other things
	use constant DEFAULT_PORT => 8443;
	## 50Mb
	use constant FILE_MAX_SIZE => 52428800;
};

{
	our $DEBUG   	= 0;
	our $VERBOSE 	= 0;
	our $ERROR		= '';
	## our $BROWSER	= 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:52.0) Gecko/20100101 Firefox/52.0';
	our $BROWSER	= 'Net::API::Telegram_Bot/' . $VERSION;
	our $TYPE2CLASS =
	{
	'message'	=> 'Net::API::Telegram::Message',
	'update'	=> 'Net::API::Telegram::Update',
	};

	struct Net::API::Telegram::Error => 
	{
	'type'		=> '$',
	'code'		=> '$',
	'message'	=> '$',
	'file'		=> '$',
	'line'		=> '$',
	'package'	=> '$',
	'sub'		=> '$',
	#'trace'		=> 'Devel::StackTrace',
	'trace'		=> '$',
	'retry_after' => '$',
	};
	our $CHILDREN = {};
	## Flag set by sig handler
	our $TIME_TO_DIE = 0;
}

sub init
{
	my $self = shift( @_ );
	my $token;
	$token = shift( @_ ) if( ( scalar( @_ ) % 2 ) );
	$self->{ 'token' }		= $token;
	$self->{ 'webhook' }	= 0;
	$self->{ 'host' }		= '';
	$self->{ 'port' }		= DEFAULT_PORT;
	$self->{ 'external_ssl' }  = 0;
	$self->{ 'external_host' } = '';
	$self->{ 'external_port' } = '';
	$self->{ 'external_path' } = '';
	$self->{ 'encode_with_json' } = 1;
	$self->{ 'cookie_file' } = '';
	$self->{ 'browser' }	= $BROWSER;
	$self->{ 'timeout' }	= 5;
	$self->{ 'use_ssl' }	= 0;
	$self->{ 'ssl_key' }	= '';
	$self->{ 'ssl_cert' }	= '';
	$self->{ 'max_connections' } = 1;
	$self->{ 'logging' }	= 0;
	$self->{ 'log_file' }	= '';
	$self->{ 'debug_log_file' }	= '';
	## Default timeout to 10 seconds
	$self->{ 'timeout' }	= 10;
	## A URI object representing the url at which the webhook can be accessed
	$self->{ 'webhook_uri' }	= '';
	## When receiving message from Telegram either on the webhook or through the getUpdates() method
	## if this is on, it will only accept messages older than our start time
	$self->{ 'skip_past_messages' } = 1;
	## Time to wait between each getUpdates() polling call
	$self->{ 'poll_interval' } = 10;
	## If true, temporary files will be removed
	$self->{ 'cleanup_temp' } = 1;
	$self->{ 'authorised_ips' } = [];
	$self->{temp_dir} = File::Spec->tmpdir;
	## Json configuration file
	$self->{conf_file} = '';
	$self->SUPER::init( @_ );
	$self->{conf_data} = {};
	if( $self->{conf_file} )
	{
		my $json = $self->conf_file( $self->{conf_file} );
		$self->{token} = $json->{token} if( !$self->{token} );
	}
	$self->debug_log_file( $self->{debug_log_file} ) if( $self->{debug_log_file} );
	$self->port( $self->{port} ) if( $self->{port} );
	$self->{ 'ug' } 		= Data::UUID->new;
	$self->{ 'json' }		= JSON->new->allow_nonref;
	$self->{ '_log_io' }	= '';
	$self->{ '_handlers' }	= {};
	$self->{ '_auth_ips' }	= [];
	$self->{ 'start_time' }	= '';
	## A boolean value that is being checked when getUpdates polling is in service.
	## This is set to true by stop()
	$self->{ '_stop_polling' } = 0;
	$self->{ '_stop_daemon' }  = 0;
	## Used to keep track of the parent pid, which in turn is used to know if it is a child process that triggered the cleanup procedure
	## Since when forking the information is hard copied into the child process, this is registered before fork happens
	$self->{ 'pid' }		= '';
	return( $self->error( "No Telegram authorisation token was provided" ) ) if( !$self->{token} );
	$self->{ 'api_uri' } = URI->new( TELEGRAM_BASE_API_URI . $self->{token} );
	## https://api.telegram.org/file/bot<token>/<file_path>
	$self->{ 'dl_uri' } = URI->new( TELEGRAM_DL_FILE_URI . $self->{token} );
	$self->{ 'offset' } = 0;
	$self->{ 'http_request' } = '';
	$self->{ 'http_response' } = '';
	$self->authorised_ips( $self->{authorised_ips} ) if( $self->{authorised_ips} && ref( $self->{authorised_ips} ) eq 'ARRAY' );
	## Customisation
	$self->message( 3, "Initialising webhook..." ) if( $self->{webhook} );
	$self->webhook( $self->{webhook} );
	return( $self );
}

sub agent
{
	my $self = shift( @_ );
	my $cookie_file = $self->cookie_file;
	my $browser = $self->browser;
	my $timeout = $self->{timeout} || 3;
	my $ua = LWP::UserAgent->new(
		agent => $browser,
		#sleep => '1..3',
		timeout		=> $timeout,
	);
	$ua->default_header( 'Content_Type' => 'multipart/form-data' );
	$ua->cookie_jar({ file => $cookie_file }) if( $cookie_file );
	return( $ua );
}

sub api_uri { return( shift->_set_get( 'api_uri', @_ ) ); }

sub authorised_ips
{
	my $self = shift( @_ );
	$self->{_auth_ips} = [] if( ref( $self->{_auth_ips} ) ne 'ARRAY' );
	my $ips = $self->{_auth_ips};
	if( @_ )
	{
		my $err = [];
		local $check = sub
		{
			my $raw = shift( @_ );
			my $ip;
			if( Scalar::Util::blessed( $raw ) && $raw->isa( 'Net::IP' ) )
			{
				$ip = $raw;
			}
			else
			{
				$ip = Net::IP->new( $raw ) || do
				{
					warn( "Warning only: IP '$raw' is not valid: ", Net::IP->Error, "\n" );
					push( @$err, sprintf( "IP '$raw' is not valid: %s", Net::IP->Error ) );
					return( '' );
				};
			}
			$self->messagef( 3, "IP block provided has %d IP addresses, starts with %s and ends with %s", $ip->size, $ip->ip, $ip->last_ip );
			foreach my $existing_ip ( @$ips )
			{
				## We found an existing ip same as the one we are adding, so we skip
				## If we are given a block that has some overlapping elements, we go ahead and add it
				## because it would become complicated and risky to only take the ips that do not overalp in the given block
				if( $ip->overlaps( $existing_ip ) == $Net::IP::IP_IDENTICAL )
				{
					return( '' );
				}
			}
			return( $ip );
		};
		
		ARG_RECEIVED: foreach my $this ( @_ )
		{
			if( ref( $this ) eq 'ARRAY' )
			{
				RAW_IPS: foreach my $raw ( @$this )
				{
					if( my $new_ip = $check->( $raw ) )
					{
						push( @$ips, $new_ip );
					}
				}
			}
			## a scalar
			elsif( !ref( $this ) )
			{
				if( my $new_ip = $check->( $this ) )
				{
					push( @$ips, $new_ip );
				}
			}
			else
			{
				warn( "Illegal argument provided '$this'. I was expecting an array of string or array reference and each value being a string or a Net::IP object\n" );
				next ARG_RECEIVED;
			}
		}
		if( scalar( @$err ) )
		{
			warn( sprintf( "Warning only: the following ip do not seem valid and were skipped: %s\n", join( ', ', @$err ) ) );
		}
	}
	return( $ips );
}

sub browser { return( shift->_set_get_scalar( 'browser', @_ ) ); }

sub cleanup
{
	my $self = shift( @_ );
    my( $pack, $file, $line ) = caller;
    $self->message( 3, "Called from package $pack in file $file at line $line" );
	$self->message( 3, "Cleaning up call from pid $$..." );
	$self->message( 3, "This is", ( $$ == $self->{pid} ? '' : ' not' ), " the parent process with pid $$." );
	## Wrap it up within 5 seconds max
	alarm( 5 );
	eval
	{
		local $SIG{ 'ALRM' } = sub{ die( "Timeout\n" ); };
		$self->stop;
	};
	alarm( 0 );
	if( $@ =~ /timeout/i )
	{
		$self->message( 1, "Timeout when cleaning up before exiting." );
	}
	return( $self );
}

sub conf_file
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $file = shift( @_ );
		if( !-e( $file ) )
		{
			return( $self->error( "Configuration file $file does not exist." ) );
		}
		elsif( -z( $file ) )
		{
			return( $self->error( "Configuration file $file is empty." ) );
		}
		my $fh = IO::File->new( "<$file" ) || return( $self->error( "Unable to open configuration file $file: $!" ) );
		$fh->binmode( ':utf8' );
		my $data = join( '', $fh->getlines );
		$fh->close;
		try
		{
			my $json = JSON->new->relaxed->decode( $data );
			$self->{conf_data} = $json;
			$self->{conf_file} = $file;
		}
		catch( $e )
		{
			return( $self->error( "An error occured while json decoding configuration file $file: $e" ) );
		}
	}
	return( $self->{conf_data} );
}

sub cookie_file { return( shift->_set_get_scalar( 'cookie_file', @_ ) ); }

sub data2json
{
	my $self = shift( @_ );
	my $data = shift( @_ );
	my $unescape = shift( @_ );
	return( $self->error( "No data provided to decode into json." ) ) if( !length( $data ) );
	if( $unescape )
	{
		$data =~ s/\\\\r\\\\n/\n/gs;
		$data =~ s/^\"|\"$//gs;
		$data =~ s/\"\[|\]\"//gs;
	}
	my $json;
	try
	{
		$json = $self->json->decode( $data );
	}
	catch( $e )
	{
		$self->message( 3, "An error occured while trying to decode json: $e" );
		my $tmpdir = $self->temp_dir;
		my $file = File::Temp::mktemp( "$tmpdir/json-XXXXXXX" );
		$file .= '.js';
		my $io = IO::File->new( ">$file" ) || return( $self->error( "Unable to write to file $file: $!" ) );
		$io->binmode( ":utf8" );
		$io->autoflush( 1 );
		$io->print( $data ) || return( $self->error( "Unable to write data to json file $file: $!" ) );
		$io->close;
		chmod( 0666, $file );
		return( $self->error( sprintf( "An error occured while attempting to parse %d bytes of data into json: $e\nFailed raw data was saved in file $file", length( $data ) ) ) );
	}
	return( $json );
}

sub debug_log_file
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $file = shift( @_ );
		return( $self->error( "Debug log file \"$file\" exists, but is not writable. Please check permissions." ) ) if( -e( $file ) && !-w( $file ) );
		my $fh = IO::File->new( ">>$file" ) || return( $self->error( "Unable to open debug log file \"$file\" in append mode: $!" ) );
		## print( STDERR ref( $self ), "::debug_log_file() opened log file \"$file\" in append mode with io $fh\n" );
		$fh->binmode( ':utf8' );
		$fh->autoflush( 1 );
		$self->log_io( $fh );
		$self->{debug_log_file} = $file;
	}
	return( $self->{debug_log_file} );
}

sub download_uri { return( shift->_set_get_uri( 'dl_uri', @_ ) ); }

sub generate_uuid
{
	return( shift->{ug}->create_str );
}

sub handler
{
	my $self = shift( @_ );
	my $handlers = $self->{ '_handlers' };
	if( @_ )
	{
		if( scalar( @_ ) == 1 )
		{
			my $name = shift( @_ );
			return( $self->error( "Handler $name is not a recognised handler." ) ) if( !Net::API::Telegram::Update->can( $name ) );
			return( $handlers->{ $name } );
		}
		elsif( scalar( @_ ) % 2 )
		{
			return( $self->error( sprintf( "Wrong number of parameters (%d) provided to set handlers.", scalar( @_ ) ) ) );
		}
		else
		{
			my $args = { @_ };
			foreach my $name ( keys( %$args ) )
			{
				return( $self->error( "Handler provided for $name is not a subroutine reference. Use something like \&some_routine or sub{ 'some code here' } as handler." ) ) if( ref( $args->{ $name } ) ne 'CODE' );
				$handlers->{ $name } = $args->{ $name };
			}
		}
	}
	return( $handlers );
}

sub json { return( shift->_set_get_object( 'json', 'JSON', @_ ) ); }

sub launch_daemon
{
	my $self = shift( @_ );
	my( $pack, $file, $line ) = caller;
	$self->message( 3, "Called from package $pack in file $file at line $line" );
	my $params = 
	{
		LocalPort => $self->{port} || DEFAULT_PORT,
		ReuseAddr => 1,
	};
	$params->{LocalAddr} = $self->{host} if( length( $self->{host} ) );
	$params->{Debug} = $self->debug;
	#$params->{LocalAddr} ||= 'localhost';
	my $httpd;
	if( $self->{use_ssl} )
	{
		$self->message( 3, "Launching the HTTP ssl daemon with parameters ", sub{ $self->dumper( $params ) } );
		return( $self->error( "No ssl key specified." ) ) if( !$self->{ssl_key} );
		return( $self->error( "No ssl certificate specified." ) ) if( !$self->{ssl_cert} );
		return( $self->error( "SSL key specified $self->{ssl_key} does not exist." ) ) if( !-e( $self->{ssl_key} ) );
		return( $self->error( "SSL certificate specified $self->{ssl_cert} does not exist." ) ) if( !-e( $self->{ssl_cert} ) );
		return( $self->error( "SSL key specified $self->{ssl_key} is not readable." ) ) if( !-e( $self->{ssl_key} ) );
		return( $self->error( "SSL certificate specified $self->{ssl_cert} is not readable." ) ) if( !-e( $self->{ssl_cert} ) );
		$params->{SSL_key_file} = $self->{ssl_key};
		$params->{SSL_cert_file} = $self->{ssl_cert};
		$httpd = HTTP::Daemon::SSL->new( %$params ) || return( $self->error( "Could not launch the HTTP daemon: $!" ) );
	}
	else
	{
		$self->message( 3, "Launching the HTTP daemon with parameters ", sub{ $self->dumper( $params ) } );
		$httpd = HTTP::Daemon->new( %$params ) || return( $self->error( "Could not launch the HTTP daemon: $!" ) );
		#$httpd = HTTP::Daemon->new( %$params ) || return( $self->error( "Could not launch the HTTP daemon: $!" ) );
	}
	$self->{httpd} = $httpd;
}

sub log 
{
	my $self = shift( @_ );
	if( $_[0] =~ /^\d{1,2}$/ )
	{
		if( $_[0] < $self->{debug} )
		{
			return;
		}
		## Make sure to remove this arguement
		else
		{
			shift( @_ );
		}
	}
    my @msg  = @_;
    # $self->message( 1, @msg ) if( -t( STDIN ) );
    my( $pack, $file, $line ) = caller;
    $self->message( 3, "Called from package $pack in file $file at line $line" );
    my @time = localtime();
    my $tz = DateTime::TimeZone->new( 'name' => 'local' );
    my $dt = DateTime->from_epoch( epoch => time(), time_zone => $tz->name );
    my $stamp = $dt->strftime( '[%Y/%m/%d %H:%M:%S]' );

    if( Scalar::Util::blessed( $msg[0] ) && $msg[0]->isa( 'Net::API::Telegram::Message' ) ) 
    {
    	my $msg = $msg[0];
        my $name = $msg->chat->title
                   || $msg->chat->username
                   || ( $msg->from ? join( ' ', $msg->from->first_name, $msg->from->last_name ) : 'unknown' );

        if( $self->{logging} && ( $self->{log_file} || $self->{_log_io} ) ) 
        {
        	my $log_io;
        	if( $self->{_log_io} )
        	{
        		$log_io = $self->{_log_io};
        	}
        	else
        	{
        		$log_io = $self->{_log_io} = IO::File->new( ">>$self->{log_file}" ) || return( $self->error( "Unable to open log file $self->{log_file} in append mode: $!" ) );
        		$log_io->binmode( ':utf8' );
        	}
        	$log_io->printf( "${stamp}: %s\n", $msg->text ) || return( $self->error( "Unable to print to log file $self->{log_file}: $!" ) );
        }
        $stamp .= "<$name> " if( $msg->chat->title );
        $self->messagef( 1, "${stamp}: %s", $msg->text );
    } 
    else 
    {
    	my $msg = join( '', @_ );
        $self->message( 1, "${stamp}: $msg" );
    }
    return( $self );
}

sub port
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		if( $v !~ /^(?:443|80|88|8443)$/ )
		{
			return( $self->error( "Illegal port number. Acceptable port numbers are: 443, 80, 88 or 8443. See https://core.telegram.org/bots/api#setwebhook for more information." ) );
		}
		$self->{port} = $v;
	}
	return( $self->{port} );
}

sub query
{
	my $self = shift( @_ );
	my $opts = shift( @_ );
	return( $self->error( "Parameter provided ($opts) is not a hash reference" ) ) if( ref( $opts ) ne 'HASH' );
	my( $uri, $headers, $data, $req, $resp );
	if( $opts->{uri} )
	{
		$uri = URI->new( $opts->{uri} );
	}
	elsif( $opts->{method} )
	{
		$uri = URI->new( $self->api_uri . "/$opts->{method}" );
	}
	if( !$opts->{headers} )
	{
		$headers = HTTP::Headers->new;
	}
	else
	{
		$headers = $opts->{headers};
	}
	$data = $opts->{data} if( length( $opts->{data} ) );
	
	if( $data->{certificate} )
	{
		my( $baseName, $cert );
		## Or possibly application/x-pem-file ?
		my $type = 'application/x-x509-ca-cert';
		if( Scalar::Util::blessed( $data->{certificate} ) )
		{
			my $obj = $data->{certificate};
			return( $self->error( "File object is not an Net::API::Telegram::InputFile object." ) ) if( !$obj->isa( 'Net::API::Telegram::InputFile' ) );
			$baseName = $obj->filename || 'certificate.pem';
			$cert = $obj->content;
		}
		elsif( -f( $data->{certificate} ) )
		{
			$baseName = File::Basename::basename( $data->{certificate} );
			$cert = $self->_load_file( $data->{certificate} ) || return( $self->error( "Unable to load the ssl certificate $data->{certificate}" ) );
		}
		else
		{
			return( $self->error( "Certificate was provided as parameter, but I am clueless about what do with it. It is not a file nor a Net::API::Telegram::InputFile object." ) );
		}
		$data->{certificate} = [ undef(), $baseName, 'Content-Type' => $type, 'Content' => $cert ];
		$req = $opts->{request} = HTTP::Request::Common::POST( $uri, 'Content-Type' => 'form-data', 'Content' => $data );
	}
	elsif( !$opts->{request} )
	{
		if( $self->{encode_with_json} )
		{
			$self->message( 3, "Encapsulating query using json payload" );
			my $payload = $self->json->utf8->encode( $data );
			$self->message( 3, "Payload is now: $payload" );
			$headers->header( 'Content-Type' => 'application/json; charset=utf-8' );
			$req = HTTP::Request->new( 'POST', $uri, $headers, $payload );
		}
		else
		{
			my $u = URI->new( $self->api_uri );
			$u->query_form( $data );
			$req = HTTP::Request->new( 'POST', $uri, $headers, $u->query );
		}
	}
	else
	{
		$req = $opts->{request};
	}
	#print( STDERR ref( $self ), "::query(): stopping here for debug\n" );
	#exit( 0 );
	
	if( !length( $req->header( 'Content-Type' ) ) )
	{
		if( $opts->{encode_with_json} || $self->encode_with_json )
		{
			$req->header( 'Content-Type' => 'application/json' );
		}
		else
		{
			$req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
		}
	}
	$req->header( 'Accept' => 'application/json' );
	$self->message( 3, "Post request is: ", $req->as_string );
	my $agent = $self->agent;
	try
	{
        $resp = $agent->request( $req );
        $self->{ 'http_request' } = $req;
        $self->{ 'http_response' } = $resp;
        ## if( $resp->code == 200 ) 
        if( $resp->is_success )
        {
        	$self->message( 3, "Request successful, decoding its content" );
            my $hash = $self->json->utf8->decode( $resp->decoded_content );
            $self->message( 3, "Returning $hash: ", sub{ $self->dumper( $hash ) } );
            return( $hash );
        }
        else 
        {
        	$self->messagef( 3, "Request failed with error %s", $resp->message );
            if( $resp->header( 'Content_Type' ) =~ m{text/html} ) 
            {
                return( $sef->error({
                    code    => $resp->code,
                    type    => $resp->message,
                    message => $resp->message
                }) );
            }
            else 
            {
                my $hash = $self->json->utf8->decode( $resp->decoded_content );
                $self->message( 3, "Error returned by Telegram is: ", sub{ $self->dumper( $hash ) } );
                $self->message( 3, "Creating error from Telegram error $hash->{description}" );
                $hash->{message} = delete( $hash->{description} );
                $hash->{code} = delete( $hash->{error_code} );
                return( $self->error( $hash->{ 'error' } // $hash ) );
            }
        }
	}
	catch
	{
		$self->message( 3, "Returning error $_" );
        return( $self->error({
			'type' => "Could not decode HTTP response: $_", 
			$resp
				? ( 'message' => $resp->status_line . ' - ' . $resp->content )
				: (),
        }) );
	};
}

sub start 
{
    my $self = shift( @_ );
    my $httpd = $self->{httpd};
    my $json = $self->{json};
    
	local $reaper = sub
	{
		local $!;
		my $child;
		my $waitedpid;
		##while( ( $waitedpid = waitpid( -1, WNOHANG ) ) > 0 && WIFEXITED( $? ) )
		while( ( $waitedpid = waitpid( -1, WNOHANG ) ) > 0 )
		{
			if( my $start = $CHILDREN->{ $waitedpid } )
			{
				my $interval = Time::HiRes::tv_interval( $start );
				delete( $CHILDREN->{ $waitedpid } );
				my( $user, $system, $cuser, $csystem ) = times();
				$self->log( "Child $waitedpid ending", ($? ? " with exit $?" : ''), " with user time $user and system time $system. It took $interval seconds." );
			}
			else
			{
				$self->log( "Reaped $waitedpid" . ($? ? " with exit $?" : '') );
			}
		}
		## loathe sysV
		$SIG{ 'CHLD' } = $reaper;
		return;
	};
	local $SIG{ 'CHLD' } = $reaper;
	
    local $SIG{ 'INT' } = sub
    {
		my $sig = @_;
		$self->message( 3, "Called with signal $sig" );
    	$self->cleanup;
    	exit( 0 );
    };
    local $SIG{ 'TERM' } = $SIG{ 'INT' };
    local $SIG{ 'ABRT' } = $SIG{ 'INT' };
    local $SIG{ 'QUIT' } = $SIG{ 'INT' };
    local $SIG{ '__DIE__' } = sub
    {
		my( $pack, $file, $line ) = caller;
		$self->message( 3, "Fatal error triggered from package $pack in file $file at line $line" );
		$self->error( join( '', @_  ) );
		my $trace = $self->error->trace;
    	$self->log( "Fatal error, terminating. ", @_, "\n$trace\n" );
    	$TIME_TO_DIE++;
    	$self->cleanup;
    	exit( 1 );
    };
	my $start_time = [Time::HiRes::gettimeofday()];
    my $tz = DateTime::TimeZone->new( 'name' => 'local' );
	my $start = $self->{start_time} = DateTime->from_epoch(
		epoch => $start_time->[0],
		time_zone => $tz->name,
	);
	my $check_messages_after;
	if( Scalar::Util::blessed( $self->{skip_past_messages} ) )
	{
		$check_messages_after = $self->{skip_past_messages};
	}
	elsif( $self->{skip_past_messages} < 0 )
	{
		$check_messages_after = $start->clone->subtract( seconds => abs( $self->{skip_past_messages} ) );
		$self->message( 3, "Will check messages only from $check_messages_after onward" );
	}
	my $handlers = $self->{ '_handlers' };
	
	my $out = IO::File->new;
	my $err = IO::File->new;
	my $in = IO::File->new;
	$out->fdopen( fileno( STDOUT ), 'w' );
	$out->binmode( ':utf8' );
	$out->autoflush( 1 );
	$err->fdopen( fileno( STDERR ), 'w' );
	$err->binmode( ':utf8' );
	$err->autoflush( 1 );
	$in->fdopen( fileno( STDIN ), 'r' );
	$in->binmode( ':utf8' );
	my $log_io = $self->{_log_io};
    if( $self->{webhook} )
    {
    	$self->message( 3, "Starting the daemon using webhook" );
    	return( $self->error( "HTTP daemon object is gone!" ) ) if( !$httpd );
    	#my $uri = URI->new( ( $self->{use_ssl} ? 'https' : 'http' ) . '://' . $self->{host} );
    	my $uri = URI->new( $httpd->url );
    	$uri->scheme( 'https' ) if( $self->{use_ssl} || $self->{external_ssl} );
    	$self->{host} = $uri->host;
    	if( $self->{external_host} )
    	{
    		$uri->host( $self->{external_host} );
    	}
    	if( $self->{external_port} )
    	{
    		$uri->port( $self->{external_port} );
    	}
    	elsif( $self->port )
    	{
			$uri->port( $self->port );
    	}
    	$self->message( 3, "Webhook path is: $self->{webhook_path}" );
    	$uri->path( ( $self->{external_path} ? $self->{external_path} : '' ) . $self->{webhook_path} );
    	$self->{webhook_uri} = $uri;
    	$self->{pid} = $$;
    	$self->message( 3, "Accepting webhooks connections on port $self->{port} with uri $uri from pid $$" );
    	my $params = 
    	{
    		url => $uri,
    		## Simultaneous connections. Since this is not threaded, we accept only one
    		max_connections => ( $self->{max_connections} || 1 ),
    	};
    	if( $self->{use_ssl} && $self->{ssl_cert} )
    	{
    		$params->{certificate} = $self->{ssl_cert};
    	}
    	## Inform Telegram of our bot webhook url
    	$self->setWebhook( $params ) || return( $self->error( "Unable to set the webhook with Telegram: ", $self->error ) );
    	## For additional security, we should check the remote ip
    	## Telegram webhook documentation tells us their requests originate from a subnet from either 149.154.160.0/20 or 91.108.4.0/22 and on ports 443, 80, 88, or 8443
    	## https://core.telegram.org/bots/webhooks
        ## while( my $client = $httpd->accept ) 
        my $client;
        my $loopback = Net::IP->new( '127.0.0.1' );
        while( !$self->{_stop_daemon} && !$TIME_TO_DIE )
        {
        	## Set when we receive signals
        	## last if( $self->{_stop_daemon} );
        	$client = $httpd->accept || do
			{
				$self->log( "Unable to accept queries on tcp port $self->{port}" );
				## https://www.perlmonks.org/bare/?node_id=244384
				next if( $! == EINTR );
				warn( "Error on accept: $!\n" );
				next;
			};
			## XXX Temporary
			# $client->debug( 3 );
        	
			$client->autoflush( 1 );
			my $pid = POSIX::getpid();
			if( !defined( $pid = fork() ) )
			{
				$self->log( "Cannot fork child process: $!" );
			}
			## Parent process
			elsif( $pid )
			{
				$self->log( "Received an incoming connection, forking to $pid" );
				$CHILDREN->{ $pid } = [Time::HiRes::gettimeofday()];
				$pid = POSIX::getpid();
				$client->close();
				waitpid( $pid, 0 );
				sleep( 0.1 );
			}
			## Child process == 0
			else
			{
				## Close STDIN, STDOUT and STDERR
				$in->close;
				$out->close;
				$err->close;
				$log_io->close if( $log_io );
				## Then, re-open them
				$out->fdopen( fileno( STDOUT ), 'w' );
				$out->binmode( ':utf8' );
				$out->autoflush( 1 );
				$err->fdopen( fileno( STDERR ), 'w' );
				$err->binmode( ':utf8' );
				$err->autoflush( 1 );
				$in->fdopen( fileno( STDIN ), 'r' );
				$in->binmode( ':utf8' );
				
				$httpd->close();
				$pid = POSIX::getpid();
				$self->log( "Child answering on socket with pid $pid" );
				## Processing here
				my $req;
				my $ip_check = 0;
				REQUEST: while( $req = $client->get_request ) 
				{
					my $remote_addr;
					if( $req->header( 'X-Forwarded-For' ) )
					{
						$remote_addr = Net::IP->new( $req->header( 'X-Forwarded-For' ) );
					}
					else
					{
						$remote_addr = Net::IP->new( Socket::inet_ntoa( $client->peeraddr ) );
					}
					$self->message( 3, "Connection received from $remote_addr" );
					## First Check the IP
					if( !$ip_check )
					{
						$ip_check++;
						$self->messagef( 3, "Remote address is: '%s'.", $remote_addr->ip );
						my $ok_ips = $self->authorised_ips;
						if( scalar( @$ok_ips ) )
						{
							$ip_is_authorised = 0;
							if( $remote_addr->overlaps( $loopback ) == $Net::IP::IP_IDENTICAL )
							{
								$ip_is_authorised++;
							}
							else
							{
								IP_BLOCK_CHECKED: foreach my $block ( @$ok_ips )
								{
									## We found an overlap, we're good.
									if( !( $remote_addr->overlaps( $block ) == $Net::IP::IP_NO_OVERLAP ) )
									{
										$ip_is_authorised++, last IP_BLOCK_CHECKED;
									}
								}
							}
						}
					}
					
					my $uri = $req->uri;
					if( $uri->path ne $self->{webhook_path} )
					{
						$client->send_response( HTTP::Response->new( 404 ) );
						last;
					}
					## We need to send back a reply to Telegram quicly or Telegram will issue a "read timeout" error and will re-send the message
					$self->message( 3, "Returning http code 200 to Telegram." );
					$client->send_response( HTTP::Response->new( 200 ) );
					my $res = $self->data2json( $req->decoded_content );
					$client->close();
					
					$self->message( 3, "Data received: ", sub{ $self->dumper( $res ) } );
					my $upd = $self->_response_to_object( 'Net::API::Telegram::Update', $res ) || do
					{
						$self->message( 1, "Error trying to instantiate object Net::API::Telegram::Update: ", $self->error->message );
						$self->error( "Could not create a Net::API::Telegram::Update with following data: " . $self->dumper( $res ) );
						$client->send_response( HTTP::Response->new( 500 ) );
						next;
					};
					## Get the Webhook information for possible error
					my $info = $self->getWebhookInfo;
					$self->messagef( 3, "WebHookInfo returned:\nallowed_updates: %s\nhas_custom_certificate: %s\nlast_error_date: %s\nlast_error_message: %s\nmax_connections: %s\npending_update_count: %s\nurl: %s", $info->allowed_updates, $info->has_custom_certificate, $info->last_error_date, $info->last_error_message, $info->max_connections, $info->pending_update_count, $info->url );
					if( length( $info->last_error_message ) )
					{
						my $err_time = $info->last_error_date;
						$self->error( sprintf( "Warning only: webhook error occured on $err_time: %s", $info->last_error_message ) );
					}
					my $msg_epoch = $upd->message->date if( $upd->message );
					if( !$self->{skip_past_messages} || 
						( $check_messages_after && $msg_epoch && $msg_epoch > $check_messages_after ) || 
						( $msg_epoch && $msg_epoch > $start ) )
					{
						my $msg = $upd->message;
						$self->log( $msg );
						## return( $msg );
						$self->message( 3, "Checking for handler." );
						foreach my $k ( keys( %$res ) )
						{
							next if( !exists( $handlers->{ $k } ) );
							my $v = $upd->$k;
							my $code = $handlers->{ $k };
							next if( ref( $code ) ne 'CODE' );
							$self->message( 3, "Calling handler $k" );
							alarm( $self->{timeout} );
							eval
							{
								local $SIG{ 'ALRM' } = sub
								{
									## Gateway Timeout
									die( "Timeout\n" );
								};
								$code->({
									'request' => $req,
									'payload' => $res,
									## Overall update object
									'update' => $upd,
									## $v could be empty. This is to the handler to decide what to do with it
									'object' => $v,
									## We send also our Telegram object so the handler can call us like $t->sendMessage
									'tg' => $self,
								});
							};
							alarm( 0 );
							if( $@ =~ /timeout/i )
							{
								## $client->send_response( HTTP::Response->new( 504 ) );
								$self->message( 3, "Timeout while calling handler $k" );
								warn( "Timeout while calling handler $k\n" );
								next REQUEST;
							}
							elsif( $@ )
							{
								$self->error( $@ );
								my $trace = $self->error->trace;
								$self->message( 3, "Error while calling handler $k: $trace" );
								## $client->send_response( HTTP::Response->new( 500 ) );
								warn( "Error while calling handler $k: $@\n" );
								next REQUEST;
							}
						}
						## $client->send_response( HTTP::Response->new( 200 ) );
					} 
					else 
					{
						## $client->send_response( HTTP::Response->new( 200 ) );
						next;
					}
				}
				undef( $client );
				exit( 0 );
			}
        }
		my $interval = Time::HiRes::tv_interval( $start_time );
		my( $user, $system, $cuser, $csystem ) = CORE::times();
		$self->message( 3, "Webhook http daemon took user time $user and system time $system. It took $interval seconds." );
    }
    else 
    {
    	$self->message( 3, "Starting the polling." );
    	my $start_time = [Time::HiRes::gettimeofday()];
    	my $poll_interval = ( $self->{poll_interval} || 10 );
        POLL: while( 1 ) 
        {
        	last if( $self->{_stop_polling} );
        	$self->message( 3, "Fetching update with office $self->{offset}" );
            my $all = $self->getUpdates( offset => $self->{offset} ) || do
            {
            	$self->error( "Error while trying to get update: ", $self->error->message );
            	sleep( 1 );
            	next;
            };
#             my $results = $res->{result};
#             $self->message( 3, "Result received frm Telegram: ", sub{ $self->dumper( $results ) } );
#             my $all = $self->_response_array_to_object( 'Net::API::Telegram::Update', $results ) || do
#             {
#             	$self->error( "Unable to get the objects for data received: ", sub{ $self->dumper( $results ) } );
#             	next;
#             };
            $self->messagef( 3, "Found %d updates received.", scalar( @$all ) );
            REQUEST: foreach my $upd ( @$all )
            {
                $self->{offset} = $upd->update_id + 1;
                my $msg_epoch = $upd->message->date if( $upd->message );
            	$self->messagef( 3, "Checking update id %s with time $msg_epoch", $upd->update_id );
                if( !$self->{skip_past_messages} || 
                	( $check_messages_after && $msg_epoch && $msg_epoch > $check_messages_after ) || 
                	( $msg_epoch && $msg_epoch > $start ) )
                {
                    my $msg = $upd->message;
                    $self->log( $msg );
                    ## return( $msg );
                    $self->message( 3, "Checking for handler." );
                    foreach my $k ( keys( %$res ) )
                    {
                    	next if( !exists( $handlers->{ $k } ) );
                    	my $v = $upd->$k;
                    	my $code = $handlers->{ $k };
                    	next if( ref( $code ) ne 'CODE' );
                    	$self->message( 3, "Calling handler $k" );
                    	alarm( $self->{timeout} );
                    	eval
                    	{
                    		local $SIG{ 'ALRM' } = sub
                    		{
                    			## Gateway Timeout
                    			die( "Timeout\n" );
                    		};
							$code->({
								'request' => $req,
								'payload' => $res,
								## Overall update object
								'update' => $upd,
								## $v could be empty. This is to the handler to decide what to do with it
								'object' => $v,
							});
                    	};
                    	alarm( 0 );
                    	if( $@ =~ /timeout/i )
                    	{
                    		next REQUEST;
                    	}
                    	elsif( $@ )
                    	{
                    		$self->message( 3, "Error while calling handler: $@" );
                    		next REQUEST;
                    	}
                    }
                } 
            }
            ## Sleep a few before doing next query
            $self->message( 3, "Sleeping $poll_interval seconds." );
            sleep( $poll_interval );
        }
		my $interval = Time::HiRes::tv_interval( $start_time );
		my( $user, $system, $cuser, $csystem ) = CORE::times();
		$self->message( 3, "Polling took user time $user and system time $system. It took $interval seconds." );
    }
    return;
}

sub stop
{
	my $self = shift( @_ );
	if( $self->{webhook} )
	{
		foreach my $kid ( keys( %$CHILDREN ) ) 
		{
			## reap them
			$self->log( "Failed to reap child pid: $kid" ) unless( kill(+ 9, $kid ) );
		}
		$self->deleteWebhook || return( $self->error( "Unable to remove webhook: ", $self->error ) );
		$self->{_stop_daemon}++;
	}
	else
	{
		$self->{_stop_polling}++;
	}
	return( $self );
}

sub temp_dir { return( shift->_set_get_scalar( 'temp_dir', @_ ) ); }

sub timeout
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		return( $self->error( "Invalid timeout value '$v'. I was expecting an integer or undefined" ) ) if( defined( $v ) && $v !~ /^\d+$/ );
		$v = 0 if( !defined( $v ) );
		$self->{timeout} = $v;
	}
	return( $self->{timeout} );
}

sub verbose { return( shift->_set_get( 'verbose', @_ ) ); }

sub webhook
{
	my $self = shift( @_ );
	if( @_ )
	{
		my $v = shift( @_ );
		$self->{webhook} = $v;
		if( $v )
		{
			$self->message( 3, "Launching daemon..." );
			$self->launch_daemon if( !$self->{ 'httpd' } );
			$self->{webhook_path} = '/' . lc( $self->generate_uuid );
		}
		else
		{
			undef( $self->{ 'httpd' } );
		}
	}
	return( $self->{webhook} );
}

## DO NOT REMOVE THIS LINE
## START DYNAMICALLY GENERATED METHODS
sub answerCallbackQuery
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter callback_query_id" ) ) if( !exists( $opts->{ 'callback_query_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'answerCallbackQuery',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method answerCallbackQuery: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub answerInlineQuery
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter inline_query_id" ) ) if( !exists( $opts->{ 'inline_query_id' } ) );
	return( $self->error( "Missing parameter results" ) ) if( !exists( $opts->{ 'results' } ) );
	return( $self->error( "Value provided for results is not an array reference." ) ) if( ref( $opts->{ 'results' } ) ne 'ARRAY' );
	return( $self->error( "Value provided is not an array of either of this objects: InlineQueryResult" ) ) if( !$self->_param_check_array_object( qr/^(?:Net::API::Telegram::InlineQueryResult)$/, @_ ) );
    $self->_load( [qw( Net::API::Telegram::InlineQueryResult )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'answerInlineQuery',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method answerInlineQuery: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub answerPreCheckoutQuery
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter ok" ) ) if( !exists( $opts->{ 'ok' } ) );
	return( $self->error( "Missing parameter pre_checkout_query_id" ) ) if( !exists( $opts->{ 'pre_checkout_query_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'answerPreCheckoutQuery',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method answerPreCheckoutQuery: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub answerShippingQuery
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter ok" ) ) if( !exists( $opts->{ 'ok' } ) );
	return( $self->error( "Value provided for shipping_options is not an array reference." ) ) if( length( $opts->{ 'shipping_options' } ) && ref( $opts->{ 'shipping_options' } ) ne 'ARRAY' );
	return( $self->error( "Value provided is not an array of either of this objects: ShippingOption" ) ) if( length( $opts->{ 'shipping_options' } ) && !$self->_param_check_array_object( qr/^(?:Net::API::Telegram::ShippingOption)$/, @_ ) );
	return( $self->error( "Missing parameter shipping_query_id" ) ) if( !exists( $opts->{ 'shipping_query_id' } ) );
    $self->_load( [qw( Net::API::Telegram::ShippingOption )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'answerShippingQuery',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method answerShippingQuery: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub createNewStickerSet
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter emojis" ) ) if( !exists( $opts->{ 'emojis' } ) );
	return( $self->error( "Value provided for mask_position is not a Net::API::Telegram::MaskPosition object." ) ) if( length( $opts->{ 'mask_position' } ) && ref( $opts->{ 'mask_position' } ) ne 'Net::API::Telegram::MaskPosition' );
	return( $self->error( "Missing parameter name" ) ) if( !exists( $opts->{ 'name' } ) );
	return( $self->error( "Missing parameter png_sticker" ) ) if( !exists( $opts->{ 'png_sticker' } ) );
	return( $self->error( "Value provided for png_sticker is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'png_sticker' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Missing parameter title" ) ) if( !exists( $opts->{ 'title' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
    $self->_load( [qw( Net::API::Telegram::MaskPosition Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'createNewStickerSet',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method createNewStickerSet: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub deleteChatPhoto
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'deleteChatPhoto',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method deleteChatPhoto: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub deleteChatStickerSet
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'deleteChatStickerSet',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method deleteChatStickerSet: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub deleteMessage
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter message_id" ) ) if( !exists( $opts->{ 'message_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'deleteMessage',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method deleteMessage: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub deleteStickerFromSet
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter sticker" ) ) if( !exists( $opts->{ 'sticker' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'deleteStickerFromSet',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method deleteStickerFromSet: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub deleteWebhook
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'deleteWebhook',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method deleteWebhook: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub editMessageCaption
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'editMessageCaption',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method editMessageCaption: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub editMessageLiveLocation
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter latitude" ) ) if( !exists( $opts->{ 'latitude' } ) );
	return( $self->error( "Missing parameter longitude" ) ) if( !exists( $opts->{ 'longitude' } ) );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'editMessageLiveLocation',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method editMessageLiveLocation: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub editMessageMedia
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter media" ) ) if( !exists( $opts->{ 'media' } ) );
	return( $self->error( "Value provided for media is not a Net::API::Telegram::InputMedia object." ) ) if( ref( $opts->{ 'media' } ) ne 'Net::API::Telegram::InputMedia' );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InputMedia Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'editMessageMedia',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method editMessageMedia: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub editMessageReplyMarkup
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'editMessageReplyMarkup',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method editMessageReplyMarkup: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub editMessageText
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
	return( $self->error( "Missing parameter text" ) ) if( !exists( $opts->{ 'text' } ) );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'editMessageText',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method editMessageText: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub exportChatInviteLink
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'exportChatInviteLink',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method exportChatInviteLink: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{result} );
	}
}

sub forwardMessage
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter from_chat_id" ) ) if( !exists( $opts->{ 'from_chat_id' } ) );
	return( $self->error( "Value provided for from_chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'from_chat_id' } ) );
	return( $self->error( "Missing parameter message_id" ) ) if( !exists( $opts->{ 'message_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'forwardMessage',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method forwardMessage: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getChat
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getChat',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getChat: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Chat', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Chat object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getChatAdministrators
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getChatAdministrators',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getChatAdministrators: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $arr = [];
		foreach my $h ( @{$hash->{result}} )
		{
			my $o = $self->_response_to_object( 'Net::API::Telegram::ChatMember', $h ) ||
			return( $self->error( "Unable to create an Net::API::Telegram::ChatMember object with this data returned: ", sub{ $self->dumper( $h ) } ) );
			push( @$arr, $o );
		}
		return( $arr );
	}
}

sub getChatMember
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getChatMember',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getChatMember: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::ChatMember', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::ChatMember object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getChatMembersCount
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getChatMembersCount',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getChatMembersCount: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{result} );
	}
}

sub getFile
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter file_id" ) ) if( !exists( $opts->{ 'file_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getFile',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getFile: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::File', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::File object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getGameHighScores
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getGameHighScores',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getGameHighScores: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $arr = [];
		foreach my $h ( @{$hash->{result}} )
		{
			my $o = $self->_response_to_object( 'Net::API::Telegram::GameHighScore', $h ) ||
			return( $self->error( "Unable to create an Net::API::Telegram::GameHighScore object with this data returned: ", sub{ $self->dumper( $h ) } ) );
			push( @$arr, $o );
		}
		return( $arr );
	}
}

sub getMe
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getMe',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getMe: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::User', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::User object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getStickerSet
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter name" ) ) if( !exists( $opts->{ 'name' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getStickerSet',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getStickerSet: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::StickerSet', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::StickerSet object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getUpdates
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Value provided for allowed_updates is not an array reference." ) ) if( length( $opts->{ 'allowed_updates' } ) && ref( $opts->{ 'allowed_updates' } ) ne 'ARRAY' );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getUpdates',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getUpdates: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $arr = [];
		foreach my $h ( @{$hash->{result}} )
		{
			my $o = $self->_response_to_object( 'Net::API::Telegram::Update', $h ) ||
			return( $self->error( "Unable to create an Net::API::Telegram::Update object with this data returned: ", sub{ $self->dumper( $h ) } ) );
			push( @$arr, $o );
		}
		return( $arr );
	}
}

sub getUserProfilePhotos
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getUserProfilePhotos',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getUserProfilePhotos: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::UserProfilePhotos', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::UserProfilePhotos object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub getWebhookInfo
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'getWebhookInfo',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method getWebhookInfo: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::WebhookInfo', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::WebhookInfo object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub kickChatMember
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'kickChatMember',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method kickChatMember: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub leaveChat
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'leaveChat',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method leaveChat: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub pinChatMessage
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter message_id" ) ) if( !exists( $opts->{ 'message_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'pinChatMessage',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method pinChatMessage: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub promoteChatMember
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'promoteChatMember',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method promoteChatMember: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub restrictChatMember
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter permissions" ) ) if( !exists( $opts->{ 'permissions' } ) );
	return( $self->error( "Value provided for permissions is not a Net::API::Telegram::ChatPermissions object." ) ) if( ref( $opts->{ 'permissions' } ) ne 'Net::API::Telegram::ChatPermissions' );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
    $self->_load( [qw( Net::API::Telegram::ChatPermissions )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'restrictChatMember',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method restrictChatMember: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub sendAnimation
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter animation" ) ) if( !exists( $opts->{ 'animation' } ) );
	return( $self->error( "Value provided for animation is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'animation' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Value provided for thumb is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( length( $opts->{ 'thumb' } ) && ref( $opts->{ 'thumb' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InputFile Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendAnimation',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendAnimation: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendAudio
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter audio" ) ) if( !exists( $opts->{ 'audio' } ) );
	return( $self->error( "Value provided for audio is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'audio' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Value provided for thumb is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( length( $opts->{ 'thumb' } ) && ref( $opts->{ 'thumb' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InputFile Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendAudio',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendAudio: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendChatAction
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter action" ) ) if( !exists( $opts->{ 'action' } ) );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendChatAction',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendChatAction: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub sendContact
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter first_name" ) ) if( !exists( $opts->{ 'first_name' } ) );
	return( $self->error( "Missing parameter phone_number" ) ) if( !exists( $opts->{ 'phone_number' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendContact',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendContact: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendDocument
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter document" ) ) if( !exists( $opts->{ 'document' } ) );
	return( $self->error( "Value provided for document is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'document' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Value provided for thumb is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( length( $opts->{ 'thumb' } ) && ref( $opts->{ 'thumb' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InputFile Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendDocument',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendDocument: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendGame
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter game_short_name" ) ) if( !exists( $opts->{ 'game_short_name' } ) );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendGame',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendGame: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendInvoice
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter currency" ) ) if( !exists( $opts->{ 'currency' } ) );
	return( $self->error( "Missing parameter description" ) ) if( !exists( $opts->{ 'description' } ) );
	return( $self->error( "Missing parameter payload" ) ) if( !exists( $opts->{ 'payload' } ) );
	return( $self->error( "Missing parameter prices" ) ) if( !exists( $opts->{ 'prices' } ) );
	return( $self->error( "Value provided for prices is not an array reference." ) ) if( ref( $opts->{ 'prices' } ) ne 'ARRAY' );
	return( $self->error( "Value provided is not an array of either of this objects: LabeledPrice" ) ) if( !$self->_param_check_array_object( qr/^(?:Net::API::Telegram::LabeledPrice)$/, @_ ) );
	return( $self->error( "Missing parameter provider_token" ) ) if( !exists( $opts->{ 'provider_token' } ) );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
	return( $self->error( "Missing parameter start_parameter" ) ) if( !exists( $opts->{ 'start_parameter' } ) );
	return( $self->error( "Missing parameter title" ) ) if( !exists( $opts->{ 'title' } ) );
    $self->_load( [qw( Net::API::Telegram::LabeledPrice Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendInvoice',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendInvoice: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendLocation
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter latitude" ) ) if( !exists( $opts->{ 'latitude' } ) );
	return( $self->error( "Missing parameter longitude" ) ) if( !exists( $opts->{ 'longitude' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendLocation',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendLocation: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendMediaGroup
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter media" ) ) if( !exists( $opts->{ 'media' } ) );
	return( $self->error( "Value provided for media is not an array reference." ) ) if( ref( $opts->{ 'media' } ) ne 'ARRAY' );
	return( $self->error( "Value provided is not an array of either of this objects: InputMediaPhoto, InputMediaVideo" ) ) if( !$self->_param_check_array_object( qr/^(?:Net::API::Telegram::InputMediaPhoto|Net::API::Telegram::InputMediaVideo)$/, @_ ) );
    $self->_load( [qw( Net::API::Telegram::InputMediaPhoto Net::API::Telegram::InputMediaVideo )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendMediaGroup',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendMediaGroup: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $arr = [];
		foreach my $h ( @{$hash->{result}} )
		{
			my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $h ) ||
			return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
			push( @$arr, $o );
		}
		return( $arr );
	}
}

sub sendMessage
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Missing parameter text" ) ) if( !exists( $opts->{ 'text' } ) );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendMessage',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendMessage: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendPhoto
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter photo" ) ) if( !exists( $opts->{ 'photo' } ) );
	return( $self->error( "Value provided for photo is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'photo' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
    $self->_load( [qw( Net::API::Telegram::InputFile Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendPhoto',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendPhoto: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendPoll
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter options" ) ) if( !exists( $opts->{ 'options' } ) );
	return( $self->error( "Value provided for options is not an array reference." ) ) if( ref( $opts->{ 'options' } ) ne 'ARRAY' );
	return( $self->error( "Missing parameter question" ) ) if( !exists( $opts->{ 'question' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendPoll',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendPoll: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendSticker
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Missing parameter sticker" ) ) if( !exists( $opts->{ 'sticker' } ) );
	return( $self->error( "Value provided for sticker is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'sticker' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendSticker',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendSticker: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendVenue
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter address" ) ) if( !exists( $opts->{ 'address' } ) );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter latitude" ) ) if( !exists( $opts->{ 'latitude' } ) );
	return( $self->error( "Missing parameter longitude" ) ) if( !exists( $opts->{ 'longitude' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Missing parameter title" ) ) if( !exists( $opts->{ 'title' } ) );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendVenue',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendVenue: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendVideo
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Value provided for thumb is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( length( $opts->{ 'thumb' } ) && ref( $opts->{ 'thumb' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Missing parameter video" ) ) if( !exists( $opts->{ 'video' } ) );
	return( $self->error( "Value provided for video is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'video' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendVideo',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendVideo: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendVideoNote
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Value provided for thumb is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( length( $opts->{ 'thumb' } ) && ref( $opts->{ 'thumb' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
	return( $self->error( "Missing parameter video_note" ) ) if( !exists( $opts->{ 'video_note' } ) );
	return( $self->error( "Value provided for video_note is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'video_note' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendVideoNote',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendVideoNote: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub sendVoice
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a valid object. I was expecting one of the following: InlineKeyboardMarkup, ReplyKeyboardMarkup, ReplyKeyboardRemove, ForceReply" ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) !~ /^(?:Net::API::Telegram::InlineKeyboardMarkup|Net::API::Telegram::ReplyKeyboardMarkup|Net::API::Telegram::ReplyKeyboardRemove|Net::API::Telegram::ForceReply)$/ );
	return( $self->error( "Missing parameter voice" ) ) if( !exists( $opts->{ 'voice' } ) );
	return( $self->error( "Value provided for voice is not a valid object. I was expecting one of the following: InputFile, String" ) ) if( ref( $opts->{ 'voice' } ) !~ /^(?:Net::API::Telegram::InputFile)$/ );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup Net::API::Telegram::ReplyKeyboardMarkup Net::API::Telegram::ReplyKeyboardRemove Net::API::Telegram::ForceReply Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'sendVoice',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method sendVoice: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) ||
		return( $self->error( "Unable to create an Net::API::Telegram::Message object with this data returned: ", sub{ $self->dumper( $h ) } ) );
		return( $o );
	}
}

sub setChatDescription
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setChatDescription',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setChatDescription: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setChatPermissions
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter permissions" ) ) if( !exists( $opts->{ 'permissions' } ) );
	return( $self->error( "Value provided for permissions is not a Net::API::Telegram::ChatPermissions object." ) ) if( ref( $opts->{ 'permissions' } ) ne 'Net::API::Telegram::ChatPermissions' );
    $self->_load( [qw( Net::API::Telegram::ChatPermissions )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setChatPermissions',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setChatPermissions: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setChatPhoto
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter photo" ) ) if( !exists( $opts->{ 'photo' } ) );
	return( $self->error( "Value provided for photo is not a Net::API::Telegram::InputFile object." ) ) if( ref( $opts->{ 'photo' } ) ne 'Net::API::Telegram::InputFile' );
    $self->_load( [qw( Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setChatPhoto',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setChatPhoto: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setChatStickerSet
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter sticker_set_name" ) ) if( !exists( $opts->{ 'sticker_set_name' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setChatStickerSet',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setChatStickerSet: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setChatTitle
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter title" ) ) if( !exists( $opts->{ 'title' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setChatTitle',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setChatTitle: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setGameScore
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter score" ) ) if( !exists( $opts->{ 'score' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setGameScore',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setGameScore: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setPassportDataErrors
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter errors" ) ) if( !exists( $opts->{ 'errors' } ) );
	return( $self->error( "Value provided for errors is not an array reference." ) ) if( ref( $opts->{ 'errors' } ) ne 'ARRAY' );
	return( $self->error( "Value provided is not an array of either of this objects: PassportElementError" ) ) if( !$self->_param_check_array_object( qr/^(?:Net::API::Telegram::PassportElementError)$/, @_ ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
    $self->_load( [qw( Net::API::Telegram::PassportElementError )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setPassportDataErrors',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setPassportDataErrors: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub setWebhook
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
    $opts->{certificate} = Net::API::Telegram::InputFile->new( $self->{ssl_cert} ) if( $opts->{certificate} && $self->{ssl_cert} );
	return( $self->error( "Value provided for allowed_updates is not an array reference." ) ) if( length( $opts->{ 'allowed_updates' } ) && ref( $opts->{ 'allowed_updates' } ) ne 'ARRAY' );
	return( $self->error( "Value provided for certificate is not a Net::API::Telegram::InputFile object." ) ) if( length( $opts->{ 'certificate' } ) && ref( $opts->{ 'certificate' } ) ne 'Net::API::Telegram::InputFile' );
	return( $self->error( "Missing parameter url" ) ) if( !exists( $opts->{ 'url' } ) );
    $self->_load( [qw( Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'setWebhook',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method setWebhook: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub stopMessageLiveLocation
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'stopMessageLiveLocation',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method stopMessageLiveLocation: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Message', $hash->{result} ) || 
		return( $self->error( "Error while getting an object out of hash for this message: ", $self->error ) );
		return( $o );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub stopPoll
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter message_id" ) ) if( !exists( $opts->{ 'message_id' } ) );
	return( $self->error( "Value provided for reply_markup is not a Net::API::Telegram::InlineKeyboardMarkup object." ) ) if( length( $opts->{ 'reply_markup' } ) && ref( $opts->{ 'reply_markup' } ) ne 'Net::API::Telegram::InlineKeyboardMarkup' );
    $self->_load( [qw( Net::API::Telegram::InlineKeyboardMarkup )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'stopPoll',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method stopPoll: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::Poll', $hash->{result} ) || 
		return( $self->error( "Error while getting a Poll object out of hash for this message: ", $self->error ) );
		return( $o );
	}
}

sub unbanChatMember
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'unbanChatMember',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method unbanChatMember: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub unpinChatMessage
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter chat_id" ) ) if( !exists( $opts->{ 'chat_id' } ) );
	return( $self->error( "Value provided for chat_id is not a valid value. I was expecting one of the following: Integer, String" ) ) if( !length( $opts->{ 'chat_id' } ) );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'unpinChatMessage',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method unpinChatMessage: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	else
	{
		return( $hash->{ok} );
	}
}

sub uploadStickerFile
{
	my $self = shift( @_ );
	my $opts = $self->_param2hash( @_ ) || return( undef() );
	return( $self->error( "Missing parameter png_sticker" ) ) if( !exists( $opts->{ 'png_sticker' } ) );
	return( $self->error( "Value provided for png_sticker is not a Net::API::Telegram::InputFile object." ) ) if( ref( $opts->{ 'png_sticker' } ) ne 'Net::API::Telegram::InputFile' );
	return( $self->error( "Missing parameter user_id" ) ) if( !exists( $opts->{ 'user_id' } ) );
    $self->_load( [qw( Net::API::Telegram::InputFile )] ) || return( undef() );
	my $form = $self->_options2form( $opts );
	my $hash = $self->query({
		'method' => 'uploadStickerFile',
		'data' => $form,
	}) || return( $self->error( "Unable to make post query for method uploadStickerFile: ", $self->error->message ) );
	if( my $t_error = $self->_has_telegram_error( $hash ) )
	{
		return( $self->error( $t_error ) );
	}
	elsif( $hash->{result} )
	{
		my $o = $self->_response_to_object( 'Net::API::Telegram::File', $hash->{result} ) || 
		return( $self->error( "Error while getting a File object out of hash for this message: ", $self->error ) );
		return( $o );
	}
}

## END DYNAMICALLY GENERATED METHODS

## Private methods
sub _encode_params
{
	my $self = shift( @_ );
    my $args = shift( @_ );
    if( $self->{ '_encode_with_json' } )
    {
    	return( $self->json->utf8->encode( $args ) );
    }
    my @components;
    foreach my $key ( keys( %$args ) )
    {
        my $ek    = URI::Escape::uri_escape( $key );
        my $value = $args->{ $key };
        my $pkg   = Scalar::Util::blessed( $value );
        if( $pkg && $pkg =~ /^AI::Net::Stripe/ && exists( $value->{ 'id' } ) )
        {
            push( @components, $ek . '=' . $value->{ 'id' } );
            next;
        }

        my $ref = ref( $value );
        if( $ref eq 'HASH' ) 
        {
        	foreach my $sk ( keys( %$value ) )
        	{
                my $sv = $value->{ $sk };
                ## don't think this PHP convention goes deeper
                next if( ref( $sv ) || !length( $sv ) );
                push( @components, sprintf( '%s[%s]=%s', $ek, URI::Escape::uri_escape( $sk ), URI::Escape::uri_escape_utf8( $sv ) ) );
            }
        } 
        elsif( $ref eq 'ARRAY' ) 
        {
            foreach my $sv ( @$value )
            {
            	## again, I think we can't go deeper
                next if( ref( $sv ) );
                push( @components, sprintf( '%s[]=%s', $ek, URI::Escape::uri_escape_utf8( $sv ) ) );
            }
        } 
        else 
        {
        	## JSON boolean stringification magic has been erased
            $value = ref( $value ) eq 'JSON::PP::Boolean'
              ? $value
                  ? 'true'
                  : 'false'
              : URI::Escape::uri_escape_utf8( $value );
            push( @components, "${ek}=${value}" );
        }
    }
    return( join( '&', @components ) );
}

sub _has_telegram_error
{
	my $self = shift( @_ );
	my $hash = shift( @_ ) || return( $self->error( "No hash reference was provided to check if it contains a Telegram api error." ) );
	## "The response contains a JSON object, which always has a Boolean field ‘ok’ and may have an optional String field ‘description’ with a human-readable description of the result. If ‘ok’ equals true, the request was successful and the result of the query can be found in the ‘result’ field.
	## In case of an unsuccessful request, ‘ok’ equals false and the error is explained in the ‘description’. An Integer ‘error_code’ field is also returned, but its contents are subject to change in the future. Some errors may also have an optional field ‘parameters’ of the type ResponseParameters, which can help to automatically handle the error."
	## https://core.telegram.org/bots/api#making-requests
	return if( !exists( $hash->{ok} ) );
	return if( $hash->{ok} );
	my $desc = $hash->{description};
	my $code = $hash->{error_code};
	my $o = Net::API::Telegram::Error->new;
	$o->message( $desc );
	$o->code( $code );
	if( exists( $hash->{parameters} ) && ref( $hash->{parameters} ) eq 'HASH' )
	{
		if( $hash->{parameters}->{retry_after} )
		{
			$desc .= ' ' if( length( $desc ) );
			$desc .= sprintf( 'Retry after %d seconds', $hash->{parameters}->{retry_after} );
			$o->message( $desc );
			$o->retry_after( $hash->{parameters}->{retry_after} );
		}
	}
	return( $o );
}

sub _instantiate
{
	my $self = shift( @_ );
	my $name = shift( @_ );
	return( $self->{ $name } ) if( exists( $self->{ $name } ) && Scalar::Util::blessed( $self->{ $name } ) );
	my $class = shift( @_ );
	my $this  = $class->new(
		'debug'		=> $self->debug,
		'verbose'	=> $self->verbose,
	) || return( $self->error( $class->error ) );
	$this->{ 'parent' } = $self;
	return( $this );
}

sub _load
{
	my $self = shift( @_ );
	my $arr  = shift( @_ );
	return( $self->error( "Parameter provided is not an array. I am expecting an array of package name like this [qw( Some::Thing Some::Else )]" ) ) if( ref( $arr ) ne 'ARRAY' );
	foreach my $pkg ( @$arr )
	{
		## eval( "require $pkg;" ) unless( defined( *{"${pkg}::"} ) );
		my $rc = eval{ $self->_load_class( $pkg ); };
		return( $self->error( "An error occured while trying to load the module $pkg: $@" ) ) if( $@ );
	}
	return( 1 );
}

sub _load_file
{
	my $self  = shift( @_ );
	my $fpath = shift( @_ ) || return( $self->error( "No file path to load into memory was provided" ) );
	return( $self->error( "File '$fpath' provided does not exist." ) ) if( !-e( $fpath ) );
	return( $self->error( "File '$fpath' provided is not readable." ) ) if( !-r( $fpath ) );
	return( $self->error( "File '$fpath' size of %d bytes exceeds maximum %d bytes" ) ) if( -s( $fpath ) > FILE_MAX_SIZE );
	my $data;
	File::Map::map_file( $data, $fpath );
	return( $data );
}

sub _make_error 
{
	my $self  = shift( @_ );
	my $args  = shift( @_ );
	if( !exists( $args->{ 'file' } ) || !exists( $args->{ 'line' } ) )
	{
		my( $pack, $file, $line ) = caller;
		my $sub  = ( caller( 1 ) )[ 3 ];
        my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
		@$args{ qw( package file line sub ) } = ( $pack, $file, $line, $sub2 );
	}
    ## my $o     = AI::Net::Stripe::Error->new( %$args );
    my $trace = Devel::StackTrace->new( ignore_package => __PACKAGE__ );
    $args->{ 'trace' } = $trace;
    return( $self->error( $args ) );
}

sub _options2form
{
	my $self = shift( @_ );
	my $opts = shift( @_ ) || return;
	return( $self->error( "Options hash reference provided ($opts) is not an hash reference" ) ) if( ref( $opts ) ne 'HASH' );
	my $form = {};
	my $opt_anti_loop = '_opt2form_anti_loop_' . time();
	local $crawl = sub
	{
		my $this = shift( @_ );
		## $self->message( 3, "\tChecking '$this'" );
		if( Scalar::Util::blessed( $this ) )
		{
			$this->debug( $self->debug ) if( ref( $this ) =~ /Net::API::Telegram::/ && $this->can( 'debug' ) );
			## $self->message( 3, "'$this' is a blessed object." );
			if( $this->can( 'as_hash' ) )
			{
				## $self->message( 3, "'$this' can do as_hash: ", sub{ $self->dumper( $this ) } );
				return( $this->as_hash( $opt_anti_loop ) );
			}
			elsif( overload::Overloaded( $this ) )
			{
				## $self->message( 3, "'$this' is overloaded. Returning '$this'." );
				return( "$this" );
			}
			elsif( $this->can( 'as_string' ) )
			{
				## $self->message( 3, "'$this' can do as_string()." );
				return( $this->as_string );
			}
			else
			{
				## $self->message( 3, "Clueless what to do with '$this'." );
				warn( "Warning: do not know what to do with this object '$this'. It does not support as_hash, as_string and is not overloaded.\n" );
			}
		}
		elsif( ref( $this ) eq 'HASH' )
		{
			my $ref = {};
			if( exists( $this->{ $opt_anti_loop } ) )
			{
				my @keys = grep( /^${opt_anti_loop}$/, keys( %$this ) );
				my $new = {};
				@$new{ @keys } = @$this{ @keys };
				return( $new );
			}
			foreach my $k ( keys( %$this ) )
			{
				$ref->{ $k } = $crawl->( $this->{ $k } );
			}
			return( $ref );
		}
		elsif( ref( $this ) eq 'ARRAY' )
		{
			my $arr = [];
			foreach my $v ( @$this )
			{
				my $res = $crawl->( $v );
				push( @$arr, $res ) if( length( $res ) );
			}
			return( $arr );
		}
		## Not an object, a hash, an array. It's got to be a scalar...
		else
		{
			## $self->message( 3, "\tReturning scalar '$this'." );
			return( $this );
		}
	};
	
	$self->message( 3, "Provided options data is: ", sub{ $self->dumper( $opts ) } );
	foreach my $k ( keys( %$opts ) )
	{
		if( length( $opts->{ $k } ) )
		{
			$form->{ $k } = $crawl->( $opts->{ $k } );
		}
	}
	$self->message( 3, "Resulting form data is: ", sub{ $self->dumper( $form ) } );
	return( $form );
}

sub _param2hash
{
	my $self = shift( @_ );
	my $opts = {};
	if( scalar( @_ ) )
	{
		if( ref( $_[0] ) eq 'HASH' )
		{
			$opts = shift( @_ );
		}
		elsif( !( scalar( @_ ) % 2 ) )
		{
			$opts = { @_ };
		}
		else
		{
			return( $self->error( "Uneven number of parameters. I was expecting a hash or a hash reference." ) );
		}
	}
	return( $opts );
}

sub _param_check_array_object
{
	my $self = shift( @_ );
	my $patt = shift( @_ ) || return( $self->error( "No pattern to check array of objects was provided." ) );
	my $arr  = shift( @_ ) || return( $self->error( "No array of objects was provided." ) );
	return( $self->error( "Pattern provided is not a pattern object. I was expecting something like qr/^(?:Some::Thing)\$/" ) ) if( ref( $patt ) ne 'Regexp' );
	return( $self->error( "Array provided ($arr) is not an array reference." ) ) if( ref( $arr ) ne 'ARRAY' );
	foreach my $o ( @$arr )
	{
		return( $self->error( "Object provided '", ref( $o ), ", ' is not a valid object matching pattern $patt" ) ) if( ref( $o ) !~ /$patt/ );
	}
	return( 1 );
}

sub _response_to_object
{
	my $self  = shift( @_ );
	my $class = shift( @_ );
	my $hash  = shift( @_ ) || return( $self->error( "No hash was provided" ) );
	return( $self->error( "Hash provided ($hash) is not a hash reference." ) ) if( $hash && ref( $hash ) ne 'HASH' );
	$self->message( 3, "Called for class $class with hash $hash" );
	$self->_load( [ $class ] ) || return( undef() );
	my $o;
	try
	{
		$o = $class->new( $self, $hash );
	}
	catch( $e )
	{
		return( $self->error( "Canot instantiate object for class $class: $e" ) );
	}
	$self->message( 3, "Returning object $o for class $class" );
	return( $o );
}

sub _response_array_to_object
{
	my $self  = shift( @_ );
	my $class = shift( @_ );
	my $arr   = shift( @_ ) || return( $self->error( "No array reference was provided" ) );
	return( $self->error( "Array provided ($arr) is not an array reference." ) ) if( $arr && ref( $arr ) ne 'ARRAY' );
	$self->message( 3, "Called for class $class with array $arr" );
	$self->_load( [ $class ] ) || return( undef() );
	my $all = [];
	foreach my $ref ( @$arr )
	{
		if( ref( $ref ) eq 'HASH' )
		{
			my $o;
			try
			{
				$o = $class->new( $self, $ref );
			}
			catch( $e )
			{
				return( $self->error( "Unable to instantiate an object of class $class: $e" ) );
			}
			push( @$all, $o );
		}
		else
		{
			$self->error( "Warning only: data provided to instaantiate object of class $class is not a hash reference" );
		}
	}
	return( $all );
}

# DESTROY
# {
# 	my $self = shift( @_ );
#     my( $pack, $file, $line ) = caller;
#     $self->message( 3, "Called from package $pack in file $file at line $line" );
# 	$self->message( 3, "Cleaning up call from pid $$..." );
# 	$self->message( 3, "Pid $$ is a child pid. We don't cleanup." ) if( exists( $CHILDREN->{ $$ } ) );
# 	$self->message( 3, "Current children pid registered are: ", join( ', ', sort( keys( %$CHILDREN ) ) ) );
# 	$self->cleanup unless( exists( $CHILDREN->{ $$ } ) );
# 	## Wrap it up within 5 seconds max
# 	alarm( 5 );
# 	eval
# 	{
# 		local $SIG{ 'ALRM' } = sub{ die( "Timeout\n" ); };
# 		$self->stop;
# 	};
# 	alarm( 0 );
# 	if( $@ =~ /timeout/i )
# 	{
# 		$self->message( 1, "Timeout when cleaning up before exiting." );
# 	}
# };

1;

__END__

=encoding utf-8

=head1 NAME

Net::API::Telegram - Telegram Bot Interface

=head1 SYNOPSIS

	my $t = Net::API::Telegram->new(
		debug => $DEBUG,
		webhook => 1,
		## This would contain a token property with the Telegram api token
		config_file => "./settings.json",
		## Since we are testing, we want to process even old messages
		skip_past_messages => -86400,
		# use_ssl => 1,
		# ssl_cert => $ssl_certificate,
		# ssl_key => $ssl_key,
		external_ssl  => 1,
 		external_path => 'tg',
 		external_host => 'www.higotonofukuin.org',
 		external_port => 443,
 		logging => 1,
 		log_file => $log_file,
 		debug_log_file => $debug_log_file,
 		error_handler => \&handleError,
	) || die( Net::API::Telegram->error->message, "\n" );
	
	## Declare some handlers
	$t->handler(
		message => \&processMessage,
	);
	$t->start || die( "Error starting: ", $t->error->message, "\n" );

=head1 VERSION

This is version 0.6

=head1 DESCRIPTION

L<Net::API::Telegram> is a powerful and yet simple interface to Telegram Bot api.

L<Net::API::Telegram> inherits from C<Module::Generic> and all its module excepted for C<Net::API::Telegram::Generic> and C<Net::API::Telegram::Number> are aut generated base don Telegram api online documentation.

=head1 CORE METHODS

=over 4

=item B<new>( [ TOKEN ], %PARAMETERS )

This initiate a L<Net::API::Telegram> object as an accessor to all the core methods and api methods.

It can take the following parameters:

=over 8

=item I<browser>

This is the name of the browser our http agent will take as identity when communicating with the Telegram api.

BY default, it looks like C<DEGUEST_Bot/0.1>

=item I<conf_file>

This is an optional configuration file in json format that contains properties. For example, it can contain the property I<token> to avoid passing it as argument.

=item I<cookie_file>

This takes a cookie file path. By default it is empty. The Telegram api does not send cookie, so it should not be needed.

=item I<debug>

Defaults to 0 (false). Can be set to any digit. The higher, the more debug output.

=item I<encode_with_json>

Can be true or false. Defaults to false.

If true, L<Net::API::Telegram> will encode data in json format and send it to the server rather than using the url-encoded format.

=item I<host>

This is the host to set up the webhook. It will be provided as part of the uri our L<HTTP::Daemon> server listens to. The path is randomly generated to ensure some level of security.

=item I<port>

This is the host to set up the webhook.

=item I<ssl_cert>

Pass to the ssl certificate. This is used to run the ssl http server and to be sent to Telegram.

This parameter is necessary only under ssl with the I<use_ssl>.

If the server is run on a host with certificate signed by a proper authority like Let's Encrypt, the certificate does not need to be sent to Telegram.

To create a ssl key and certificate, you can use the following command:

	openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/C=JP/ST=Tokyo/L=Tokyo/O=Deguest Pte. Ltd./OU=Org/CN=www.example.jp"

Ref: L<https://stackoverflow.com/questions/10175812/how-to-create-a-self-signed-certificate-with-openssl>

=item I<ssl_key>

Path to the ssl key. This is used to run the ssl http server.

This parameter is necessary only under ssl with the I<use_ssl>.

=item I<timeout>

The timeout in second when making http requests. It defaults to 5 seconds.

=item I<token>

This is a required item. It can be provided either the first parameter of the B<new>() method or as a hash parameter. Example:

	my $t = Net::API::Telegram->new( '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11', debug => 3, webhook => 1 );
	
	## or
	
	my $t = Net::API::Telegram->new( 'token' => '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11', debug => 3, webhook => 1 );

=item I<use_ssl>

Can be true or false. If true, the server launched to handle the webhook will run under ssl. Please note that Telegram only accepts webhooks that run under ssl.

=item I<verbose>

Defaults to 0 (false).

=item I<webhook>

Either true or false. If true, this will initiate the web token and automatically declare it to the Telegram server. It defaults to false.

=back

=item B<agent>()

It returns a L<LWP::UserAgent> object which is used to make http calls to Telegram api.

=item B<api_uri>()

This returns the uri of the api for our bot. It would be something like: L<https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11>

=item B<data2json>( JSON )

Given a json data this returns an equivalent structure in perl, so a hash reference.

=item B<debug>( TRUE | FALSE )

Set or get the debug value, which is an integer. 0 deactivate debug mode and a number greater than 0 activates it. The greater the number, the more debug output.

=item B<error>( ERROR )

Sets or get an error. When making calls to methods under this package and package children, if the return value is undef(), then it means an error has been set and can be retrieved with C<$t->error>

The error retrieved is a L<Net::API::Telegram::Error> object that has the following properties:

=over 8

=item I<type>

This is the type of error, if any. It could be empty.

=item I<code>

This is the error code using the http standard.

=item I<message>

This is the error message.

=item I<file>

The file from which the error came from.

=item I<line>

The line at which the error was triggered.

=item I<package>

The perl module name from which the error occurred.

=item I<sub>

The subroutine that triggered the error.

=item I<trace>

This is a Devel::StackTrace which can be stringified. This provides the full stack trace of the error.

=item I<retry_after>

This is optional, and represents the number of seconds to wait until the next attempt. This is provided as a response by the Telegram api.

=back

=item B<generate_uuid>()

This will generate a new uuid using L<Data::UUID>.

=item B<launch_daemon>()

This will prepare a new http daemon to listen for the webhook

=item B<port>( INTEGER )

This sets the port that will be used by L<HTTP::Daemon> to listen for webhooks.

The only acceptable ports, as per Telegram Bot API documentation, are: 443, 80, 88, 8443.

It returns the current value set, if any.

Ref: L<https://core.telegram.org/bots/api#setwebhook>

=item B<query>( { PARAMETERS } )

This takes an hash reference as parameters, and issues a http post request to Telegram api. If successful, it returns a hash reference of the data returned by Telegram api, otherwise it returns undef() upon an error.

=item B<start>()

This will start processing requests received by the bot.

If the I<webhook> option was set, this will start the http daemon, as prepared with the B<launch_daemon>() method.

Otherwise, this will probe indefinitely, in a loop, the Telegram server using the api method B<getUpdates>()

It will receive json data from Telegram in the form of a L<Net::API::Telegram::Update> object.

Ref: L<https://core.telegram.org/bots/api#update>

=item B<verbose>( [ TRUE | FALSE ] )

This sets or get the value of verbose.

=item B<webhook>( [ TRUE | FALSE ] )

This sets the boolean flag for the option I<webhook>. If set to true, this will call the B<launch_daemon>() method. It will also create a randomly generated path which can be retrieved using the B<webhook_path> method.

=item B<webhook_path>()

Returns the webhook path randomly generated. If webhook has not been activated this will return an empty string.

=back

=head1 API METHODS

=over 4

=item B<answerCallbackQuery>( %PARAMETERS )

Use this method to send answers to callback queries sent from inline keyboards. The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, True is returned.

Reference: L<https://core.telegram.org/bots/api#answercallbackquery>

This methods takes the following parameters:

=over 8

=item I<cache_time>

This parameter type is Integer and is optional.

The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support caching starting in version 3.14. Defaults to 0.

=item I<callback_query_id>

This parameter type is String and is required.

Unique identifier for the query to be answered

=item I<show_alert>

This parameter type is Boolean and is optional.

If true, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to false.

=item I<text>

This parameter type is String and is optional.

Text of the notification. If not specified, nothing will be shown to the user, 0-200 characters

=item I<url>

This parameter type is String and is optional.

URL that will be opened by the user's client. If you have created a Game and accepted the conditions via @Botfather, specify the URL that opens your game – note that this will only work if the query comes from a callback_game button.Otherwise, you may use links like t.me/your_bot?start=XXXX that open your bot with a parameter.

=back

=item B<answerInlineQuery>( %PARAMETERS )

Use this method to send answers to an inline query. On success, True is returned.No more than 50 results per query are allowed.

Reference: L<https://core.telegram.org/bots/api#answerinlinequery>

This methods takes the following parameters:

=over 8

=item I<cache_time>

This parameter type is Integer and is optional.

The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300.

=item I<inline_query_id>

This parameter type is String and is required.

Unique identifier for the answered query

=item I<is_personal>

This parameter type is Boolean and is optional.

Pass True, if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query

=item I<next_offset>

This parameter type is String and is optional.

Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don‘t support pagination. Offset length can’t exceed 64 bytes.

=item I<results>

This parameter type is an array of L<Net::API::Telegram::InlineQueryResult> and is required.
A JSON-serialized array of results for the inline query

=item I<switch_pm_parameter>

This parameter type is String and is optional.

Deep-linking parameter for the /start message sent to the bot when user presses the switch button. 1-64 characters, only A-Z, a-z, 0-9, _ and - are allowed.Example: An inline bot that sends YouTube videos can ask the user to connect the bot to their YouTube account to adapt search results accordingly. To do this, it displays a ‘Connect your YouTube account’ button above the results, or even before showing any. The user presses the button, switches to a private chat with the bot and, in doing so, passes a start parameter that instructs the bot to return an oauth link. Once done, the bot can offer a switch_inline button so that the user can easily return to the chat where they wanted to use the bot's inline capabilities.

=item I<switch_pm_text>

This parameter type is String and is optional.

If passed, clients will display a button with specified text that switches the user to a private chat with the bot and sends the bot a start message with the parameter switch_pm_parameter

=back

=item B<answerPreCheckoutQuery>( %PARAMETERS )

Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an Update with the field pre_checkout_query. Use this method to respond to such pre-checkout queries. On success, True is returned. Note: The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.

Reference: L<https://core.telegram.org/bots/api#answerprecheckoutquery>

This methods takes the following parameters:

=over 8

=item I<error_message>

This parameter type is String and is optional.

Required if ok is False. Error message in human readable form that explains the reason for failure to proceed with the checkout (e.g. "Sorry, somebody just bought the last of our amazing black T-shirts while you were busy filling out your payment details. Please choose a different color or garment!"). Telegram will display this message to the user.

=item I<ok>

This parameter type is Boolean and is required.

Specify True if everything is alright (goods are available, etc.) and the bot is ready to proceed with the order. Use False if there are any problems.

=item I<pre_checkout_query_id>

This parameter type is String and is required.

Unique identifier for the query to be answered

=back

=item B<answerShippingQuery>( %PARAMETERS )

If you sent an invoice requesting a shipping address and the parameter is_flexible was specified, the Bot API will send an Update with a shipping_query field to the bot. Use this method to reply to shipping queries. On success, True is returned.

Reference: L<https://core.telegram.org/bots/api#answershippingquery>

This methods takes the following parameters:

=over 8

=item I<error_message>

This parameter type is String and is optional.

Required if ok is False. Error message in human readable form that explains why it is impossible to complete the order (e.g. "Sorry, delivery to your desired address is unavailable'). Telegram will display this message to the user.

=item I<ok>

This parameter type is Boolean and is required.

Specify True if delivery to the specified address is possible and False if there are any problems (for example, if delivery to the specified address is not possible)

=item I<shipping_options>

This parameter type is an array of L<Net::API::Telegram::ShippingOption> and is optional.
Required if ok is True. A JSON-serialized array of available shipping options.

=item I<shipping_query_id>

This parameter type is String and is required.

Unique identifier for the query to be answered

=back

=item B<createNewStickerSet>( %PARAMETERS )

Use this method to create new sticker set owned by a user. The bot will be able to edit the created sticker set. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#createnewstickerset>

This methods takes the following parameters:

=over 8

=item I<contains_masks>

This parameter type is Boolean and is optional.

Pass True, if a set of mask stickers should be created

=item I<emojis>

This parameter type is String and is required.

One or more emoji corresponding to the sticker

=item I<mask_position>

This parameter type is an object L<Net::API::Telegram::MaskPosition> and is optional.
A JSON-serialized object for position where the mask should be placed on faces

=item I<name>

This parameter type is String and is required.

Short name of sticker set, to be used in t.me/addstickers/ URLs (e.g., animals). Can contain only english letters, digits and underscores. Must begin with a letter, can't contain consecutive underscores and must end in “_by_<bot username>”. <bot_username> is case insensitive. 1-64 characters.

=item I<png_sticker>

This parameter type is one of the following L<InputFile> or String and is required.
Png image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a file_id as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »

=item I<title>

This parameter type is String and is required.

Sticker set title, 1-64 characters

=item I<user_id>

This parameter type is Integer and is required.

User identifier of created sticker set owner

=back

=item B<deleteChatPhoto>( %PARAMETERS )

Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#deletechatphoto>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=back

=item B<deleteChatStickerSet>( %PARAMETERS )

Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#deletechatstickerset>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)

=back

=item B<deleteMessage>( %PARAMETERS )

Use this method to delete a message, including service messages, with the following limitations:- A message can only be deleted if it was sent less than 48 hours ago.- Bots can delete outgoing messages in private chats, groups, and supergroups.- Bots can delete incoming messages in private chats.- Bots granted can_post_messages permissions can delete outgoing messages in channels.- If the bot is an administrator of a group, it can delete any message there.- If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.Returns True on success.

Reference: L<https://core.telegram.org/bots/api#deletemessage>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<message_id>

This parameter type is Integer and is required.

Identifier of the message to delete

=back

=item B<deleteStickerFromSet>( %PARAMETERS )

Use this method to delete a sticker from a set created by the bot. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#deletestickerfromset>

This methods takes the following parameters:

=over 8

=item I<sticker>

This parameter type is String and is required.

File identifier of the sticker

=back

=item B<deleteWebhook>()

Use this method to remove webhook integration if you decide to switch back to getUpdates. Returns True on success. Requires no parameters.

Reference: L<https://core.telegram.org/bots/api#deletewebhook>

This method does not take any parameter.

=item B<editMessageCaption>( %PARAMETERS )

Use this method to edit captions of messages. On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#editmessagecaption>

This methods takes the following parameters:

=over 8

=item I<caption>

This parameter type is String and is optional.

New caption of the message

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message to edit

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for an inline keyboard.

=back

=item B<editMessageLiveLocation>( %PARAMETERS )

Use this method to edit live location messages. A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message was sent by the bot, the edited Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#editmessagelivelocation>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<latitude>

This parameter type is Float number and is required.

Latitude of new location

=item I<longitude>

This parameter type is Float number and is required.

Longitude of new location

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message to edit

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for a new inline keyboard.

=back

=item B<editMessageMedia>( %PARAMETERS )

Use this method to edit animation, audio, document, photo, or video messages. If a message is a part of a message album, then it can be edited only to a photo or a video. Otherwise, message type can be changed arbitrarily. When inline message is edited, new file can't be uploaded. Use previously uploaded file via its file_id or specify a URL. On success, if the edited message was sent by the bot, the edited Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#editmessagemedia>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<media>

This parameter type is an object L<Net::API::Telegram::InputMedia> and is required.
A JSON-serialized object for a new media content of the message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message to edit

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for a new inline keyboard.

=back

=item B<editMessageReplyMarkup>( %PARAMETERS )

Use this method to edit only the reply markup of messages. On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#editmessagereplymarkup>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message to edit

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for an inline keyboard.

=back

=item B<editMessageText>( %PARAMETERS )

Use this method to edit text and game messages. On success, if edited message is sent by the bot, the edited Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#editmessagetext>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_web_page_preview>

This parameter type is Boolean and is optional.

Disables link previews for links in this message

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message to edit

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for an inline keyboard.

=item I<text>

This parameter type is String and is required.

New text of the message

=back

=item B<exportChatInviteLink>( %PARAMETERS )

Use this method to generate a new invite link for a chat; any previously generated link is revoked. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns the new invite link as String on success.

Reference: L<https://core.telegram.org/bots/api#exportchatinvitelink>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=back

=item B<forwardMessage>( %PARAMETERS )

Use this method to forward messages of any kind. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#forwardmessage>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<from_chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the chat where the original message was sent (or channel username in the format @channelusername)

=item I<message_id>

This parameter type is Integer and is required.

Message identifier in the chat specified in from_chat_id

=back

=item B<getChat>( %PARAMETERS )

Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a Chat object on success.

Reference: L<https://core.telegram.org/bots/api#getchat>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)

=back

=item B<getChatAdministrators>( %PARAMETERS )

Use this method to get a list of administrators in a chat. On success, returns an Array of ChatMember objects that contains information about all chat administrators except other bots. If the chat is a group or a supergroup and no administrators were appointed, only the creator will be returned.

Reference: L<https://core.telegram.org/bots/api#getchatadministrators>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)

=back

=item B<getChatMember>( %PARAMETERS )

Use this method to get information about a member of a chat. Returns a ChatMember object on success.

Reference: L<https://core.telegram.org/bots/api#getchatmember>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<getChatMembersCount>( %PARAMETERS )

Use this method to get the number of members in a chat. Returns Int on success.

Reference: L<https://core.telegram.org/bots/api#getchatmemberscount>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)

=back

=item B<getFile>( %PARAMETERS )

Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>, where <file_path> is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again.

Reference: L<https://core.telegram.org/bots/api#getfile>

This methods takes the following parameters:

=over 8

=item I<file_id>

This parameter type is String and is required.

File identifier to get info about

=back

=item B<getGameHighScores>( %PARAMETERS )

Use this method to get data for high score tables. Will return the score of the specified user and several of his neighbors in a game. On success, returns an Array of GameHighScore objects.

Reference: L<https://core.telegram.org/bots/api#getgamehighscores>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Unique identifier for the target chat

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the sent message

=item I<user_id>

This parameter type is Integer and is required.

Target user id

=back

=item B<getMe>()

A simple method for testing your bot's auth token. Requires no parameters. Returns basic information about the bot in form of a User object.

Reference: L<https://core.telegram.org/bots/api#getme>

This method does not take any parameter.

=item B<getStickerSet>( %PARAMETERS )

Use this method to get a sticker set. On success, a StickerSet object is returned.

Reference: L<https://core.telegram.org/bots/api#getstickerset>

This methods takes the following parameters:

=over 8

=item I<name>

This parameter type is String and is required.

Name of the sticker set

=back

=item B<getUpdates>( %PARAMETERS )

Use this method to receive incoming updates using long polling (wiki). An Array of Update objects is returned.

Reference: L<https://core.telegram.org/bots/api#getupdates>

This methods takes the following parameters:

=over 8

=item I<allowed_updates>

This parameter type is an array of  and is optional.
List the types of updates you want your bot to receive. For example, specify [“message”, “edited_channel_post”, “callback_query”] to only receive updates of these types. See Update for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used.Please note that this parameter doesn't affect updates created before the call to the getUpdates, so unwanted updates may be received for a short period of time.

=item I<limit>

This parameter type is Integer and is optional.

Limits the number of updates to be retrieved. Values between 1—100 are accepted. Defaults to 100.

=item I<offset>

This parameter type is Integer and is optional.

Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned. An update is considered confirmed as soon as getUpdates is called with an offset higher than its update_id. The negative offset can be specified to retrieve updates starting from -offset update from the end of the updates queue. All previous updates will forgotten.

=item I<timeout>

This parameter type is Integer and is optional.

Timeout in seconds for long polling. Defaults to 0, i.e. usual short polling. Should be positive, short polling should be used for testing purposes only.

=back

=item B<getUserProfilePhotos>( %PARAMETERS )

Use this method to get a list of profile pictures for a user. Returns a UserProfilePhotos object.

Reference: L<https://core.telegram.org/bots/api#getuserprofilephotos>

This methods takes the following parameters:

=over 8

=item I<limit>

This parameter type is Integer and is optional.

Limits the number of photos to be retrieved. Values between 1—100 are accepted. Defaults to 100.

=item I<offset>

This parameter type is Integer and is optional.

Sequential number of the first photo to be returned. By default, all photos are returned.

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<getWebhookInfo>()

Use this method to get current webhook status. Requires no parameters. On success, returns a WebhookInfo object. If the bot is using getUpdates, will return an object with the url field empty.

Reference: L<https://core.telegram.org/bots/api#getwebhookinfo>

This method does not take any parameter.

=item B<kickChatMember>( %PARAMETERS )

Use this method to kick a user from a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the group on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#kickchatmember>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target group or username of the target supergroup or channel (in the format @channelusername)

=item I<until_date>

This parameter type is Integer and is optional.

Date when the user will be unbanned, unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<leaveChat>( %PARAMETERS )

Use this method for your bot to leave a group, supergroup or channel. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#leavechat>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)

=back

=item B<pinChatMessage>( %PARAMETERS )

Use this method to pin a message in a group, a supergroup, or a channel. The bot must be an administrator in the chat for this to work and must have the ‘can_pin_messages’ admin right in the supergroup or ‘can_edit_messages’ admin right in the channel. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#pinchatmessage>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Pass True, if it is not necessary to send a notification to all chat members about the new pinned message. Notifications are always disabled in channels.

=item I<message_id>

This parameter type is Integer and is required.

Identifier of a message to pin

=back

=item B<promoteChatMember>( %PARAMETERS )

Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Pass False for all boolean parameters to demote a user. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#promotechatmember>

This methods takes the following parameters:

=over 8

=item I<can_change_info>

This parameter type is Boolean and is optional.

Pass True, if the administrator can change chat title, photo and other settings

=item I<can_delete_messages>

This parameter type is Boolean and is optional.

Pass True, if the administrator can delete messages of other users

=item I<can_edit_messages>

This parameter type is Boolean and is optional.

Pass True, if the administrator can edit messages of other users and can pin messages, channels only

=item I<can_invite_users>

This parameter type is Boolean and is optional.

Pass True, if the administrator can invite new users to the chat

=item I<can_pin_messages>

This parameter type is Boolean and is optional.

Pass True, if the administrator can pin messages, supergroups only

=item I<can_post_messages>

This parameter type is Boolean and is optional.

Pass True, if the administrator can create channel posts, channels only

=item I<can_promote_members>

This parameter type is Boolean and is optional.

Pass True, if the administrator can add new administrators with a subset of his own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by him)

=item I<can_restrict_members>

This parameter type is Boolean and is optional.

Pass True, if the administrator can restrict, ban or unban chat members

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<restrictChatMember>( %PARAMETERS )

Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate admin rights. Pass True for all permissions to lift restrictions from a user. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#restrictchatmember>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)

=item I<permissions>

This parameter type is an object L<Net::API::Telegram::ChatPermissions> and is required.
New user permissions

=item I<until_date>

This parameter type is Integer and is optional.

Date when restrictions will be lifted for the user, unix time. If user is restricted for more than 366 days or less than 30 seconds from the current time, they are considered to be restricted forever

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<sendAnimation>( %PARAMETERS )

Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent Message is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.

Reference: L<https://core.telegram.org/bots/api#sendanimation>

This methods takes the following parameters:

=over 8

=item I<animation>

This parameter type is one of the following L<InputFile> or String and is required.
Animation to send. Pass a file_id as String to send an animation that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an animation from the Internet, or upload a new animation using multipart/form-data. More info on Sending Files »

=item I<caption>

This parameter type is String and is optional.

Animation caption (may also be used when resending animation by file_id), 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<duration>

This parameter type is Integer and is optional.

Duration of sent animation in seconds

=item I<height>

This parameter type is Integer and is optional.

Animation height

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<thumb>

This parameter type is one of the following L<InputFile> or String and is optional.
Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail‘s width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can’t be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More info on Sending Files »

=item I<width>

This parameter type is Integer and is optional.

Animation width

=back

=item B<sendAudio>( %PARAMETERS )

Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent Message is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.For sending voice messages, use the sendVoice method instead.

Reference: L<https://core.telegram.org/bots/api#sendaudio>

This methods takes the following parameters:

=over 8

=item I<audio>

This parameter type is one of the following L<InputFile> or String and is required.
Audio file to send. Pass a file_id as String to send an audio file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an audio file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »

=item I<caption>

This parameter type is String and is optional.

Audio caption, 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<duration>

This parameter type is Integer and is optional.

Duration of the audio in seconds

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<performer>

This parameter type is String and is optional.

Performer

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<thumb>

This parameter type is one of the following L<InputFile> or String and is optional.
Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail‘s width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can’t be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More info on Sending Files »

=item I<title>

This parameter type is String and is optional.

Track name

=back

=item B<sendChatAction>( %PARAMETERS )

Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success.We only recommend using this method when a response from the bot will take a noticeable amount of time to arrive.

Reference: L<https://core.telegram.org/bots/api#sendchataction>

This methods takes the following parameters:

=over 8

=item I<action>

This parameter type is String and is required.

Type of action to broadcast. Choose one, depending on what the user is about to receive: typing for text messages, upload_photo for photos, record_video or upload_video for videos, record_audio or upload_audio for audio files, upload_document for general files, find_location for location data, record_video_note or upload_video_note for video notes.

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=back

=item B<sendContact>( %PARAMETERS )

Use this method to send phone contacts. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendcontact>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<first_name>

This parameter type is String and is required.

Contact's first name

=item I<last_name>

This parameter type is String and is optional.

Contact's last name

=item I<phone_number>

This parameter type is String and is required.

Contact's phone number

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<vcard>

This parameter type is String and is optional.

Additional data about the contact in the form of a vCard, 0-2048 bytes

=back

=item B<sendDocument>( %PARAMETERS )

Use this method to send general files. On success, the sent Message is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.

Reference: L<https://core.telegram.org/bots/api#senddocument>

This methods takes the following parameters:

=over 8

=item I<caption>

This parameter type is String and is optional.

Document caption (may also be used when resending documents by file_id), 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<document>

This parameter type is one of the following L<InputFile> or String and is required.
File to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<thumb>

This parameter type is one of the following L<InputFile> or String and is optional.
Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail‘s width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can’t be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More info on Sending Files »

=back

=item B<sendGame>( %PARAMETERS )

Use this method to send a game. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendgame>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is Integer and is required.

Unique identifier for the target chat

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<game_short_name>

This parameter type is String and is required.

Short name of the game, serves as the unique identifier for the game. Set up your games via Botfather.

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for an inline keyboard. If empty, one ‘Play game_title’ button will be shown. If not empty, the first button must launch the game.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=back

=item B<sendInvoice>( %PARAMETERS )

Use this method to send invoices. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendinvoice>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is Integer and is required.

Unique identifier for the target private chat

=item I<currency>

This parameter type is String and is required.

Three-letter ISO 4217 currency code, see more on currencies

=item I<description>

This parameter type is String and is required.

Product description, 1-255 characters

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<is_flexible>

This parameter type is Boolean and is optional.

Pass True, if the final price depends on the shipping method

=item I<need_email>

This parameter type is Boolean and is optional.

Pass True, if you require the user's email address to complete the order

=item I<need_name>

This parameter type is Boolean and is optional.

Pass True, if you require the user's full name to complete the order

=item I<need_phone_number>

This parameter type is Boolean and is optional.

Pass True, if you require the user's phone number to complete the order

=item I<need_shipping_address>

This parameter type is Boolean and is optional.

Pass True, if you require the user's shipping address to complete the order

=item I<payload>

This parameter type is String and is required.

Bot-defined invoice payload, 1-128 bytes. This will not be displayed to the user, use for your internal processes.

=item I<photo_height>

This parameter type is Integer and is optional.

Photo height

=item I<photo_size>

This parameter type is Integer and is optional.

Photo size

=item I<photo_url>

This parameter type is String and is optional.

URL of the product photo for the invoice. Can be a photo of the goods or a marketing image for a service. People like it better when they see what they are paying for.

=item I<photo_width>

This parameter type is Integer and is optional.

Photo width

=item I<prices>

This parameter type is an array of L<Net::API::Telegram::LabeledPrice> and is required.
Price breakdown, a list of components (e.g. product price, tax, discount, delivery cost, delivery tax, bonus, etc.)

=item I<provider_data>

This parameter type is String and is optional.

JSON-encoded data about the invoice, which will be shared with the payment provider. A detailed description of required fields should be provided by the payment provider.

=item I<provider_token>

This parameter type is String and is required.

Payments provider token, obtained via Botfather

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for an inline keyboard. If empty, one 'Pay total price' button will be shown. If not empty, the first button must be a Pay button.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<send_email_to_provider>

This parameter type is Boolean and is optional.

Pass True, if user's email address should be sent to provider

=item I<send_phone_number_to_provider>

This parameter type is Boolean and is optional.

Pass True, if user's phone number should be sent to provider

=item I<start_parameter>

This parameter type is String and is required.

Unique deep-linking parameter that can be used to generate this invoice when used as a start parameter

=item I<title>

This parameter type is String and is required.

Product name, 1-32 characters

=back

=item B<sendLocation>( %PARAMETERS )

Use this method to send point on the map. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendlocation>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<latitude>

This parameter type is Float number and is required.

Latitude of the location

=item I<live_period>

This parameter type is Integer and is optional.

Period in seconds for which the location will be updated (see Live Locations, should be between 60 and 86400.

=item I<longitude>

This parameter type is Float number and is required.

Longitude of the location

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=back

=item B<sendMediaGroup>( %PARAMETERS )

Use this method to send a group of photos or videos as an album. On success, an array of the sent Messages is returned.

Reference: L<https://core.telegram.org/bots/api#sendmediagroup>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the messages silently. Users will receive a notification with no sound.

=item I<media>

This parameter type is an array of L<Net::API::Telegram::InputMediaPhoto> and L<Net::API::Telegram::InputMediaVideo> and is required.
A JSON-serialized array describing photos and videos to be sent, must include 2–10 items

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the messages are a reply, ID of the original message

=back

=item B<sendMessage>( %PARAMETERS )

Use this method to send text messages. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendmessage>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<disable_web_page_preview>

This parameter type is Boolean and is optional.

Disables link previews for links in this message

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in your bot's message.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<text>

This parameter type is String and is required.

Text of the message to be sent

=back

=item B<sendPhoto>( %PARAMETERS )

Use this method to send photos. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendphoto>

This methods takes the following parameters:

=over 8

=item I<caption>

This parameter type is String and is optional.

Photo caption (may also be used when resending photos by file_id), 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<photo>

This parameter type is one of the following L<InputFile> or String and is required.
Photo to send. Pass a file_id as String to send a photo that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a photo from the Internet, or upload a new photo using multipart/form-data. More info on Sending Files »

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=back

=item B<sendPoll>( %PARAMETERS )

Use this method to send a native poll. A native poll can't be sent to a private chat. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendpoll>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername). A native poll can't be sent to a private chat.

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<options>

This parameter type is an array of  and is required.
List of answer options, 2-10 strings 1-100 characters each

=item I<question>

This parameter type is String and is required.

Poll question, 1-255 characters

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=back

=item B<sendSticker>( %PARAMETERS )

Use this method to send static .WEBP or animated .TGS stickers. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendsticker>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<sticker>

This parameter type is one of the following L<InputFile> or String and is required.
Sticker to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a .webp file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »

=back

=item B<sendVenue>( %PARAMETERS )

Use this method to send information about a venue. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendvenue>

This methods takes the following parameters:

=over 8

=item I<address>

This parameter type is String and is required.

Address of the venue

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<foursquare_id>

This parameter type is String and is optional.

Foursquare identifier of the venue

=item I<foursquare_type>

This parameter type is String and is optional.

Foursquare type of the venue, if known. (For example, “arts_entertainment/default”, “arts_entertainment/aquarium” or “food/icecream”.)

=item I<latitude>

This parameter type is Float number and is required.

Latitude of the venue

=item I<longitude>

This parameter type is Float number and is required.

Longitude of the venue

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<title>

This parameter type is String and is required.

Name of the venue

=back

=item B<sendVideo>( %PARAMETERS )

Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as Document). On success, the sent Message is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.

Reference: L<https://core.telegram.org/bots/api#sendvideo>

This methods takes the following parameters:

=over 8

=item I<caption>

This parameter type is String and is optional.

Video caption (may also be used when resending videos by file_id), 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<duration>

This parameter type is Integer and is optional.

Duration of sent video in seconds

=item I<height>

This parameter type is Integer and is optional.

Video height

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<supports_streaming>

This parameter type is Boolean and is optional.

Pass True, if the uploaded video is suitable for streaming

=item I<thumb>

This parameter type is one of the following L<InputFile> or String and is optional.
Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail‘s width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can’t be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More info on Sending Files »

=item I<video>

This parameter type is one of the following L<InputFile> or String and is required.
Video to send. Pass a file_id as String to send a video that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a video from the Internet, or upload a new video using multipart/form-data. More info on Sending Files »

=item I<width>

This parameter type is Integer and is optional.

Video width

=back

=item B<sendVideoNote>( %PARAMETERS )

As of v.4.0, Telegram clients support rounded square mp4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent Message is returned.

Reference: L<https://core.telegram.org/bots/api#sendvideonote>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<duration>

This parameter type is Integer and is optional.

Duration of sent video in seconds

=item I<length>

This parameter type is Integer and is optional.

Video width and height, i.e. diameter of the video message

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<thumb>

This parameter type is one of the following L<InputFile> or String and is optional.
Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail‘s width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can’t be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More info on Sending Files »

=item I<video_note>

This parameter type is one of the following L<InputFile> or String and is required.
Video note to send. Pass a file_id as String to send a video note that exists on the Telegram servers (recommended) or upload a new video using multipart/form-data. More info on Sending Files ». Sending video notes by a URL is currently unsupported

=back

=item B<sendVoice>( %PARAMETERS )

Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .ogg file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent Message is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.

Reference: L<https://core.telegram.org/bots/api#sendvoice>

This methods takes the following parameters:

=over 8

=item I<caption>

This parameter type is String and is optional.

Voice message caption, 0-1024 characters

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<disable_notification>

This parameter type is Boolean and is optional.

Sends the message silently. Users will receive a notification with no sound.

=item I<duration>

This parameter type is Integer and is optional.

Duration of the voice message in seconds

=item I<parse_mode>

This parameter type is String and is optional.

Send Markdown or HTML, if you want Telegram apps to show bold, italic, fixed-width text or inline URLs in the media caption.

=item I<reply_markup>

This parameter type is one of the following L<InlineKeyboardMarkup> or L<ReplyKeyboardMarkup> or L<ReplyKeyboardRemove> or L<ForceReply> and is optional.
Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove reply keyboard or to force a reply from the user.

=item I<reply_to_message_id>

This parameter type is Integer and is optional.

If the message is a reply, ID of the original message

=item I<voice>

This parameter type is one of the following L<InputFile> or String and is required.
Audio file to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. More info on Sending Files »

=back

=item B<setChatDescription>( %PARAMETERS )

Use this method to change the description of a group, a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#setchatdescription>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<description>

This parameter type is String and is optional.

New chat description, 0-255 characters

=back

=item B<setChatPermissions>( %PARAMETERS )

Use this method to set default chat permissions for all members. The bot must be an administrator in the group or a supergroup for this to work and must have the can_restrict_members admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#setchatpermissions>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)

=item I<permissions>

This parameter type is an object L<Net::API::Telegram::ChatPermissions> and is required.
New default chat permissions

=back

=item B<setChatPhoto>( %PARAMETERS )

Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#setchatphoto>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<photo>

This parameter type is an object L<Net::API::Telegram::InputFile> and is required.
New chat photo, uploaded using multipart/form-data

=back

=item B<setChatStickerSet>( %PARAMETERS )

Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field can_set_sticker_set optionally returned in getChat requests to check if the bot can use this method. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#setchatstickerset>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)

=item I<sticker_set_name>

This parameter type is String and is required.

Name of the sticker set to be set as the group sticker set

=back

=item B<setChatTitle>( %PARAMETERS )

Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#setchattitle>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<title>

This parameter type is String and is required.

New chat title, 1-255 characters

=back

=item B<setGameScore>( %PARAMETERS )

Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited Message, otherwise returns True. Returns an error, if the new score is not greater than the user's current score in the chat and force is False.

Reference: L<https://core.telegram.org/bots/api#setgamescore>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Unique identifier for the target chat

=item I<disable_edit_message>

This parameter type is Boolean and is optional.

Pass True, if the game message should not be automatically edited to include the current scoreboard

=item I<force>

This parameter type is Boolean and is optional.

Pass True, if the high score is allowed to decrease. This can be useful when fixing mistakes or banning cheaters

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the sent message

=item I<score>

This parameter type is Integer and is required.

New score, must be non-negative

=item I<user_id>

This parameter type is Integer and is required.

User identifier

=back

=item B<setPassportDataErrors>( %PARAMETERS )

Informs a user that some of the Telegram Passport elements they provided contains errors. The user will not be able to re-submit their Passport to you until the errors are fixed (the contents of the field for which you returned the error must change). Returns True on success.Use this if the data submitted by the user doesn't satisfy the standards your service requires for any reason. For example, if a birthday date seems invalid, a submitted document is blurry, a scan shows evidence of tampering, etc. Supply some details in the error message to make sure the user knows how to correct the issues.

Reference: L<https://core.telegram.org/bots/api#setpassportdataerrors>

This methods takes the following parameters:

=over 8

=item I<errors>

This parameter type is an array of L<Net::API::Telegram::PassportElementError> and is required.
A JSON-serialized array describing the errors

=item I<user_id>

This parameter type is Integer and is required.

User identifier

=back

=item B<setWebhook>( %PARAMETERS )

Use this method to specify a url and receive incoming updates via an outgoing webhook. Whenever there is an update for the bot, we will send an HTTPS POST request to the specified url, containing a JSON-serialized Update. In case of an unsuccessful request, we will give up after a reasonable amount of attempts. Returns True on success.If you'd like to make sure that the Webhook request comes from Telegram, we recommend using a secret path in the URL, e.g. https://www.example.com/. Since nobody else knows your bot‘s token, you can be pretty sure it’s us.

Reference: L<https://core.telegram.org/bots/api#setwebhook>

This methods takes the following parameters:

=over 8

=item I<allowed_updates>

This parameter type is an array of  and is optional.
List the types of updates you want your bot to receive. For example, specify [“message”, “edited_channel_post”, “callback_query”] to only receive updates of these types. See Update for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used.Please note that this parameter doesn't affect updates created before the call to the setWebhook, so unwanted updates may be received for a short period of time.

=item I<certificate>

This parameter type is an object L<Net::API::Telegram::InputFile> and is optional.
Upload your public key certificate so that the root certificate in use can be checked. See our self-signed guide for details.

=item I<max_connections>

This parameter type is Integer and is optional.

Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery, 1-100. Defaults to 40. Use lower values to limit the load on your bot‘s server, and higher values to increase your bot’s throughput.

=item I<url>

This parameter type is String and is required.

HTTPS url to send updates to. Use an empty string to remove webhook integration

=back

=item B<stopMessageLiveLocation>( %PARAMETERS )

Use this method to stop updating a live location message before live_period expires. On success, if the message was sent by the bot, the sent Message is returned, otherwise True is returned.

Reference: L<https://core.telegram.org/bots/api#stopmessagelivelocation>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is optional.
Required if inline_message_id is not specified. Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<inline_message_id>

This parameter type is String and is optional.

Required if chat_id and message_id are not specified. Identifier of the inline message

=item I<message_id>

This parameter type is Integer and is optional.

Required if inline_message_id is not specified. Identifier of the message with live location to stop

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for a new inline keyboard.

=back

=item B<stopPoll>( %PARAMETERS )

Use this method to stop a poll which was sent by the bot. On success, the stopped Poll with the final results is returned.

Reference: L<https://core.telegram.org/bots/api#stoppoll>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=item I<message_id>

This parameter type is Integer and is required.

Identifier of the original message with the poll

=item I<reply_markup>

This parameter type is an object L<Net::API::Telegram::InlineKeyboardMarkup> and is optional.
A JSON-serialized object for a new message inline keyboard.

=back

=item B<unbanChatMember>( %PARAMETERS )

Use this method to unban a previously kicked user in a supergroup or channel. The user will not return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#unbanchatmember>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target group or username of the target supergroup or channel (in the format @username)

=item I<user_id>

This parameter type is Integer and is required.

Unique identifier of the target user

=back

=item B<unpinChatMessage>( %PARAMETERS )

Use this method to unpin a message in a group, a supergroup, or a channel. The bot must be an administrator in the chat for this to work and must have the ‘can_pin_messages’ admin right in the supergroup or ‘can_edit_messages’ admin right in the channel. Returns True on success.

Reference: L<https://core.telegram.org/bots/api#unpinchatmessage>

This methods takes the following parameters:

=over 8

=item I<chat_id>

This parameter type is one of the following Integer or String and is required.
Unique identifier for the target chat or username of the target channel (in the format @channelusername)

=back

=item B<uploadStickerFile>( %PARAMETERS )

Use this method to upload a .png file with a sticker for later use in createNewStickerSet and addStickerToSet methods (can be used multiple times). Returns the uploaded File on success.

Reference: L<https://core.telegram.org/bots/api#uploadstickerfile>

This methods takes the following parameters:

=over 8

=item I<png_sticker>

This parameter type is an object L<Net::API::Telegram::InputFile> and is required.
Png image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. More info on Sending Files »

=item I<user_id>

This parameter type is Integer and is required.

User identifier of sticker file owner

=back

=back

=head1 COPYRIGHT

Copyright (c) 2000-2019 DEGUEST Pte. Ltd.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Net::API::Telegram>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut

