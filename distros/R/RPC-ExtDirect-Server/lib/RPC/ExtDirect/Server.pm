package RPC::ExtDirect::Server;

use strict;
use warnings;
no  warnings 'uninitialized';   ## no critic

use Carp;

use RPC::ExtDirect::Util::Accessor;
use RPC::ExtDirect::Config;
use RPC::ExtDirect::API;
use RPC::ExtDirect;
use CGI::ExtDirect;

use HTTP::Server::Simple::CGI;
use base 'HTTP::Server::Simple::CGI';

### PACKAGE GLOBAL VARIABLE ###
#
# Version of this module.
#

our $VERSION = '1.24';

# We're trying hard not to depend on any non-core modules,
# but there's no reason not to use them if they're available
my ($have_http_date, $have_cgi_simple);

{
    local $@;
    $have_http_date  = eval "require HTTP::Date";

    # CGI::Simple is only meaningful if we're using old CGI.pm,
    # and only if certain version of CGI::Simple is available
    $have_cgi_simple = $CGI::VERSION < 4.0
        && eval "require CGI::Simple; $CGI::Simple::VERSION > 1.113";
}

# CGI.pm < 3.36 does not support HTTP_COOKIE environment variable
# with multiple values separated by commas instead of semicolons,
# which is exactly what HTTP::Server::Simple::CGI::Environment
# does in version <= 0.51. The module below will fix that.

if ( $CGI::VERSION < 3.36 && $HTTP::Server::Simple::VERSION <= 0.51 ) {
    local $@;

    require RPC::ExtDirect::Server::Patch::HTTPServerSimple;
}

# We assume that HTTP::Date::time2str is better maintained,
# so use it if we can. If HTTP::Date is not installed,
# fall back to our own time2str - which was shamelessly copied
# from HTTP::Date anyway.
if ( $have_http_date ) {
    *time2str = *HTTP::Date::time2str;
    *str2time = *HTTP::Date::str2time;
}
else {
    eval <<'END_SUB';
    my @DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    
    sub time2str {
        my $time = shift;
        
        $time = time unless defined $time;
        
        my ($sec, $min, $hour, $mday, $mon, $year, $wday)
            = gmtime($time);
        
        return sprintf "%s, %02d %s %04d %02d:%02d:%02d GMT",
                       $DoW[$wday],
                       $mday,
                       $MoY[$mon],
                       $year + 1900,
                       $hour,
                       $min,
                       $sec
                       ;
    }
END_SUB
}

my %DEFAULTS = (
    index_file    => 'index.html',
    expires_after => 259200, # 3 days in seconds
    buffer_size   => 262144, # 256kb in bytes
);

### PUBLIC CLASS METHOD (CONSTRUCTOR) ###
#
# Instantiate a new HTTPServer
#

sub new {
    my ($class, %arg) = @_;

    my $api        = delete $arg{api}        || RPC::ExtDirect->get_api();
    my $config     = delete $arg{config}     || $api->config;
    my $host       = delete $arg{host}       || '127.0.0.1';
    my $port       = delete $arg{port}       || 8080;
    my $cust_disp  = delete $arg{dispatch}   || [];
    my $static_dir = delete $arg{static_dir} || '/tmp';
    my $cgi_class  = delete $arg{cgi_class};

    $config->set_options(%arg);

    my $self = $class->SUPER::new($port);
    
    $self->_init_cgi_class($cgi_class);
    
    $self->api($api);
    $self->config($config);
    $self->host($host);

    $self->static_dir($static_dir);
    $self->logit("Using static directory ". $self->static_dir);
    
    foreach my $k (keys %DEFAULTS) {
        my $v = $DEFAULTS{$k};
        my $value = exists $arg{ $k } ? delete $arg{ $k } : $v;
        
        $self->$k($value);
    }

    $self->_init_dispatch($cust_disp);
    
    return bless $self, $class;
}

### PUBLIC INSTANCE METHOD ###
#
# Find matching method by URI and dispatch it.
# This is an entry point for HTTP::Server::Simple API, and is called
# by the underlying module (in fact HTTP::Server::Simple::CGI).
#

sub handle_request {
    my ($self, $cgi) = @_;
    
    my $path_info = $cgi->path_info();
    
    my $debug = $self->config->debug;
    
    $self->logit("Handling request: $path_info") if $debug;
    
    $cgi->nph(1);
    
    HANDLER:
    for my $handler ( @{ $self->dispatch } ) {
        my $match = $handler->{match};
        
        $self->logit("Matching '$path_info' against $match") if $debug;
        
        next HANDLER unless $path_info =~ $match;
        
        $self->logit("Got specific handler with match '$match'") if $debug;
        
        my $code = $handler->{code};
        
        # Handlers are always called as if they were ref($self)
        # instance methods
        return $code->($self, $cgi);
    }

    $self->logit("No specific handlers found, serving default") if $debug;
    
    return $self->handle_default($cgi, $path_info);
}

### PUBLIC INSTANCE METHOD ###
#
# Default request handler
#

sub handle_default {
    my ($self, $cgi, $path) = @_;

    # Lame security measure
    return $self->handle_403($cgi, $path) if $path =~ m{/\.\.};

    my $static = $self->static_dir();
    $static   .= '/' unless $path =~ m{^/};

    my $file_name = $static . $path;
    
    my $file_exists   = -f $file_name;
    my $file_readable = -r $file_name;

    if ( -d $file_name ) {
        $self->logit("Got directory request");
        return $self->handle_directory($cgi, $path);
    }
    elsif ( $file_exists && !$file_readable ) {
        $self->logit("File exists but no permissions to read it (403)");
        return $self->handle_403($cgi, $path);
    }
    elsif ( $file_exists && $file_readable ) {
        $self->logit("Got readable file, serving as static content");
        return $self->handle_static(
            cgi       => $cgi,
            path      => $path,
            file_name => $file_name,
        );
    }
    else {
        return $self->handle_404($cgi, $path);
    };

    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Handle directory request. Usually results in a redirect
# but can be overridden to do something fancier.
#

sub handle_directory {
    my ($self, $cgi, $path) = @_;
    
    # Directory requested, redirecting to index.html
    $path =~ s{/+$}{};
    
    my $index_file = $self->index_file;
    
    $self->logit("Redirecting to $path/$index_file");
    
    my $out = $self->stdio_handle;

    print $out $cgi->redirect(
        -uri    => "$path/$index_file",
        -status => '301 Moved Permanently'
    );
    
    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Handle static content
#

sub handle_static {
    my ($self, %arg) = @_;

    my $cgi       = $arg{cgi};
    my $file_name = $arg{file_name};

    $self->logit("Handling static request for $file_name");

    my ($fsize, $fmtime) = (stat $file_name)[7, 9];
    my ($type, $charset) = $self->_guess_mime_type($file_name);
    
    $self->logit("Got MIME type $type");
    
    my $out = $self->stdio_handle;
    
    # We're only processing If-Modified-Since if HTTP::Date is installed.
    # That's because str2time is not trivial and there's no point in
    # copying that much code. The feature is not worth it.
    if ( $have_http_date ) {
        my $ims = $cgi->http('If-Modified-Since');
    
        if ( $ims && $fmtime <= str2time($ims) ) {
            $self->logit("File has not changed, serving 304");
            print $out $cgi->header(
                -type   => $type,
                -status => '304 Not Modified',
            );
        
            return 1;
        };
    }
    
    my ($in, $buf);

    if ( not open $in, '<', $file_name ) {
        $self->logit("File is unreadable, serving 403");
        return $self->handle_403($cgi);
    };

    $self->logit("Serving file content with 200");
    
    my $expires = $self->expires_after;

    print $out $cgi->header(
        -type    => $type,
        -status  => '200 OK',
        -charset => ($charset || ($type !~ /image|octet/ ? 'utf-8' : '')),
        ( $expires ? ( -Expires => time2str(time + $expires) ) : () ),
        -Content_Length => $fsize,
        -Last_Modified  => time2str($fmtime),
    );

    my $bufsize = $self->buffer_size;
    
    binmode $in;
    binmode $out;
    
    # Making the out handle hot helps in older Perls
    {
        my $orig_fh = select $out;
        $| = 1;
        select $orig_fh;
    }

    print $out $buf while sysread $in, $buf, $bufsize;

    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Return Ext.Direct API declaration JavaScript
#

sub handle_extdirect_api {
    my ($self, $cgi) = @_;

    $self->logit("Got Ext.Direct API request");

    return $self->_handle_extdirect($cgi, 'api');
}

### PUBLIC INSTANCE METHOD ###
#
# Route Ext.Direct method calls
#

sub handle_extdirect_router {
    my ($self, $cgi) = @_;

    $self->logit("Got Ext.Direct route request");

    return $self->_handle_extdirect($cgi, 'route');
}

### PUBLIC INSTANCE METHOD ###
#
# Poll Ext.Direct event providers for events
#

sub handle_extdirect_poll {
    my ($self, $cgi) = @_;

    $self->logit("Got Ext.Direct event poll request");

    return $self->_handle_extdirect($cgi, 'poll');
}

### PUBLIC INSTANCE METHOD ###
#
# Return 403 header without a body.
#

sub handle_403 {
    my ($self, $cgi, $uri) = @_;
    
    $self->logit("Handling 403 for URI $uri");
    
    my $out = $self->stdio_handle;
    
    print $out $cgi->header(-status => '403 Forbidden');
    
    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Return 404 header without a body.
#

sub handle_404 {
    my ($self, $cgi, $uri) = @_;

    $self->logit("Handling 404 for URI $uri");
    
    my $out = $self->stdio_handle;

    print $out $cgi->header(-status => '404 Not Found');

    return 1;
}

### PUBLIC INSTANCE METHOD ###
#
# Log debugging info to STDERR
#

sub logit {
    my $self = shift;
    
    print STDERR @_, "\n" if $self->config->debug;
}

### PUBLIC PACKAGE SUBROUTINE ###
#
# Prints banner, but only if debugging is on
#

sub print_banner {
    my $self = shift;

    $self->SUPER::print_banner if $self->config->debug;
}

### PUBLIC INSTANCE METHODS ###
#
# Read-write accessors
#

RPC::ExtDirect::Util::Accessor->mk_accessors(
    simple => [qw/
        api
        config
        dispatch
        static_dir
        index_file
        expires_after
        buffer_size
    /],
);

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Parse HTTP request line. Returns three values: request method,
# URI and protocol.
#
# This method is overridden to improve parsing speed. The original
# method is reading characters from STDIN one by one, which
# results in abysmal performance. Not sure what was the intent
# there but I haven't encountered any problems so far with the
# faster implementation below.
#
# The same is applicable to the parse_headers() below.
#

sub parse_request {
    my $self = shift;

    my $io_handle = $self->stdio_handle;
    my $input     = <$io_handle>;

    return unless $input;

    $input =~ /^(\w+)\s+(\S+)(?:\s+(\S+))?\r?$/ and
        return ( $1.'', $2.'', $3.'' );
}

### PRIVATE INSTANCE METHOD ###
#
# Parse incoming HTTP headers from input file handle and return
# an arrayref of header/value pairs.
#

sub parse_headers {
    my $self = shift;

    my $io_handle = $self->stdio_handle;

    my @headers;

    while ( my $input = <$io_handle> ) {
        $input =~ s/[\r\l\n\s]+$//;
        last if !$input;

        push @headers, $1 => $2
            if $input =~ /^([^()<>\@,;:\\"\/\[\]?={} \t]+):\s*(.*)/i;
    };

    return \@headers;
}

### PRIVATE INSTANCE METHOD ###
#
# Initialize CGI class. Used by constructor.
#

sub _init_cgi_class {
    my ($self, $cgi_class) = @_;
    
    # Default to CGI::Simple > 1.113 if it's available, unless the user
    # overrode cgi_class to do something else. CGI::Simple 1.113 and
    # earlier has a bug with form/multipart file upload handling, so
    # we don't use it even if it is installed.
    if ( $cgi_class ) {
        $self->cgi_class($cgi_class);
        
        if ( $cgi_class eq 'CGI' ) {
            $self->cgi_init(sub {
                local $@;
                
                eval {
                    require CGI;
                    CGI::initialize_globals();
                }
            });
        }
        else {
            $self->cgi_init(sub {
                eval "require $cgi_class";
            });
        }
    }
    elsif ( $have_cgi_simple && $self->cgi_class eq 'CGI' ) {
        $self->cgi_class('CGI::Simple');
        $self->cgi_init(undef);
    }
}

### PRIVATE INSTANCE METHOD ###
#
# Initialize dispatch table. Used by constructor.
#

sub _init_dispatch {
    my ($self, $cust_disp) = @_;
    
    my $config = $self->config;
    
    my @dispatch;

    # Set the custom handlers so they would come first served.
    # Format:
    # [ qr{URI} => \&method, ... ]
    # [ { match => qr{URI}, code => \&method, } ]
    while ( my $uri = shift @$cust_disp ) {
        $self->logit("Installing custom handler for URI: $uri");
        push @dispatch, {
            match => qr{$uri},
            code  => shift @$cust_disp,
        };
    };
    
    # The default Ext.Direct handlers always come last
    for my $type ( qw/ api router poll / ) {
        my $uri_getter = "${type}_path";
        my $handler    = "handle_extdirect_${type}";
        my $uri        = $config->$uri_getter;
        
        if ( $uri ) {
            push @dispatch, {
                match => qr/^\Q$uri\E$/, code => \&{ $handler },
            }
        }
    }

    $self->dispatch(\@dispatch);
}

### PRIVATE INSTANCE METHOD ###
#
# Do the actual heavy lifting for Ext.Direct calls
#

sub _handle_extdirect {
    my ($self, $cgi, $what) = @_;

    my $exd = CGI::ExtDirect->new({
        api    => $self->api,
        config => $self->config,
        cgi    => $cgi,
    });

    # Standard CGI headers for this handler
    my %std_cgi = ( '-nph' => 1, '-charset' => 'utf-8' );
    
    my $out = $self->stdio_handle;

    print $out $exd->$what( %std_cgi );

    return 1;
}

# Popular MIME types, taken from http://lwp.interglacial.com/appc_01.htm
my %MIME_TYPES = (
    au   => 'audio/basic',
    avi  => 'vide/avi',
    bmp  => 'image/bmp',
    bz2  => 'application/x-bzip2',
    css  => 'text/css',
    dtd  => 'application/xml-dtd',
    doc  => 'application/msword',
    gif  => 'image/gif',
    gz   => 'application/x-gzip',
    ico  => 'image/x-icon',
    hqx  => 'application/mac-binhex40',
    htm  => 'text/html',
    html => 'text/html',
    jar  => 'application/java-archive',
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    js   => 'text/javascript',
    json => 'application/json',
    midi => 'audio/x-midi',
    mp3  => 'audio/mpeg',
    mpeg => 'video/mpeg',
    ogg  => 'audio/vorbis',
    pdf  => 'application/pdf',
    pl   => 'application/x-perl',
    png  => 'image/png',
    ppt  => 'application/vnd.ms-powerpoint',
    ps   => 'application/postscript',
    qt   => 'video/quicktime',
    rdf  => 'application/rdf',
    rtf  => 'application/rtf',
    sgml => 'text/sgml',
    sit  => 'application/x-stuffit',
    svg  => 'image/svg+xml',
    swf  => 'application/x-shockwave-flash',
    tgz  => 'application/x-tar',
    tiff => 'image/tiff',
    tsv  => 'text/tab-separated-values',
    txt  => 'text/plain',
    wav  => 'audio/wav',
    xls  => 'application/excel',
    xml  => 'application/xml',
    zip  => 'application/zip',
);

### PRIVATE INSTANCE METHOD ###
#
# Return the guessed MIME type for a file name
#

# We try to use File::LibMagic or File::MimeInfo if available
{
    local $@;
    
    my $have_libmagic = $ENV{DEBUG_NO_FILE_LIBMAGIC}
                      ? !1
                      : eval "require File::LibMagic";
    
    #
    # File::MimeInfo is a bit kludgy: it depends on shared-mime-info database
    # being installed, and when said database is missing it will do only
    # very basic guessing that is not very useful. Not only that, it will
    # also complain loudly into STDERR about the missing database, which is
    # definitely not helping either. So in addition to checking if the module
    # itself is available we poke a bit deeper and decide if it's worth using.
    #
    my $have_mimeinfo = !$ENV{DEBUG_NO_FILE_MIMEINFO} &&
        eval {
            require File::MimeInfo;
            # This is a dependency of File::MimeInfo
            require File::BaseDir;

            # When both arrays are empty the module is essentially useless
            @File::MimeInfo::DIRS || File::BaseDir::data_files('mime/globs');
        };
    
    sub _guess_mime_type {
        my ($self, $file_name) = @_;
        
        my ($type, $charset);
        
        if ( $have_libmagic ) {
            my $magic = File::LibMagic->new();
            my $mime = $magic->checktype_filename($file_name);
            
            ($type, $charset) = $mime =~ m{^([^;]+);\s*charset=(.*)$};
        }
        elsif ( $have_mimeinfo ) {
            my $mimeinfo = File::MimeInfo->new();
            $type = $mimeinfo->mimetype($file_name);
        }
        
        # If none of the advanced modules are present, resort to
        # guesstimating by file extension
        else {
            my ($suffix) = $file_name =~ /.*\.(\w+)$/;
            
            $type = $MIME_TYPES{ $suffix };
        }
        
        return ($type || 'application/octet-stream', $charset);
    }
}

1;
