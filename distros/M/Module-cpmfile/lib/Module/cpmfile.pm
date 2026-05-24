package Module::cpmfile v1.0.0;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

our $TRIAL = 0;


use Module::cpmfile::Prereqs;
use Module::cpmfile::Util qw(merge_version _yaml_hash);
use YAML::PP ();

sub load ($class, $file) {
    my ($hash) = YAML::PP->new->load_file($file);
    $class->new($hash);
}

sub new ($class, $hash) {
    my $prereqs = Module::cpmfile::Prereqs->new($hash->{prereqs});
    my %feature;
    for my $id (sort keys %{ $hash->{features} || +{} }) {
        my $description = $hash->{features}{$id}{description};
        my $prereqs = Module::cpmfile::Prereqs->new($hash->{features}{$id}{prereqs});
        $feature{$id} = { description => $description, prereqs => $prereqs };
    }
    bless { prereqs => $prereqs, features => \%feature, _mirrors => [] }, $class;
}

sub from_cpanfile ($class, $cpanfile) {
    my %feature;
    for my $feature ($cpanfile->features) {
        my $id = $feature->{identifier};
        my $description = $feature->{description};
        my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($feature->{prereqs});
        $feature{$id} = { description => $description, prereqs => $prereqs };
    }
    my $prereqs = Module::cpmfile::Prereqs->from_cpanmeta($cpanfile->prereqs);
    for my $p ($prereqs, map { $_->{prereqs} } values %feature) {
        $p->walk(undef, undef, sub ($phase, $type, $package, $original_options) {
            my $additional_options = $cpanfile->options_for_module($package) || +{};
            if ($additional_options->%*) {
                $original_options->%* = ($original_options->%*, $additional_options->%*);
            }
        });
    }
    my $mirrors = $cpanfile->mirrors;
    bless { prereqs => $prereqs, features => \%feature, _mirrors => $mirrors }, $class;
}

sub from_cpanmeta ($class, $cpanmeta) {
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

sub prereqs ($self) {
    $self->{prereqs};
}

sub features ($self) {
    if ($self->{features}->%*) {
        return $self->{features};
    }
    return;
}

sub _feature_prereqs ($self, $ids = undef) {
    my @prereqs;
    for my $id (@{ $ids || [] }) {
        my $feature = $self->{features}{$id};
        next if !$feature || !$feature->{prereqs};
        push @prereqs, $feature->{prereqs}
    }
    @prereqs;
}

sub effective_requirements ($self, $feature_ids = undef, $phases = undef, $types = undef) {
    my %req;
    for my $prereqs ($self->{prereqs}, $self->_feature_prereqs($feature_ids)) {
        $prereqs->walk($phases, $types, sub ($phase, $type, $package, $options) {
            if (exists $req{$package}) {
                my $v1 = $req{$package}{version} || 0;
                my $v2 = $options->{version} || 0;
                my $version  = merge_version $v1, $v2;
                $req{$package} = +{
                    %{$req{$package}},
                    $options->%*,
                    $version ? (version => $version) : (),
                };
            } else {
                $req{$package} = $options;
            }
        });
    }
    \%req;
}

sub to_string ($self) {
    my @out;
    push @out, $self->prereqs->to_string;
    if (my $features = $self->features) {
        push @out, "features:";
        for my $id (sort keys $features->%*) {
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


=head1 ARTIFACT ATTESTATIONS

GitHub Artifact Attestations are generated for release tarballs uploaded to
CPAN. If you care about provenance for the uploaded tarballs, see:

L<https://github.com/skaji/cpmfile/attestations>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
