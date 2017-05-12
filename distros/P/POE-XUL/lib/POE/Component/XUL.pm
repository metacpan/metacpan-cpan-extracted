package                     # Hide from CPAN indexer
    POE::Component::XUL;
# $Id: XUL.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;

use File::Path;
use File::Spec;
use File::Basename;
use HTTP::Date;
use HTTP::Status;
use HTML::Entities qw( encode_entities_numeric );
use I18N::AcceptLanguage;
use IO::File;
use MIME::Types;
use POE;
use POE::Component::Server::HTTP;
use POE::Session;
use POE::XUL::Controler;
use POE::XUL::Node;
use POE::XUL::Request;
use POE::XUL::Logging;
use POSIX qw(:errno_h);
use Scalar::Util qw( reftype blessed );
use Socket qw( unpack_sockaddr_in );

use Carp;

our $VERSION = '0.0601';

use constant DEBUG => 0;

use vars qw( $HAVE_DEVEL_SIZE $HAVE_DATA_DUMPER $SINGLETON );
BEGIN {
    $HAVE_DEVEL_SIZE = 0;
    eval "use " .           # Hide from CPANTS kwalitee
         "Devel::Size;";
    $HAVE_DEVEL_SIZE = 1 unless $@;

    $HAVE_DATA_DUMPER = 0;
    eval "use Data::Dumper;";
    $HAVE_DATA_DUMPER = 1 unless $@;
}

###############################################################
sub spawn 
{
	my ($package, $args) = @_;

    my $self = $package;
    unless( blessed $self ) {
        $self = $package->new( $args );
    }

	POE::Session->create(
        options => { %{ $self->{opts}||{} } },
		object_states => [
            $self => [ qw( _start shutdown
                           static xul httpd_error xul_file
                           poe_size poe_kernel poe_test
                           session_count session_timeout session_exists
                           sig_HUP sig_DIE
                     ) ],
		],
	);
}

###############################################################
sub new
{
    my( $package, $args ) = @_;

	$args->{port} = $args->{port};
    $args->{port} = 8077 unless defined $args->{port};      # PORT
	$args->{root} = $args->{root} || '/usr/local/poe-xul/xul'; # ROOT
    $args->{alias} ||= 'component-poe-xul';
	$args->{apps} = {} if (!defined $args->{apps});
	$args->{opts} = {} if (!defined $args->{opts});
    $args->{timeout} ||= 60*30;         # 30 minutes

	unless (ref($args->{apps}) eq 'HASH') {
		croak "apps parameter must be a HASH ref";
	}
	unless (ref($args->{opts}) eq 'HASH') {
		croak "opts parameter must be a HASH ref";
	}

    my $self = bless { %$args }, $package;
    $self->build_controler( $self->{timeout}, $self->{apps} );

    $self->__parse_apps();
    $self->{sessions} = {};

    $self->{static_root} ||= File::Spec->catfile( $self->{root}, 'xul' );
    $self->{log_root}    ||= File::Spec->catfile( $self->{root}, 'log' );

    $self->build_logging( $args->{logging} );

    $self->{languages} = [ qw( en fr ) ];   # XXX
    $self->{default_language} = 'fr';       # XXX

    return $SINGLETON = $self;
}

sub __parse_apps
{
    my( $self ) = @_;

    my $controler = $self->{controler};
    $self->{app_names} ||= {};

	foreach my $app ( keys %{ $self->{apps} } ) {
        my $A = $self->{apps}{$app};
        my $r = ref $A;
        # Make sure we have a package or a coderef
        my $ok = 0;
        if( $r and 'HASH' eq $r ) {
            $self->{app_names}{$app} = {
                                    en => $A->{en},
                                    fr => $A->{fr},
                                };
            if( $A->{package} ) {
                $A = $A->{package};
                undef $r;
            }
            else {
                $A = $A->{code};
                $r = 'CODE';
            }
        }
        if( not $r and $controler->package_ctor( $A ) ) {
            $ok = 1;
        }
        elsif( $r eq 'CODE') {
            $ok = 1;
        }
        unless( $ok ) {
            croak "apps parameter $app must be a code reference or name of a package that defines ->spawn, not $r ($A)";
		}
        $self->{apps}{$app} = $A;
	}
}


###############################################################
sub build_controler
{
    my( $self, $timeout, $apps ) = @_;

    $self->{controler} = POE::XUL::Controler->new( $timeout, $apps );
}

###############################################################
sub build_http_server
{
    my( $self, $addr, $port ) = @_;
    $self->{mimetypes} = MIME::Types->new();

    my $alias = $self->{alias};

    $self->{aliases} = POE::Component::Server::HTTP->new(
        Port => $self->{port},
        MapOrder => 'bottom-first',
        # PreHandler => { '/' => _mk_handler( $self, 'pre_connection' ) },
        PostHandler => { 
                '/'     => _mk_handler( $self, 'post_connection' ) 
            },
        ContentHandler => {
                '/xul'          => _mk_call( $alias, 'xul' ),
                '/xul/file/'    => _mk_call( $alias, 'xul_file' ),
                '/__poe_size'   => _mk_call( $alias, 'poe_size' ),
                '/__poe_kernel' => _mk_call( $alias, 'poe_kernel' ),
                '/__poe_text  ' => _mk_call( $alias, 'poe_text' ),
                '/'             => _mk_call( $alias, 'static' ),
            },
        ErrorHandler => {
                '/'             => _mk_call( $alias, 'httpd_error' ),
            },

        Headers => { 'X-POE-XUL' => $VERSION },
    );
}

## We build these closures outside of build_http_server, because otherwise
## they would capture a reference to $self
sub _mk_handler
{
    my( $self, $call ) = @_;
    return [ sub { RC_OK } ] unless $self;
    return [ sub { $self->$call(@_) } ] 
}

sub _mk_call
{
    my( $alias, $handler ) = @_;
    return sub { return $poe_kernel->call( $alias, $handler, @_ ) };
}


###############################################################
# Introspection used for load balancer
sub port
{
    my( $self ) = @_;
    
    my $sid = $self->{aliases}{tcp};
    my $tcp = $poe_kernel->alias_resolve( $sid );
    die "$$: Server::TCP has disapeared!  tcp=$sid" unless $tcp;
    my $wheel = $tcp->get_heap->{listener};
    die "Server::TCP no longer has the listener wheel in 'listener'"
        unless $wheel;
    my $sockname = $wheel->getsockname;
    my($peer_port, $peer_addr) = unpack_sockaddr_in( $sockname );
    return $peer_port;   
#    use Data::Denter;
#    die Denter $sockname;
}

sub alias
{
    my( $self ) = @_;
    return $self->{alias};
}

############################################################################
# POE methods

###############################################################
sub _start 
{
	my ($self, $kernel, $session) = @_[OBJECT, KERNEL, SESSION];

	$kernel->alias_set( $self->{alias} );
    $kernel->sig( shutdown => 'shutdown' );
    $kernel->sig( HUP => 'sig_HUP' );
    $kernel->sig( DIE => 'sig_DIE' );

    # TODO: listen host
    $self->build_http_server( '0.0.0.0', $self->{port} );
    $self->log_setup;
}

# NB : no longer used
sub _stop
{
    xwarn "XUL stop";
}

###############################################################
# Sane shutdown
sub shutdown
{
    my( $self ) = @_;
    # xwarn "$$ XUL shutdown";
    $self->{shutdown} = 1;
    $poe_kernel->post( $self->{aliases}{httpd}, 'shutdown' );
    $poe_kernel->alias_remove( delete $self->{alias} );
    $poe_kernel->sig( 'HUP' );
}

###############################################################
# POE Exception handling
sub sig_DIE
{
    my( $self, $kernel, $sig, $ex ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];
    xwarn "============================\nERROR: $sig $ex\n";
    xwarn "Exception in $ex->{event}: $ex->{error_str}\n";
}




###############################################################
sub session_timeout 
{
	my ($self, $kernel, $SID) = @_[OBJECT, KERNEL, ARG0];
    my $controler = $self->{controler};
    DEBUG and 
        xwarn "Session timeout for $SID";
    if( defined $SID and $controler->exists( $SID ) ) {
        DEBUG and 
            xdebug "Timeout SID=$SID";
        $kernel->call( $SID, 'timeout', $SID ); # TODO unit test
        # unregister will send the 'shutdown' event
        $controler->unregister( $SID );
    }
}

###############################################################
# Get the number of active sessions.
# Used by IGDAIP::App to see when a backend should exit
sub session_count
{
	my ($self, $kernel) = @_[ OBJECT, KERNEL ];
    return $self->{controler}->count;
}

###############################################################
# Verify if a session exists
sub session_exists
{
	my ($self, $kernel, $SID ) = @_[ OBJECT, KERNEL, ARG0 ];
    return $self->{controler}->exists( $SID );
}





############################################################################
# XUL request handling

###############################################################
# Get the arguments out of a request
sub parse_args
{
    my( $self, $req ) = @_;

    return POE::XUL::Request->new( $req );
}

###############################################################
# Report an error in the request parsing
sub parse_error
{
    my( $self, $rc ) = @_;

    $self->error_standard( $rc, "argument parsing" );
}

###############################################################
# A request under /xul for an application
sub xul
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0..$#_ ];

    DEBUG and 
        warn "$$: xul";
    if( $self->{shutdown} ) {
        xwarn "XUL request, but we are shutdown\n";
        return;
    }

    local $self->{request}  = $req;
	local $self->{response} = $resp;

    DEBUG and xwarn "XUL request";

    my $controler = $self->{controler};

    my $uri = $req->uri->path;
    if( $uri ne '/xul' ) {
        return $self->error_standard( RC_BAD_REQUEST, "parsing uri", 
                                      "$uri isn't a valid path\n" );
    }

    my $ret = $self->parse_args( $req );
    unless( ref $ret ) {
        return $self->parse_error( $ret );
    }

    $req->{start} = time;

    my $SID = $req->param( 'SID' ) || '';
    my $event = $req->param( 'event' ) || 'boot';
    my $app = $req->param( 'app' ) || '';
    DEBUG and xdebug "Request for app=$app SID=$SID event=$event";

    unless( $app and $event ) {
        $req->pre_log;
        xlog "app=$app SID=$SID event=$event is an empty request";
        return $self->error( RC_BAD_REQUEST, 'Empty request' );
    }

    my $rc;
    eval {
        local $self->{logging}->{app} = $app;
        $req->pre_log;
		if( $event eq 'boot' ) {
            my $fail = $controler->boot( $req, $resp );
            if( $fail ) {
                # boot failed
                $rc = $self->error_boot_fail( $fail );
            }
		}
        ## TODO: move the rest of this into Controler->something
		elsif( ! $controler->exists( $SID ) ) {
			$rc = $self->error_unknown_session( $SID );
        }
        else {
            $controler->keepalive( $SID );  
            if( $event eq 'connect' ) {
                $controler->connect( $SID, $req, $resp );
            }
            elsif( $event eq 'disconnect' ) {
                $controler->disconnect( $SID, $req, $resp );
            }
            elsif( $event eq 'close' ) {
                $controler->close( $SID, $req, $resp );
            }
            else {
                # everything else is a DOM event
                $controler->request( $SID, $event, $req, $resp );
            }
		}
        $rc ||= RC_WAIT;
	};

    unless( defined $rc ) {
        warn "Error: $@";
        $rc = $self->error_standard( RC_INTERNAL_SERVER_ERROR, $event, $@ );
    }

    return $rc;
}

###############################################################
## Request for a file that starts with /xul/
sub xul_file
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0..$#_ ];

    # DEBUG and 
        warn "$$: xul_file";
    my $uri = $req->uri->path;
    unless( $uri =~ m(^/xul/file(/(.*))?) ) {
        return $self->error_standard( RC_BAD_REQUEST, "parsing uri", 
                                      "$uri isn't a valid path\n" );
    }
    my $filename = $2||'';
    $req->uri->path( '/xul' );
    my $ret = $self->parse_args( $req );
    unless( ref $ret ) {
        return $self->parse_error( $ret );
    }

    $req->param( filename => $filename );
    return shift->xul( @_ );
}



############################################################################
# Static file handling

###############################################################
sub static
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0..$#_ ];

    DEBUG and 
        xwarn "POE::Component::XUL->static";
    if( $self->{shutdown} ) {
        xwarn "Static request, but we are shutdown\n";
        return;
    }

    local $self->{request}  = $req;
    local $self->{response} = $resp;

    my $ret;
    eval {
        my $method = $req->method;
        # Verify HTTP method
        unless( $method eq 'GET' or $method eq 'HEAD' ) {
            $ret = $self->error_standard( RC_METHOD_NOT_ALLOWED, $method );
            return;
        }

        # Send the file
        my $uri = $req->uri->path;
        DEBUG and 
                xdebug "Static request: $uri";

        my $file = $self->uri_to_file( $uri );
        if( -d $file ) {
            $ret = $self->static_file( $uri, 'index.html' );
        }
        elsif( -f "$file.build" ) {
            $ret = $self->build_file( $uri, $file );
        }
        else {
            $ret = $self->static_file( $uri );
        }
        DEBUG and xwarn "$$: ret=$ret";
    };

    if( $ret ) {
        $resp->code( $ret );
        # $response->continue;
        return $ret;
    }
    $self->error_standard( RC_INTERNAL_SERVER_ERROR, "serving static file", $@ );
}

####################################################################
sub uri_to_file
{
    my( $self, @path ) = @_;

    my $path = File::Spec->catfile( grep {defined} @path );
    $path =~ s(/\./)(/)g;
    $path =~ s(/\.\./)(/)g;

    unless( $path =~ s(^/)($self->{static_root}/) ) {
        $path = File::Spec->catfile( $self->{static_root}, $path );
    }
    $path =~ s(//)(/)g;
    return $path;
}

####################################################################
sub static_file
{
    my( $self, $uri, $file ) = @_;

    my $req = $self->{request};
    my $resp = $self->{response};

    my $fullfile = $file;
    if( $uri ) {
        $fullfile = $self->uri_to_file( $uri, $file );
    }
    DEBUG and xdebug "Static file: $fullfile";


#    warn "REQUEST=", $req->as_string;
    # Does the file exist?
    return $self->error_not_found( $fullfile ) unless -f $fullfile;

    my $lastmod = (stat _)[9];
    my $size    = (stat _)[7];

    # open the file
    my $in = IO::File->new( $fullfile );
    unless( $in ) {
        return $self->error( RC_FORBIDDEN, "$uri: $!" );
    }

    # Make sure it's not too huge
    if( $size > 1024 * 1024 ) {
        return $self->error_standard( RC_REQUEST_ENTITY_TOO_LARGE, 
                                      "looking at the file", 
                                      "$size is much to large" );
    }

    # set up content-type
    my $ct = $self->guess_ct( $fullfile );
    DEBUG and xdebug "content_type=$ct\n";
    $self->{response}->content_type( $ct );

    # add useful headers
    if( $lastmod and not $ct =~ m(^application/vnd\.mozilla\.xul\+xml$) ) {
        DEBUG and xdebug "Last-modified=", time2str( $lastmod );
        $self->{response}->header( 'Last-Modified' =>
                                        time2str( $lastmod )
                                 );
    }

    # bail if HEAD request
    if ( $req->method eq 'HEAD' ) {
        DEBUG and 
            xdebug "HEAD size=$size";
        $resp->content_length( $size );
        return RC_OK;
    }
    
    # RFC1945 says HEAD should ingore if-modified-since

    # 304 check
    my $since = $req->header( 'If-Modified-Since' );
    if( $since ) {
        DEBUG and xdebug "If-mod-since=$since";
        $since = str2time( $since );
        
        if ( $lastmod && $since && $since >= $lastmod ) {
            DEBUG and xdebug "NOT MODIFIED SINCE (size=$size)";
			$resp->header( 'Last-Modified' => '' );
            return RC_NOT_MODIFIED;
        }
    }
#    warn "RESPONSE=", $self->{response}->as_string;

    # Read and set the content
    my $c = join '', <$in>;
    undef( $in );

    if( ($uri eq '/' or $uri =~ m(^/index.html?)) and 
            $c =~ /\[APP-LIST\]/ ) {
        my $alist = $self->app_list;
        $c =~ s/\[APP-LIST\]/$alist/g;
    }

    $self->{response}->content( $c );
    $self->{response}->content_length( length $c );
    return RC_OK;
}

####################################################################
sub app_list
{
    my( $self ) = @_;
    my @html = <<HTML;
<script type="text/javascript"><!--
function Link(name) {
    window.open(
        "start.xul?" + name + "#1" ,
        (new Date()).getTime(),
        "toolbar=0,menubar=0,status=0,resizable=1"
    );
    return false;
}
// ->
</script>
<ul id="POE-XUL-application-list">
HTML
    my $lang = $self->language_guess;

    my $text = $lang eq 'fr' ? "Avec menus" : "Keep menus";
    my $count = keys %{ $self->{apps} };
    foreach my $app ( sort keys %{ $self->{apps} } ) {
        next if $app eq 'IGDAIP' and 1 != $count;
        my $name = $self->{app_names}{$app}{$lang} || $app;
        push @html, <<HTML;
    <li><a href="start.xul?$app" onclick="return Link('$app')">$name</a>
            (<a href="start.xul?$app">$text</a>)</li>
HTML
    }

    push @html, "</ul>";
    return join "\n", @html;
}

sub language_guess
{
    my( $self ) = @_;
    return $self->{default_language} unless $self->{request};
    my $accept = $self->{request}->header( 'Accept-Language' );
    $self->{acceptor} ||= I18N::AcceptLanguage->new( 
                            defaultLanguage => $self->{default_language},
                            strict => 0
                          );
    return $self->{acceptor}->accepts( $accept, $self->{languages} );
}

####################################################################
# Build a file out of smaller files
# This removes the need for complex Makefiles to build up a single
# javascript / CSS / XBL file.  
#
# The Build files is the filename + .build extention
# A Cache file is the filename + .cache extention
sub build_file
{
    my( $self, $uri, $fullfile ) = @_;

    my $bfile = "$fullfile.build";
    my $bage  = (stat $bfile)[9];
    my $cfile = "$fullfile.cache";
    my $cage  = (stat $cfile)[9];
    
    unless( $cage and $cage > $bage ) {  # cache file isn't newer then build file
        # so we have to create the cache file
        local $self->{loop_check} = {};
        $self->create_cache_file( $cfile, $bfile );
    }
    
    return $self->static_file( '', $cfile );
}

############################################################
# Recursively create the file in $cfile from $bfile
sub create_cache_file
{
    my( $self, $cfile, $bfile ) = @_;
    my $out = $cfile;
    $out = IO::File->new( "> $cfile" ) unless ref $cfile;

    my $dir = dirname $bfile;

    if( $self->{loop_check}{ $bfile } ) {
        die "Recursion detected: $bfile included more then once";
    }
    local $self->{loop_check}{ $bfile } = 1;

    my $in = IO::File->new( $bfile ) or die "Unable to read $bfile: $!\n";
    while( my $line = <$in> ) {
        if( $line =~ /^\s*\@include "(.+)"\s*$/) {
            my $file = File::Spec->rel2abs( $1, $dir );
            $self->create_cache_file( $out, $file );
        }
        else {
            $out->print( $line );
        }
    }
}

############################################################
sub guess_ct
{
    my($self, $file)=@_;
    $file =~ s/\.cache$//;
    my $ct = $self->{mimetypes}->mimeTypeOf( $file );
    $ct ||=  'application/octet-stream';
    $ct .= '; charset=iso-8859-1'  if $ct eq 'text/html';

    return $ct;
}

############################################################
# URI that would restart an application
sub uri_restart
{
    my( $self ) = @_;
    my $req = $self->{request};
    my $uri = $req->uri;

    # We need to know what the browser thinks we are called
    my $host = $req->header( 'X-Forwarded-Host' );
    if( $host ) {
        xwarn "Restart on $host";
        $host =~ s/,.+$//;
        $uri->host( $host );
        $uri->port( undef ) if defined $uri->port and 0==$uri->port;
    }
    my $referer = $req->header( 'Referer' );
    if( $referer and $referer =~ /https/ ) {
        $uri->scheme( 'https' );
    }
    $uri->path( '/start.xul' );
    my $app = $req->param( 'app' );
    $uri->query_keywords( $app );
    return $uri;
}

############################################################################
# Error handling

############################################################
sub error
{
    my($self, $code, $text, $ct)=@_;

    $ct ||= 'text/plain';

    # This could get annoying fast.  It also shows 404s
    warn "$code $text\n"unless $ENV{AUTOMATED_TESTING};
    xlog "$code $text\n"
                if $ct eq 'text/plain' and (DEBUG or $code != RC_NOT_FOUND);

    if( $self->{response} ) {
        $self->{response}->code( $code );
        $self->{response}->content_type( $ct );
        if( $ct eq 'text/html' ) {
            $text = encode_entities_numeric( $text, "\x80-\xff" );
        }

        $self->{response}->content( $text );
        $self->{response}->content_length( length $text );
    }
    else {
        xcarp "Response was already sent!";
    }
    return $code;
}

############################################################
sub error_standard
{
    my( $self, $code, $when, $what ) = @_;

    # Thank you HTTP::Status
    my $message = status_message( $code );
    $message ||= 'unknown';

    $what ||= '';

    return $self->error( $code, "Error while $when: $message ($code)\n$what" );
}

############################################################
sub error_not_found
{
    my( $self, $file ) = @_;
    my $msg = "Unknown file '$file'";
    xwarn "$msg\n";

    return $self->error( RC_NOT_FOUND, <<"    HTML", 'text/html');
<html>
    <head><title>404 N'existe pas</title></head>
    <body>
    <h1>Le fichier que vous cherchez ne semble pas exister.</h1>
    <pre>$msg</pre>
    </body>
</html>
    HTML
}

###############################################################
## TODO : as XUL
sub error_unknown_session
{
    my( $self, $SID ) = @_;

    xwarn "Unknown session $SID";

    my $url = $self->uri_restart;

    return $self->error( RC_GONE, <<"    HTML", 'text/html');
<html>
    <head><title>410 absent</title></head>
    <body>
    <h1>Program inexistante</h1>
    <p>Votre session (<tt>$SID</tt>) n'existe pas. Elle est surement expirée.</p>
    <p><a href="$url">Ouvrir une nouvelle session</a>.</p>
    </body>
</html>
    HTML
}

###############################################################
## TODO : as XUL
sub error_boot_fail
{
    my( $self, $fail ) = @_;

    return $self->error( RC_NOT_FOUND, <<"    HTML", 'text/html');
<html>
    <head><title>404 absent</title></head>
    <body>
    <h1>Écheque au démarrage</h1>
    <p>$fail</p>
    </body>
</html>
    HTML
}




############################################################
sub httpd_error
{
    my( $self, $request, $response) = @_[ OBJECT, ARG0..$#_ ];

    my $op=$request->header('Operation');
    my $errnum=$request->header('Errnum');
    my $errstr=$request->header('Error');

    DEBUG and
        xdebug "HTTPD ERROR op=$op errstr=$errstr errnum=$errnum\n";

    if($op eq 'read' and ($errnum==0 or $errnum = ECONNRESET)) {
                                                      # remote closed
        if( $self->{controler} and $request ) {
            DEBUG and 
                xdebug "$$ REMOTE CLOSED req=$request";
            $self->{controler}->cancel( $request );
        }
        # PostHandler will deal with resuming the listening socket
    }
    else {
        xwarn "Error during $op: [$errnum] $errstr";
    }

    return RC_OK;
    
}

############################################################################
# Peeking

###############################################################
sub poe_size
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    my $content = -1;
    if( DEBUG and $HAVE_DEVEL_SIZE ) {
        $content = Devel::Size::total_size( $kernel );
    }
    $resp->code( RC_OK );
    $resp->content_type( 'text/plain' );
    $resp->content_length( length $content );
    $resp->content( $content );
    return RC_OK;
}

sub poe_kernel
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    my $content = '';
    if( DEBUG and $HAVE_DATA_DUMPER ) {
        local $Data::Dumper::Indent = 1;
        $content = Data::Dumper::Dumper( $kernel );
    }
    $resp->code( RC_OK );
    $resp->content_type( 'text/plain' );
    $resp->content_length( length $content );
    $resp->content( $content );
    return RC_OK;
}

sub poe_test
{
    my( $self, $kernel, $req, $resp ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

    local $self->{request} = $req;
    local $self->{response} = $resp;

    $self->parse_args( $req );

    my $uri_restart = $self->uri_restart;
    my $content = <<TEXT;
uri_restart: $uri_restart
TEXT
    xwarn "content=$content";
    $resp->code( RC_OK );
    $resp->content_type( 'text/plain' );
    $resp->content_length( length $content );
    $resp->content( $content );
    return RC_OK;
}






############################################################################
# Log handling

############################################################
sub build_logging
{
    my( $self, $args_log ) = @_;

    $self->{logging} = POE::XUL::Logging->new( $args_log, $self->{log_root} );
}

############################################################
sub log_setup
{
    my( $self ) = @_;
    $self->{logging}->setup;
}

############################################################
sub sig_HUP
{
    my( $self ) = @_;
    xwarn "SIGHUP";
    $poe_kernel->sig_handled();

    $self->log_setup;
}


############################################################
sub post_connection
{
    my( $self, $req, $resp ) = @_;
    my $app = eval { $req->param( 'app' ) } || $self->{logging}->{app};
    local $self->{logging}->{app} = $app;

    my $conn = $req->connection;
    my @log;
    push @log, ($conn ? $conn->remote_ip : '0.0.0.0');
    if( $log[-1] eq '127.0.0.1' and $req->header( 'X-Forwarded-For' ) ) {
        $log[-1] = $req->header( 'X-Forwarded-For' );
    }
    # push @log, ($self->{preforked} ? $$ : '-');
    push @log, $$, '-';

    

    my $path = $req->uri->path;
    my $query = $req->uri->query;
    $path .= "?$query" if $query and $req->method eq 'GET';

    push @log, "[". POSIX::strftime("%d/%m/%Y:%H:%M:%S %z", localtime)."]",
               join ' ', $req->method, $path;
    $log[-1] = qq("$log[-1]");
    push @log, ($resp->code||'000'), ($resp->content_length||0);

    xlog( { message => join( ' ', @log )."\n",
            type    => 'REQ'
        } );
#    use Devel::Cycle;
#    find_cycle( $poe_kernel );
    return RC_OK;
}




1;

__END__

=head1 NAME

POE::Component::XUL - POE::XUL server

=head2 SYNOPSIS

    use POE;
    use POE::Component::XUL;

    POE::Component::XUL->spawn( { 
                                    port => 8001,
                                    root => '/var/poe-xul/',
                                    alias => 'POE-XUL',
                                    opts  => {},
                                    timeout => 30 * 60,
                                    logging => {},
                                    apps => {   
                                        MyApp => 'My::App',
                                        # ....
                                    } 
                              } );
    $poe_kernel->run();

=head1 DESCRIPTION

POE::Component::XUL handles all POE and HTTP events for a POE::XUL server.

POE::Component::XUL creates an HTTP server with
L<POE::Component::Server::HTTP>.

POE::Component::XUL can server up static files, and a limited form of
server-side includes L</BUILD FILES>.  XUL events (under the C</xul> URI) are
passed to L<POE::XUL::Controler> to be handled.

=head1 STATIC FILES

Any request not under C</xul> is handled as a static file.  For directories,
you must provide an C<index.html>; no autoindexing is provided.

The response's content type is guessed at with L<MIME::Types>.

=head1 BUILD FILES

A sub-set of static files are the I<build files>.  They allow you to create
a response by including multiple files into one response.  This cuts down on
HTTP trafic while still allowing you to maintain various parts in individual
files and not creating complex Makefiles.  Of course, all the sub-files must
share a same mime-type.

Given a request for a C</path/file.ext>, if the I<build file>
C</path/file.ext.build> exists, it is used to build the response.  The
response is saved in the I<cache file> C</path/file.ext.cache> and which is
sent for subsequent requests for C</path/file.ext>, unless
C</path/file.ext.build> is updated.

A I<build file> is expected to be a text file.  It may contain the following
command:

=head2 @include

    @include "other-file.ext"

The file <other-file.ext> is included at that point in the file.  The
sub-files are themselves parse like I<build files>; they may include further
files.  


=head2 Example

C<my-xbl.xml.build>:

    <?xml version="1.0"?>
    <bindings
        xmlns="http://www.mozilla.org/xbl"
        xmlns:xbl="http://www.mozilla.org/xbl"
        xmlns:html="http://www.w3.org/1999/xhtml"
        xmlns:xul="http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul">
    @include "tag1.xml"
    @include "tag2.xml"
    @include "tag3.xml"
    </bindings>

C<tag1.xml>:

    <binding id="tag1">
        <content><children /></content>
        <implementation> ... </implementation>
    </binding>

and similarly for tag2.xml and tag3.xml.

=head1 METHODS

=head2 spawn

Spawns the component.  Arguments are:

=over 4

=item apps

A hash ref that defines the applications this server handles.  Hash keys are
the names of the application, as used in the initial URL
C</start.xul?AppName>.  The values may be either package names or coderefs.
In the former case, the object method C<spawn> is called when a new
application instance is needed.  In the latter case, the coderef is called.

=item port

The TCP port the server should listen too.  Defaults to what you specified 
to Makefile.PL (8077).

=item root

Path of the static files handled by the server.  B<Must> include
C<start.xul> and the javascript client library.  Defaults to what you specified 
to Makefile.PL (/usr/local/poe-xul).

=item timeout

The number of seconds of inactivity before an application instance is
shutdown.  Activity is currently defined as events sent from the javascript
client library.

=item alias

The session alias for this component.  Defaults to C<component-poe-xul>.

=item opts

Hashref of options passed to C<POE::Session/create>.

=item logging

Parameters passed to L<POE::XUL::Logging>.

=back


=head1 EVENTS

=head2 shutdown

As all good components should, POE::Component::XUL has a shutdown event,
which also tells the POE::Component::Server::HTTP to 'shutdown'.

=head1 AUTHOR

Philip Gwyn E<lt>gwyn-at-cpan.orgE<gt>

=head1 CREDITS

Based on XUL::Node by Ran Eilam, POE::Component::XUL by David Davis, and of
course, POE, by the illustrious Rocco Caputo.

=head1 SEE ALSO

perl(1), L<POE::XUL>, L<POE::Component::Server::HTTP>.

=cut

__END__
