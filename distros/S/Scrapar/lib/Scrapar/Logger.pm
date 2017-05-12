package Scrapar::Logger;

use strict;
#use warnings;

use base qw(Log::Handler);

sub backend {
    my $self = shift;
    $self->{_backend} = shift;
}

sub debug {
    my $self = shift;
    $self->SUPER::debug("[$self->{_backend}] " . shift);
}

sub info {
    my $self = shift;
    $self->SUPER::info("[$self->{_backend}] " . shift);
}

sub notice {
    my $self = shift;
    $self->SUPER::notice("[$self->{_backend}] " . shift);
}

sub warning {
    my $self = shift;
    $self->SUPER::warning("[$self->{_backend}] " . shift);
}

sub warn {
    my $self = shift;
    $self->SUPER::warn("[$self->{_backend}] " . shift);
}

sub error {
    my $self = shift;
    $self->SUPER::error("[$self->{_backend}] " . shift);
}

sub err {
    my $self = shift;
    $self->SUPER::err("[$self->{_backend}] " . shift);
}

sub critical {
    my $self = shift;
    $self->SUPER::critical("[$self->{_backend}] " . shift);
}

sub crit {
    my $self = shift;
    $self->SUPER::crit("[$self->{_backend}] " . shift);
}

sub alert {
    my $self = shift;
    $self->SUPER::alert("[$self->{_backend}] " . shift);
}

sub emergency {
    my $self = shift;
    $self->SUPER::emergency("[$self->{_backend}] " . shift);
}

sub emerg {
    my $self = shift;
    $self->SUPER::emerg("[$self->{_backend}] " . shift);
}

$ENV{SCRAPER_LOGGER} = __PACKAGE__->new() if !$ENV{SCRAPER_LOGGER};

1;
