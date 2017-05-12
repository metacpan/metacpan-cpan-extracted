package TOML::Dumper::Context::Table;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/name tree inline/];

use TOML::Dumper::Name;
use TOML::Dumper::Context::Array;
use TOML::Dumper::Context::Value;

sub new {
    my ($class, %args) = @_;
    my ($name, $tree) = @args{qw/name tree/};
    my $self = bless {
        name => $name,
        tree => {},
    } => $class;
    for my $name (keys %$tree) {
        $self->set($name => $tree->{$name});
    }
    return $self;
}

sub depth { scalar @{ shift->{name} } }
sub priority { 0 }

sub set {
    my ($self, $name, $object) = @_;
    my @name = defined $self->{name} ? (@{ $self->{name} }, $name) : ($name);
    if (ref $object eq 'HASH') {
        $self->{tree}->{$name} = TOML::Dumper::Context::Table->new(name => \@name, tree => $object);
    }
    elsif (ref $object eq 'ARRAY') {
        $self->{tree}->{$name} = TOML::Dumper::Context::Array->new(name => \@name, objects => $object);
    }
    else {
        $self->{tree}->{$name} = TOML::Dumper::Context::Value->new(name => \@name, atom => $object);
    }
    return $self;
}

sub remove {
    my ($self, $name) = @_;
    delete $self->{tree}->{$name};
    return $self;
}

sub objects {
    my $self = shift;
    return sort { $a->depth <=> $b->depth || $b->priority <=> $a->priority || $a->name->[-1] cmp $b->name->[-1] } values %{ $self->{tree} };
}

sub as_string {
    my $self = shift;
    my $name = $self->{name};
    my $body = @$name ? "\n".'['.TOML::Dumper::Name::join(@$name).']'."\n" : '';
    $body .= join "\n", map { $_->as_string() } $self->objects;
    return $body;
}

1;
