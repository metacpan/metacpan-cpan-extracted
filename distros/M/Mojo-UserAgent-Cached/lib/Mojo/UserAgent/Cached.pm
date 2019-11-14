package Mojo::UserAgent::Cached;

use warnings;
use strict;
use v5.10;
use Algorithm::LCSS;
use CHI;
use Cwd;
use Devel::StackTrace;
use English qw(-no_match_vars);
use File::Basename;
use File::Path;
use File::Spec;
use List::Util;
use Mojo::JSON qw/to_json/;
use Mojo::Transaction::HTTP;
use Mojo::URL;
use Mojo::Log;
use Mojo::Base 'Mojo::UserAgent';
use Mojo::File;
use POSIX;
use Readonly;
use String::Truncate;
use Time::HiRes qw/time/;

Readonly my $HTTP_OK => 200;
Readonly my $HTTP_FILE_NOT_FOUND => 404;

our $VERSION = '1.11';

# TODO: Timeout, fallback
# TODO: Expected result content (json etc)

# MOJO_USERAGENT_CONFIG
## no critic (ProhibitMagicNumbers)
has 'connect_timeout'    => sub { $ENV{MOJO_CONNECT_TIMEOUT}    // 10  };
has 'inactivity_timeout' => sub { $ENV{MOJO_INACTIVITY_TIMEOUT} // 20  };
has 'max_redirects'      => sub { $ENV{MOJO_MAX_REDIRECTS}      // 4   };
has 'request_timeout'    => sub { $ENV{MOJO_REQUEST_TIMEOUT}    // 0   };
## use critic

# MUAC_CLIENT_CONFIG
has 'local_dir'          => sub { $ENV{MUAC_LOCAL_DIR}          // q{}   };
has 'always_return_file' => sub { $ENV{MUAC_ALWAYS_RETURN_FILE} // undef };

has 'cache_agent'        => sub {
  $ENV{MUAC_NOCACHE} ? () : CHI->new(
    driver             => $ENV{MUAC_CACHE_DRIVER}             || 'File',
    root_dir           => $ENV{MUAC_CACHE_ROOT_DIR}           || '/tmp/mojo-useragent-cached',
    serializer         => $ENV{MUAC_CACHE_SERIALIZER}         || 'Storable',
    namespace          => $ENV{MUAC_CACHE_NAMESPACE}          || 'MUAC_Client',
    expires_in         => $ENV{MUAC_CACHE_EXPIRES_IN}         // '1 minute',
    expires_on_backend => $ENV{MUAC_CACHE_EXPIRES_ON_BACKEND} // 1,
    %{ shift->cache_opts || {} },
  )
};
has 'cache_opts'                 => sub { {} };
has 'cache_url_opts'             => sub { {} };
has 'logger'                     => sub { Mojo::Log->new() };
has 'access_log'                 => sub { $ENV{MUAC_ACCESS_LOG} || '' };
has 'use_expired_cached_content' => sub { $ENV{MUAC_USE_EXPIRED_CACHED_CONTENT} // 1 };
has 'accepted_error_codes'       => sub { $ENV{MUAC_ACCEPTED_ERROR_CODES} || '' };
has 'sorted_queries'             => 1;

has 'created_stacktrace' => '';

sub new {
    my ($class, %opts) = @_;

    my %mojo_agent_config = map { $_ => $opts{$_} } grep { exists $opts{$_} } qw/
        ca
        cert
        connect_timeout
        cookie_jar
        inactivity_timeout
        ioloop
        key
        local_address
        max_connections
        max_redirects
        proxy
        request_timeout
        server
        transactor
    /;

    my $ua = $class->SUPER::new(%mojo_agent_config);

    # Populate attributes
    map { $ua->$_( $opts{$_} ) } grep { exists $opts{$_} } qw/
        local_dir
        always_return_file
        cache_opts
        cache_agent
        cache_url_opts
        logger
        access_log
        use_expired_cached_content
        accepted_error_codes
        sorted_queries
    /;

    $ua->created_stacktrace($ua->_get_stacktrace);

    return bless($ua, $class);
}


sub invalidate {
    my ($self, $key) = @_;

    if ($self->is_cacheable($key)) {
        $self->logger->debug("Invalidating cache for '$key'");
        return $self->cache_agent->remove($key);
    }

    return;
}

sub expire {
    my ($self, $key) = @_;

    if ($self->is_cacheable($key)) {
        $self->logger->debug("Expiring cache for '$key'");
        return $self->cache_agent->expire($key);
    }

    return;
}

sub build_tx {
  my ($self, $method, $url, @more) = @_;

  $url = ($self->always_return_file || $url);

  if ($url !~ m{^(/|[^/]+:)}) {
    if ($self->local_dir) {
      $url = 'file://' . File::Spec->catfile($self->local_dir, "$url");
    } elsif ($self->always_return_file) {
      $url = 'file://' . "$url";
    } elsif ($url !~ m{^(/|[^/]+:)}) {
      $url = 'file://' . Cwd::realpath("$url");
    }
  }

  $self->transactor->tx($method, $url, @more);
}

sub start {
  my ($self, $tx, $cb) = @_;

  my $url     = $tx->req->url;
  my $method  = $tx->req->method;
  my $headers = $tx->req->headers->to_hash(1);
  my $content = $tx->req->content->asset->slurp;
  $url = $self->sort_query($url) if $self->sorted_queries;

  delete $headers->{'User-Agent'};
  delete $headers->{'Accept-Encoding'};
  my @opts = (($method eq 'GET' ? () : $method), (keys %{ $headers || {} } ? $headers : ()), $content || ());
  my $key = $self->generate_key($url, @opts);
  my $start_time = time;

  # We wrap the incoming callback in our own callback to be able to cache the response
  my $wrapper_cb = $cb ? sub {
    my ($ua, $tx) = @_;
    $cb->($ua, $ua->_post_process_get($tx, $start_time, $key, @opts));
  } : ();
  # Is an absolute URL or an URL relative to the app eg. http://foo.com/ or /foo.txt
  if ($url !~ m{ \A file:// }gmx && (Mojo::URL->new($url)->is_abs || ($url =~ m{ \A / }gmx && !$self->always_return_file))) {
    if ($self->is_cacheable($key)) {
      my $serialized = $self->cache_agent->get($key);
      if ($serialized) {
        my $cached_tx = _build_fake_tx($serialized);
        $self->_log_line($cached_tx, {
          start_time => $start_time,
          key => $key,
          type => 'cached result',
        });
        return $cb->($self, $cached_tx) if $cb;
        return $cached_tx;
      }
    }
    # Fork-safety
    $self->_cleanup->server->restart unless ($self->{pid} //= $$) eq $$;
    # Non-blocking
    if ($wrapper_cb) {
      warn "-- Non-blocking request (@{[_url($tx)]})\n" if Mojo::UserAgent::DEBUG;
      return $self->_start(Mojo::IOLoop->singleton, $tx, $wrapper_cb);
    }

    # Blocking
    warn "-- Blocking request (@{[_url($tx)]})\n" if Mojo::UserAgent::DEBUG;
    $self->_start($self->ioloop, $tx => sub { shift->ioloop->stop; $tx = shift });
    $self->ioloop->start;

    return $self->_post_process_get( $tx, $start_time, $key, @opts );
  } else { # Local file eg. t/data/foo.txt or file://.*/
    $url =~ s{file://}{};
    my $code = $HTTP_FILE_NOT_FOUND;
    my $res;
    eval {
      $res = $self->_parse_local_file_res($url);
      $code = $res->{code};
    } or $self->logger->error($EVAL_ERROR);

    my $params = { url => $url, body => $res->{body}, code => $code, method => 'FILE', headers => $res->{headers} };

    # first non-blocking, if no callback, regular post process
    my $tx = _build_fake_tx($params);
    $self->_log_line($tx, {
      start_time => $start_time,
      key => $key,
      type => 'local file',
    });

    return $cb->($self, $tx) if $cb;
    return $tx;
  }

  return $tx;
}

sub _post_process_get {
    my ($self, $tx, $start_time, $key) = @_;

    if ( $tx->req->url->scheme ne 'file' && $self->is_cacheable($key) ) {
        if ( $self->is_considered_error($tx) ) {
            # Return an expired+cached version of the page for other errors
            if ( $self->use_expired_cached_content ) { # TODO: URL by URL, and case-by-case expiration
                if (my $cache_obj = $self->cache_agent->get_object($key)) {
                    my $serialized = $cache_obj->value;
                    $serialized->{headers}->{'X-Mojo-UserAgent-Cached-ExpiresAt'} = $cache_obj->expires_at($key);

                    my $expired_tx = _build_fake_tx($serialized);
                    $self->_log_line( $expired_tx, {
                        start_time => $start_time,
                        key        => $key,
                        type       => 'expired and cached',
                        orig_tx    => $tx,
                    });

                    return $expired_tx;
                }
            }
        } else {
            # Store object in cache
            $self->cache_agent->set($key, _serialize_tx($tx), $self->_cache_url_opts($tx->req->url));
        }
    }

    $self->_log_line($tx, {
        start_time => $start_time,
        key => $key,
        type => 'fetched',
    });

    return $tx;
}

sub _cache_url_opts {
    my ($self, $url) = @_;
    my ($pat, $opts) = List::Util::pairfirst { $url =~ /$a/; } %{ $self->cache_url_opts || {} };
    return $opts || ();
}

sub set {
    my ($self, $url, $value) = @_;

    my $key = $self->generate_key($url);
    $self->logger->debug("Illegal cache key: $key") && return if ref $key;

    my $fake_tx = _build_fake_tx({
        url    => $key,
        body   => $value,
        code   => $HTTP_OK,
        method => 'FILE'
    });

    $self->logger->debug("Set cache key: $key");
    $self->cache_agent->set($key, _serialize_tx($fake_tx));
    return $key;
}

sub is_valid {
    my ($self, $key) = @_;

    ($self->logger->debug("Illegal cache key: $key") && return) if ref $key;

    $self->logger->debug("Checking if key is valid: $key");
    return $self->cache_agent->is_valid($key);
}

sub is_cacheable {
    my ($self, $url) = @_;

    return $self->cache_agent && ($url !~ m{ \A / }gmx);
}

sub generate_key {
    my ($self, $url, @opts) = @_;

    my $cb = ref $opts[-1] eq 'CODE' ? pop @opts : undef;

    my $key = join q{,}, $self->sort_query($url), (@opts ? to_json(@opts > 1 ? \@opts : $opts[0]) : ());

    return $key;
}

sub is_considered_error {
    my ($self, $tx) = @_;

    # If we find some error codes that should be accepted, we don't consider this an error
    if ( $tx->error && $self->accepted_error_codes ) {
        my $codes = ref $self->accepted_error_codes ?     $self->accepted_error_codes
                  :                                   [ ( $self->accepted_error_codes ) ];
        return if List::Util::first { $tx->error->{code} == $_ } @{$codes};
    }

    return $tx->error;
}

sub sort_query {
    my ($self, $url) = @_;
    $url = Mojo::URL->new($url);

    my $flattened_sorted_url = ($url->protocol ? ( $url->protocol . '://' ) : '' ) .
                               ($url->host     ? ( $url->host_port        ) : '' ) .
                               ($url->path     ? ( $url->path             ) : '' ) ;

    $flattened_sorted_url .= '?' . join '&', sort { $a cmp $b } List::Util::pairmap { (($b ne '') ? (join '=', $a, $b) : $a); } @{ $url->query }
        if scalar @{ $url->query };

    return $flattened_sorted_url;
}

sub _serialize_tx {
    my ($tx) = @_;

    $tx->res->headers->header('X-Mojo-UserAgent-Cached', time);

    return {
        method  => $tx->req->method,
        url     => $tx->req->url,
        code    => $tx->res->code,
        body    => $tx->res->body,
        json    => $tx->res->json,
        headers => $tx->res->headers->to_hash,
    };
}

sub _build_fake_tx {
    my ($opts) = @_;

    # Create transaction object to return so we look like a regular request
    my $tx = Mojo::Transaction::HTTP->new();

    $tx->req->method($opts->{method});
    $tx->req->url(Mojo::URL->new($opts->{url}));

    $tx->res->headers->from_hash($opts->{headers});

    my $now = time;
    $tx->res->headers->header('X-Mojo-UserAgent-Cached-Age', $now - ($tx->res->headers->header('X-Mojo-UserAgent-Cached') || $now));

    $tx->res->code($opts->{code});
    $tx->res->{json} = $opts->{json};
    $tx->res->body($opts->{body});

    return $tx;
}

sub _parse_local_file_res {
    my ($self, $url) = @_;

    my $headers;
    my $body = Mojo::File->new($url)->slurp;
    my $code = $HTTP_OK;
    my $msg  = 'OK';

    if ($body =~ m{\A (?: DELETE | GET | HEAD | OPTIONS | PATCH | POST | PUT ) \s }gmx) {
        my $code_msg_headers;
        my $code_msg;
        my $http;
        my $msg;
        (undef, $code_msg_headers, $body) = split m{(?:\r\n|\n){2,}}mx, $body,             3; ## no critic (ProhibitMagicNumbers)
        ($code_msg, $headers)             = split m{(?:\r\n|\n)}mx,     $code_msg_headers, 2;
        ($http, $code, $msg)              = $code_msg =~ m{ \A (?:(\S+) \s+)? (\d+) \s+ (.*) \z}mx;

        $headers = Mojo::Headers->new->parse("$headers\n\n")->to_hash;
    }

    return { body => $body, code => $code, message => $msg, headers => $headers };
}

sub _write_local_file_res {
    my ($self, $tx, $dir) = @_;

    return unless ($dir && -e $dir && -d $dir);

    my $method = $tx->req->method;
    my $url  = $tx->req->url;
    my $body = $tx->res->body;
    my $code = $tx->res->code;
    my $message = $tx->res->message;

    my $target_file = File::Spec->catfile($dir, split '/', $url->path_query);
    File::Path::make_path(File::Basename::dirname($target_file));
    Mojo::File->new($target_file)->spurt((
        join "\n\n",
           (join " ", $method, "$url\n"  ) . $tx->req->headers->to_string,
           (join " ", $code, "$message\n") . $tx->res->headers->to_string,
           $body
        )
    ) and $self->logger->debug("Wrote request+response to: '$target_file'");
}

sub _log_line {
    my ($self, $tx, $opts) = @_;

    $self->_write_local_file_res($tx, $ENV{MUAC_CLIENT_WRITE_LOCAL_FILE_RES_DIR});

    my $callers = $self->_get_stacktrace;
    my $created_stacktrace = $self->created_stacktrace;

    # Remove common parts to get smaller created stacktrace
    my $strings = Algorithm::LCSS::CSS_Sorted( [ split /,/, $callers ] , [ split /,/, $created_stacktrace ] );
    map {
        my @lcss = @{$_};
        my $pat = join ",", @lcss[1..$#lcss-1];
        if (scalar @lcss > 2) { $created_stacktrace =~ s{$pat}{,}mx }
    } @{ $strings || [] };

    $self->logger->debug(sprintf(q{Returning %s '%s' => %s for %s (%s)}, (
        $opts->{type},
        String::Truncate::elide( $tx->req->url, 150, { truncate => 'middle'} ),
        ($tx->res->code || $tx->res->error->{code} || $tx->res->error->{message}),
        $callers, $created_stacktrace
    )));

    return unless $self->access_log;

    my $elapsed_time = sprintf '%.3f', (time-$opts->{start_time});

    my $NONE = q{-};

    my $http_host              = $tx->req->url->host                                   || $NONE;
    my $remote_addr            =                                                          $NONE;
    my $time_local             = POSIX::strftime('%d/%b/%Y:%H:%M:%S %z', localtime)    || $NONE;
    my $request                = ($tx->req->method . q{ } . $tx->req->url->path_query) || $NONE;
    my $status                 = $tx->res->code                                        || $NONE;
    my $body_bytes_sent        = length $tx->res->body                                 || $NONE;
    my $http_referer           = $callers                                              || $NONE;
    my $http_user_agent        = __PACKAGE__ . "(" . $opts->{type} .")"                || $NONE;
    my $request_time           = $elapsed_time                                         || $NONE;
    my $upstream_response_time = $elapsed_time                                         || $NONE;
    my $http_x_forwarded_for   =                                                          $NONE;

    # Use sysopen, slightly slower and hits disk, but avoids clobbering
    sysopen my $fh, $self->access_log,  O_WRONLY | O_APPEND | O_CREAT; ## no critic (ProhibitBitwiseOperators)
    syswrite $fh, qq{$http_host $remote_addr [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time $upstream_response_time "$http_x_forwarded_for"\n}
        or $self->logger->warn("Unable to write to '" . $self->access_log . "': $OS_ERROR");
    close $fh or $self->logger->warn("Unable to close '" . $self->access_log . "': $OS_ERROR");

    return;
}

sub _get_stacktrace {
    my ($self) = @_;

    my @frames = ( Devel::StackTrace->new(
        ignore_class => [ 'Devel::StackTrace', 'Mojo::UserAgent::Cached', 'Template::Document', 'Template::Context', 'Template::Service' ],
        frame_filter => sub { ($_[0]->{caller}->[0] !~ m{ \A Mojo | Try }gmx) },
    )->frames() );

    my $prev_package = '';
    my $callers = join q{,}, map {
        my $package = $_->package;
        if ($package eq 'Template::Provider') {
            $package = (join "/", grep { $_ } (split '/', $_->filename)[-3..-1]);
        }
        if ($prev_package eq $package) {
            $package = '';
        } else {
            $prev_package = $package;
            $package =~ s/(?:(\w)\w*::)/$1./gmx;
            $package .= ':';
        }
        $package . $_->line();
    } grep { $_ } @frames;
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Cached - Caching, Non-blocking I/O HTTP, Local file and WebSocket user agent

=head1 SYNOPSIS

  use Mojo::UserAgent::Cached;

  my $ua = Mojo::UserAgent::Cached->new;

=head1 DESCRIPTION

L<Mojo::UserAgent::Cached> is a full featured caching, non-blocking I/O HTTP, Local file and WebSocket user
agent, with IPv6, TLS, SNI, IDNA, Comet (long polling), keep-alive, connection
pooling, timeout, cookie, multipart, proxy, gzip compression and multiple
event loop support.

It inherits all of the features L<Mojo::UserAgent> provides but in addition allows you to
retrieve cached content using a L<CHI> compatible caching engine.

See L<Mojo::UserAgent> and L<Mojolicious::Guides::Cookbook/"USER AGENT"> for more.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Cached> inherits all attributes from L<Mojo::UserAgent> and implements the following new ones.

=head2 local_dir

  my $local_dir = $ua->local_dir;
  $ua->local_dir('/path/to/local_files');

Sets the local dir, used as a prefix where relative URLs are fetched from. A C<get('foobar.txt')> request would
read the file '/tmp/foobar.txt' if local_dir is set to '/tmp', defaults to the value of the
C<MUAC_LOCAL_DIR> environment variable and if not set, to ''.

=head2 always_return_file

  my $file = $ua->always_return_file;
  $ua->always_return_file('/tmp/default_file.txt');

Makes all consecutive request return the same file, no matter what file or URL is requested with C<get()>, defaults
to the value of the C<MUAC_ALWAYS_RETURN_FILE> environment value and if not, it respects the File/URL in the request.

=head2 cache_agent

  my $cache_agent = $ua->cache_agent;
  $ua->cache_agent(CHI->new(
    driver             => $ENV{MUAC_CACHE_DRIVER}             || 'File',
    root_dir           => $ENV{MUAC_CACHE_ROOT_DIR}           || '/tmp/mojo-useragent-cached',
    serializer         => $ENV{MUAC_CACHE_SERIALIZER}         || 'Storable',
    namespace          => $ENV{MUAC_CACHE_NAMESPACE}          || 'MUAC_Client',
    expires_in         => $ENV{MUAC_CACHE_EXPIRES_IN}         // '1 minute',
    expires_on_backend => $ENV{MUAC_CACHE_EXPIRES_ON_BACKEND} // 1,
  ));

Tells L<Mojo::UserAgent::Cached> which cache_agent to use. It needs to be CHI-compliant and defaults to the above settings.

You may also set the C<$ENV{MUAC_NOCACHE}> environment variable to avoid caching at all.

=head2 cache_opts

  my $cache_opts = $ua->cache_opts;
  $ua->cache_opts({ expires_in => '5 minutes' });

Allows passing in cache options that will be appended to existing options in default cache agent creation.

=head2 cache_url_opts

  my $urls_href = $ua->cache_url_opts;
  $ua->cache_url_opts({ 
    'https?://foo.com/long-lasting-data.*' => { expires_in => '2 weeks' }, # Cache some data two weeks
    '.*' => { expires_at => 0 }, # Don't store anything in cache
  });
   
Accepts a hash ref of regexp strings and expire times, this allows you to define cache validity time for individual URLs, hosts etc.
The first match will be used.

=head2 logger

Provide a logging object, defaults to Mojo::Log

  # Example:
  # Returning fetched 'https://graph.facebook.com?ids=http%3A%2F%2Fexample.com%2Flivet%2F20...-lommebok&access_token=1234' => 200 for A.C.Facebook:133,185,183,A.M.F.ArticleList:19,9,A.M.Selector:47,responsive/modules/most-shared.html.tt:15,15,13,templates/inc/macros.tt:125,138,templates/responsive/frontpage.html.tt:10,10,16,Template:66,A.G.C.Article:338,147,main:14 (A.C.Facebook:68,E.C.Sandbox_874:7,A.C.Facebook:133,,,main:14)

Format:
  Returning <cache-status> '<URL>' => 'HTTP code' for <request_stacktrace> (<created_stacktrace>)

  cache-status: (cached|fetched|cached+expired)
  URL: the URL requested, shortened when it is really long
  request_stacktrace: Simplified stacktrace with leading module names shortened, also includes TT stacktrace support. Line numbers in the same module are grouped (order kept of course).
  created_stacktrace: Stack trace for creation of UA object, useful to see what options went in, and which object is used. Same format as normal stacktrace, but skips common parts.
  
  Example:
    created_stacktrace: A.C.Facebook:68,E.C.Sandbox_874:7,A.C.Facebook:133,<common part replaced>,main:14
    stacktrace: A.C.Facebook:133,< common part: 185,183,A.M.F.ArticleList:19,9,A.M.Selector:47,responsive/modules/most-shared.html.tt:15,15,13,templates/inc/macros.tt:125,138,templates/responsive/frontpage.html.tt:10,10,16,Template:66,A.G.C.Article:338,147 >,main:14

=head2 access_log

A file that will get logs of every request, the format is a hybrid of Apache combined log, including time spent for the request.
If provided the file will be written to. Defaults to C<$ENV{MUAC_ACCESS_LOG} || ''> which means no log will be written.

=head2 use_expired_cached_content

Indicates that we will send expired, cached content back. This means that if a request fails, and the cache has expired, you
will get back the last successful content. Defaults to C<$ENV{MUAC_EXPIRED_CONTENT} // 1>

=head2 accepted_error_codes

A list of error codes that should not be considered as errors. For instance this means that the client will not look for expired
cached content for requests that result in this response. Defaults to C<$ENV{MUAC_ACCEPTED_ERROR_CODES} || ''>

=head2 sorted_queries

Setting this to a true value will sort query parameters in the resulting URL. This means that requests will be identical if the key/value pairs
are the same. This helps when URLs have been built up using hashes that may have random orders.

=head1 OVERRIDEN ATTRIBUTES

In addition L<Mojo::UserAgent::Cached> overrides the following L<Mojo::UserAgent> attributes.

=head2 connect_timeout

Defaults to C<$ENV{MOJO_CONNECT_TIMEOUT} // 2>

=head2 inactivity_timeout

Defaults to C<$ENV{MOJO_INACTIVITY_TIMEOUT} // 5>

=head2 max_redirects

Defaults to C<$ENV{MOJO_MAX_REDIRECTS} // 4>

=head2 request_timeout

Defaults to C<$ENV{MOJO_REQUEST_TIMEOUT} // 10>

=head1 METHODS

L<Mojo::UserAgent::Cached> inherits all methods from L<Mojo::UserAgent> and
implements the following new ones.

=head2 invalidate

  $ua->invalidate($key);

Deletes the cache of the given $key.

=head2 expire

  $ua->expire($key);

Set the cache of the given $key as expired.

=head2 set

  my $tx = $ua->build_tx(GET => "http://localhost:$port", ...);
  $tx = $ua->start($tx);
  my $cache_key = $ua->generate_key("http://localhost:$port", ...);
  $ua->set($cache_key, $tx);

Set allows setting data directly for a given URL

=head2 generate_key(@params)

Returns a key to be used for the cache agent. It accepts the same parameters
that a normal ->get() request does.

=head2 validate_key

  my $status = $ua4->validate_key('http://example.com');

Fast validates if key is valid in cache without doing fetch.
Return 1 if true.

=head2 sort_query($url)

Returns a string with the URL passed, with sorted query parameters suitable for cache lookup

=head1 OVERRIDEN METHODS

=head2 new

  my $ua = Mojo::UserAgent::Cached->new( request_timeout => 1, ... );

Accepts the attributes listed above and all attributes from L<Mojo::UserAgent>.
Stores its own attributes and passes on the relevant ones when creating a
parent L<Mojo::UserAgent> object that it inherits from. Returns a L<Mojo::UserAgent::Cached> object

=head2 get(@params)

  my $tx = $ua->get('http://example.com');

Accepts the same arguments and returns the same as L<Mojo::UserAgent>.

It will try to return a cached version of the $url, adhering to the set or default attributes.

In addition if a relative file path is given, it tries to return the file appended to
the attribute C<local_dir>. In this case a fake L<Mojo::Transaction::HTTP> object is returned,
populated with a L<Mojo::Message::Request> with method and url, and a L<Mojo::Message::Response>
with headers, code and body set.

=head1 ENVIRONMENT VARIABLES

C<$ENV{MUAC_CLIENT_WRITE_LOCAL_FILE_RES_DIR}> can be set to a directory to store a request in:

  # Re-usable local file with headers and metadata ends up at 't/data/dir/lol/foo.html?bar=1'
  $ENV{MUAC_CLIENT_WRITE_LOCAL_FILE_RES_DIR}='t/data/dir';
  Mojo::UserAgent::Cached->new->get("http://foo.com/lol/foo.html?bar=1");

=head1 SEE ALSO

L<Mojo::UserAgent>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 COPYRIGHT

Nicolas Mendoza (2015-), ABC Startsiden (2015)

=head1 LICENSE

Same as Perl licence as per agreement with ABC Startsiden on 2015-06-02

=cut
