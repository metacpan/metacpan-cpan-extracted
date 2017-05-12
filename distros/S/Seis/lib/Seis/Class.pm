package Seis::Class;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Seis::MetaClass;

our %INSTANCES;

use overload (
    q{~~} => sub {
        my ($x, $y, $r) = @_;
        if ($r) {
            UNIVERSAL::isa($y, $x->{name});
        } else {
            ...
        }
    },
    q{""} => sub {
        $_[0]->{name} . '()'
    },
    fallback => 1,
);


# DO NOT CALL THIS METHOD DIRECTLY.
sub _new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    if ($args{name}) {
        $INSTANCES{$args{name}} //= bless { %args }, $class;
    } else {
        bless { %args }, $class;
    }
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ s/.*:://;
    shift->{name}->$AUTOLOAD(@_);
}

sub meta {
    my $self = shift;
    return Seis::MetaClass->new(name => $self->{name});
}

sub gist {
    my $self = shift;
    '(' . $self->{name} . ')';
}

sub perl {
    my $self = shift;
    '(' . ($self->{name} || '-') . ')';
}

1;

