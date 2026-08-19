#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

# A tiny OTLP/HTTP collector: it accepts what the exporter sends and prints
# it to STDERR as a readable trace tree, so you can watch telemetry arrive
# instead of taking a vendor's word for it.
#
# It speaks the JSON transport (OTEL_EXPORTER_OTLP_PROTOCOL=http/json), which
# is exactly why that transport exists: you can read it. The protobuf form is
# three to five times smaller and is what you would actually ship.
#
#   plackup -s Hyperman -p 4318 example/collector.psgi
#
# Endpoints, as the spec puts them: POST /v1/traces, /v1/metrics, /v1/logs.
# It answers 200 with an empty JSON object, which is a full accept.

use Punk;
use File::Raw::JSON ();

sub say_err { print STDERR @_, "\n" }

# One line per span, indented by depth, so a parent and its children read as
# the tree they are. Spans arrive in whatever order they ended, so the tree is
# reconstructed from parent_span_id rather than assumed from the order.
sub print_spans {
    my ($rs) = @_;
    for my $r (@{ $rs || [] }) {
        my $res  = $r->{resource}{attributes} || [];
        my %attr = map { $_->{key} => _val($_->{value}) } @$res;
        my $svc  = $attr{'service.name'} // '(unnamed)';
        my $inst = $attr{'service.instance.id'} // '?';
        say_err "";
        say_err "=== $svc  instance=" . _short($inst)
              . ($r->{schemaUrl} ? "  schema=$r->{schemaUrl}" : '');

        for my $ss (@{ $r->{scopeSpans} || [] }) {
            my $scope = $ss->{scope}{name} // '?';
            say_err "  scope: $scope" . ($ss->{scope}{version}
                                        ? " $ss->{scope}{version}" : '');
            my @spans = @{ $ss->{spans} || [] };
            my %by_parent;
            my %known = map { $_->{spanId} => 1 } @spans;
            for my $s (@spans) {
                my $p = $s->{parentSpanId};
                # a parent that is not in this batch is a root as far as we
                # can see - which is the normal case for a continued trace
                push @{ $by_parent{ (defined $p && $known{$p}) ? $p : '' } }, $s;
            }
            _print_tree(\%by_parent, '', 2);
        }
    }
}

sub _print_tree {
    my ($by_parent, $parent, $depth) = @_;
    for my $s (@{ $by_parent->{$parent} || [] }) {
        my $pad  = '  ' x $depth;
        my $ms   = _duration_ms($s);
        my $kind = _kind($s->{kind});
        my $st   = $s->{status} && $s->{status}{code} ? " status=$s->{status}{code}" : '';
        say_err sprintf('%s%-28s %-8s %7.2fms  trace=%s span=%s%s',
            $pad, $s->{name} // '?', $kind, $ms,
            _short($s->{traceId}), _short($s->{spanId}), $st);

        for my $a (@{ $s->{attributes} || [] }) {
            say_err sprintf('%s    %s = %s', $pad, $a->{key}, _val($a->{value}));
        }
        for my $e (@{ $s->{events} || [] }) {
            say_err sprintf('%s    * %s', $pad, $e->{name} // '?');
        }
        _print_tree($by_parent, $s->{spanId}, $depth + 1);
    }
}

# OTLP/JSON writes 64-bit integers as STRINGS - a nanosecond timestamp is
# ~1.7e18 and would lose its last two digits as an IEEE double. So these are
# subtracted as strings-turned-numbers only after the difference is small.
sub _duration_ms {
    my ($s) = @_;
    my ($a, $b) = ($s->{startTimeUnixNano}, $s->{endTimeUnixNano});
    return 0 unless defined $a && defined $b;
    # take the difference in the last 15 digits, which no span exceeds
    my $d = substr($b, -15) - substr($a, -15);
    $d += 1e15 if $d < 0;
    return $d / 1_000_000;
}

sub _kind {
    my ($k) = @_;
    return '' unless defined $k;
    my %K = (SPAN_KIND_INTERNAL => 'internal', SPAN_KIND_SERVER => 'server',
             SPAN_KIND_CLIENT   => 'client',   SPAN_KIND_PRODUCER => 'producer',
             SPAN_KIND_CONSUMER => 'consumer');
    return $K{$k} // lc $k;
}

sub _val {
    my ($v) = @_;
    return '' unless ref $v eq 'HASH';
    for my $k (qw(stringValue intValue doubleValue boolValue)) {
        return $v->{$k} if defined $v->{$k};
    }
    return '(complex)';
}

sub _short { my ($x) = @_; defined $x ? substr($x, 0, 8) : '?' }

# ---- the routes -------------------------------------------------------------

my $accepted = 0;

post '/v1/traces' => sub {
    my ($c) = @_;
    my $doc = eval { File::Raw::JSON::file_json_decode($c->req->body) };
    if (!$doc) {
        say_err "collector: could not decode a body of "
              . length($c->req->body // '') . " bytes"
              . " - is the exporter sending protobuf? this demo speaks JSON";
        return $c->json({}, 200);
    }
    $accepted++;
    print_spans($doc->{resourceSpans});
    # An empty object is a FULL accept. A partial success would name the
    # rejected spans here, and an exporter that treated that as success would
    # lose data while every dashboard stayed green.
    return $c->json({}, 200);
};

# metrics and logs are accepted and counted, not printed - traces are the
# point of the demo and printing all three at once is unreadable
post '/v1/metrics' => sub { say_err "collector: metrics batch"; $_[0]->json({}, 200) };
post '/v1/logs'    => sub { say_err "collector: logs batch";    $_[0]->json({}, 200) };

get '/stats' => sub { $_[0]->json({ batches => $accepted }) };

say_err "collector: listening for OTLP/JSON on /v1/traces";

__PACKAGE__->to_app;
