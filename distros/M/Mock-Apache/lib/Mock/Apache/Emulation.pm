package Mock::Apache::Emulation;


##############################################################################

package                 # hide from PAUSE indexer
    Apache;

use Carp;
use HTTP::Request;
use Readonly;
use Scalar::Util qw(weaken);
use URI;
use URI::QueryParam;

use parent qw(Class::Accessor);

__PACKAGE__->mk_ro_accessors(qw( log
                                 _env
                                 _uri
                                 _mock_client
                                 _output
                              ));

our $server;
our $request;

# Create a new Apache request
# Apache->_new_request($mock_client, @params)

sub _new_request {
    my $class = shift;
    my $mock_client = shift;

    # Set up environment for later - %ENV entries will be localized

    my $env = { GATEWAY_INTERFACE => 'CGI-Perl/1.1',
                MOD_PERL          => '1.3',
                SERVER_SOFTWARE   => 'Apache emulation (Mock::Apache)',
                REMOTE_ADDR       => $mock_client->remote_addr,
                REMOTE_HOST       => $mock_client->remote_host };

    my $r = $class->SUPER::new( { request_time   => time,
                                  is_initial_req => 1,
                                  is_main        => 1,
                                  server         => $mock_client->mock_apache->server,
                                  connection     => $mock_client->connection,
                                  _mock_client   => $mock_client,
                                  _env           => $env,
                                  _output        => '',
                                } );

    local $Mock::Apache::DEBUG = 0;

    $r->{log}           ||= $r->{server}->log;
    $r->{notes}           = Apache::Table->new($r);
    $r->{pnotes}          = Apache::Table->new($r, 1);
    $r->{headers_in}      = Apache::Table->new($r);
    $r->{headers_out}     = Apache::Table->new($r);
    $r->{err_headers_out} = Apache::Table->new($r);
    $r->{subprocess_env}  = Apache::Table->new($r);

    $request = $r;
    $server  = $r->{server};

    # Having set up a skeletal request object, see about fleshing out the detail

    my $initializer = (@_ == 1) ? shift : HTTP::Request->new(@_);
    croak('request initializer must be an HTTP:Request object')
        unless $initializer->isa('HTTP::Request');
    $r->_initialize_from_http_request_object($initializer);


    # Expand the environment with information from server object

    $env->{DOCUMENT_ROOT} ||= $r->document_root;
    $env->{SERVER_ADMIN}  ||= $server->server_admin;
    $env->{SERVER_NAME}   ||= $server->server_hostname;
    $env->{SERVER_PORT}   ||= $r->get_server_port;

    # TODO: AUTH_TYPE, CONTENT_LENGTH, CONTENT_TYPE, PATH_INFO,
    # PATH_TRANSLATED, QUERY_STRING, REMOTE_IDENT, REMOTE_USER,
    # REQUEST_METHOD, SCRIPT_NAME, SERVER_PROTOCOL, UNIQUE_ID

    while (my($key, $val) = each %$env) {
        $r->{subprocess_env}->set($key, $val);
    }

    return $r;
}

sub _initialize_from_http_request_object {
    my ($r, $http_req) = @_;

#    $DB::single=1;

    my $uri = $http_req->uri;
    $uri = URI->new($uri) unless ref $uri;

    $r->{method}   = $http_req->method;
    $r->{_uri}     = $uri;
    ($r->{uri}     = $uri->path) =~ s{^/}{};
    $r->{protocol} = 'HTTP/1.1';
    $r->{content}  = $http_req->content;

    $http_req->headers->scan( sub {
                                  my ($key, $value) = @_;
                                  $r->headers_in->set($key, $value);
                                  (my $header_env = "HTTP_$key") =~ s/-/_/g;
                                  $r->{subprocess_env}->set($header_env, $value);
                              } );

    return;
}

################################################################################
#
# The Request Object                                                    MPPR p23
#
# Handlers are called with a reference to the current request object (Apache),
# which by convention is named $r.

# $r = Apache->request([$r])                                            MPPR p23
# Returns a reference to the request object.  Perl handlers are called with a
# reference to the request object as the first argument.
sub request {
    DEBUG('Apache->request => ' . $request);
    return $request
}

# $bool = $r->is_initial_req                                            MPPR p23
# Returns true if the current request is the initial request, and false if it is
# a subrequest or an internal redirect.
sub is_initial_req {
    my ($r) = @_;
    my $bool = $r->{is_initial_req};
    DEBUG('$r->is_initial_req => %s', $bool ? 'true' : 'false');
    return $bool;
}

# $bool = $r->is_main                                                   MPPR p23
# Returns true if the current request is the initial request or an internal
# redirect, and false if it is a subrequest.
sub is_main {
    my ($r) = @_;
    my $bool = $r->{is_main};
    DEBUG('$r->is_main => %s', $bool ? 'true' : 'false');
    return $bool;
}

# $req = $r->last                                                       MPPR p24
# Returns a reference to the last request object in the chain.  When used in a 
# logging handler, this is the request object that generated the final result.
sub last {
    my ($r) = @_;
    my $req = undef;
    DEBUG('$r->last => %s', ref $req ? $req : 'undef');
    return $req;
}

# $req = $r->main                                                       MPPR p24
# Returns a reference to the main (intitial) request object, or undef if $r is
# the main request obeject.
sub main {
    my ($r) = @_;
    my $req = $r->{main};
    DEBUG('$r->main => %s', ref $req ? $req : 'undef');
    return $req;
}

# $req = $r->next                                                       MPPR p24
# Returns a reference to the next request object in the chain.
sub next {
    my ($r) = @_;
    my $req = undef;
    DEBUG('$r->next => %s', ref $req ? $req : 'undef');
    return $req;
}

# $req = $r->prev                                                       MPPR p24
# Returns a reference to the previous request object in the chain.  When used in
# an error handler, this is the request that triggered the error.
sub prev {
    my ($r) = @_;
    my $req = undef;
    DEBUG('$r->prev => %s', ref $req ? $req : 'undef');
    return $req;
}


################################################################################
#
# The Apache::SubRequest Class                                          MPPR p24
#
# The Apache::SubRequest Class is a subclass of Apache and inherits its methods.

# $subr = $r->lookup_file($filename)                                    MPPR p24
# Fetches a subrequest object by filename.
sub lookup_file {
    my ($r, $file) = @_;

    $DB::single=1;
    return $r->new( uri            => $file,
                    is_initial_req => 0 );
}

# $subr = $r->lookup_uri($uri)                                          MPPR p24
# Fetches a subrequest object by URI.
sub lookup_uri {
    my ($r, $uri) = @_;

    $DB::single=1;
    return $r->new( uri            => $uri,
                    is_initial_req => 0 );
}


# $subr->run                                                            MPPR p24
# Invokes the subrequest's content handler and the returns the content handler's
# status code.
{
    package
        Apache::SubRequest;

    our @ISA = qw(Apache);
    sub run {
        my ($r) = @_;
        NYI_DEBUG('$r->run');
    }
}


################################################################################
#
# Client request methods                                                MPPR p24

# {$str|@arr} = $r->args                                                MPPR p24
# FIXME: query_form_hash does not return the right data if keys are repeated
sub args {
    my $r = shift;
    DEBUG('$r->args => %s', wantarray ? '( @list )' : $r->_uri->query);
    return wantarray ? $r->_uri->query_form_hash : $r->_uri->query;
}

# $c = $r->connection                                                   MPPR p25
sub connection {
    my ($r) = @_;
    my $connection = $r->{connection};
    DEBUG('$r->connection => %s', ref $connection ? $connection : 'undef');
    return $connection;
}

# {$str|@arr} = $r->content                                             MPPR p25
sub content {
    my ($r) = @_;
    my $content = $r->{content};
    DEBUG('$r->content => %s',
          wantarray ? '( \'' . substr($content, 0, 20) . '...\'' : substr($content, 0, 20) . '...');
    return wantarray ? split(qr{\n}, $content) : $content;

}

# $str = $r->filename([$newfilename])                                   MPPR p25
sub filename {
    my ($r, $newfilename) = @_;
    my $filename = $r->{filename};
    DEBUG('$r->filename(%s)%s',
          @_ > 1 ? "'$newfilename'" : '',
          defined wantarray ? " => $filename" : '');
    $r->{filename} = $newfilename if @_ > 1;
    return $filename;
}

# $handle = $r->finfo()                                                 MPPR p25
sub finfo {
    my ($r) = @_;
    NYI_DEBUG('$r->finfo');
}

# $str = $r->get_remote_host([$lookup_type])                            MPPR p25
# FIXME: emulate lookups properly
sub get_remote_host {
    my ($r, $type) = @_;
    DEBUG('$r->get_remote_host(%s)', $type);
    if (@_ == 0 or $type == $Apache::Constant::REMOTE_HOST) {
        return $r->_mock_client->remote_host;
    }
    elsif ($type == $Apache::Constant::REMOTE_ADDR) {
        return $r->_mock_client->remote_addr;
    }
    elsif ($type == $Apache::Constant::REMOTE_NOLOOKUP) {
        return $r->_mock_client->remote_addr;
    }
    elsif ($type == $Apache::Constant::REMOTE_DOUBLE_REV) {
        return $r->_mock_client->remote_addr;
    }
    else {
        croak "unknown lookup type";
    }
}

# $str = $r->get_remote_logname                                        MPPR p26
sub get_remote_logname {
    my ($r) = @_;
    NYI_DEBUG('$r->get_remote_logname');
}

# $str = $r->header_in($key[, $value])                                  MPPR p26
# $str = $r->header_out($key[, $value])                                 MPPR p26
# $str = $r->err_header_out($key[, $value])                             MPPR p26
sub header_in       { shift->{headers_in}->_get_or_set(@_); }
sub header_out      { shift->{headers_out}->_get_or_set(@_); }
sub err_header_out  { shift->{err_headers_out}->_get_or_set(@_); }

# {$href|%hash} = $r->headers_in                                        MPPR p26
# {$href|%hash} = $r->headers_out                                       MPPR p26
# {$href|%hash} = $r->err_headers_out                                   MPPR p26
sub headers_in      { shift->{headers_in}->_hash_or_list; }
sub headers_out     { shift->{headers_out}->_hash_or_list; }
sub err_headers_out { shift->{err_headers_out}->_hash_or_list; }


# $bool = $r->header_only                                               MPPR p26
sub header_only {
    my $r = shift;
    my $bool = $r->{method} eq 'HEAD';
    DEBUG('$r->header_only => %s', $bool ? 'true' : 'false');
    return $bool;
}

# $str = $r->method([$newval])                                          MPPR p26
# FIXME: method should be settable
sub method {
    my ($r, $newval) = @_;
    my $val = $r->{method};
    DEBUG('\$r->(\'%s\') => \'%s\'', $newval, $val);
    if (@_ > 1) {
        $r->{method} = $newval;
    }
    return $val;
}

# $num = $r->method_number([$newval])                                   MPPR p26
# FIXME: deal with newval (need to update method)
sub method_number {
    my ($r, $newval) = @_;
    my $method = eval '&Apache::Constants::M_' . $_[0]->{method};
    DEBUG('$r->method_number(%s) => %d', @_ > 1 ? $newval : '', $method);
    return $method;
}

# $str = $r->parsed_uri                                                 MPPR p26
sub parsed_uri {
    my ($r) = @_;
    my $uri = $r->{_uri};
    DEBUG('$r->parsed_uri => %s', ref $uri ? $uri : 'undef');
    return $uri;
}

# $str = $r->path_info([$newval])                                       MPPR p26
sub path_info {
    my ($r) = @_;
    my $str = $r->{_uri}->path_info;
    DEBUG('$r->path_info => \'%s\'', $str);
    return $str;
}

# $str = $r->protocol                                                   MPPR p26
sub protocol {
    my ($r) = @_;
    my $str = $r->{protocol};
    DEBUG('$r->protocol => \'%s\'', $str);
    return $str;
}

# $str = $r->the_request                                                MPPR p26
sub the_request {
    my ($r) = @_;
    my $str = eval {
        local $Mock::Apache::DEBUG = 0;
        sprintf("%s %s %s", $r->method, $r->{_uri}, $r->protocol);
    };
    DEBUG('$r->the_request => \'%s\'', $str);
    return $str;
}

# $str = $r->uri([$newuri])                                             MPPR p27
sub uri {
    my ($r, $newuri) = @_;
    my $uri = $r->{uri};
    DEBUG('$r->uri(%s) => %s', @_ > 1 ? "'$newuri'" : '', $uri);
    $r->{uri} = $newuri if @_ > 1;
    return $uri;
}


################################################################################
#
# Server Response Methods                                              MPPR p27

# $str = $r->cgi_header_out                                            MPPR p28
sub cgi_header_out {
    NYI_DEBUG('$r->cgi_header_out');
}

# $str = $r->content_encoding([$newval])                               MPPR p28
sub content_encoding {
    my ($r, $newval) = @_;
    my $encoding = $r->{content_encoding};
    DEBUG('$r->content_encoding(%s) => \'%s\'', @_ > 1 ? sprintf("'%s'", $newval || '') : '', $encoding);
    $r->{content_encoding} = $newval if @_ > 1;
    return $encoding;
}

sub content_languages {
    NYI_DEBUG('$r->content_languages');
}

# $str = $r->content_type([$newval])                                   MPPR p28
sub content_type {
    my ($r, $newval) = @_;
    my $content_type = $r->{content_type};
    DEBUG('$r->content_type(%s) => \'%s\'', @_ > 1 ? "'$newval'" : '', $content_type);
    if (@_ > 1) {
        $r->{content_type} = $newval;
        local $Mock::Apache::DEBUG = 0;
        $r->header_out('content-type' => $newval);
    }
    return $content_type;
}


# $num = $r->request_time                                              MPPR p29
# Returns the time at which the request started as a Unix time value.
sub request_time {
    my ($r) = @_;
    my $num = $r->{request_time};
    DEBUG('$r->request_time => %d', $num);
    return $num;
}

# $num = $r->status([$newval])                                         MPPR p29
# Gets or sets the status code of the outgoing response.  Symbolic names for
# all standard status codes are provided by the Apache::Constants module.
sub status   {
    my ($r, $newval) = @_;
    my $status = $r->{status};
    DEBUG('$r->status(%s) => %d', @_ > 1 ? "$newval" : '', $status);
    $r->{status} = $r->{status_line} = $newval if @_ > 1;
    return $status;
}

# $str = $r->status_line([$newstr])                                    MPPR p29
sub status_line   {
    my ($r, $newval) = @_;
    my $status_line = $r->{status_line};
    DEBUG('$r->status_line(%s) => %d', @_ > 1 ? "$newval" : '', $status_line);
    if (@_ > 1) {
        if (($r->{status_line} = $newval) =~ m{^(\d\d\d)}x) {
            $r->status($1);
        }
    }
    return $status_line;
}


# FIXME: need better implementation of print
sub print {
    my ($r, @list) = @_;
    foreach my $item (@list) {
        $r->{_output} .= ref $item eq 'SCALAR' ? $$item : $item;
    }
    return;
}

# $r->send_http_header([$content_type])                                 MPPR p30
sub send_http_header{
    my ($r, $content_type) = @_;
    DEBUG('$r->send_http_header(%s)', @_ > 1 ? "'$content_type" : '');
    return;
}



# {$str|$href} = $r->notes([$key[,$val]])                               MPPR p31
# with no arguments returns a reference to the notes table
# otherwise gets or sets the named note
sub notes {
    my $r = shift;
    my $notes = $r->{notes};
    return @_ ? $notes->_get_or_set(@_) : $notes->_hash_or_list;
}

# {$str|$href} = $r->pnotes([$key[,$val]])                              MPPR p31
# with no arguments returns a reference to the pnotes table
# otherwise gets or sets the named pnote
sub pnotes {
    my $r = shift;
    my $pnotes = $r->{pnotes};
    return @_ ? $pnotes->_get_or_set(@_) : $pnotes->_hash_or_list;
}

# $str = $r->document_root                                              MPPR p32
sub document_root {
    my $r = shift;
    my $str = $r->{server}->{document_root};
    DEBUG('$r->document_root => \'%s\'', $str);
    return $str;
}

# $num = $r->server_port                                                MPPR p33
sub get_server_port {
    my $r = shift;
    my $port = $r->{server}->{server_port};
    DEBUG('$r->server_port => \'%d\'', $port);
    return $port;
}

# $r->log_error($message)                                               MPPR p34
sub log_error {
    my ($r, $message) = @_;
    DEBUG('$r->log_error(\%s\')', $message);
    $r->{log}->error($message);
}


# $s = $r->server                                                       MPPR p38
# $s = Apache->server
sub server  {
    my $self = shift;
    DEBUG('%s->server => ' . $server, ref $self ? '$r' : 'Apache');
    return $server;
}

sub subprocess_env {
    my $r = shift;
    my $subprocess_env = $r->{subprocess_env};

    if (@_) {
        $subprocess_env->_get_or_set(@_);
    }
    elsif (defined wantarray) {
        return $subprocess_env->_hash_or_list;
    }
    else {
        $r->{subprocess_env} = Apache::Table->new($r);

        while (my($key, $val) = each %{$r->{_env}}) {
            $r->{subprocess_env}->set($key, $val);
        }
        return;
    }
}


sub dir_config {
    my ($r) = @_;
    NYI_DEBUG('$r->dir_config');
}





package
    Apache::STDOUT;




################################################################################
#
# The Apache::Server Class                                              MPPR p38

package
    Apache::Server;

use parent 'Class::Accessor';


__PACKAGE__->mk_ro_accessors(qw(_mock_apache uid gid log));

sub new {
    my ($class, $mock_apache, %params) = @_;
    $params{log} = Apache::Log->new();
    $params{_mock_apache} = $mock_apache;
    return $class->SUPER::new(\%params);
}

# $num = $s->gid                                                        MPPR p38
# Returns the numeric group ID under which the server answers requests.  This is
# the value of the Apache "Group" directive.
sub gid {
    my $s = shift;
    my $gid = $s->{gid};
    DEBUG('$s->gid => %d', $gid);
    return $gid;
}

# $num = $s->port                                                       MPPR p39
# Returns the port number on which this server listens.
sub port {
    my $s = shift;
    my $port = $s->{port};
    DEBUG('$s->port => %d', $port);
    return $port;
}

# $str = $s->server_hostname                                            MPPR p39
sub server_hostname {
    my $s = shift;
    my $hostname = $s->{server_hostname};
    DEBUG('$s->server_hostname => \'%s\'', $hostname);
    return $hostname;
}

# $str = $s->server_admin                                               MPPR p39
sub server_admin {
    my $s = shift;
    my $admin = $s->{server_admin};
    DEBUG('$s->server_admin => \'%s\'', $admin);
    return $admin;
}


sub names {
    my $self = shift;
    return @{$self->{names} || []};
}

# $num = $s->uid                                                        MPPR p39
# Returns the numeric user ID under which the server answers requests.  This is
# the value of the Apache "User" directive.
sub uid {
    my $s = shift;
    my $uid = $s->{uid};
    DEBUG('$s->uid => %d', $uid);
    return $uid;
}

# is_virtual
# log
# log_error
# loglevel
# names
# next
# port
# timeout
# warn


################################################################################
#
# The Apache Connection Class                                           MPPR p39

package
    Apache::Connection;

use Scalar::Util qw(weaken);
use parent qw(Class::Accessor);

__PACKAGE__->mk_ro_accessors(qr(_mock_client));

sub new {
    my ($class, $mock_client) = @_;
    my $self = bless { _mock_client => $mock_client }, $class;
    weaken $self->{_mock_client};
    return $self;
}

sub aborted { return $_[0]->{_aborted} }
sub auth_type {
    NYI_DEBUG('$c->auth_type');
}

sub fileno {
    NYI_DEBUG('$c->fileno');
}

sub local_addr {
    NYI_DEBUG('$c->local_addr');
}

sub remote_addr {
    NYI_DEBUG('$c->remote_addr');
}

sub remote_host { $_->_mock_client->remote_host; }
sub remote_ip   { $_->_mock_client->remote_addr; }

sub remote_logname {
    NYI_DEBUG('$c->remote_logname');
    return;
}
sub user {
    NYI_DEBUG('$c->remote_user');
    return;
}

##############################################################################
#
# Logging and the Apache::Log Class                                   MPPR p34

package
    Apache::Log;

use Log::Log4perl;

sub new {
    my ($class, %params) = @_;
    return bless \%params, $class;
}

sub log_reason {}

sub warn {
    my $r = shift;
    print STDERR "[warn]:  ", @_, "\n";
}

sub emerg {
    my $r = shift;
    print STDERR "[emerg]: ", @_, "\n";
}

sub alert {
    my $r = shift;
    print STDERR "[alert]: ", @_, "\n";
}

sub error {
    my $r = shift;
    print STDERR "[error]: ", @_, "\n";
}

sub notice {
    my $r = shift;
    print STDERR "[notice]: ", @_, "\n";
}

sub info {
    my $r = shift;
    print STDERR "[info]: ", @_, "\n";
}

sub debug {
    my $r = shift;
    print STDERR "[debug]: ", @_, "\n";
}


##############################################################################
#
# The Apache::Table Class                                             MPPR p40

package
    Apache::Table;

use Apache::FakeTable;
use parent 'Apache::FakeTable';

sub new {
    my ($class, $r, $allow_refs) = @_;

    my $self = $class->SUPER::new($r);
    bless tied(%$self), 'Apache::FakeTableHash::RefsAllowed'
        if $allow_refs;
    return $self;
}

sub _hash_or_list {
    my ($self) = @_;

    my $method_name = (caller(1))[3];
    DEBUG("\$r->$method_name(%s) => %s",
          wantarray ? 'list' : $self);

    if (wantarray) {
        my @values;
        while (my ($key, $value) = each %$self) {
            push @values, $key, $value;
        }
        return @values;
    }
    else {
        return $self;
    }
}


sub _get_or_set {
    my ($self, $key, @new_values) = @_;

    my $method_name = (caller(1))[3];
    my @old_values = $self->get($key);
    DEBUG("\$r->$method_name('%s'%s)%s", $key,
          @new_values ? join(',', '', @new_values) : '',
          defined wantarray ? ' => ' . (@old_values ? join(',', @old_values) : "''" ) : '');
    if (@new_values) {
        $self->set($key, @new_values);
    }
    return unless defined wantarray;
    return wantarray ? @old_values : $old_values[0];
}

# Apache::FakeTableHash always stores values as strings in an array.
# We need to allow references to be stored (for pnotes), so we rebless
# the tied hash into our own Apache::FakeTableHash::RefsAllowed class,
# which is a subclass of Apache::FakeTableHash.

package
    Apache::FakeTableHash::RefsAllowed;

our @ISA = qw(Apache::FakeTableHash);

sub STORE {
    my ($self, $key, $value) = @_;

    # Issue a warning if the value is undefined.
    if (! defined $value and $^W) {
        require Carp;
        Carp::carp('Use of uninitialized value in null operation');
        $value = '';
    }
    $self->{lc $key} = [ $key => [$value] ];
}

sub _add {
    my ($self, $key, $value) = @_;
    my $ckey = lc $key;

    if (exists $self->{$ckey}) {
        # Add it to the array,
        push @{$self->{$ckey}[1]}, $value;
    } else {
        # It's a simple assignment.
        $self->{$ckey} = [ $key => [$value] ];
    }
}

##############################################################################
#
# The Apache::File Class                                              MPPR p

package
    Apache::File;



##############################################################################
#
# The Apache::URI Class                                               MPPR p41
package
    Apache::URI;

use strict;
use URI;

our @ISA = qw(URI);

sub parse {
    my ($r, $string_uri) = @_;
    DEBUG('$r->parse(%s)', $string_uri);
    $DB::single=1;
    croak("not yet implemented");
    return;
}

##############################################################################
#
# The Apache::Util Class                                              MPPR p43

package
    Apache::Util;

use parent 'Exporter';
our @EXPORT_OK   = qw( escape_html escape_uri unescape_uri unescape_uri_info
		       parsedate ht_time size_string validate_password );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub escape_html {
    my ($html) = @_;
    my $out = $html;
    $out =~ s/&/&amp;/g;
    $out =~ s/</&lt;/g;
    $out =~ s/>/&gt;/g;
    $out =~ s/"/&quot;/g;
    DEBUG('Apache::Util::escape_html(\'%s\') => \'%s\'', $html, $out);
    return $out;
}

sub escape_uri {
    NYI_DEBUG('escape_uri');
}
sub ht_time {
    NYI_DEBUG('ht_time');
}
sub parsedate {
    NYI_DEBUG('parsedate');
}
sub size_string {
    NYI_DEBUG('size_string');
}
sub unescape_uri {
    NYI_DEBUG('unescape_uri');
}
sub unescape_uri_info {
    NYI_DEBUG('unescape_uri_info');
}
sub validate_password {
    NYI_DEBUG('validate_password');
}


package
    Apache::ModuleConfig;

sub new {
}
sub get {
}


##############################################################################

package
    Apache::Constants;

use parent 'Exporter';

our @COMMON_CONSTS      = qw( OK DECLINED DONE NOT_FOUND FORBIDDEN AUTH_REQUIRED SERVER_ERROR );
our @RESPONSE_CONSTS    = qw( DOCUMENT_FOLLOWS  MOVED  REDIRECT  USE_LOCAL_COPY
                              BAD_REQUEST  BAD_GATEWAY  RESPONSE_CODES  NOT_IMPLEMENTED
                              CONTINUE  NOT_AUTHORITATIVE );
our @METHOD_CONSTS      = qw( METHODS  M_CONNECT  M_DELETE  M_GET  M_INVALID
                              M_OPTIONS  M_POST  M_PUT  M_TRACE  M_PATCH
                              M_PROPFIND  M_PROPPATCH  M_MKCOL  M_COPY
                              M_MOVE  M_LOCK  M_UNLOCK );
our @OPTIONS_CONSTS     = qw( OPT_NONE  OPT_INDEXES  OPT_INCLUDES  OPT_SYM_LINKS
                              OPT_EXECCGI  OPT_UNSET  OPT_INCNOEXEC
                              OPT_SYM_OWNER  OPT_MULTI  OPT_ALL );
our @SATISFY_CONSTS     = qw( SATISFY_ALL SATISFY_ANY SATISFY_NOSPEC );
our @REMOTEHOST_CONSTS  = qw( REMOTE_HOST REMOTE_NAME REMOTE_NOLOOKUP REMOTE_DOUBLE_REV );
our @HTTP_CONSTS        = qw( HTTP_OK  HTTP_MOVED_TEMPORARILY  HTTP_MOVED_PERMANENTLY
                              HTTP_METHOD_NOT_ALLOWED  HTTP_NOT_MODIFIED  HTTP_UNAUTHORIZED
                              HTTP_FORBIDDEN  HTTP_NOT_FOUND  HTTP_BAD_REQUEST
                              HTTP_INTERNAL_SERVER_ERROR  HTTP_NOT_ACCEPTABLE  HTTP_NO_CONTENT
                              HTTP_PRECONDITION_FAILED  HTTP_SERVICE_UNAVAILABLE
                              HTTP_VARIANT_ALSO_VARIES );
our @SERVER_CONSTS      = qw( MODULE_MAGIC_NUMBER  SERVER_VERSION  SERVER_BUILT );
our @CONFIG_CONSTS      = qw( DECLINE_CMD );
our @TYPES_CONSTS       = qw( DIR_MAGIC_TYPE );
our @OVERRIDE_CONSTS    = qw( OR_NONE  OR_LIMIT  OR_OPTIONS  OR_FILEINFO  OR_AUTHCFG
                              OR_INDEXES  OR_UNSET  OR_ALL  ACCESS_CONF  RSRC_CONF );
our @ARGS_HOW_CONSTS    = qw( RAW_ARGS  TAKE1  TAKE2  TAKE12  TAKE3  TAKE23  TAKE123
                              ITERATE  ITERATE2  FLAG  NO_ARGS );


our @EXPORT      = ( @COMMON_CONSTS );
our @EXPORT_OK   = ( @COMMON_CONSTS, @RESPONSE_CONSTS, @METHOD_CONSTS, @OPTIONS_CONSTS, @SATISFY_CONSTS,
                     @REMOTEHOST_CONSTS, @HTTP_CONSTS, @SERVER_CONSTS, @CONFIG_CONSTS, @TYPES_CONSTS,
                     @OVERRIDE_CONSTS, @ARGS_HOW_CONSTS);

our %EXPORT_TAGS = ( common     => \@COMMON_CONSTS,
                     response   => [ @COMMON_CONSTS, @RESPONSE_CONSTS ],
                     methods    => \@METHOD_CONSTS,
                     options    => \@OPTIONS_CONSTS,
                     satisfy    => \@SATISFY_CONSTS,
                     remotehost => \@REMOTEHOST_CONSTS,
                     http       => \@HTTP_CONSTS,
                     server     => \@SERVER_CONSTS,
                     config     => \@CONFIG_CONSTS,
                     types      => \@TYPES_CONSTS,
                     override   => \@OVERRIDE_CONSTS,
                     args_how   => \@ARGS_HOW_CONSTS,   );


sub OK                          {  0 }
sub DECLINED                    { -1 }
sub DONE                        { -2 }

# CONTINUE and NOT_AUTHORITATIVE are aliases for DECLINED.

sub CONTINUE                    { 100 }
sub DOCUMENT_FOLLOWS            { 200 }
sub NOT_AUTHORITATIVE           { 203 }
sub MOVED                       { 301 }
sub REDIRECT                    { 302 }
sub USE_LOCAL_COPY              { 304 }
sub BAD_REQUEST                 { 400 }
sub AUTH_REQUIRED               { 401 }
sub FORBIDDEN                   { 403 }
sub NOT_FOUND                   { 404 }
sub SERVER_ERROR                { 500 }
sub NOT_IMPLEMENTED             { 501 }
sub BAD_GATEWAY                 { 502 }

sub HTTP_OK                     { 200 }
sub HTTP_NO_CONTENT             { 204 }
sub HTTP_MOVED_PERMANENTLY      { 301 }
sub HTTP_MOVED_TEMPORARILY      { 302 }
sub HTTP_NOT_MODIFIED           { 304 }
sub HTTP_BAD_REQUEST            { 400 }
sub HTTP_UNAUTHORIZED           { 401 }
sub HTTP_FORBIDDEN              { 403 }
sub HTTP_NOT_FOUND              { 404 }
sub HTTP_METHOD_NOT_ALLOWED     { 405 }
sub HTTP_NOT_ACCEPTABLE         { 406 }
sub HTTP_LENGTH_REQUIRED        { 411 }
sub HTTP_PRECONDITION_FAILED    { 412 }
sub HTTP_INTERNAL_SERVER_ERROR  { 500 }
sub HTTP_NOT_IMPLEMENTED        { 501 }
sub HTTP_BAD_GATEWAY            { 502 }
sub HTTP_SERVICE_UNAVAILABLE    { 503 }
sub HTTP_VARIANT_ALSO_VARIES    { 506 }

# methods

sub M_GET       { 0 }
sub M_PUT       { 1 }
sub M_POST      { 2 }
sub M_DELETE    { 3 }
sub M_CONNECT   { 4 }
sub M_OPTIONS   { 5 }
sub M_TRACE     { 6 }
sub M_INVALID   { 7 }

# options

sub OPT_NONE      {   0 }
sub OPT_INDEXES   {   1 }
sub OPT_INCLUDES  {   2 }
sub OPT_SYM_LINKS {   4 }
sub OPT_EXECCGI   {   8 }
sub OPT_UNSET     {  16 }
sub OPT_INCNOEXEC {  32 }
sub OPT_SYM_OWNER {  64 }
sub OPT_MULTI     { 128 }
sub OPT_ALL       {  15 }

# satisfy

sub SATISFY_ALL    { 0 }
sub SATISFY_ANY    { 1 }
sub SATISFY_NOSPEC { 2 }

# remotehost

sub REMOTE_HOST       { 0 }
sub REMOTE_NAME       { 1 }
sub REMOTE_NOLOOKUP   { 2 }
sub REMOTE_DOUBLE_REV { 3 }



sub MODULE_MAGIC_NUMBER { "42" }
sub SERVER_VERSION      { "1.x" }
sub SERVER_BUILT        { "199908" }



##############################################################################
#
# Implementation of Apache::Request - a.k.a. libapreq

package
    Apache::Request;

use URI::QueryParam;
use parent 'Apache';

sub new {
    my ($class, $r, %params) = @_;

    DEBUG('Apache::Request->new(%s) => %s', join(',', map { "$_=>'$params{$_}'" } keys %params ), $r);
    $r->{$_} = $params{$_}
        for qw(POST_MAX DISABLE_UPLOADS TEMP_DIR HOOK_DATA UPLOAD_HOOK);

    return bless $r, $class;
}

sub instance {
    NYI_DEBUG('$apr->instance')
}


sub parse {
    my $apr = shift;
    DEBUG('$apr->parse');

    my $params = $apr->{params} = Apache::Table->new($apr);
    my $uri = $apr->_uri;
    foreach my $key ($uri->query_param) {
        foreach my $value ($uri->query_param($key)) {
            $params->add($key, $value);
        }
    }
    return;
}


sub param {
    my $apr = shift;
    NYI_DEBUG('$apr->param')
}


sub parms {
    my ($apr, $newval) = @_;
    DEBUG('$apr->parms(%s)', @_ > 1 ? "$newval" : '');
    $apr->parse unless $apr->{params};
    return $apr->{params};
}

sub upload {
    my $apr = shift;
    NYI_DEBUG('$apr->upload')
}

###############################################################################

package
    Apache::Upload;

sub name {
    NYI_DEBUG('Apache::Upload->name');
}

sub filename {
    NYI_DEBUG('Apache::Upload->filename');
}

sub fh {
    NYI_DEBUG('Apache::Upload->fh');
}

sub size {
    NYI_DEBUG('Apache::Upload->size');
}

sub info {
    NYI_DEBUG('Apache::Upload->info');
}

sub type {
    NYI_DEBUG('Apache::Upload->type');
}

sub next {
    NYI_DEBUG('Apache::Upload->next');
}

sub tempname {
    NYI_DEBUG('Apache::Upload->tempname');
}

sub link {
    NYI_DEBUG('Apache::Upload->link');
}

################################################################################

package
    Apache::Cookie;

sub new {
    NYI_DEBUG('Apache::Cookie->new');
}

sub bake {
    NYI_DEBUG('$c->bake');
}

sub parse {
    NYI_DEBUG('$c->parse');
}

sub fetch {
    NYI_DEBUG('$c->fetch');
}

sub as_string {
    NYI_DEBUG('$c->as_string');
}

sub name {
    NYI_DEBUG('$c->name');
}

sub value {
    NYI_DEBUG('$c->value');
}

sub domain {
    NYI_DEBUG('$c->domain');
}

sub path {
    NYI_DEBUG('$c->path');
}

sub expires {
    NYI_DEBUG('$c->expires');
}

sub secure {
    NYI_DEBUG('$c->secure');
}


1;
