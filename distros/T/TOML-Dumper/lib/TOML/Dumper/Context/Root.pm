package TOML::Dumper::Context::Root;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/tree/];

use TOML::Dumper::Context::Table;

sub new {
    my ($class, $object) = @_;
    return bless {
        tree => TOML::Dumper::Context::Table->new(name => [], tree => $object),
    } => $class;
}

sub set {
    my $self = shift;
    $self->{tree}->set(@_);
    return $self;
}

sub remove {
    my $self = shift;
    $self->{tree}->remove(@_);
    return $self;
}

sub as_string {
    my $self = shift;
    return $self->{tree}->as_string;
}

1;
__END__
