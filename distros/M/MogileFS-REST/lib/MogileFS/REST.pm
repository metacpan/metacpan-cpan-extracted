package MogileFS::REST;
use strict;
use warnings;
use Carp;
use HTTP::Status ':constants';
use MogileFS::Client;
use Plack::Request;
use Plack::Response;
use Data::Dumper;

our $VERSION = '0.04';

## set shortcut methods to log handler
for my $lvl (qw/debug info warn error fatal/) {
    no strict 'refs';
    *{$lvl} = sub {
        my $app = shift;
        my $log = $app->{log};
        $log->$lvl(@_);
    };
}

sub new {
    my $class = shift;
    my %opts =  @_;
    unless ($opts{servers}) {
        croak "servers should be specified.";
    }
    my $app = bless \%opts, $class;
    if (! $app->{log}) {
        require MogileFS::REST::DumbLogger;
        $app->{log} = MogileFS::REST::DumbLogger->new;
    }
    $app->debug("Config: " . (Dumper { %$app, log => ref $app->{log} } ));
    return $app;
}

sub run {
    my $app = shift;
    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $method = $req->method;
        my $res;
        if ($method eq 'GET' or $method eq 'HEAD') {
            if ($req->path eq '/') {
                $res = $app->home($req);
            }
            else {
                $res = $app->get($req);
            }
        }
        elsif ($method eq 'DELETE') {
            $res = $app->delete($req);
        }
        elsif ($method eq 'PUT') {
            $res = $app->put($req);
        }
        else {
            $res = $app->respond_not_found($req);
        }
        return $res->finalize;
    };
}

sub get_client {
    my ($app, $domain) = @_;
    my $client = MogileFS::Client->new(
        domain => $domain,
        hosts  => $app->{servers},
    );
    return $client;
}

sub home {
    my ($app, $req) = @_;
    my $res = $req->new_response(HTTP_OK);
    $res->content_type('text/plain');
    $res->body(<<EOA);
This is a simple REST API abstraction to MogileFS, so that
we can store and retrieve files from mogile, without having to reimplement
a MogileFS client in different languages.

Files are hosted at:
/:domain/:key

* you can GET/PUT/DELETE on those resources, please README for more details.
* GET /:domain/:key?paths returns the network paths to the storage node for
  that file. (one per line)

EOA
    return $res;
}

sub get {
    my ($app, $req) = @_;
    my ($domain, $key) = split_path($req->path);
    $app->debug("Getting: $domain:$key");

    my $p = $req->query_parameters;
    if (exists $p->{paths}) {
        return $app->get_paths($req, $domain, $key);
    }
    my $can_reproxy = 0;
    my $capabilities = $req->header('X-Proxy-Capabilities');
    if ($capabilities && $capabilities =~ m{\breproxy-file\b}i) {
        $can_reproxy = 1;
    }
    my $client = $app->get_client($domain);
    my $res = $req->new_response(HTTP_OK);

    ## so, where is this file?
    my @paths = $client->get_paths($key, { no_verify => 1 });
    unless (@paths) {
        ## nowhere
        return $req->new_response(HTTP_NOT_FOUND);
    }
    if ($can_reproxy) {
        $res->header('X-Reproxy-URL' => join " ", @paths);
        ## we can reproxy, so just send headers without any body
        $app->debug("reproxying to " . $res->header('X-Reproxy-URL'));
        $res->status(HTTP_NO_CONTENT);
        return $res;
    }

    $res->header('Content-Type' => 'application/octet-stream');

    if ($req->method eq 'HEAD') {
        ## deprecated. backward compat only
        $res->header('X-Reproxy-URL' => join " ", @paths);
        if ($can_reproxy) {
            $app->warn("If you want to get paths use GET /d/k?paths instead");
        }
        ## end deprecated
        $app->debug("request is HEAD, returning no content");
        return $res;
    }
    my $handle = $client->read_file($key);
    return $app->respond_not_found($req) unless $handle;
    $res->body($handle);
    return $res;
}

sub get_paths {
    my ($app, $req, $domain, $key) = @_;
    my $res = $req->new_response(HTTP_OK);
    $res->content_type('text/plain');
    my $client = $app->get_client($domain);
    my @paths = $client->get_paths($key, { no_verify => 1 });
    return $app->respond_not_found($req) unless @paths;
    my $paths = join "\n", @paths;
    $res->header('Content-Length', length $paths);
    if ($req->method ne 'HEAD') {
        $res->body($paths);
    }
    return $res;
}

sub delete {
    my ($app, $req) = @_;

    my ($domain, $key) = split_path($req->path);
    $app->info("deleting $domain:$key");
    my $client = $app->get_client($domain);
    my $rv = $client->delete($key);
    my $e = $client->errstr;
    return $app->respond_error($req, "Couldn't delete $domain/$key: $e")
        unless $rv;
    my $res = $req->new_response(HTTP_NO_CONTENT);
    return $res;
}

sub put {
    my ($app, $req) = @_;

    my ($domain, $key) = split_path($req->path);
    $app->info("creating $domain:$key");
    my $mogclass = $req->header('X-MogileFS-Class') || $app->{default_class};

    my $size = $req->content_length;
    my $opts = { bytes => $size, largefile => $app->{largefile} };
    my $data_handle = $req->input;
    my $client = $app->get_client($domain);
    my $rv = $client->store_file($key, $mogclass, $data_handle, $opts);
    if (defined $rv) {
        my $res = $req->new_response(HTTP_CREATED);
        $res->header( Location => $req->uri );
        return $res;
    }
    else {
        my $errstr = $client->errstr;
        my $err = "Can't save key '$domain/$key': $errstr";
        $app->error($err);
        return $app->respond_error($req, $err);
    }
}

sub respond_not_found {
    my ($app, $req) = @_;
    my $res = $req->new_response(HTTP_NOT_FOUND);
    $res->content_type('text/plain');
    $res->body('No such file');
    return $res;
}

sub respond_error {
    my ($app, $req, $error) = @_;
    my $res = $req->new_response(HTTP_INTERNAL_SERVER_ERROR);
    $res->content_type('text/plain');
    $res->body($error || "Server Error");
    return $res;
}

sub split_path {
    my $path = shift;
    $path =~ s{^/+}{};
    my ($domain, $key) = split m{/}, $path, 2;
    return ($domain, $key);
}

1;
