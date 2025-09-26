package NetBox::API::REST;
use strict;
use warnings 'FATAL' => 'all';
no warnings qw(experimental::signatures);
use feature qw(signatures);
use boolean qw(:all);
use parent qw(NetBox::API::Common);

use Data::Dumper;
use HTTP::Request;
use JSON;
use URI::Escape;

BEGIN {
    #{{{
    require Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT = qw();
    our @EXPORT_OK = qw();
} #}}}

our $VERSION = $NetBox::API::Common::VERSION;

sub __call :prototype($$$$$) ($class, $self, $method, $query, $vars = {}) {
    #{{{
    delete $vars->{'raw'} if exists $vars->{'raw'};
    return $class->GET($self, $query, $vars) if $method eq 'GET';
    my @result = qw();
    my $request = HTTP::Request->new($method, sprintf('%s/%s/', $self->baseurl, $query));
    $request->content(JSON->new->pretty(0)->encode($vars));
    eval {
        local $SIG{'ALRM'} = sub { die "operation timed out\n" };
        alarm $self->timeout;
        my $response = $self->ua->request($request);
        if ($response->is_success) {
            if ($method ne 'DELETE') {
                my $content = $response->decoded_content;
                my $payload = decode_json $content;
                unless (defined $payload) {
                    $self->__seterror(NetBox::API::Common::E_DECFAIL);
                    return qw();
                }
                @result = @{$payload}
            }
        } else {
            $self->__seterror(NetBox::API::Common::E_REQFAIL, $response->status_line);
            return qw();
        }
        alarm 0;
    };
    $self->__seterror(NetBox::API::Common::E_TIMEOUT) if $@;
    return @result;
} #}}}

sub GET :prototype($$$$) ($class, $self, $query, $vars = {}) {
    #{{{
    my @result = qw();
    eval {
        local $SIG{'ALRM'} = sub { die "operation timed out\n" };
        alarm $self->timeout;
        $vars->{'offset'} = 0;
        my $count = -1;
        my $i = boolean::true;
        my $fields = '.*';
        if (defined $vars->{'fields'}) {
            $fields = join '|', @{($vars->{'fields'})};
            delete $vars->{'fields'};
        }
        while (isTrue $i) {
            my @vars = qw();
            $vars->{'limit'} = $self->limit;
            foreach my $var (keys %{$vars}) {
                foreach my $val (ref $vars->{$var} eq 'ARRAY' ? @{$vars->{$var}} : ($vars->{$var})) {
                    push @vars, join('=', uri_escape($var), uri_escape($val));
                }
            }
            my $uri = sprintf '%s/%s/?%s', $self->{'baseurl'}, $query, join('&', @vars);
            my $response = $self->ua->get($uri);
            if ($response->is_success) {
                my $content = $response->decoded_content;
                my $payload = decode_json $content;
                $count = $payload->{'count'} if $count == -1;
                foreach my $r (@{$payload->{'results'}}) {
                    my $record = {};
                    if ($fields eq '.*') {
                        push @result, $r;
                    } else {
                        map { $record->{$_} = $r->{$_} if $_ =~ /^(?:$fields)$/i; } keys %{$r};
                        push @result, $record;
                    }
                }
                $vars->{'offset'} += $self->limit;
                $i = boolean::false if scalar @result >= $count;
            } else {
                $self->__seterror(NetBox::API::Common::E_REQFAIL, $response->status_line);
                $i = boolean::false;
            }
        }
        alarm 0;
    };
    if ($@) {
        $self->__seterror(NetBox::API::Common::E_TIMEOUT);
        return qw();
    }
    return @result;
} #}}}

sub POST {}

sub PUT {}

sub PATCH {}

sub DELETE {}

1;
