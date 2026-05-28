package SignalWire::SWML::Document;
use strict;
use warnings;
use Moo;
use JSON ();

has 'version' => (
    is      => 'ro',
    default => sub { '1.0.0' },
);

has 'sections' => (
    is      => 'rw',
    default => sub { {} },
);

sub add_section {
    my ($self, $name) = @_;
    $self->sections->{$name} //= [];
    return $self;
}

sub add_verb {
    my ($self, $section_name, $verb_name, $verb_data) = @_;
    $self->sections->{$section_name} //= [];
    push @{ $self->sections->{$section_name} }, { $verb_name => $verb_data };
    return $self;
}

sub add_raw_verb {
    my ($self, $section_name, $verb_hash) = @_;
    $self->sections->{$section_name} //= [];
    push @{ $self->sections->{$section_name} }, $verb_hash;
    return $self;
}

sub get_section {
    my ($self, $name) = @_;
    return $self->sections->{$name};
}

sub has_section {
    my ($self, $name) = @_;
    return exists $self->sections->{$name};
}

sub clear_section {
    my ($self, $name) = @_;
    $self->sections->{$name} = [];
    return $self;
}

sub to_hash {
    my ($self) = @_;
    return {
        version  => $self->version,
        sections => $self->sections,
    };
}

sub to_json {
    my ($self) = @_;
    return JSON::encode_json($self->to_hash);
}

sub to_pretty_json {
    my ($self) = @_;
    my $json = JSON->new->utf8->canonical->pretty;
    return $json->encode($self->to_hash);
}

1;
