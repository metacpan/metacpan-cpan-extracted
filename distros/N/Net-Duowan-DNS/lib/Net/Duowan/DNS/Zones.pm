package Net::Duowan::DNS::Zones;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use JSON;
use base 'Net::Duowan::DNS::Common';

use vars qw/$VERSION/;
$VERSION = '1.2.0';

sub new {
    my $class = shift;
    my $psp = shift;
    my $token = shift;
    bless { psp => $psp, token => $token },$class;
}

sub fetch {
    my $self = shift;

    my $psp = $self->{psp};
    my $token = $self->{token};

    my %args = @_;
    my $offset = $args{offset} || 0;
    my $number = $args{number} || -1;

    my $act = 'zone_load_multi';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

sub check {
    my $self = shift;

    my @zones = @_;
    unless (@zones) {
        croak "no zones list provided";
    }

    my $zones = join ',',@zones;
    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'zone_check';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, zones=>$zones);

    return $self->reqTemplate(%reqs);
}

sub create {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'zone_new';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, z=>$zone);

    return $self->reqTemplate(%reqs);
}

sub remove {
    my $self = shift;
    my $zone = shift || croak "no zone provided";

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'zone_delete';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, z=>$zone);

    return $self->reqTemplate(%reqs);
}

1;
