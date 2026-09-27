use strict;

# $Id: API.pm,v 1.35 2009/08/02 17:16:12 asc Exp $
# -*-perl-*-

package Net::Flickr::API;

$Net::Flickr::API::VERSION = '1.8';

=head1 NAME

Net::Flickr::API - base API class for Net::Flickr::* libraries

=head1 SYNOPSIS

 package Net::Flickr::RDF;
 use base qw (Net::Flickr::API);

=head1 DESCRIPTION

Base API class for Net::Flickr::* libraries

Net::Flickr::API is a wrapper for Flickr::API that provides support for
throttling API calls (per hour), retries if the API is disabled or
rate-limited, and marshalling of API responses into XML::LibXML or XML::XPath
objects.

=head1 OPTIONS

Options are passed to Net::Flickr::Backup using a Config::Simple object or
a valid Config::Simple config file. Options are grouped by "block".

=head2 flick

=over 4

=item * B<api_key>

String. I<required>

A valid Flickr API key.

=item * B<api_secret>

String. I<required>

A valid Flickr Auth API secret key.

=item * B<auth_token>

String. I<required>

A valid Flickr Auth API token.

=item * B<api_handler>

String. I<required>

The B<api_handler> defines which XML/XPath handler to use to process API responses.

=over 4 

=item * B<LibXML>

Use XML::LibXML.

=item * B<XPath>

Use XML::XPath.

=back

=item * B<api_calls_per_hour>

Integer.

The most API calls to make in any hour, counting retries.  Short bursts are
allowed after a lull, but never enough to go over this in any rolling hour.

The default, and the maximum, is 3600, which is Flickr's documented limit per
API key.  The minimum is 60.

=back

=head2 reporting

=over 

=item * B<enabled>

Boolean.

Default is false.

=item * B<handler>

String.

The default handler is B<Screen>, as in C<Log::Dispatch::Screen>

=item * B<handler_args>

For example, the following :

 reporting_handler_args=name:foobar;min_level=info

Would be converted as :

 (name      => "foobar",
  min_level => "info");

The default B<name> argument is "__report". The default B<min_level> argument
is "info".

=back

=cut

use Config::Simple;

use Flickr::API;
use Flickr::Upload;

use HTTP::Date qw(str2time);
use List::Util qw(min);
use Time::HiRes ();
use Readonly;
use Data::Dumper;

use Log::Dispatch;
use Log::Dispatch::Screen;

Readonly::Scalar my $CALLS_PER_HOUR_MAX        => 3600;
Readonly::Scalar my $CALLS_PER_HOUR_MIN        => 60;
Readonly::Scalar my $PAUSE_SECONDS_UNAVAILABLE => 4;
Readonly::Scalar my $PAUSE_MAXTRIES            => 10;
Readonly::Hash   my %PAUSE_ONSTATUS            => (429 => 1, 503 => 1);

Readonly::Scalar my $RETRY_MAXTRIES            => 10;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($cfg)

Where B<$cfg> is either a valid I<Config::Simple> object or the path
to a file that can be parsed by I<Config::Simple>.

Returns a I<Net::Flickr::API> object.

=cut

sub new {
        my $pkg = shift;
        my $cfg = shift;
    
        my $self = {'__retries' => 0,};

        bless $self,$pkg;

        if (! $self->init($cfg)) {
                undef $self;
        }
        
        return $self;
}

sub init {
        my $self = shift;
        my $cfg  = shift;
        
        $self->{cfg} = (UNIVERSAL::isa($cfg, "Config::Simple")) ? $cfg : Config::Simple->new($cfg);
        
        if ($self->{cfg}->param("flickr.api_handler") !~ /^(?:XPath|LibXML)$/) {
                warn "Invalid API handler";
                return 0;
        }

        $self->_init_rate_limit();
        
        #
        
        my $log_fmt = sub {
                my %args = @_;
                
                my $msg = $args{'message'};
                chomp $msg;
                
                if ($args{'level'} eq "error") {
                        
                        my ($ln, $sub) = (caller(4))[2,3];
                        $sub =~ s/.*:://;
                        
                        return sprintf("[%s][%s, ln%d] %s\n",
                                       $args{'level'}, $sub, $ln, $msg);
                }
                
                return sprintf("[%s] %s\n", $args{'level'}, $msg);
        };
        
        my $logger = Log::Dispatch->new(callbacks=>$log_fmt);
        my $error  = Log::Dispatch::Screen->new(name      => '__error',
                                                min_level => 'error',
                                                stderr    => 1);
        
        $logger->add($error);

        #
        # Custom report logging
        #

        if ($self->{cfg}->param("reporting.enable")) {

                my $report_handler = $self->{cfg}->param("reporting.handler") || "Screen";
                $report_handler    =~ s/:://g;

                my $report_pkg = "Log::Dispatch::$report_handler";
                eval "require $report_pkg";

                if ($@) {
                        warn "Failed to load $report_pkg, $@";
                        return 0;
                }

                my %report_args = ();

                if (my $args = $self->{cfg}->param("reporting.handler_args")) {

                        foreach my $part (split(",", $args)) {
                                my ($key, $value) = split(":", $part);
                                $report_args{$key} = $value;
                        }
                }

                $report_args{'name'}      ||= "__report";
                $report_args{'min_level'} ||= "info";

                my $reporter = $report_pkg->new(%report_args);

                if (! $reporter) {
                        warn "Failed to instantiate $report_pkg, $!";
                        return 0;
                }

                $logger->add($reporter);
        }

        $self->{'__logger'} = $logger;

        #
        
        $self->{api} = Flickr::API->new({key     => $self->{cfg}->param("flickr.api_key"),
                                         secret  => $self->{cfg}->param("flickr.api_secret"),
                                         handler => $self->{cfg}->param("flickr.api_handler")});
        
        my $pkg     = ref($self);
        my $version = undef;
        
        do {
                my $ref = join("::", $pkg, "VERSION");
                
                no strict "refs";
                $version = ${$ref};
        };
        
        my $agent_string = sprintf("%s/%s", $pkg, $version);
        
        $self->{api}->agent($agent_string);
        return 1;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->api_call(\%args)

Valid args are :

=over 4

=item * B<method>

A string containing the name of the Flickr API method you are
calling.

=item * B<args>

A hash ref containing the key value pairs you are passing to 
I<method>

=back

If the method encounters any errors calling the API, receives an API error
or can not parse the response it will log an error event, via the B<log> method,
and return undef.

Otherwise it will return a I<XML::LibXML::Document> object (if XML::LibXML is
installed) or a I<XML::XPath> object.

=cut

sub api_call {
        my $self = shift;
        my $args = shift;
        
        # A 429 (rate limited) or 503 (unavailable) reply is retried in this
        # loop, up to $PAUSE_MAXTRIES times.  This used to be done by having
        # retry_api_call call api_call recursively, which reset the retry
        # count as each nested call returned. -- claude, 2026-09-26

        my $res   = undef;
        my $tries = 0;

        while (1) {

                # check to see if we need to take
                # breather (are we pounding or are
                # we not?)

                $self->_await_rate_limit();

                # send request

                if (exists($args->{'args'}->{'api_sig'})) {
                        delete $args->{'args'}->{'api_sig'};
                }

                $args->{'args'}->{'auth_token'} = $self->{cfg}->param("flickr.auth_token");

                #

                my $req = Flickr::API::Request->new($args);

                $self->log()->debug("calling $args->{method} : " . Dumper($args->{args}));

                eval {
                        $res = $self->{'api'}->execute_request($req);
                };

                if ($@) {
                        $self->log()->error("Fatal error calling the Flickr API, $@");
                        return undef;
                }

                #
                # check for 429 or 503 status
                #

                last unless $PAUSE_ONSTATUS{ $res->code() };

                # you are in a dark and twisty corridor
                # where all the errors look the same - 
                # just give up if we hit this ceiling

                $tries ++;

                if ($tries > $PAUSE_MAXTRIES) {
                        my $errmsg = sprintf("service returned status %d %d times calling %s; giving up",
                                             $res->code(), $PAUSE_MAXTRIES, $args->{method});

                        $self->log()->error($errmsg);
                        return undef;
                }

                my $pause = $self->_retry_pause($res, $tries);

                $self->log()->debug(sprintf("service returned status %d, pause for %.2f seconds",
                                            $res->code(), $pause));

                $self->_sleep($pause);
        }

        return $self->parse_api_call($args, $res);
}

# How long to wait before the $tries-th retry of a request that got $res.
# Retry-After may be either a number of seconds or an HTTP date; without it,
# we back off a little more on each try.
sub _retry_pause {
        my $self  = shift;
        my $res   = shift;
        my $tries = shift;

        my $retry_after = $res->header("Retry-After");

        if (defined($retry_after)) {
                if ($retry_after =~ /\A\s*([0-9]+)\s*\z/) {
                        return $1;
                }

                if (my $when = str2time($retry_after)) {
                        my $pause = $when - $self->_now;
                        return ($pause > 0) ? $pause : 0;
                }
        }

        return $PAUSE_SECONDS_UNAVAILABLE * $tries;
}

# Pacing is a token bucket: it holds up to "size" tokens, refills at "rate"
# tokens per second, and each request sent (retries included) spends one.  In
# any window of T seconds, then, at most size + rate * T requests go out.  The
# rate is set so that this is no more than calls_per_hour for T = 3600, so a
# burst after a lull never pushes an hour over the limit.  The bucket is
# charged when a request is sent, so request latency overlaps the wait for the
# next token instead of adding to it. -- claude, 2026-09-26
sub _init_rate_limit {
        my $self = shift;

        my $per_hour = $self->{cfg}->param("flickr.api_calls_per_hour");
        $per_hour    = $CALLS_PER_HOUR_MAX unless defined($per_hour) && length($per_hour);

        if ($per_hour !~ /\A[0-9]+\z/ || $per_hour > $CALLS_PER_HOUR_MAX) {
                warn "api_calls_per_hour must be at most $CALLS_PER_HOUR_MAX; using $CALLS_PER_HOUR_MAX\n";
                $per_hour = $CALLS_PER_HOUR_MAX;
        }

        if ($per_hour < $CALLS_PER_HOUR_MIN) {
                warn "api_calls_per_hour must be at least $CALLS_PER_HOUR_MIN; using $CALLS_PER_HOUR_MIN\n";
                $per_hour = $CALLS_PER_HOUR_MIN;
        }

        my $size = int($per_hour / 360) || 1;

        $self->{'__bucket'} = {size   => $size,
                               rate   => ($per_hour - $size) / 3600,
                               tokens => $size,
                               at     => $self->_now};
}

sub _await_rate_limit {
        my $self = shift;

        my $bucket = $self->{'__bucket'};
        my $now    = $self->_now;

        # The wall clock can be set backward, which must not drain the bucket.
        my $elapsed = $now - $bucket->{at};
        $elapsed    = 0 if $elapsed < 0;

        $bucket->{tokens} = min($bucket->{size},
                                $bucket->{tokens} + $elapsed * $bucket->{rate});
        $bucket->{at}     = $now;

        if ($bucket->{tokens} < 1) {
                my $pause = (1 - $bucket->{tokens}) / $bucket->{rate};

                my $debug_msg = sprintf("trying not to beat up the Flickr servers, pause for %.2f seconds",
                                        $pause);

                $self->log()->debug($debug_msg);
                $self->_sleep($pause);

                $bucket->{tokens} = 1;
                $bucket->{at}     = $now + $pause;
        }

        $bucket->{tokens} --;
}

# These exist so that tests can supply a fake clock.
sub _now {
        return Time::HiRes::time();
}

sub _sleep {
        my $self    = shift;
        my $seconds = shift;

        Time::HiRes::sleep($seconds);
}

=head2 $obj->get_auth()

Return an XML I<node> element containing the Flickr auth token information for
the current object.

Returns undef if no token information is present.

=cut

sub get_auth {
        my $self = shift;
        
        if (! $self->{'__auth'}) {
                my $auth = $self->api_call({"method" => "flickr.auth.checkToken"});
                
                if (! $auth) {
                        return undef;
                }
                
                my $nsid = $auth->find("/rsp/auth/user/\@nsid")->string_value();
                
                if (! $nsid) {
                        $self->log()->error("unabled to determine ID for token");
                        return undef;
                }
                
                $self->{'__auth'} = $auth;
        }
        
        return $self->{'__auth'};
}

=head2 $obj->get_auth_nsid()

Return the Flickr NSID of the user associated with the Flickr auth token information
for the current object.

Returns undef if no token information is present.

=cut

sub get_auth_nsid {
        my $self = shift;

        if (my $auth = $self->get_auth()){
                return $auth->find("/rsp/auth/user/\@nsid")->string_value();
        }

        return undef;
}

sub parse_api_call {
        my $self = shift;
        my $args = shift;
        my $res  = shift;

        $self->log()->debug($res->decoded_content());

        my $xml = $self->_parse_results_xml($res);

        if (! $xml) {
                $self->log()->error("failed to parse API response, calling $args->{method}");
                $self->log()->error($res->decoded_content());
                return undef;
        }

        my $stat = $xml->find("/rsp/\@stat")->string_value();

        if ($stat eq "fail") {
                my $code = $xml->findvalue("/rsp/err/\@code");
                my $msg  = $xml->findvalue("/rsp/err/\@msg");

                $self->log()->error(sprintf("[%s] %s (calling $args->{method})\n",
                                            $code,
                                            $msg));

                if ($code==0) {
                        $self->log()->info(sprintf("api disabled attempting %s/%s tries to see if it's come back up", $self->{'__retries'}, $RETRY_MAXTRIES));
                        return $self->api_disabled($args, $res);                
                }
        }

        $self->{'__retries'} = 0;

        return ($@) ? undef : $xml;
}

sub _parse_results_xml {
        my $self = shift;
        my $res  = shift;

        my $xml = undef;

        #
        # Please for Cal to someday accept the patch to add
        # response handlers to Flickr::API...
        #

        if ($self->{cfg}->param("flickr.api_handler") eq "XPath") {
                eval "require XML::XPath";

                if (! $@) {
                        eval {
                                $xml = XML::XPath->new(xml=>$res->decoded_content());
                        };
                }
        }
        
        else {
                eval "require XML::LibXML";

                if (! $@) {
                        eval {
                                my $parser = XML::LibXML->new();
                                $xml = $parser->parse_string($res->decoded_content());
                        };
                }
        }
        
        #

        if (! $xml) {
                $self->log()->error("XML parse error : $@");
                return undef;
        }
        
        #

        return $xml;
}

sub api_disabled {
        my $self = shift;
        my $args = shift;
        my $res  = shift;

        $self->{'__retries'} ++;

        if ($self->{'__retries'} > $RETRY_MAXTRIES) {
                $self->log()->critical(sprintf("API still down after %s tries - exiting", $RETRY_MAXTRIES));
                exit;
        }

        my $pause = $PAUSE_SECONDS_UNAVAILABLE * $self->{'__retries'};

        $self->log()->debug(sprintf("api disabled, pause for %.2f seconds", $pause));
        $self->_sleep($pause);

        # try, try again

        $res = $self->api_call($args);

        if (! $res) {
                $self->log()->critical("Returned false during 'api disabled' retry. That can only be bad - exiting");
                exit;
        }

        return $res;
}

=head2 $obj->upload(\%args)

This is a helper method that simply wraps calls to the I<Flickr::Upload> upload
method. All the arguments are the same. For complete documentation please consult:

L<http://search.cpan.org/dist/Flickr-Upload/Upload.pm#upload>

(Note: There's no need to pass an auth_token argument as the wrapper will take care
of for you.)

Returns a photo ID (or a ticket ID if the call is asynchronous) on success or false
if there was a problem.

=cut

sub upload {
        my $self = shift;
        my $args = shift;

        $args->{'auth_token'} = $self->{cfg}->param("flickr.auth_token");

        my $ua = Flickr::Upload->new({'key' => $self->{cfg}->param("flickr.api_key"),
                                      'secret' => $self->{cfg}->param("flickr.api_secret")});
        
        my $id = undef;

        eval {
                $id = $ua->upload(%$args);
        };

        if ($@){
                $self->log()->error("upload failed: $@");
                return 0;
        }

        return $id;
}

=head2 $obj->log()

Returns a I<Log::Dispatch> object.

=cut

sub log {
        my $self = shift;
        return $self->{'__logger'};
}

=head1 VERSION

1.8

=head1 DATE

$Date: 2009/08/02 17:16:12 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Config::Simple>

L<Flickr::API>

L<XML::XPath>

L<XML::LibXML>

=head1 BUGS

Please report all bugs via http://rt.cpan.org/

=head1 LICENSE

Copyright (c) 2005-2008 Aaron Straup Cope. All Rights Reserved.

This is free software. You may redistribute it and/or
modify it under the same terms as Perl itself.

=cut

return 1;

__END__
