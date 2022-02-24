package Module::cpmfile;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.006';

use Module::cpmfile::Prereqs;
use Module::cpmfile::Util qw(merge_version _yaml_hash);
use YAML::PP ();

sub load {
    my ($class, $file) = @_;
    my ($hash) = YAML::PP->new->load_file($file);
    $class->new($hash);
}

sub new {
    my ($class, $hash) = @_;
    my $prereqs = Module::cpmfile::Prereqs->new($hash->{prereqs});
    my %feature;
    for my $id (sort keys %{ $hash->{features} || +{} }) {
        my $description = $hash->{features}{$id}{description};
        my $prereqs = Module::cpmfile::Prereqs->new($hash->{features}{$id}{prereqs});
        $feature{$id} = { description => $description, prereqs => $prereqs };
    }
    bless { prereqs => $prereqs, features => \%feature, _mirrors => [] }, $class;
}

sub from_cpanfile {
    my ($class, $cpanfile) = @_;
    my %feature;
    for my $feature ($cpanfile->features) {
        my $id = $feature->{identifier};
        my $description = $feature->{description};
        my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($feature->{prereqs});
        $feature{$id} = { description => $description, prereqs => $prereqs };
    }
    my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($cpanfile->prereqs);
    for my $p ($prereqs, map { $_->{prereqs} } values %feature) {
        $p->walk(undef, undef, sub {
            my (undef, undef, $package, $original_options) = @_;
            my $additional_options = $cpanfile->options_for_module($package) || +{};
            if (%$additional_options) {
                %$original_options = (%$original_options, %$additional_options);
            }
        });
    }
    my $mirrors = $cpanfile->mirrors;
    bless { prereqs => $prereqs, features => \%feature, _mirrors => $mirrors }, $class;
}

sub from_cpanmeta {
    my ($class, $cpanmeta) = @_;
    my %feature;
    for my $id (keys %{$cpanmeta->optional_features}) {
        my $f = $cpanmeta->optional_features->{$id};
        my $description = $f->{description};
        my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($f->{prereqs});
        $feature{$id} = { description => $description, prereqs => $prereqs };
    }
    my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($cpanmeta->prereqs);
    bless { prereqs => $prereqs, features => \%feature, _mirrors => [] }, $class;
}

sub prereqs {
    my $self = shift;
    $self->{prereqs};
}

sub features {
    my $self = shift;
    if (%{$self->{features}}) {
        return $self->{features};
    }
    return;
}

sub _feature_prereqs {
    my ($self, $ids) = @_;
    my @prereqs;
    for my $id (@{ $ids || [] }) {
        my $feature = $self->{features}{$id};
        next if !$feature || !$feature->{prereqs};
        push @prereqs, $feature->{prereqs}
    }
    @prereqs;
}

sub effective_requirements {
    my ($self, $feature_ids, $phases, $types) = @_;
    my %req;
    for my $prereqs ($self->{prereqs}, $self->_feature_prereqs($feature_ids)) {
        $prereqs->walk($phases, $types, sub {
            my (undef, undef, $package, $options) = @_;
            if (exists $req{$package}) {
                my $v1 = $req{$package}{version} || 0;
                my $v2 = $options->{version} || 0;
                my $version  = merge_version $v1, $v2;
                $req{$package} = +{
                    %{$req{$package}},
                    %$options,
                    $version ? (version => $version) : (),
                };
            } else {
                $req{$package} = $options;
            }
        });
    }
    \%req;
}

sub to_string {
    my $self = shift;
    my @out;
    push @out, $self->prereqs->to_string;
    if (my $features = $self->features) {
        push @out, "features:";
        for my $id (sort keys %$features) {
            my $feature = $features->{$id};
            push @out, "  $id:";
            if (my $desc = $feature->{description}) {
                push @out, _yaml_hash({ description => $desc }, "    ");
            }
            if (my $prereqs = $feature->{prereqs}) {
                push @out, $prereqs->to_string("    ");
            }
        }
    }
    ( join "\n", @out ) . "\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

Module::cpmfile - Parse cpmfile

=head1 SYNOPSIS

  use Module::cpmfile;

  my $cpmfile = Module::cpmfile->load("cpm.yml");
  my $reqs = $cpmfile->effective_requirements(undef, ["runtime"], ["requires"]);

=head1 DESCRIPTION

THIS IS EXPERIMENTAL.

cpmfile (usually saved as C<cpm.yml>) is yet another file format for describing module dependencies,
and Module::cpmfile helps you parse it.

The JSON Schema for cpmfile is available at L<jsonschema.json|https://github.com/skaji/cpmfile/blob/main/jsonschema.json>.

cpmfile will be used mainly by L<App::cpm>.

=head1 SEE ALSO

L<cpanfile>

L<Module::CPANfile>

L<App::cpm>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
