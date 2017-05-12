package TOML::Dumper::Context::Array;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/name objects inline/];

use TOML::Dumper::Context::Table::Inline;
use TOML::Dumper::Context::Array::Inline;
use TOML::Dumper::Context::Value::Inline;
use TOML::Dumper::Name;

sub new {
    my ($class, %args) = @_;
    my ($name, $objects) = @args{qw/name objects/};
    my $self = bless {
        name    => $name,
        objects => [],
        type    => undef,
    } => $class;
    for my $object (@$objects) {
        $self->add($object);
    }
    return $self;
}

sub depth { scalar @{ shift->{name} } }
sub priority { defined $_[0]->{type} && $_[0]->{type} eq 'table' ? 0 : 1 }

sub add {
    my ($self, $object) = @_;
    my $type = $self->{type};
    if (ref $object eq 'HASH') {
        $self->{type} = 'table';
        push @{ $self->{objects} } => TOML::Dumper::Context::Table::Inline->new(name => $self->{name}, tree => $object);
    }
    elsif (ref $object eq 'ARRAY') {
        $self->{type} = 'array';
        push @{ $self->{objects} } => TOML::Dumper::Context::Array::Inline->new(name => undef, objects => $object);
    }
    else {
        my $object = TOML::Dumper::Context::Value::Inline->new(name => undef, atom => $object);
        $self->{type} = $object->type;
        push @{ $self->{objects} } => $object;
    }

    if (defined $type && $self->{type} ne $type) {
        my $name = TOML::Dumper::Name::join(@{ $self->{name} });
        die "TOML array can contain each type of all values. ($name = $type)";
    }

    return $self;
}

sub as_string {
    my $self = shift;
    if (defined $self->{type} && $self->{type} eq 'table') {
        my $name = TOML::Dumper::Name::join(@{ $self->{name} });
        my $body = "\n";
        for my $object (@{ $self->{objects} }) {
            $body .= "\n[[$name]]\n";
            $body .= join "\n", map { $_->as_string() } $object->objects;
            $body .= "\n";
        }
        return $body;
    }
    else {
        my $name = TOML::Dumper::Name::format($self->{name}->[-1]);
        my $body = $self->TOML::Dumper::Context::Array::Inline::as_string();
        return "$name = $body\n";
    }
}

1;
