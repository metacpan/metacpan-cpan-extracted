package Net::PulseMeter::Sensor::Base;
use strict;
use warnings 'all';

use base qw/Exporter/;
use Data::Dumper;
use Redis;

our $redis;

sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    $self->init(@_);
    return $self;
}

sub init {
    my ($self, $name) = @_;
    $self->{name} = $name;
}

sub r { $redis }
sub redis {
    my ($self, $r) = @_;
    $redis = $r if ($r);
    return $redis;
}
sub name { shift->{name} }

1;
