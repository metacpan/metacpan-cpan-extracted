package Module::cpmfile::Prereqs;
use strict;
use warnings;

use CPAN::Meta::Prereqs;

my @PHASE = qw(runtime configure build test develop);
my @TYPE = qw(requires recommends suggests);

sub new {
    my $class = shift;
    my $hash = shift || +{};
    my $self = +{};
    for my $phase (@PHASE) {
        for my $type (@TYPE) {
            next if !$hash->{$phase} || !$hash->{$phase}{$type};
            for my $package (sort keys %{$hash->{$phase}{$type}}) {
                $self->{$phase}{$type}{$package}
                    = $hash->{$phase}{$type}{$package} || +{};
            }
        }
    }
    bless $self, $class;
}

sub from_cpanmeta {
    my ($class, $cpanmeta) = @_;
    my $hash = $cpanmeta->as_string_hash;
    my $out = {};
    for my $phase (sort keys %$hash) {
        for my $type (sort keys %{ $hash->{$phase} }) {
            for my $package (sort keys %{ $hash->{$phase}{$type} }) {
                my $version = $hash->{$phase}{$type}{$package};
                my $options = +{ $version ? (version => $version) : () };
                $out->{$phase}{$type}{$package} = $options;
            }
        }
    }
    $class->new($out);
}

sub cpanmeta {
    my $self = shift;
    my $hash = +{};
    for my $phase (sort keys %$self) {
        for my $type (sort keys %{$self->{$phase}}) {
            for my $package (sort keys %{$self->{$phase}{$type}}) {
                my $options = $self->{$phase}{$type}{$package};
                $hash->{$phase}{$type}{$package} = $options->{version} || 0;
            }
        }
    }
    CPAN::Meta::Prereqs->new($hash);
}

sub walk {
    my ($self, $phases, $types, $cb) = @_;
    $phases ||= \@PHASE;
    $types ||= \@TYPE;
    for my $phase (@$phases) {
        for my $type (@$types) {
            next if !$self->{$phase} || !$self->{$phase}{$type};
            for my $package (sort keys %{$self->{$phase}{$type}}) {
                my $options = $self->{$phase}{$type}{$package};
                my $ret = $cb->($phase, $type, $package, $options);
                return if ref($ret) eq 'SCALAR' && !$$ret;
            }
        }
    }
}

1;
