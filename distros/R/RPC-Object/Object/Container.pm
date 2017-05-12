package RPC::Object::Container;
use strict;
use threads;
use threads::shared;
use warnings;
use Scalar::Util qw(blessed refaddr weaken);

sub new : locked {
    my ($class) = @_;
    my $self = &share({});
    bless $self, $class;
    return $self;
}

sub insert : locked method {
    my ($self, $obj) = @_;
    my $ref = _encode_ref($obj);
    $self->{$ref} = $obj;
    weaken $self->{$ref};
    return $ref;
}

sub get : locked method {
    my ($self, $ref) = @_;
    my $obj = $self->{$ref};
    return $obj;
}

sub find : locked method {
    my ($self, $class) = @_;
    my $ref;
    for (keys %$self) {
        $ref = $_;
        last if $class eq blessed $self->{$ref};
    }
    return $ref;
}

sub _encode_ref {
    my ($obj) = @_;
    return refaddr $obj;
}

1;

