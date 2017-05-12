package Pinwheel::ModperlHandler;

use strict;
use warnings;

use Time::HiRes ();

our $warn_handler;

BEGIN {
    eval { require Apache2::RequestRec };
    if ($@) {
        require Apache::RequestRec;
        require Apache::RequestIO;
        require Apache::RequestUtil;
        require Apache::Const;
        import Apache::Const qw(OK DECLINED FORBIDDEN M_GET);
        # No Apache 1.x $warn_handler for now
    } else {
        require Apache2::RequestRec;
        require Apache2::RequestIO;
        require Apache2::RequestUtil;
        require Apache2::Const;
        require Apache2::Log;
        import Apache2::Const qw(OK DECLINED FORBIDDEN M_GET);
        $warn_handler = \&Apache2::ServerRec::warn;
    }
    use APR::Table ();
}

use Pinwheel::Controller;
use Pinwheel::Database;

our $preloaded;

sub preload
{
    my ($s) = @_;
    return if $preloaded++;

    my $config = $s->dir_config;
    
    # Load the application's configuration
    require Config::Pinwheel;
}

sub post_config_handler
{
    my ($class, $conf_pool, $log_pool, $temp_pool, $s) = @_;
    preload($s);
    Pinwheel::Database::disconnect();
    return OK;
}

sub child_init_handler
{
    my ($class, $child_pool, $s) = @_;
    preload($s);
    return;
}

sub child_exit_handler
{
    my ($class, $child_pool, $s) = @_;
    Pinwheel::Database::finish_all();
    return;
}

sub map_to_storage_handler
{
    my ($class, $r) = @_;
    my $u = $r->uri;

    return DECLINED unless (
        $u =~ /^(?:\/\w+)?\/events(?:\.|\/|$)/
        && $u !~ /^\/events\/(?:includes|r)\b/
    );
    return OK;
}

sub response_handler
{
    my ($class, $r) = @_;
    my ($u, $request, $headers, $content);

    $u = $r->uri;
    return DECLINED unless (
        $u =~ /^(?:\/\w+)?\/events(?:\.|\/|$)/
        && $u !~ /^\/events\/(?:includes|r)\b/
    );

    return FORBIDDEN
        unless $r->method_number == M_GET; # also covers HEAD

    local $SIG{__WARN__} = $SIG{__WARN__};
    $SIG{__WARN__} = $warn_handler if $warn_handler;

    $request = {
        method => $r->method,
        host => $r->headers_in->{Host} || $r->hostname,
        path => $u,
        base => '',
        query => $r->args,
        accepts => $r->headers_in->{Accept},
        time => $r->request_time,
    };

    $request->{host} = $ENV{OVERRIDE_HOST}
        if $ENV{OVERRIDE_HOST};

    if ($u =~ /\/$/ || $u =~ /\/\//) {
        $u =~ s/\/$//;
        $u =~ s/\/{2,}/\//g;
        $headers = {
            'status' => ['Status', 301],
            'content-type' => ['Content-Type', 'text/plain'],
            'location' => ['Location', 'http://' . $request->{host} . $u],
        };
        $content = ' ';
    } else {
        ($headers, $content) = Pinwheel::Controller::dispatch($request);
    }

    $r->status((delete $headers->{'status'})->[1]);
    $r->content_type((delete $headers->{'content-type'})->[1]);
    $r->headers_out->add(@$_) foreach (values %$headers);
    $r->print($content) unless $r->header_only;

    {
        # For logging
        my $ctx = Pinwheel::Context::get("*Pinwheel::Controller");
        $r->subprocess_env(controller => $ctx->{route}{controller});
        $r->subprocess_env(action => $ctx->{route}{action});
        $r->subprocess_env(dbhost => Pinwheel::Database::dbhostname);
    }

    return OK;
}

sub post_read_request_handler
{
    my ($class, $r) = @_;
    my $t0 = [Time::HiRes::gettimeofday()];
    $r->pnotes(t0 => $t0);
    return DECLINED;
}

sub log_handler
{
    my ($class, $r) = @_;
    my $t0 = $r->pnotes('t0');
    if ($t0) {
	my $int = Time::HiRes::tv_interval($t0);
    	$r->subprocess_env('clock_ms' => int($int * 1000));
    } else {
	# For 400 Bad Request, post_read_request_handler is not fired
    	$r->subprocess_env('clock_ms' => '-');
    }
    return DECLINED;
}

1;
