package PAGI::StructuredParameters;
$PAGI::StructuredParameters::VERSION = '0.001000';
use strict;
use warnings;
use Storable ();
use Carp ();
use PAGI::StructuredParameters::Exception::MissingParameter;
use PAGI::StructuredParameters::Exception::InvalidArrayLength;
use PAGI::StructuredParameters::Exception::InvalidArrayPointer;

our $MAX_ARRAY_DEPTH = 1000;

# A no-dependency port of the core of Catalyst::Utils::StructuredParameters:
# given a flat form/query hash (keys encode nesting: name.first, email[0],
# children[0].age) or already-nested body data, it whitelists and reconstructs
# only the rule-described shape. Validation of *values* is out of scope.

sub new { my ($class, %args) = @_;
    my $src = $args{src} // 'body';
    my $flatten = exists $args{flatten_array_value}
        ? $args{flatten_array_value}
        : ($src eq 'data' ? 0 : 1);

    return bless {
        src                 => $src,
        src_data            => $args{src_data} // {},
        namespace           => $args{namespace},
        flatten_array_value => $flatten,
        max_array_depth     => $args{max_array_depth} // $MAX_ARRAY_DEPTH,
        context             => $args{context},
    }, $class;
}

# --- request adapters -------------------------------------------------------

sub from_body { my ($class, $req, $context) = @_;
    require PAGI::StructuredParameters::Request;
    return PAGI::StructuredParameters::Request->new(
        request => $req, kind => 'body', context => $context,
    );
}

sub from_query { my ($class, $req, $context) = @_;
    require PAGI::StructuredParameters::Request;
    return PAGI::StructuredParameters::Request->new(
        request => $req, kind => 'query', context => $context,
    );
}

sub from_data { my ($class, $req, $context) = @_;
    require PAGI::StructuredParameters::Request;
    return PAGI::StructuredParameters::Request->new(
        request => $req, kind => 'data', context => $context,
    );
}

# --- configuration (chainable) ---------------------------------------------

sub namespace { my ($self, $arg) = @_;
    $self->{namespace} = $arg if defined $arg;
    return $self;
}

sub flatten_array_value { my ($self, $arg) = @_;
    $self->{flatten_array_value} = $arg if defined $arg;
    return $self;
}

sub max_array_depth { my ($self, $arg) = @_;
    $self->{max_array_depth} = $arg if defined $arg;
    return $self;
}

# --- terminal whitelisting --------------------------------------------------

sub permitted { my ($self, @proto) = @_;
    my ($ns, $rules) = $self->_namespace_and_rules(@proto);
    return $self->_parse(Storable::dclone($self->{src_data}), $ns, $rules, 0);
}

sub required { my ($self, @proto) = @_;
    my $on_missing = pop @proto;
    Carp::croak('required needs an on-missing callback')
        unless ref($on_missing) eq 'CODE';

    local $self->{_missing} = [];
    my ($ns, $rules) = $self->_namespace_and_rules(@proto);
    my $parsed = $self->_parse(Storable::dclone($self->{src_data}), $ns, $rules, 1);

    if (@{$self->{_missing}}) {
        die $on_missing->($self->{context}, $self->{_missing});
    }
    return $parsed;
}

# Pull a leading \@namespace affix off the rule list, if present, and combine it
# with any namespace set via ->namespace. A leading *arrayref* is unambiguously a
# namespace (top-level rules are only scalars or hashrefs).
sub _namespace_and_rules { my ($self, @proto) = @_;
    my $ns = $self->{namespace} // [];
    if (@proto && ref($proto[0]) eq 'ARRAY') {
        my $affix = shift @proto;
        $ns = [@$ns, @$affix];
    }
    return ($ns, [@proto]);
}

sub _normalize_array_value { my ($self, $value) = @_;
    return $value unless $self->{flatten_array_value};
    return ((ref($value) || '') eq 'ARRAY') ? $value->[-1] : $value;
}

# Empty final index ('') sorts last; numeric indexes sort numerically.
sub _sort_indexes { my (@indexes) = @_;
    return sort {
        $a eq '' ? 1 : $b eq '' ? -1 : $a <=> $b
    } @indexes;
}

sub _parse { my ($self, $context, $ns, $rules, $required) = @_;
    return $self->{src} eq 'data'
        ? $self->_parse_data($context, $ns, $rules, $required)
        : $self->_parse_formlike($context, $ns, $rules, $required);
}

sub _parse_formlike { my ($self, $context, $ns, $rules, $required) = @_;
    my $current = {};

    while (@$rules) {
        my $rule = shift @$rules;

        if ((ref($rule) || '') eq 'HASH') {
            # +{ key => [...] } : an array, or an array of hashes
            my ($local_ns, $sub_rules) = %$rule;
            my $key = join('.', @$ns, $local_ns);

            my %indexes;
            for my $field (keys %$context) {
                my ($i, $under) = ($field =~ m/^\Q$key\E\[(\d*)\]\.?(.*)$/);
                next unless defined $i;
                $indexes{$i} = $under;
            }

            my $found = scalar keys %indexes;
            PAGI::StructuredParameters::Exception::InvalidArrayLength->throw(
                pointer   => $local_ns,
                max       => $self->{max_array_depth},
                attempted => $found,
            ) if $found > $self->{max_array_depth};

            unless (%indexes) {
                # The array key is wholly absent from the input. With no indexes
                # the index loop never runs, so report the key missing here (a
                # no-op for permitted, where $required is false).
                $self->_record_missing($key, $required);
                next;
            }

            for my $index (_sort_indexes(keys %indexes)) {
                my $cloned = Storable::dclone($sub_rules);
                $cloned = [''] unless @$cloned;    # bare array case: +{ email => [] }

                my $old = $self->{flatten_array_value};
                $self->{flatten_array_value} = 0 if $index eq '';
                my $value = $self->_parse_formlike(
                    $context, [@$ns, "${local_ns}[$index]"], $cloned, $required,
                );

                if ($index eq '' && $old) {
                    $self->{flatten_array_value} = $old;
                    if ((ref($value) || '') eq 'ARRAY') {
                        push @{$current->{$local_ns}}, @$value;
                    }
                    elsif ((ref($value) || '') eq 'HASH') {
                        if (ref $value->{$indexes{$index}}) {
                            push @{$current->{$local_ns}},
                                map { +{ $indexes{$index} => $_ } }
                                @{$value->{$indexes{$index}}};
                        }
                        else {
                            push @{$current->{$local_ns}}, $value;
                        }
                    }
                }
                else {
                    # A row with only invalid (unlisted) fields is not "missing".
                    next if (ref($value) || '') eq 'HASH' && !%$value;
                    push @{$current->{$local_ns}}, $value;
                }
            }
        }
        elsif ((ref($rules->[0]) || '') eq 'ARRAY') {
            # scalar key followed by \@subkeys : a nested hash
            my $value = $self->_parse_formlike(
                $context, [@$ns, $rule], shift(@$rules), $required,
            );
            next unless %$value;    # lenient: drop empty nested hash
            $current->{$rule} = $value;
        }
        elsif ($rule eq '') {
            # bare leaf at the current namespace (used by array reconstruction)
            my $key = join('.', @$ns);
            unless (defined $context->{$key}) {
                $self->_record_missing($key, $required);
                next;
            }
            $current = $self->_normalize_array_value($context->{$key});
        }
        else {
            # plain scalar key
            my $key = join('.', @$ns, $rule);
            unless (defined $context->{$key}) {
                $self->_record_missing($key, $required);
                next;
            }
            $current->{$rule} = $self->_normalize_array_value($context->{$key});
        }
    }

    return $current;
}

sub _parse_data { my ($self, $context, $ns, $rules, $required) = @_;
    my $current = {};

    RULE: while (@$rules) {
        my $rule = shift @$rules;

        if ((ref($rule) || '') eq 'HASH') {
            # +{ key => [...] } : the value at this pointer must be an array
            my ($local_ns, $sub_rules) = %$rule;

            my $value = $context;
            for my $pointer (@$ns, $local_ns) {
                if ((ref($value) || '') eq 'HASH' && exists $value->{$pointer}) {
                    $value = $value->{$pointer};
                }
                else {
                    $self->_record_missing(join('.', @$ns, $local_ns), $required);
                    next RULE;
                }
            }

            PAGI::StructuredParameters::Exception::InvalidArrayPointer->throw(
                pointer => join('.', @$ns, $local_ns),
            ) unless (ref($value) || '') eq 'ARRAY';

            my $found = scalar @$value;
            PAGI::StructuredParameters::Exception::InvalidArrayLength->throw(
                pointer   => $local_ns,
                max       => $self->{max_array_depth},
                attempted => $found,
            ) if $found > $self->{max_array_depth};

            my @gathered;
            for my $item (@$value) {
                my $cloned = Storable::dclone($sub_rules);
                $cloned = [''] unless @$cloned;    # bare array case
                my $parsed = $self->_parse_data($item, [], $cloned, $required);
                next if (ref($parsed) || '') eq 'HASH' && !%$parsed;
                push @gathered, $parsed;
            }
            $current->{$local_ns} = \@gathered;
        }
        elsif ((ref($rules->[0]) || '') eq 'ARRAY') {
            # scalar key followed by \@subkeys : a nested hash
            my $value = $self->_parse_data(
                $context, [@$ns, $rule], shift(@$rules), $required,
            );
            next unless %$value;
            $current->{$rule} = $value;
        }
        elsif ($rule eq '') {
            my $value = $context;
            for my $pointer (@$ns) {
                if ((ref($value) || '') eq 'HASH' && exists $value->{$pointer}) {
                    $value = $value->{$pointer};
                }
                else {
                    $self->_record_missing(join('.', @$ns, $rule), $required);
                    next RULE;
                }
            }
            $current = $self->_normalize_array_value($value);
        }
        else {
            my $value = $context;
            for my $pointer (@$ns, $rule) {
                if ((ref($value) || '') eq 'HASH' && exists $value->{$pointer}) {
                    $value = $value->{$pointer};
                }
                else {
                    $self->_record_missing(join('.', @$ns, $rule), $required);
                    next RULE;
                }
            }
            $current->{$rule} = $self->_normalize_array_value($value);
        }
    }

    return $current;
}

sub _record_missing { my ($self, $key, $required) = @_;
    return unless $required;
    push @{$self->{_missing}}, $key;
}

1;

=encoding utf8

=head1 NAME

PAGI::StructuredParameters - Whitelist and structure incoming request parameters

=head1 SYNOPSIS

    use PAGI::StructuredParameters;

    my $params = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {
            username     => 'jnap',
            'name.first' => 'John',
            'name.last'  => 'Napiorkowski',
            'email[0]'   => 'jnap@example.com',
        },
    );

    my $clean = $params->permitted(
        'username',
        name => ['first', 'last'],
        +{ email => [] },
    );

    # $clean = {
    #   username => 'jnap',
    #   name     => { first => 'John', last => 'Napiorkowski' },
    #   email    => ['jnap@example.com'],
    # }

=head1 DESCRIPTION

A no-dependency port of the core of
L<Catalyst::Utils::StructuredParameters>, decoupled from Catalyst. Its job is to
B<whitelist and structure> incoming parameters I<before> they reach a model: a
prior layer to validation, not validation itself. Validation of values is out of
scope (use a downstream validator such as Valiant).

Form and query parameters arrive as a flat hash whose keys encode nesting
(C<name.first>, C<email[0]>, C<children[0].age>). The rule grammar reconstructs
the named, present keys into the described nested shape and drops everything
else. Already-nested body data (such as decoded JSON) is simply whitelisted.

=head1 CONSTRUCTOR

=head2 new

    my $params = PAGI::StructuredParameters->new(
        src                 => 'body',     # 'body' | 'query' | 'data'
        src_data            => \%params,   # the source hash to filter
        namespace           => \@fields,   # optional starting namespace
        flatten_array_value => $bool,      # default: 1 for body/query, 0 for data
        max_array_depth     => 1000,       # cap on array reconstruction
        context             => $obj,       # optional; passed to required's callback
    );

C<src_data> is the materialized source hash. For request-bound, asynchronous
sources (a POST body), use the adapters in
L<PAGI::StructuredParameters::Request> instead.

=head1 REQUEST ADAPTERS

These class methods bind the engine to a live L<PAGI::Request>, returning a
L<PAGI::StructuredParameters::Request> whose C<permitted>/C<required> are
asynchronous (the request body is read with C<await>).

=head2 from_body

    my $params = PAGI::StructuredParameters->from_body($req, $context);

Source is the request's form/body parameters (array values flattened by default).

=head2 from_query

    my $params = PAGI::StructuredParameters->from_query($req, $context);

Source is the URI query string (array values flattened by default).

=head2 from_data

    my $params = PAGI::StructuredParameters->from_data($req, $context);

Source is the decoded request body data such as JSON (arrays kept as-is).

The optional C<$context> is passed as the first argument to C<required>'s
on-missing callback.

=head1 RULE SPECIFICATIONS

=over 4

=item C<'username', 'password'> — scalar keys.

=item C<< name => ['first', 'last'] >> — a nested hash, reconstructed from
C<name.first> / C<name.last>.

=item C<< +{ email => [] } >> — an array, reconstructed from C<email[0]>,
C<email[1]>, ...

=item C<< +{ children => [['name','age']] } >> — an array of hashes,
reconstructed from C<children[0].name>, C<children[1].age>, ...

=back

A leading arrayref is treated as a starting namespace affix, e.g.
C<< $params->permitted(['person'], 'name', 'age') >>.

=head1 METHODS

=head2 namespace

    $params->namespace(['person']);

Scope all subsequent rules under the given key path. Returns the object for
chaining.

=head2 flatten_array_value

    $params->flatten_array_value(0);

Toggle array-value flattening ("pick last"), a common workaround for HTML form
controls that submit repeated values. On by default for C<body>/C<query>, off
for C<data>. Returns the object for chaining.

=head2 max_array_depth

    $params->max_array_depth(50);

Cap the number of items reconstructed for any single array, guarding against
hostile input. Throws
L<PAGI::StructuredParameters::Exception::InvalidArrayLength> when exceeded.
Returns the object for chaining.

=head2 permitted

    my $clean = $params->permitted(@rules);

Lenient whitelist. Returns a clean hashref containing only the permitted, present
keys, reconstructed into the shape the rules describe. Absent keys are simply
omitted.

=head2 required

    my $clean = $params->required(@rules, $on_missing);

Strict whitelist. The trailing argument B<must> be a coderef (otherwise a loud
C<required needs an on-missing callback> error is raised at the call site).

On success, returns the clean hashref, exactly as L</permitted> would. If any
required key is absent, C<$on_missing> is invoked as
C<< $on_missing->($context, \@missing) >> — where C<$context> is the object's
C<context> attribute (in L<PAGI::Nano> this is the request context C<$c>) and
C<\@missing> is an arrayref of every missing dotted key path — and its return
value is thrown. PAGI::Nano's dispatch catches that thrown, respond-able value
and sends it, making the failure response explicit and chosen at the call site.

Passing the context as an argument (rather than closing over it) lets the
callback be a shared, named sub reused across routes.

=head1 SEE ALSO

L<PAGI::StructuredParameters::Request>, L<PAGI::Nano>,
L<Catalyst::TraitFor::Request::StructuredParameters>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
