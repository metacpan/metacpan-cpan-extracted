package Net::Hadoop::WebHDFS;

use strict;
use warnings;
use Carp;

use JSON::XS qw//;

use Furl;
use File::Spec;
use URI;
use Try::Tiny;

use constant GENERIC_FS_ACTION_WITH_NO_PATH => '';

our $VERSION = "0.8";

our %OPT_TABLE = ();

sub new {
    my ($this, %opts) = @_;
    my $self = +{
        host => $opts{host} || 'localhost',
        port => $opts{port} || 50070,
        standby_host => $opts{standby_host},
        standby_port => ($opts{standby_port} || $opts{port} || 50070),
        httpfs_mode => $opts{httpfs_mode} || 0,
        username => $opts{username},
        doas => $opts{doas},
        useragent => $opts{useragent} || 'Furl Net::Hadoop::WebHDFS (perl)',
        timeout => $opts{timeout} || 10,
        suppress_errors => $opts{suppress_errors} || 0,
        last_error => undef,
        under_failover => 0,
    };
    $self->{furl} = Furl::HTTP->new(agent => $self->{useragent}, timeout => $self->{timeout}, max_redirects => 0);
    return bless $self, $this;
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CREATE
#                 [&overwrite=<true|false>][&blocksize=<LONG>][&replication=<SHORT>]
#                 [&permission=<OCTAL>][&buffersize=<INT>]"
sub create {
    my ($self, $path, $body, %options) = @_;
    if ($self->{httpfs_mode}) {
        %options = (%options, data => 'true');
    }
    my $err = $self->check_options('CREATE', %options);
    croak $err if $err;

    my $res = $self->operate_requests('PUT', $path, 'CREATE', \%options, $body);
    $res->{code} == 201;
}
$OPT_TABLE{CREATE} = ['overwrite', 'blocksize', 'replication', 'permission', 'buffersize', 'data'];

# curl -i -X POST "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=APPEND
#                       [&buffersize=<INT>]"
sub append {
    my ($self, $path, $body, %options) = @_;
    if ($self->{httpfs_mode}) {
        %options = (%options, data => 'true');
    }
    my $err = $self->check_options('APPEND', %options);
    croak $err if $err;

    my $res = $self->operate_requests('POST', $path, 'APPEND', \%options, $body);
    $res->{code} == 200;
}
$OPT_TABLE{APPEND} = ['buffersize', 'data'];

# curl -i -L "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=OPEN
#                [&offset=<LONG>][&length=<LONG>][&buffersize=<INT>]"
sub read {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('OPEN', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', $path, 'OPEN', \%options);
    $res->{body};
}
$OPT_TABLE{OPEN} = ['offset', 'length', 'buffersize'];
sub open { (shift)->read(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/<PATH>?op=MKDIRS
#                   [&permission=<OCTAL>]"
sub mkdir {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('MKDIRS', %options);
    croak $err if $err;

    my $res = $self->operate_requests('PUT', $path, 'MKDIRS', \%options);
    $self->check_success_json($res, 'boolean');
}
$OPT_TABLE{MKDIRS} = ['permission'];
sub mkdirs { (shift)->mkdir(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=RENAME
#                   &destination=<PATH>"
sub rename {
    my ($self, $path, $dest, %options) = @_;
    my $err = $self->check_options('RENAME', %options);
    croak $err if $err;

    unless ($dest =~ m!^/!) {
        $dest = '/' . $dest;
    }
    my $res = $self->operate_requests('PUT', $path, 'RENAME', {%options, destination => $dest});
    $self->check_success_json($res, 'boolean');
}

# curl -i -X DELETE "http://<host>:<port>/webhdfs/v1/<path>?op=DELETE
#                          [&recursive=<true|false>]"
sub delete {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('DELETE', %options);
    croak $err if $err;

    my $res = $self->operate_requests('DELETE', $path, 'DELETE', \%options);
    $self->check_success_json($res, 'boolean');
}
$OPT_TABLE{DELETE} = ['recursive'];

# curl -i  "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETFILESTATUS"
sub stat {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('GETFILESTATUS', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', $path, 'GETFILESTATUS', \%options);
    $self->check_success_json($res, 'FileStatus');
}
sub getfilestatus { (shift)->stat(@_); }

# curl -i  "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=LISTSTATUS"
sub list {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('LISTSTATUS', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', $path, 'LISTSTATUS', \%options);
    $self->check_success_json($res, 'FileStatuses')->{FileStatus};
}
sub liststatus { (shift)->list(@_); }

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETCONTENTSUMMARY"
sub content_summary {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('GETCONTENTSUMMARY', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', $path, 'GETCONTENTSUMMARY', \%options);
    $self->check_success_json($res, 'ContentSummary');
}
sub getcontentsummary { (shift)->content_summary(@_); }

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETFILECHECKSUM"
sub checksum {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('GETFILECHECKSUM', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', $path, 'GETFILECHECKSUM', \%options);
    $self->check_success_json($res, 'FileChecksum');
}
sub getfilechecksum { (shift)->checksum(@_); }

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/?op=GETHOMEDIRECTORY"
sub homedir {
    my ($self, %options) = @_;
    my $err = $self->check_options('GETHOMEDIRECTORY', %options);
    croak $err if $err;

    my $res = $self->operate_requests('GET', '/', 'GETHOMEDIRECTORY', \%options);
    $self->check_success_json($res, 'Path');
}
sub gethomedirectory { (shift)->homedir(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETPERMISSION
#                 [&permission=<OCTAL>]"
sub chmod {
    my ($self, $path, $mode, %options) = @_;
    my $err = $self->check_options('SETPERMISSION', %options);
    croak $err if $err;

    my $res = $self->operate_requests('PUT', $path, 'SETPERMISSION', {%options, permission => $mode});
    $res->{code} == 200;
}
sub setpermission { (shift)->chmod(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETOWNER
#                          [&owner=<USER>][&group=<GROUP>]"
sub chown {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('SETOWNER', %options);
    croak $err if $err;

    unless (defined($options{owner}) or defined($options{group})) {
        croak "'chown' needs at least one of owner or group";
    }

    my $res = $self->operate_requests('PUT', $path, 'SETOWNER', \%options);
    $res->{code} == 200;
}
$OPT_TABLE{SETOWNER} = ['owner', 'group'];
sub setowner { (shift)->chown(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETREPLICATION
#                           [&replication=<SHORT>]"
sub replication {
    my ($self, $path, $replnum, %options) = @_;
    my $err = $self->check_options('SETREPLICATION', %options);
    croak $err if $err;

    my $res = $self->operate_requests('PUT', $path, 'SETREPLICATION', {%options, replication => $replnum});
    $self->check_success_json($res, 'boolean');
}
sub setreplication { (shift)->replication(@_); }

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETTIMES
#                           [&modificationtime=<TIME>][&accesstime=<TIME>]"
# modificationtime: radix-10 long integer
# accesstime: radix-10 long integer
$OPT_TABLE{SETTIMES} = [ qw( modificationtime accesstime ) ];
sub touch {
    my ($self, $path, %options) = @_;
    my $err = $self->check_options('SETTIMES', %options);
    croak $err if $err;

    unless (defined($options{modificationtime}) or defined($options{accesstime})) {
        croak "'touch' needs at least one of modificationtime or accesstime";
    }

    my $res = $self->operate_requests('PUT', $path, 'SETTIMES', \%options);
    $res->{code} == 200;
}

#---------------------------- EXTENDED ATTRIBUTES START -----------------------#

sub xattr {
    my($self, $path, $action, @args) = @_;
    croak "No action defined for xattr" if ! $action;
    my $target  = sprintf '_%s_xattr', $action;
    my $target2 = sprintf '_%s_xattrs', $action;
    my $method  = $self->can( $target )
                    || $self->can( $target2 )
                    || croak "invalid action `$action`";
    $self->$method( $path, @args );
}

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETXATTRS
#                           &xattr.name=<XATTRNAME>&encoding=<ENCODING>"
#
# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=GETXATTRS
#                           &xattr.name=<XATTRNAME1>&xattr.name=<XATTRNAME2>&encoding=<ENCODING>"
$OPT_TABLE{GETXATTRS} = [qw( names encoding flatten )];
sub _get_xattrs {
    my($self, $path, %options) = @_;
    my $err = $self->check_options('GETXATTRS', %options);
    croak $err if $err;

    my $flatten = delete $options{flatten};

    # limit to a subset? will return all of the attributes otherwise
    if ( my $name = delete $options{names} ) {
        croak "getxattrs: name needs to be an arrayref" if ref $name ne 'ARRAY';
        $options{'xattr.name'} = $name;
    }

    my $res = $self->operate_requests('GET', $path, 'GETXATTRS', \%options);
    if ( my $rv = $self->check_success_json($res, 'XAttrs') ) {
        croak "Unexpected return value from listxattrs: $rv"
            if ref $rv ne 'ARRAY';
        return $rv if ! $flatten;
        map { @{ $_ }{qw/ name value /} } @{ $rv };
    }
}

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=LISTXATTRS"
sub _list_xattrs  {
    my($self, $path) = @_;

    my $res = $self->operate_requests('GET', $path, 'LISTXATTRS');
    if ( my $rv = $self->check_success_json($res, 'XAttrNames') ) {
        my $attr = JSON::XS::decode_json $rv;
        croak "Unexpected return value from listxattrs: $attr"
            if ref $attr ne 'ARRAY';
        return @{ $attr };
    }
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=SETXATTR
#                           &xattr.name=<XATTRNAME>&xattr.value=<XATTRVALUE>&flag=<FLAG>"
# https://blog.cloudera.com/blog/2014/06/why-extended-attributes-are-coming-to-hdfs/
# flag: [CREATE,REPLACE]
$OPT_TABLE{SETXATTR} = [qw( name value flag )];
sub _set_xattr {
    my($self, $path, %options) = @_;
    my $err = $self->check_options('SETXATTR', %options);
    croak $err if $err;

    croak "value of xattr not set" if ! exists $options{value};

    $options{ 'xattr.name' }  = delete $options{name}  || croak "name of xattr not set";
    $options{ 'xattr.value' } = delete $options{value};

    croak 'flag was not specified.' if ! $options{flag};

    my $res = $self->operate_requests( PUT => $path, 'SETXATTR', \%options);
    $res->{code} == 200;
}

sub _create_xattr {
    my($self, $path, $name, $value) = @_;
    $self->_set_xattr(
        $path,
        name  => $name,
        value => $value,
        flag  => 'CREATE',
    );
}

sub _replace_xattr {
    my($self, $path, $name, $value) = @_;
    $self->_set_xattr(
        $path,
        name  => $name,
        value => $value,
        flag  => 'REPLACE',
    );
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=REMOVEXATTR
#                           &xattr.name=<XATTRNAME>"
sub _remove_xattr {
    my($self, $path, $name) = @_;

    my %options;
    $options{'xattr.name'} =  $name || croak "xattr name was not specified";

    my $res = $self->operate_requests( PUT => $path, 'REMOVEXATTR', \%options);
    $res->{code} == 200;
}

#---------------------------- EXTENDED ATTRIBUTES END -------------------------#

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CHECKACCESS
#                           &fsaction=<FSACTION>
# this seems to be broken in some versions. You may get a "No enum constant ..."
# error if this is the case.
# Also see https://issues.apache.org/jira/browse/HDFS-9695
#
sub checkaccess  {
    my($self, $path, $fsaction, %options) = @_;
    croak "checkaccess: fsaction parameter was not specified" if ! $fsaction;
    my $err = $self->check_options('CHECKACCESS', %options);
    croak $err if $err;

    $options{fsaction} = $fsaction;

    my $res = $self->operate_requests('GET', $path, 'CHECKACCESS', \%options);
    $res->{code} == 200;
}

# curl -i -X POST "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CONCAT
#                           &sources=<PATHS>"
sub concat  {
    my($self, $path, @sources) = @_;

    croak "At least one source path needs to be specified" if ! @sources;

    my $paths = join q{,}, @sources;

    my $res = $self->operate_requests(
                    POST => $path,
                    'CONCAT',
                    { sources => $paths },
                );
    $res->{code} == 200;
}

# curl -i -X POST "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=TRUNCATE
#                           &newlength=<LONG>"
# Available after Hadoop v2.7
# https://issues.apache.org/jira/browse/HDFS-7655
#
sub truncate {
    my($self, $path, $newlength) = @_;
    $newlength = 0 if ! defined $newlength;

    my $res = $self->operate_requests(
                    POST => $path,
                    'TRUNCATE',
                    { newlength => $newlength },
                );

    if ( my $rv = $self->check_success_json($res, 'boolean') ) {
        $rv eq 'true';
    }
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CREATESYMLINK
#                           &destination=<PATH>[&createParent=<true |false>]"
# currently broken/disabled
# https://issues.apache.org/jira/browse/HADOOP-10019

#$OPT_TABLE{CREATESYMLINK} = [qw( destination createParent )];
#sub createsymlink {
#    # Not available yet
#    # https://issues.apache.org/jira/browse/HADOOP-10019
#    my($self, $path, $destination, $createParent) = @_;
#
#    croak "createsymlink: destination not specified" if ! $destination;
#
#    my %options = (
#        destination  => $destination,
#        ($createParent ? (
#        createParent => $createParent ? 'true' : 'false',
#        ) : ())
#    );
#
#    my $res = $self->operate_requests( PUT => $path, 'CREATESYMLINK', \%options);
#    $res->{code} == 200;
#}

#---------------------------- DELEGATION TOKEN START --------------------------#
# Also see
# http://hadoop.apache.org/docs/r2.6.0/hadoop-hdfs-httpfs/httpfs-default.html

# GETDELEGATIONTOKENS: Obsolete and removed after HDFS-10200, HDFS-3667
#

sub delegation_token {
    my($self, $action, @args) = @_;
    croak "No action defined for delegation_token" if ! $action;
    my $target = sprintf '_%s_delegation_token', $action;
    croak "invalid action $action" if ! $self->can( $target );
    $self->$target( @args );
}

# curl -i "http://<HOST>:<PORT>/webhdfs/v1/?op=GETDELEGATIONTOKEN
#                           &renewer=<USER>&service=<SERVICE>&kind=<KIND>"
# kind: The kind of the delegation token requested
#       <empty> (Server sets the default kind for the service)
#       A string that represents token kind e.g "HDFS_DELEGATION_TOKEN" or "WEBHDFS delegation"
# service: The name of the service where the token is supposed to be used, e.g. ip:port of the namenode
#
$OPT_TABLE{GETDELEGATIONTOKEN} = [qw( renewer service kind )];
sub _get_delegation_token  {
    my($self, $path, %options) = @_;
    my $err = $self->check_options('GETDELEGATIONTOKEN', %options);
    croak $err if $err;

    $options{renewer} ||= $self->{username} if $self->{username};

    my $res = $self->operate_requests( GET => $path, 'GETDELEGATIONTOKEN', \%options);

    if ( my $rv = $self->check_success_json($res, 'Token') ) {
        $rv->{urlString};
    }
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/?op=RENEWDELEGATIONTOKEN
#                           &token=<TOKEN>"
sub _renew_delegation_token {
    my($self, $token) = @_;

    croak "No token was specified" if ! $token;

    my $res = $self->operate_requests(
                    PUT => GENERIC_FS_ACTION_WITH_NO_PATH,
                    'RENEWDELEGATIONTOKEN',
                    { token => $token },
                );
    if ( my $rv = $self->check_success_json($res, 'long') ) {
        $rv; # new expiration time in miliseconds
    }
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/?op=CANCELDELEGATIONTOKEN
#                           &token=<TOKEN>"
sub _cancel_delegation_token {
    my($self, $token) = @_;

    croak "No token was specified" if ! $token;

    my $res = $self->operate_requests(
                    PUT => GENERIC_FS_ACTION_WITH_NO_PATH,
                    'CANCELDELEGATIONTOKEN',
                    { token => $token },
                );
    $res->{code} == 200;
}

#---------------------------- DELEGATION TOKEN END ----------------------------#

#---------------------------- SNAPSHOT START ----------------------------------#

# Needs testing, seems to be buggy and can be destructive in earlier versions
# i.e.: https://issues.apache.org/jira/browse/HDFS-9406
#
# Snaphotting is not enabled by default and this needs to be executed as a super user:
# hdfs dfsadmin -allowSnapshot $path
#
sub snapshot {
    my($self, $path, $action, @args) = @_;
    croak "No action defined for delegation_token" if ! $action;
    my $target = sprintf '_%s_snapshot', $action;
    croak sprintf "%s: invalid action $action", (caller 0)[3] if ! $self->can( $target );
    $self->$target( $path => @args );
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=CREATESNAPSHOT
#                           [&snapshotname=<SNAPSHOTNAME>]"
sub _create_snapshot {
    my($self, $path, $snapshotname) = @_;

    my %options;
    $options{snapshotname} = $snapshotname if $snapshotname;
    my $res = $self->operate_requests('PUT', $path, 'CREATESNAPSHOT', \%options);
    if ( my $rv = $self->check_success_json($res, 'Path') ) {
        $rv;
    }
}

# curl -i -X PUT "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=RENAMESNAPSHOT
#                           &oldsnapshotname=<SNAPSHOTNAME>&snapshotname=<SNAPSHOTNAME>"
sub _rename_snapshot {
    my($self, $path, $oldsnapshotname, $snapshotname) = @_;

    my %options = (
        oldsnapshotname => $oldsnapshotname,
        snapshotname    => $snapshotname,
    );

    my $res = $self->operate_requests('PUT', $path, 'RENAMESNAPSHOT', \%options);
    $res->{code} == 200;
}

# curl -i -X DELETE "http://<HOST>:<PORT>/webhdfs/v1/<PATH>?op=DELETESNAPSHOT
#                           &snapshotname=<SNAPSHOTNAME>"
sub _delete_snapshot {
    my($self, $path, $snapshotname) = @_;
    croak "No snapshotname specified" if ! $snapshotname;

    my %options = (
        snapshotname => $snapshotname,
    );
    my $res = $self->operate_requests('DELETE', $path, 'DELETESNAPSHOT', \%options);
    $res->{code} == 200;
}

#---------------------------- SNAPSHOT END ------------------------------------#

sub touchz {
    my ($self, $path) = @_;
    return $self->create( $path, '', overwrite => 'true' );
}

sub settimes { (shift)->touch(@_); }

# sub delegation_token {}
# sub renew_delegation_token {}
# sub cancel_delegation_token {}

sub check_options {
    my ($self, $op, %opts) = @_;
    my @ex = ();
    my $opts = $OPT_TABLE{$op} || [];
    foreach my $k (keys %opts) {
        push @ex, $k if scalar(grep {$k eq $_} @$opts) < 1;
    }
    return undef unless @ex;
    'no such option: ' . join(' ', @ex);
}

sub check_success_json {
    my ($self, $res, $attr) = @_;
    $res->{code} == 200 and $res->{content_type} =~ m!^application/json! and
        (not defined($attr) or JSON::XS::decode_json($res->{body})->{$attr});
}

sub api_path {
    my ($self, $path) = @_;
    return '/webhdfs/v1' . $path if $path =~ m!^/!;
    '/webhdfs/v1/' . $path;
}

sub build_path {
    my ($self, $path, $op, %params) = @_;
    my %opts = (('op' => $op),
                ($self->{username} ? ('user.name' => $self->{username}) : ()),
                ($self->{doas} ? ('doas' => $self->{doas}) : ()),
                %params);
    my $u = URI->new('', 'http');
    $u->query_form(%opts);
    $self->api_path($path) . $u->path_query; # path_query() #=> '?foo=1&bar=2'
}

sub connect_to {
    my $self = shift;
    if ($self->{under_failover}) {
        return ($self->{standby_host}, $self->{standby_port});
    }
    return ($self->{host}, $self->{port});
}

our %REDIRECTED_OPERATIONS = (APPEND => 1, CREATE => 1, OPEN => 1, GETFILECHECKSUM => 1);
sub operate_requests {
    my ($self, $method, $path, $op, $params, $payload) = @_;

    my ($host, $port) = $self->connect_to();

    my $headers = []; # or undef ?
    if ($self->{httpfs_mode} or not $REDIRECTED_OPERATIONS{$op}) {
        # empty files are ok
        if ($self->{httpfs_mode} and defined($payload)) {
            $headers = ['Content-Type' => 'application/octet-stream'];
        }
        return $self->request($host, $port, $method, $path, $op, $params, $payload, $headers);
    }

    # pattern for not httpfs and redirected by namenode
    my $res = $self->request($host, $port, $method, $path, $op, $params, undef);
    unless ($res->{code} >= 300 and $res->{code} <= 399 and $res->{location}) {
        my $code = $res->{code};
        my $body = $res->{body};
        croak "NameNode returns non-redirection (or without location header), code:$code, body:$body.";
    }
    my $uri = URI->new($res->{location});
    $headers = ['Content-Type' => 'application/octet-stream'];
    return $self->request($uri->host, $uri->port, $method, $uri->path_query, undef, {}, $payload, $headers);
}

sub request {
    my $self = shift;
    return $self->_request(@_) unless $self->{suppress_errors};

    try {
        $self->_request(@_);
    } catch {
        $self->{last_error} = $_;
        0;
    };
}

# IllegalArgumentException      400 Bad Request
# UnsupportedOperationException 400 Bad Request
# SecurityException             401 Unauthorized
# IOException                   403 Forbidden
# FileNotFoundException         404 Not Found
# RumtimeException              500 Internal Server Error
sub _request {
    my ($self, $host, $port, $method, $path, $op, $params, $payload, $header) = @_;

    my $request_path = $op ? $self->build_path($path, $op, %$params) : $path;
    my ($ver, $code, $msg, $headers, $body) = $self->{furl}->request(
        method => $method,
        host => $host,
        port => $port,
        path_query => $request_path,
        headers => $header,
        ($payload ? (content => $payload) : ()),
    );

    my $res = { code => $code, body => $body };

    for (my $i = 0; $i < scalar(@$headers); $i += 2) {
        my $header = $headers->[$i];
        my $value = $headers->[$i + 1];

        if ($header =~ m!^location$!i) { $res->{location} = $value; }
        elsif ($header =~ m!^content-type$!i) { $res->{content_type} = $value; }
    }

    return $res if $code >= 200 and $code <= 299;
    return $res if $code >= 300 and $code <= 399;

    my $errmsg = $res->{body} || 'Response body is empty...';
    $errmsg =~ s/\n//g;

    if ($code == 400) { croak "ClientError: $errmsg"; }
    elsif ($code == 401) { croak "SecurityError: $errmsg"; }
    elsif ($code == 403) {
        if ($errmsg =~ /org\.apache\.hadoop\.ipc\.StandbyException/) {
            if ($self->{httpfs_mode} || not defined($self->{standby_host})) {
                # failover is disabled
            } elsif ($self->{retrying}) {
                # more failover is prohibited
                $self->{retrying} = 0;
            } else {
                $self->{under_failover} = not $self->{under_failover};
                $self->{retrying} = 1;
                my ($next_host, $next_port) = $self->connect_to();
                my $val = $self->request($next_host, $next_port, $method, $path, $op, $params, $payload, $header);
                $self->{retrying} = 0;
                return $val;
            }
        }
        croak "IOError: $errmsg";
    }
    elsif ($code == 404) { croak "FileNotFoundError: $errmsg"; }
    elsif ($code == 500) { croak "ServerError: $errmsg"; }

    croak "RequestFailedError, code:$code, message:$errmsg";
}

sub exists {
    my $self = shift;
    my $path = shift || croak "No HDFS path was specified";
    my $stat;
    eval {
        $stat = $self->stat( $path );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        return if $eval_error =~ m<
            \QFileNotFoundError: {"RemoteException":{"message":"File does not exist:\E
        >xms;
        # just re-throw
        croak $eval_error;
    };
    return $stat;
}

sub find {
    my $self      = shift;
    my $file_path = shift || croak "No file path specified";
    my $cb        = shift;
    my $opt       = @_ && ref $_[-1] eq 'HASH' ? pop @_ : {};

    if ( ref $cb ne 'CODE' ) {
        die "Call back needs to be a CODE ref";
    }

    my $suppress = $self->{suppress_errors};
    # can be used to quickly skip the java junk like, file names starting with
    # underscores, etc.
    my $re_ignore     = $opt->{re_ignore} ? qr/$opt->{re_ignore}/ : undef;

    #
    # No such thing like symlinks (yet) in HDFS, in case you're wondering:
    # https://issues.apache.org/jira/browse/HADOOP-10019
    # although check that link yourself
    #
    my $looper;
    $looper = sub {
        my $thing = shift;
        if ( ! $self->exists( $thing ) ) {
            # should happen at the start, so this will short-circuit the recursion
            warn "The HDFS directory specified ($thing) does not exist! Please guard your HDFS paths with exists()";
            return;
        }
        my $list = $self->list( $thing );
        foreach my $e ( @{ $list } ) {
            my $path = $e->{pathSuffix};
            my $type = $e->{type};

            next if $re_ignore && $path && $path =~ $re_ignore;

            if ( $type eq 'DIRECTORY' ) {
                $cb->( $thing, $e );
                eval {
                    $looper->( File::Spec->catdir( $thing, $path ) );
                    1;
                } or do {
                    my $eval_error = $@ || 'Zombie error';
                    if ( $suppress ) {
                        warn "[ERROR DOWNGRADED] Failed to check $thing/$path: $eval_error";
                        next;
                    }
                    croak $eval_error;
                }
            }
            elsif ( $type eq 'FILE' ) {
                $cb->( $thing, $e );
            }
            else {
                my $msg = "I don't know what to do with type=$type!";
                if ( $suppress ) {
                    warn "[ERROR DOWNGRADED] $msg";
                    next;
                }
                croak $msg;
            }
        }
        return;
    };

    $looper->( $file_path );

    return;
}

1;

__END__

=head1 NAME

Net::Hadoop::WebHDFS - Client library for Hadoop WebHDFS and HttpFs

=head1 SYNOPSIS

  use Net::Hadoop::WebHDFS;
  my $client = Net::Hadoop::WebHDFS->new( host => 'hostname.local', port => 50070 );

  my $statusArrayRef = $client->list('/');

  my $contentData = $client->read('/data.txt');

  $client->create('/foo/bar/data.bin', $bindata);

=head1 DESCRIPTION

This module supports WebHDFS v1 on Hadoop 1.x (and CDH4.0.0 or later), and HttpFs on Hadoop 2.x (and CDH4 or later).
WebHDFS/HttpFs has two authentication methods: pseudo authentication and Kerberos, but this module supports pseudo authentication only.

=head1 METHODS

Net::Hadoop::WebHDFS class method and instance methods.

=head2 CLASS METHODS

=head3 C<< Net::Hadoop::WebHDFS->new( %args ) :Net::Hadoop::WebHDFS >>

Creates and returns a new client instance with I<%args>.
If you are using HttpFs, set I<< httpfs_mode => 1 >> and I<< port => 14000 >>.


I<%args> might be:

=over

=item host :Str = "namenode.local"

=item port :Int = 50070

=item standby_host :Str = "standby.namenode.local"

=item standby_port :Int = 50070

=item username :Str = "hadoop"

=item doas :Str = "hdfs"

=item httpfs_mode :Bool = 0/1

=back

=head2 INSTANCE METHODS

=head3 C<< $client->create($path, $body, %options) :Bool >>

Creates file on HDFS with I<$body> data. If you want to create blank file, pass blank string.

I<%options> might be:

=over

=item overwrite :Str = "true" or "false"

=item blocksize :Int

=item replication :Int

=item permission :Str = "0600"

=item buffersize :Int

=back

=head3 C<< $client->append($path, $body, %options) :Bool >>

Append I<$body> data to I<$path> file.

I<%options> might be:

=over

=item buffersize :Int

=back

=head3 C<< $client->read($path, %options) :Str >>

Open file of I<$path> and returns its content. Alias: B<open>.

I<%options> might be:

=over

=item offset :Int

=item length :Int

=item buffersize :Int

=back

=head3 C<< $client->mkdir($path, [permission => '0644']) :Bool >>

Make directory I<$path> on HDFS. Alias: B<mkdirs>.

=head3 C<< $client->rename($path, $dest) :Bool >>

Rename file or directory as I<$dest>.

=head3 C<< $client->delete($path, [recursive => 0/1]) :Bool >>

Delete file I<$path> from HDFS. With optional I<< recursive => 1 >>, files and directories are removed recursively (default false).

=head3 C<< $client->stat($path) :HashRef >>

Get and returns file status object for I<$path>. Alias: B<getfilestatus>.

=head3 C<< $client->list($path) :ArrayRef >>

Get list of files in directory I<$path>, and returns these status objects arrayref. Alias: B<liststatus>.

=head3 C<< $client->content_summary($path) :HashRef >>

Get 'content summary' object and returns it. Alias: B<getcontentsummary>.

=head3 C<< $client->checksum($path) :HashRef >>

Get checksum information object for I<$path>. Alias: B<getfilechecksum>.

=head3 C<< $client->homedir() :Str >>

Get accessing user's home directory path. Alias: B<gethomedirectory>.

=head3 C<< $client->chmod($path, $mode) :Bool >>

Set permission of I<$path> as octal I<$mode>. Alias: B<setpermission>.

=head3 C<< $client->chown($path, [owner => 'username', group => 'groupname']) :Bool >>

Set owner or group of I<$path>. One of owner/group must be specified. Alias: B<setowner>.

=head3 C<< $client->replication($path, $replnum) :Bool >>

Set replica number for I<$path>. Alias: B<setreplication>.

=head3 C<< $client->touch($path, [modificationtime => $mtime, accesstime => $atime]) :Bool >>

Set mtime/atime of I<$path>. Alias: B<settimes>.

=head3 C<< $client->touchz($path) :Bool >>

Create a zero length file.

=head3 C<< $client->checkaccess( $path, $fsaction ) :Bool >>

Test if the user has the rights to do a file system action.

=head3 C<< $client->concat( $path, @source_paths ) :Bool >>

Concatenate paths.

=head3 C<< $client->truncate( $path, $newlength ) :Bool >>

Truncate a path contents.

=head3 C<< $client->delegation_token( $action, $path, @args ) >>

This is a method wrapping the multiple methods for delegation token
handling.

    my $token = $client->delegation_token( get => $path );
    print "Token: $token\n";

    my $milisec = $client->delegation_token( renew => $token );
    printf "Token expiration renewed until %s\n", scalar localtime $milisec / 1000;

    if ( $client->delegation_token( cancel => $token ) ) {
        print "Token cancelled. There will be a new one created.\n";
        my $token_new = $client->delegation_token( get => $path );
        print "New token: $token_new\n";
        printf "New token is %s\n", $token_new eq $token ? 'the same' : 'different';
    }
    else {
        warn "Failed to cancel token $token!";
    }

=head4 C<< $client->delegation_token( get => $path, [renewer => $username, service => $service, kind => $kind ] ) :Str ) >>

Returns the delegation token id for the specified path.

=head4 C<< $client->delegation_token( renew => $token ) :Int >>

Returns the new expiration time for the specified delegation token in miliseconds.

=head4 C<< $client->delegation_token( cancel => $token ) :Bool >>

Cancels the specified delegation token (which will force a new one to be created.

=head3 C<< $client->snapshot( $path, $action => @args ) >>

This is a method wrapping the multiple methods for snapshot handling.

=head4 C<< $client->snapshot( $path, create => [, $snapshotname ] ) :Str >>

Creates a new snaphot on the specified path and returns the name of the
snapshot.

=head4 C<< $client->snapshot( $path, rename => $oldsnapshotname, $snapshotname ) :Bool >>

Renames the snaphot.

=head4 C<< $client->snapshot( $path, delete => $snapshotname ) :Bool >>

Deletes the specified snapshot.

=head3 C<< $client->xattr( $path, $action, @args ) >>

This is a method wrapping the multiple methods for extended attributes handling.

    my @attr_names = $client->xattr( $path, 'list' );

    my %attr = $client->xattr( $path, get => flatten => 1 );

    if ( ! exists $attr{'user.bar'} ) {
        warn "set user.bar = 42\n";
        $client->xattr( $path, create => 'user.bar' => 42 )
            || warn "Failed to create user.bar";
    }
    else {
        warn "alter user.bar = 24\n";
        $client->xattr( $path, replace => 'user.bar' => 24 )
            || warn "Failed to replace user.bar";
        ;
    }

    if ( exists $attr{'user.foo'} ) {
        warn "No more foo\n";
        $client->xattr( $path, remove => 'user.foo')
            || warn "Failed to remove user.foo";
        ;
    }

=head4 C<< $client->xattr( $path, get => [, names => \@attr_names]  [, flatten => 1 ] [, encoding => $enc ] ) :Struct >>

Returns the extended attribute key/value pairs on a path. The default data set
is an array of hashrefs with the pairs, however if you set C<<flatten>> to a true
value then a simple hash will be returned.

It is also possible to fetch a subset of the attributes if you specify the
names of them with the C<<names>> option.

=head4 C<< $client->xattr( $path, 'list' ) :List >>

This method will return the names of all the attributes set on C<<$path>>.

=head4 C<< $client->xattr( $path, create => $attr_name => $value ) :Bool >>

It is possible to create a new  extended attribute on a path with this method.

=head4 C<< $client->xattr( $path, replace => $attr_name => $value ) :Bool >>

It is possible to replace the value of an existing extended attribute on a path
with this method.

=head4 C<< $client->xattr( $path, remove => $attr_name ) :Bool >>

Deletes the speficied attribute on C<<$path>>.

=head2 EXTENSIONS

=head3 C<< $client->exists($path) :Bool >>

Returns the C<< stat() >> hash if successful, and false otherwise. Dies on
interface errors.

=head3 C<< $client->find($path, $callback, $options_hash) >>

Loops recursively over the specified path:

    $client->find(
        '/user',
        sub {
            my($cwd, $path) = @_;
            my $date = localtime $path->{modificationTime};
            my $type = $path->{type} eq q{DIRECTORY} ? "[dir ]" : "[file]";
            my $size = sprintf "% 10s",
                                $path->{blockSize}
                                    ? sprintf "%.2f MB", $path->{blockSize} / 1024**2
                                    : 0;
            print "$type $size $path->{permission} $path->{owner}:$path->{group} $cwd/$path->{pathSuffix}\n";
        },
        { # optional
            re_ignore => qr{
                            \A      # Filter some filenames out even before reaching the callback
                                [_] # logs and meta data, java junk, _SUCCESS files, etc.
                        }xms,
        }
    );

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
