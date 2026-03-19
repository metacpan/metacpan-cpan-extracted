package SignalWire::Agents::SWML::Schema;
use strict;
use warnings;
use Moo;
use JSON ();
use File::Basename ();

# Singleton instance
my $instance;

has 'verbs' => (
    is      => 'ro',
    default => sub { {} },
);

has 'schema_data' => (
    is      => 'ro',
    default => sub { {} },
);

sub BUILD {
    my ($self) = @_;
    $self->_load_schema();
}

sub _load_schema {
    my ($self) = @_;
    my $dir = File::Basename::dirname(__FILE__);
    my $schema_file = "$dir/schema.json";

    open my $fh, '<', $schema_file
        or die "Cannot open schema.json at $schema_file: $!";
    local $/;
    my $json_text = <$fh>;
    close $fh;

    my $data = JSON::decode_json($json_text);
    $self->{schema_data} = $data;

    my $defs = $data->{'$defs'} || {};
    my $swml_method = $defs->{SWMLMethod} || {};
    my $any_of = $swml_method->{anyOf} || [];

    my %verbs;
    for my $entry (@$any_of) {
        my $ref = $entry->{'$ref'} || next;
        (my $def_name) = $ref =~ m{/([^/]+)$};
        next unless $def_name;

        my $def = $defs->{$def_name} || next;
        my $props = $def->{properties} || next;

        my @keys = keys %$props;
        next unless @keys;

        my $verb_name = $keys[0];
        $verbs{$verb_name} = {
            schema_name => $def_name,
            verb_name   => $verb_name,
            properties  => $props->{$verb_name},
        };
    }

    $self->{verbs} = \%verbs;
}

sub instance {
    my ($class) = @_;
    $instance //= $class->new();
    return $instance;
}

sub get_verb_names {
    my ($self) = @_;
    return sort keys %{ $self->verbs };
}

sub has_verb {
    my ($self, $name) = @_;
    return exists $self->verbs->{$name};
}

sub get_verb {
    my ($self, $name) = @_;
    return $self->verbs->{$name};
}

sub verb_count {
    my ($self) = @_;
    return scalar keys %{ $self->verbs };
}

1;
