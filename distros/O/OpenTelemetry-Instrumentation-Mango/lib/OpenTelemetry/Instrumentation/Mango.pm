package OpenTelemetry::Instrumentation::Mango;
# ABSTRACT: OpenTelemetry instrumentation for Mango

our $VERSION = '0.01';

use strict;
use warnings;
use experimental 'signatures';
use feature 'state';

use Class::Inspector;
use Class::Method::Modifiers 'install_modifier';
use Feature::Compat::Try;
use JSON::PP ();
use OpenTelemetry::Constants qw(SPAN_KIND_CLIENT SPAN_STATUS_ERROR SPAN_STATUS_OK);
use OpenTelemetry::Context;
use OpenTelemetry::Trace;
use OpenTelemetry;
use Scalar::Util 'blessed';
use Syntax::Keyword::Dynamically;

use parent 'OpenTelemetry::Instrumentation';

sub dependencies {'Mango'}

my (%ORIGINAL, $loaded);

# Commands whose first key names the targeted collection
my %COMMAND_WITH_COLLECTION = map {$_ => 1} qw(
    aggregate collstats count create createIndexes delete distinct drop
    dropIndexes find findAndModify insert listIndexes mapReduce mapreduce
    rename update
);

# Methods on Test::Mock::Mango::Collection that represent one operation each
my @COLLECTION_METHODS = qw(
    aggregate create drop find_and_modify find_one insert remove update
);

my $JSON = JSON::PP->new->canonical->allow_blessed;

sub uninstall($class) {
    return unless $loaded;
    no strict 'refs';
    no warnings 'redefine';
    for my $key (keys %ORIGINAL) {
        my ($package, $method) = $key =~ /^(.+)::(\w+)$/;
        delete $Class::Method::Modifiers::MODIFIER_CACHE{$package}{$method};
        *{"$package\::$method"} = delete $ORIGINAL{$key};
    }
    undef $loaded;
    return;
}

sub install($class, %options) {
    return if $loaded;
    return unless Class::Inspector->loaded('Mango');
    for my $target ($class->_targets) {
        my ($package, $method, $extract) = @$target;
        my $original = $package->can($method) or next;
        $ORIGINAL{"$package\::$method"} = $original;
        install_modifier $package, around => $method, _wrapper($extract);
    }
    return $loaded = 1;
}

sub _plain($data, $depth = 0) {
    return '...' if $depth > 9;
    return "$data" if blessed $data;
    return [ map {_plain($_, $depth + 1)} @$data ] if ref $data eq 'ARRAY';
    return { map {$_ => _plain($data->{$_}, $depth + 1)} keys %$data }
        if ref $data eq 'HASH';
    return $data;
}

sub _statement($doc) {
    return undef unless ref $doc eq 'HASH';
    my $json = eval {$JSON->encode(_plain($doc))} or return undef;
    return length $json > 512 ? substr($json, 0, 509) . '...' : $json;
}

# Read an attribute from either a real Mojo::Base object or a
# Test::Mock::Mango hashref. Attributes are stored in hash slots in both
# cases, so we never call user-facing methods (some, like
# Mango::Database::collection, build objects as a side effect).
sub _attr($invokant, $name) {
    return undef unless defined $invokant && ref $invokant;
    return $invokant->{$name};
}

sub _db_name($invokant) {
    my $db = _attr($invokant, 'db')
        // _attr(_attr($invokant, 'collection'), 'db')
        // $invokant;
    return _attr($db, 'name');
}

sub _collection_name($invokant) {
    my $collection = _attr($invokant, 'collection');
    return _attr($collection, 'name') if defined $collection;
    return _attr($invokant, 'name') if defined _attr($invokant, 'db');
    return undef;
}

sub _mango_of($invokant) {
    return _attr($invokant, 'mango')
        // _attr(_attr($invokant, 'db'), 'mango')
        // _attr(_attr(_attr($invokant, 'collection'), 'db'), 'mango');
}

sub _host_port($mango) {
    my $hosts = _attr($mango, 'hosts') or return ();
    my $first = $hosts->[0] or return ();
    return () unless ref $first eq 'ARRAY';
    my ($host, $port) = @$first;
    return ($host, $port // 27017);
}

sub _cb_idx(@args) {
    return undef unless @args && ref $args[-1] eq 'CODE';
    return $#args;
}

sub _describe($text) {
    my ($description) = split /\n/, $text =~ s/^\s+|\s+$//gr, 2;
    $description =~ s/ at \S+ line \d+\.$//a if defined $description;
    return defined $description && length $description ? $description : 'error';
}

# Attributes shared by every operation: db/collection names when known,
# plus server info when the Mango object is reachable
sub _common_attrs($invokant, $db_name, $collection) {
    my %attrs;
    $attrs{'db.namespace'} = $db_name if defined $db_name;
    $attrs{'db.collection.name'} = $collection if defined $collection;

    if (my $mango = _mango_of($invokant)) {
        my ($host, $port) = _host_port($mango);
        $attrs{'server.address'} = $host if defined $host;
        $attrs{'server.port'} = $port if defined $port;
    }

    return %attrs;
}

sub _span_name($operation, $db_name, $collection) {
    my $target = join '.', grep {defined} $db_name, $collection;
    my $name = $target ? "$operation $target" : $operation;
    return substr($name, 0, 100);
}

sub _command_extract($invokant, @args) {
    my $command = $args[0];
    my ($operation, $collection);

    if (!ref $command) {
        $operation = $command;
    } elsif (ref $command eq 'HASH') {
        for my $key (keys %$command) {
            next unless $COMMAND_WITH_COLLECTION{$key};
            ($operation, $collection) = ($key, $command->{$key});
            last;
        }
        # Real Mango command docs are bson_doc (insertion-ordered), so the
        # first key is the command name
        ($operation) = keys %$command unless defined $operation;
        undef $collection
            if !defined $collection || ref $collection || $collection =~ /\./;
    } else {
        $operation = 'command';
    }

    my $db_name = _db_name($invokant);

    my %attrs = (
        'db.system.name'    => 'mongodb',
        'db.operation.name' => $operation,
        _common_attrs($invokant, $db_name, $collection),
    );

    my $statement = _statement($command);
    $attrs{'db.statement'} = $statement if defined $statement;

    return (_span_name($operation, $db_name, $collection), \%attrs, _cb_idx(@args));
}

sub _build_query($invokant) {
    return $invokant->build_query if blessed $invokant && $invokant->can('build_query');
    return $invokant->{query};
}

sub _find_extract($invokant, @args) {
    my $db_name = _db_name($invokant);
    my $collection = _collection_name($invokant);

    my %attrs = (
        'db.system.name'    => 'mongodb',
        'db.operation.name' => 'find',
        _common_attrs($invokant, $db_name, $collection),
    );

    my $statement = _statement(_build_query($invokant));
    $attrs{'db.statement'} = $statement if defined $statement;

    return (_span_name('find', $db_name, $collection), \%attrs, _cb_idx(@args));
}

sub _wire_extract($operation, $with_ns = 1) {
    sub($invokant, @args) {
        my ($db_name, $collection, $label) = (undef, undef, '');

        if ($with_ns) {
            $label = $args[0] // '';
            ($db_name, $collection) = split /\./, $label, 2;
            $db_name = undef if defined $db_name && !length $db_name;
        } else {
            # Mango::kill_cursors receives a cursor id, not a namespace:
            # keep the id in the span name, but not in the db attributes
            $label = $args[0] // '';
        }

        my %attrs = (
            'db.system.name'    => 'mongodb',
            'db.operation.name' => $operation,
        );
        $attrs{'db.namespace'} = $db_name if defined $db_name;
        $attrs{'db.collection.name'} = $collection
            if defined $collection && length $collection && $collection !~ /^\$cmd/;

        my ($host, $port) = _host_port($invokant);
        $attrs{'server.address'} = $host if defined $host;
        $attrs{'server.port'} = $port if defined $port;

        my $name = length $label ? "$operation $label" : $operation;
        return (substr($name, 0, 100), \%attrs, _cb_idx(@args));
    };
}

sub _named_extract($operation) {
    sub($invokant, @args) {
        my $db_name = _db_name($invokant);
        my $collection = _collection_name($invokant);

        my %attrs = (
            'db.system.name'    => 'mongodb',
            'db.operation.name' => $operation,
            _common_attrs($invokant, $db_name, $collection),
        );

        return (_span_name($operation, $db_name, $collection), \%attrs, _cb_idx(@args));
    };
}

sub _wrapper($extract) {
    sub($orig, $invokant, @args) {
        my ($name, $attributes, $cb_idx) = $extract->($invokant, @args);

        my $span = OpenTelemetry->tracer_provider->tracer->create_span(
            name       => $name,
            kind       => SPAN_KIND_CLIENT,
            attributes => $attributes,
        );

        my $done;
        my $finish = sub($description = undef) {
            return if $done;
            $done = 1;

            if (defined $description && length $description) {
                $span->set_status(SPAN_STATUS_ERROR, $description);
            } else {
                $span->set_status(SPAN_STATUS_OK);
            }

            $span->end;
            return;
        };

        my $out;
        try {
            if (defined $cb_idx) {
                my $cb = $args[$cb_idx];
                my $ctx = OpenTelemetry::Trace->context_with_span($span);
                my @copied = @args;
                $copied[$cb_idx] = sub(@reply) {
                    try {
                        dynamically OpenTelemetry::Context->current = $ctx;
                        $finish->(
                            defined $reply[1] ? _describe("$reply[1]") : undef
                        );
                        $cb->(@reply);
                    } catch ($error) {
                        die $error;
                    }
                };
                $out = [ $invokant->$orig(@copied) ];
            } else {
                dynamically OpenTelemetry::Context->current
                    = OpenTelemetry::Trace->context_with_span($span);

                $out = [ $invokant->$orig(@args) ];
            }
        } catch ( $error ) {
            $span->record_exception($error) unless $done;
            $finish->(_describe("$error"));
            die $error;
        } finally {
            # Blocking calls finish here; non-blocking calls finish in the callback
            $finish->() unless defined $cb_idx;
        }

        # Every wrapped Mango method returns a single value; the arrayref
        # merely carries it out of the try block
        return $out->[0];
    };
}

sub _targets($class) {
    return (
        [ 'Mango::Database', 'command', \&_command_extract ],
        [ 'Mango::Cursor::Query', '_start', \&_find_extract ],
        [ 'Mango', 'get_more', _wire_extract('get_more') ],
        [ 'Mango', 'kill_cursors', _wire_extract('kill_cursors', 0) ],
        Class::Inspector->loaded('Test::Mock::Mango') ? (
            [ 'Test::Mock::Mango::DB', 'command', \&_command_extract ],
            (map {[ 'Test::Mock::Mango::Collection', $_, _named_extract($_) ]}
                @COLLECTION_METHODS),
            (map {[ 'Test::Mock::Mango::Cursor', $_, _named_extract('find') ]}
                qw(all next)),
            [ 'Test::Mock::Mango::Cursor', 'count', _named_extract('count') ],
        ) : (),
    );
}

1;