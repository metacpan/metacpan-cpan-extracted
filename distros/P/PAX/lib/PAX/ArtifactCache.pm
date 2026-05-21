package PAX::ArtifactCache;

our $VERSION = '0.031';

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP qw(decode_json);

sub new {
    my ($class, %args) = @_;
    my $root = $args{root} // '.pax/cache';
    return bless {
        root => $root,
    }, $class;
}

sub write_artifact {
    my ($self, %args) = @_;
    my $manifest = $args{manifest} // die 'manifest required';
    my $artifact = $args{artifact} // die 'artifact required';
    my $metadata = $self->metadata_for($manifest, $artifact);
    my $id = $metadata->{artifact_id};
    my $dir = File::Spec->catdir($self->{root}, substr($id, 0, 2));
    make_path($dir);
    my $path = File::Spec->catfile($dir, "$id.json");
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} JSON::PP->new->canonical(1)->pretty(1)->encode({
        metadata => $metadata,
        artifact => $artifact,
    });
    close $fh;
    return {
        id => $id,
        path => $path,
        metadata => $metadata,
    };
}

sub metadata_for {
    my ($self, $manifest, $artifact) = @_;
    my $module_graph_hash = sha256_hex(join "\n", @{ $manifest->{module_graph}{modules} // [] });
    my $capture_manifest_hash = sha256_hex(JSON::PP->new->canonical(1)->encode($manifest));
    my $cpu_target = join('-', $^O, $manifest->{runtime}{archname} // 'unknown');
    my $id_input = join "\n",
        $manifest->{runtime}{perl_config_version} // '',
        $manifest->{runtime}{pax_abi_stamp} // '',
        $module_graph_hash,
        $capture_manifest_hash,
        $artifact->{region_id} // '';

    return {
        artifact_id => sha256_hex($id_input),
        perl_version => $manifest->{runtime}{perl_config_version},
        perl_abi_stamp => $manifest->{runtime}{pax_abi_stamp},
        pax_runtime_abi_version => '0.0.1',
        module_graph_hash => $module_graph_hash,
        capture_manifest_hash => $capture_manifest_hash,
        cpu_target => $cpu_target,
        cpu_features => [],
        guard_schema_version => 1,
        snapshot_schema_version => $manifest->{schema_version},
        debug_map => {},
        source_map => {
            entrypoint => $manifest->{source_entrypoint},
        },
        profile_provenance => 'none',
        capture_mode => $manifest->{capture}{mode},
        environment_bound => ($manifest->{capture}{mode} // '') eq 'live' ? JSON::PP::true() : JSON::PP::false(),
    };
}

sub read_artifact {
    my ($self, $path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/;
    return decode_json(<$fh>);
}

sub validate_metadata {
    my ($self, %args) = @_;
    my $manifest = $args{manifest} // die 'manifest required';
    my $metadata = $args{metadata} // die 'metadata required';
    my @errors;

    push @errors, 'perl_version_mismatch'
        if ($metadata->{perl_version} // '') ne ($manifest->{runtime}{perl_config_version} // '');
    push @errors, 'abi_stamp_mismatch'
        if ($metadata->{perl_abi_stamp} // '') ne ($manifest->{runtime}{pax_abi_stamp} // '');
    push @errors, 'snapshot_schema_mismatch'
        if ($metadata->{snapshot_schema_version} // -1) != ($manifest->{schema_version} // -2);
    push @errors, 'capture_mode_mismatch'
        if ($metadata->{capture_mode} // '') ne ($manifest->{capture}{mode} // '');

    return {
        valid => @errors ? JSON::PP::false() : JSON::PP::true(),
        errors => \@errors,
    };
}

1;

=pod

=head1 NAME

PAX::ArtifactCache - artifact metadata store for compiled native outputs

=head1 SYNOPSIS

  use PAX::ArtifactCache;

  my $obj = PAX::ArtifactCache->new(...);
  my $result = $obj->write_artifact(...);

=head1 DESCRIPTION

Writes, reads, and validates cache metadata for compiled artifacts so PAX can tell whether a native output still matches the current manifest and runtime ABI.

=head1 METHODS

=head2 new, write_artifact, metadata_for, read_artifact, validate_metadata

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the artifact metadata store for compiled native outputs logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs artifact metadata store for compiled native outputs. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects artifact metadata store for compiled native outputs, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover artifact metadata store for compiled native outputs.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::ArtifactCache -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
