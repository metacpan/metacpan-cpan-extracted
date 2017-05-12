package TOML::Dumper::Context::Value;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/name type atom/];

use B;
use overload ();
use Scalar::Util qw/blessed/;

use TOML::Dumper::Name;
use TOML::Dumper::String;

our @BOOLEAN_CLASSES = qw/
    JSON::PP::Boolean
    JSON::XS::Boolean
/;

sub new {
    my ($class, %args) = @_;
    my ($name, $atom) = @args{qw/name atom/};
    my $self = bless {
        name => $name,
        type => undef,
        atom => undef,
    } => $class;
    $self->set($atom);
    return $self;
}

sub depth { scalar @{ shift->{name} } }
sub priority { 3 }

sub set {
    my ($self, $atom) = @_;
    die 'Cannot set undef value' unless defined $atom;
    if (blessed $atom) {
        for my $class (@BOOLEAN_CLASSES) {
            next unless $atom->isa($class);

            $self->{type} = 'bool';
            $self->{atom} = !!$atom ? 'true' : 'false';
            return $self;
        }
        if (overload::StrVal($atom)) {
            $self->{type} = 'string';
            $self->{atom} = "$atom";
            return $self;
        }
    }
    elsif (ref $atom eq 'SCALAR' && !ref $$atom) {
        $self->{type} = 'bool';
        $self->{atom} = !!$$atom ? 'true' : 'false';
        return $self;
    }
    die 'Cannot set reference value' if ref $atom;

    my $flags = B::svref_2object(\$atom)->FLAGS;
    if ($flags & (B::SVp_IOK | B::SVp_NOK) & ~B::SVp_POK) {
        $self->{type} = 'number';
        $self->{atom} = $atom;
    }
    else {
        $self->{type} = 'string';
        $self->{atom} = $atom;
    }
    return $self;
}

sub as_string {
    my $self = shift;
    my $name = TOML::Dumper::Name::format($self->{name}->[-1]);
    my $body = $self->TOML::Dumper::Context::Value::Inline::as_string();
    return "$name = $body";
}

1;
