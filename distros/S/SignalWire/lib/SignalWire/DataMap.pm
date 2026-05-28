package SignalWire::DataMap;
use strict;
use warnings;
use Moo;
use JSON ();

has 'function_name' => (
    is       => 'ro',
    required => 1,
);

has '_purpose' => (
    is      => 'rw',
    default => sub { '' },
);

has '_parameters' => (
    is      => 'rw',
    default => sub { {} },
);

has '_required_params' => (
    is      => 'rw',
    default => sub { [] },
);

has '_expressions' => (
    is      => 'rw',
    default => sub { [] },
);

has '_webhooks' => (
    is      => 'rw',
    default => sub { [] },
);

has '_output' => (
    is      => 'rw',
    default => sub { undef },
);

has '_error_keys' => (
    is      => 'rw',
    default => sub { [] },
);

# Constructor shortcut: DataMap->new("name") or DataMap->new(function_name => "name")
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    if (@args == 1 && !ref $args[0]) {
        return $class->$orig(function_name => $args[0]);
    }
    return $class->$orig(@args);
};

#
# purpose — set the LLM-facing tool description. PROMPT ENGINEERING,
# not developer documentation.
#
# The description string is rendered into the OpenAI tool schema
# `description` field on every LLM turn. The model reads it to decide
# WHEN to call this tool. A vague purpose() is the #1 cause of "the
# model has the right tool but doesn't call it" failures with data-map
# tools.
#
# BAD vs GOOD:
#
#   BAD : ->purpose('weather api')
#   GOOD: ->purpose('Get the current weather conditions and forecast '
#                 . 'for a specific city. Use this whenever the user '
#                 . 'asks about weather, temperature, rain, or similar '
#                 . 'conditions in a named location.')
#
sub purpose {
    my ($self, $desc) = @_;
    $self->_purpose($desc);
    return $self;
}

#
# description — alias for purpose(). Sets the LLM-facing tool
# description. This string is read by the model to decide WHEN to call
# this tool. See purpose() for bad-vs-good examples.
#
sub description {
    my ($self, $desc) = @_;
    return $self->purpose($desc);
}

#
# parameter — add a parameter definition; the `description` is
# LLM-FACING.
#
# Each parameter description is rendered into the OpenAI tool schema
# under parameters.properties.<name>.description and sent to the
# model. The model uses it to decide HOW to fill in the argument from
# user speech. It is prompt engineering, not developer FYI.
#
# BAD vs GOOD:
#
#   BAD : ->parameter('city', 'string', 'the city')
#   GOOD: ->parameter('city', 'string',
#             'The name of the city to get weather for, e.g. '
#           . '"San Francisco". Ask the user if they did not provide '
#           . 'one. Include the state or country if the city name is '
#           . 'ambiguous.')
#
sub parameter {
    my ($self, $name, $type, $description, %opts) = @_;
    my $required = $opts{required} // 0;
    my $enum     = $opts{enum};

    my %param_def = (
        type        => $type,
        description => $description,
    );
    $param_def{enum} = $enum if $enum;

    $self->_parameters->{$name} = \%param_def;

    if ($required) {
        my $req = $self->_required_params;
        push @$req, $name unless grep { $_ eq $name } @$req;
    }

    return $self;
}

sub expression {
    my ($self, $test_value, $pattern, $output, %opts) = @_;
    my $nomatch_output = $opts{nomatch_output};

    # If pattern is a compiled regex, extract the string
    if (ref $pattern eq 'Regexp') {
        $pattern = "$pattern";
        # Strip Perl regex delimiters: (?^:...) or (?^u:...)
        $pattern =~ s/^\(\?[\^a-z]*://;
        $pattern =~ s/\)$//;
    }

    my %expr = (
        string  => $test_value,
        pattern => $pattern,
        output  => $output->to_hash,
    );
    $expr{'nomatch-output'} = $nomatch_output->to_hash if $nomatch_output;

    push @{ $self->_expressions }, \%expr;
    return $self;
}

sub webhook {
    my ($self, $method, $url, %opts) = @_;
    my $headers            = $opts{headers};
    my $form_param         = $opts{form_param};
    my $input_args_as_params = $opts{input_args_as_params};
    my $require_args       = $opts{require_args};

    my %wh = (
        url    => $url,
        method => uc($method),
    );
    $wh{headers}            = $headers            if $headers;
    $wh{form_param}         = $form_param         if $form_param;
    $wh{input_args_as_params} = JSON::true        if $input_args_as_params;
    $wh{require_args}       = $require_args       if $require_args;

    push @{ $self->_webhooks }, \%wh;
    return $self;
}

sub webhook_expressions {
    my ($self, $expressions) = @_;
    die "Must add webhook before setting webhook expressions"
        unless @{ $self->_webhooks };
    $self->_webhooks->[-1]{expressions} = $expressions;
    return $self;
}

sub body {
    my ($self, $data) = @_;
    die "Must add webhook before setting body"
        unless @{ $self->_webhooks };
    $self->_webhooks->[-1]{body} = $data;
    return $self;
}

sub params {
    my ($self, $data) = @_;
    die "Must add webhook before setting params"
        unless @{ $self->_webhooks };
    $self->_webhooks->[-1]{params} = $data;
    return $self;
}

sub foreach {
    my ($self, $config) = @_;
    die "Must add webhook before setting foreach"
        unless @{ $self->_webhooks };
    die "foreach_config must be a hashref" unless ref $config eq 'HASH';

    for my $key (qw(input_key output_key append)) {
        die "foreach config missing required key: $key"
            unless exists $config->{$key};
    }

    $self->_webhooks->[-1]{foreach} = $config;
    return $self;
}

sub output {
    my ($self, $result) = @_;
    die "Must add webhook before setting output"
        unless @{ $self->_webhooks };
    $self->_webhooks->[-1]{output} = $result->to_hash;
    return $self;
}

sub fallback_output {
    my ($self, $result) = @_;
    $self->_output($result->to_hash);
    return $self;
}

sub error_keys {
    my ($self, $keys) = @_;
    if (@{ $self->_webhooks }) {
        $self->_webhooks->[-1]{error_keys} = $keys;
    } else {
        $self->_error_keys($keys);
    }
    return $self;
}

sub global_error_keys {
    my ($self, $keys) = @_;
    $self->_error_keys($keys);
    return $self;
}

sub to_swaig_function {
    my ($self) = @_;

    # Build parameter schema
    my %param_schema;
    if (keys %{ $self->_parameters }) {
        $param_schema{type}       = 'object';
        $param_schema{properties} = { %{ $self->_parameters } };
        if (@{ $self->_required_params }) {
            $param_schema{required} = [ @{ $self->_required_params } ];
        }
    } else {
        %param_schema = (type => 'object', properties => {});
    }

    # Build data_map
    my %data_map;
    if (@{ $self->_expressions }) {
        $data_map{expressions} = $self->_expressions;
    }
    if (@{ $self->_webhooks }) {
        $data_map{webhooks} = $self->_webhooks;
    }
    if (defined $self->_output) {
        $data_map{output} = $self->_output;
    }
    if (@{ $self->_error_keys }) {
        $data_map{error_keys} = $self->_error_keys;
    }

    return {
        function    => $self->function_name,
        description => $self->_purpose || "Execute " . $self->function_name,
        parameters  => \%param_schema,
        data_map    => \%data_map,
    };
}

1;
