% if (0) {
%# This is here for vim syntax highlighting
<script>
% }
require(["dojo/_base/array"], function (array) {

var fieldHeader = ['index', 'name', 'optional', 'type', 'validateSpec'];

// Custom types

function _table2objects (data, columns) {
    if (columns === undefined) {
        columns = data.shift();
    }
    var objects = [], i, j, obj;
    for (i = 0; i < data.length; i++) {
        obj = {};
        for (j = 0; j < columns.length; j++) {
            obj[ columns[j] ] = data[i][j];
        }
        objects.push(obj);
    }
    return objects;
}

<%perl>
my @type_custom_declare = ([qw(name type validateSpec)]);
foreach my $type (
    sort { $a->name cmp $b->name }
    grep { $_->isa('Thrift::IDL::TypeDef') }
    values %types
) {

    my %details = (
        name => $type->name,
        type => describe_type($type->type, $namespace, 1),
    );

    my $spec = describe_validateSpec($type);
    if (@$spec) {
        $details{validateSpec} = $spec;
    }
    else {
        $details{validateSpec} = [];
    }

    push @type_custom_declare, [ map { $details{$_} } @{ $type_custom_declare[0] } ];

</%perl>
\
<%doc>
dojo.declare('<% $namespace %>.<% $type->name %>', Tapir.Type.Custom, {
    type: <% describe_type($type->type) %>,
%   if ($type->{doc} && $type->{doc}{validate}) {
    validateSpec: [
%       foreach my $validate_type (keys %{ $type->{doc}{validate} }) {
%           foreach my $validate_param (@{ $type->{doc}{validate}{$validate_type} }) {
        {
            type: '<% $validate_type %>',
%               if ($validate_type eq 'range' || $validate_type eq 'length') {
%                   my ($low, $high) = $validate_param =~ /^\s* (\d*) \s*-\s* (\d*) \s*$/x;
            low: <% length $low ? $low : 'null' %>,
            high: <% length $high ? $high : 'null' %>,
%               } elsif ($validate_type eq 'regex') {
            pattern: <% $validate_param %>,
%               } else {
%                   print STDERR "Unrecognized \@validate spec '$validate_type $validate_param'\n";
%               }
        },
%           } # foreach validate_param
%       } # foreach validate_type
    ],
%   } # if doc
});
</%doc>
\
% } # foreach type

array.forEach(
    _table2objects(<% $jsonxs->encode(\@type_custom_declare) %>),
    function (type, i) {
        dojo.declare('<% $namespace %>.' + type.name, Tapir.Type.Custom, type);
    }
);

// Custom Enum

<%perl>
foreach my $type (
    sort { $a->name cmp $b->name }
    grep { $_->isa('Thrift::IDL::Enum') }
    values %types
) {
</%perl>
\
dojo.declare('<% $namespace %>.<% $type->name %>', Tapir.Type.Enum, {
    values: { <% join ', ', map { "'$$_[0]': $$_[1]" } @{ $type->numbered_values } %> }
});
\
% } # foreach type

// Custom exceptions and structures

<%perl>
foreach my $type (
    sort { $a->name cmp $b->name }
    grep { $_->isa('Thrift::IDL::Struct') }
    values %types
) {
</%perl>
\
dojo.declare('<% $namespace %>.<% $type->name %>', Tapir.Type.<% $type->isa('Thrift::IDL::Exception') ? 'Exception' : 'Struct' %>, {
    fieldSpec: <% describe_fields($type->fields, $namespace) %>
});
\
% } # foreach type

// Services

% my @method_declare = ([qw(name serviceName fieldSpec spec)]);
% foreach my $service (@services) {
\
dojo.declare('<% $namespace %>.<% $service->name %>', Tapir.Service, {
    name: '<% $service->name %>',
    methods: [ <% join ', ', map { '"' . $_->name . '"' } @{ $methods{ $service->name } } %> ],
    baseName: '<% $namespace %>.<% $service->name %>'
});

TapirClient.services.push('<% $namespace %>.<% $service->name %>');
\
<%doc>
dojo.declare('<% $namespace %>.<% $service->name %>.<% $method->name %>', Tapir.Method, {
    name: '<% $method->name %>',
    serviceName: '<% $service->name %>',
    fieldSpec: <% describe_fields($method->arguments) %>,
    spec: {
        exceptions: <% describe_fields($method->throws) %>,
        returns: <% describe_type($method->returns) %>
    }
});
</%doc>
\
<%perl>
    foreach my $method (@{ $methods{ $service->name } }) {
        push @method_declare, [
            $method->name,
            $service->name,
            describe_fields($method->arguments, $namespace, 1, 1),
            {
                exceptions => describe_fields($method->throws, $namespace, 1, 1),
                returns    => describe_type($method->returns, $namespace, 1)
            }
        ];
    }
</%perl>
\
% } # foreach service

array.forEach(
    _table2objects(<% $jsonxs->encode(\@method_declare) %>),

    function (method, i) {
        method.fieldSpec       = _table2objects(method.fieldSpec, fieldHeader);
        method.spec.exceptions = _table2objects(method.spec.exceptions, fieldHeader);
        dojo.declare('<% $namespace %>.' + method.serviceName + '.' + method.name, Tapir.Method, method);
    }
);

});
% if (0) {
</script>
% }

<%once>
use JSON::XS;
my $jsonxs = JSON::XS->new->ascii->pretty(1)->allow_nonref;
</%once>

<%args>
$document
$namespace
%types
</%args>

<%init>
my (@services, %methods);

foreach my $service (@{ $document->services }) {
    push @services, $service;
    foreach my $method (@{ $service->methods }) {
        push @{ $methods{ $service->name } }, $method;
    }
}

sub describe_type {
    my ($type, $namespace, $want_perl) = @_;

    my $namespaced_type = $type->isa('Thrift::IDL::Type::Custom') ? join '.', $namespace, $type->name : $type->name;

    if ($type->can('val_type')) {
        my %details = (
            type => $namespaced_type,
            valType => describe_type($type->val_type, $namespace, 1),
        );
        if ($type->can('key_type')) {
            $details{keyType} = describe_type($type->key_type, $namespace, 1);
        }

        return $want_perl ? \%details : $jsonxs->encode(\%details);
    }

    return $want_perl ? $namespaced_type : "'" . $namespaced_type . "'";
}

sub describe_fields {
    my ($fields, $namespace, $want_perl, $no_header) = @_;

    my @output = (
        ($no_header ? () : (
        [qw(index name optional type validateSpec)],
        ))
    );
    foreach my $field (@$fields) {
        my $optional = $field->optional ? 1 : 0;
        if (! $optional && $field->{doc} && $field->{doc}{optional}) {
            $optional = 1;
        }
        push @output, [
            $field->id,
            $field->name,
            ($optional ? JSON::XS::true : JSON::XS::false),
            describe_type($field->type, $namespace, 1),
            describe_validateSpec($field)
        ];
    }

    return $want_perl ? \@output : '_table2objects(' . $jsonxs->encode(\@output) . ')';
}

sub describe_validateSpec {
    my $type = shift;
    return [] unless $type->{doc};

    my @spec;

    if ($type->{doc}{validators}) {
        foreach my $validator (@{ $type->{doc}{validators} }) {
            my ($type) = ref($validator) =~ m{::([^:]+)$};
            my %spec_details = (
                type => lc($type)
            );
            push @spec, \%spec_details;

            if ($type eq 'Range' || $type eq 'Length') {
                $spec_details{low}  = $validator->{min};
                $spec_details{high} = $validator->{max};
            }
            elsif ($type eq 'Regex') {
                # Javascript doesn't support POSIX named character classes
                my $pattern = $validator->{body};
                $pattern =~ s{\[:alnum:\]}{A-Za-z0-9}g;
                if ($pattern =~ /\[:([a-z]+):\]/) {
                    print STDERR "Failed to convert POSIX named character class '$1'\n";
                }
                $spec_details{pattern} = $pattern;
            }
            else {
                print STDERR "Unrecognized \@validate spec '$type'\n";
            }
        }
    }

    if ($type->{doc}{utf8}) {
        push @spec, { type => 'utf8' };
    }

    return \@spec;
}
</%init>
