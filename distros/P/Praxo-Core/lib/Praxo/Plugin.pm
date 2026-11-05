package Praxo::Plugin;

use strict;
use warnings;
use Exporter 'import';
use Scalar::Util qw(looks_like_number);
use Praxo::Json ();
use Praxo::Errors qw(praxo_error);

our @EXPORT_OK = qw(parse_manifest);

my @KINDS = qw(
    tool.provider.v1 model.provider.v1 policy.provider.v1
    memory.provider.v1 sandbox.provider.v1
);
my %TOP_KEYS = map { $_ => 1 } qw(
    schemaVersion id version kind entrypoint protocol capabilities permissions
    limits isolation health signature sbom
);
my %ENTRYPOINT_KEYS = map { $_ => 1 } qw(type command module image args dir);
my %PERMISSION_KEYS = map { $_ => 1 } qw(filesystem network env);
my %LIMIT_KEYS = map { $_ => 1 } qw(memoryMB cpuMillis timeoutMs maxInflight);
my %HEALTH_KEYS = map { $_ => 1 } qw(method intervalMs);
my %SIGNATURE_KEYS = map { $_ => 1 } qw(algorithm keyId);
my %KIND_LOOKUP = map { $_ => 1 } @KINDS;

sub parse_manifest {
    my ($raw) = @_;
    praxo_error('PLUGIN_INVALID', 'plugin: manifest is empty')
        unless defined($raw) && $raw =~ /\S/;
    my $value = eval { Praxo::Json::parse($raw) };
    praxo_error('PLUGIN_INVALID', "plugin: manifest: $@") if $@;
    praxo_error('PLUGIN_INVALID', 'plugin: manifest must be an object')
        unless ref($value) eq 'HASH';
    _check_keys($value, \%TOP_KEYS, 'manifest');

    my $schema_version = _as_int($value->{schemaVersion}, 'schemaVersion');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: schemaVersion = $schema_version, want 1")
        unless $schema_version == 1;
    my $id = _as_string($value->{id}, 'id');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: id $id is not reverse-DNS")
        unless $id =~ /^(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/;
    my $version = _as_string($value->{version}, 'version');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: version $version is not semver")
        unless $version =~ /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
    my $kind = _as_string($value->{kind}, 'kind');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: kind $kind is not a known contract")
        unless $KIND_LOOKUP{$kind};
    my $protocol = _as_string($value->{protocol}, 'protocol');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: protocol = $protocol, want jsonrpc-2")
        unless $protocol eq 'jsonrpc-2';

    my $entrypoint = _as_object($value->{entrypoint}, 'entrypoint');
    _check_keys($entrypoint, \%ENTRYPOINT_KEYS, 'entrypoint');
    my $entry_type = _as_string($entrypoint->{type}, 'entrypoint.type');
    my $required = $entry_type eq 'process' ? 'command'
        : $entry_type eq 'wasm' ? 'module'
        : $entry_type eq 'container' ? 'image'
        : undef;
    praxo_error('PLUGIN_INVALID', "plugin: manifest: unknown entrypoint type $entry_type")
        unless defined $required;
    praxo_error('PLUGIN_INVALID', "plugin: manifest: $entry_type entrypoint requires $required")
        unless _text_present($entrypoint->{$required});

    my $isolation = _as_string($value->{isolation}, 'isolation');
    praxo_error('PLUGIN_INVALID', "plugin: manifest: isolation $isolation does not match entrypoint $entry_type")
        unless $isolation eq $entry_type;

    my $permissions = _as_object($value->{permissions}, 'permissions');
    _check_keys($permissions, \%PERMISSION_KEYS, 'permissions');
    my $limits = _as_object($value->{limits}, 'limits');
    _check_keys($limits, \%LIMIT_KEYS, 'limits');
    for my $key (keys %$limits) {
        praxo_error('PLUGIN_INVALID', 'plugin: manifest: limits must not be negative')
            if _as_int($limits->{$key}, "limits.$key") < 0;
    }
    my $health = _as_object($value->{health}, 'health');
    _check_keys($health, \%HEALTH_KEYS, 'health');

    if (exists $value->{signature}) {
        my $signature = _as_object($value->{signature}, 'signature');
        _check_keys($signature, \%SIGNATURE_KEYS, 'signature');
        praxo_error('PLUGIN_INVALID', 'plugin: manifest: signature requires algorithm and keyId')
            unless _text_present($signature->{algorithm}) && _text_present($signature->{keyId});
    }

    my @capabilities;
    if (exists $value->{capabilities}) {
        praxo_error('PLUGIN_INVALID', 'plugin: manifest: capabilities must be an array')
            unless ref($value->{capabilities}) eq 'ARRAY';
        for my $item (@{ $value->{capabilities} }) {
            push @capabilities, _as_string($item, 'capabilities');
        }
    }
    praxo_error('PLUGIN_INVALID', 'plugin: manifest: capability must not be empty')
        if grep { $_ eq '' } @capabilities;
    my %seen;
    for my $capability (@capabilities) {
        praxo_error('PLUGIN_INVALID', 'plugin: manifest: duplicate capability')
            if $seen{$capability}++;
    }

    return {
        schemaVersion => $schema_version,
        id => $id,
        version => $version,
        kind => $kind,
        entrypoint => $entrypoint,
        protocol => $protocol,
        capabilities => \@capabilities,
        permissions => $permissions,
        limits => $limits,
        isolation => $isolation,
        health => $health,
    };
}

sub _check_keys {
    my ($value, $allowed, $where) = @_;
    for my $key (keys %$value) {
        praxo_error('PLUGIN_INVALID', "plugin: manifest: unknown field $key in $where")
            unless $allowed->{$key};
    }
}

sub _as_object {
    my ($value, $where) = @_;
    return {} unless defined $value;
    praxo_error('PLUGIN_INVALID', "plugin: manifest: $where must be an object")
        unless ref($value) eq 'HASH';
    return $value;
}

sub _as_string {
    my ($value, $where) = @_;
    praxo_error('PLUGIN_INVALID', "plugin: manifest: $where must be a string")
        unless defined($value) && !ref($value);
    return "$value";
}

sub _as_int {
    my ($value, $where) = @_;
    praxo_error('PLUGIN_INVALID', "plugin: manifest: $where must be an integer")
        unless defined($value) && !ref($value) && looks_like_number($value);
    return int($value);
}

sub _text_present {
    my ($value) = @_;
    return defined($value) && !ref($value) && length("$value");
}

1;
