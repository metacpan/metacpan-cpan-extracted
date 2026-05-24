package Module::cpmfile::Prereqs;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use CPAN::Meta::Prereqs;
use Module::cpmfile::Util '_yaml_hash';
use Scalar::Util 'blessed';

my @PHASE = qw(runtime configure build test develop);
my @TYPE = qw(requires recommends suggests);

sub new ($class, $hash = +{}) {
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

sub from_cpanmeta ($class, $cpanmeta) {
    my $hash = $cpanmeta;
    if (blessed $cpanmeta and $cpanmeta->isa('CPAN::Meta::Prereqs')) {
        $hash = $cpanmeta->as_string_hash;
    }
    my $out = {};
    for my $phase (sort keys $hash->%*) {
        for my $type (sort keys $hash->{$phase}->%*) {
            for my $package (sort keys %{ $hash->{$phase}{$type} }) {
                my $version = $hash->{$phase}{$type}{$package};
                my $options = +{ $version ? (version => $version) : () };
                $out->{$phase}{$type}{$package} = $options;
            }
        }
    }
    $class->new($out);
}

sub cpanmeta ($self) {
    my $hash = +{};
    for my $phase (sort keys $self->%*) {
        for my $type (sort keys $self->{$phase}->%*) {
            for my $package (sort keys %{$self->{$phase}{$type}}) {
                my $options = $self->{$phase}{$type}{$package};
                $hash->{$phase}{$type}{$package} = $options->{version} || 0;
            }
        }
    }
    CPAN::Meta::Prereqs->new($hash);
}

sub walk ($self, $phases, $types, $cb) {
    $phases ||= \@PHASE;
    $types ||= \@TYPE;
    for my $phase ($phases->@*) {
        for my $type ($types->@*) {
            next if !$self->{$phase} || !$self->{$phase}{$type};
            for my $package (sort keys %{$self->{$phase}{$type}}) {
                my $options = $self->{$phase}{$type}{$package};
                my $ret = $cb->($phase, $type, $package, $options);
                return if ref($ret) eq 'SCALAR' && !$$ret;
            }
        }
    }
}

sub to_string ($self, $indent = "") {
    my @out;
    push @out, "prereqs:";
    for my $phase (@PHASE) {
        my $spec1 = $self->{$phase} or next;
        push @out, "  $phase:";
        for my $type (@TYPE) {
            my $spec2 = $spec1->{$type} or next;
            push @out, "    $type:";
            for my $package (sort keys $spec2->%*) {
                if (my %option = %{ $spec2->{$package} || +{} }) {
                    my @key = keys %option;
                    if (@key == 1 && $key[0] eq "version") {
                        push @out, "      $package: { version: '$option{version}' }";
                    } else {
                        push @out, "      $package:";
                        push @out, _yaml_hash(\%option, "        ");
                    }
                } else {
                    push @out, "      $package:";
                }
            }
        }
    }
    join "\n", map { "$indent$_" } @out;
}

1;
