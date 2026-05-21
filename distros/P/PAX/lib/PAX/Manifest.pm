package PAX::Manifest;

our $VERSION = '0.031';

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use PAX::Compatibility;

use constant TARGET_PERL_FAMILY => '5.42.x';

sub new {
    my ($class, %args) = @_;
    return bless {
        capture => $args{capture},
    }, $class;
}

sub to_hash {
    my ($self) = @_;
    my $capture = $self->{capture} // {};
    my $runtime = $capture->{runtime} // {};
    my $config = $runtime->{config} // {};
    my $version = $runtime->{config_version} // '';
    my $baseline_match = $version =~ /^5\.42\./ ? 1 : 0;
    my $abi_stamp = _abi_stamp($runtime);
    my $compatibility = PAX::Compatibility->new(
        capture => $capture,
        baseline_match => $baseline_match,
    )->report;

    return {
        schema_version => 1,
        pax_version => '0.0.1',
        source_entrypoint => $capture->{source_entrypoint},
        runtime => {
            perl_version => $runtime->{perl_version},
            perl_config_version => $version,
            perl_family_target => TARGET_PERL_FAMILY,
            baseline_match => $baseline_match ? JSON::PP::true() : JSON::PP::false(),
            archname => $runtime->{archname},
            executable => $runtime->{executable},
            config => $config,
            pax_abi_stamp => $abi_stamp,
        },
        capture => {
            status => $capture->{status},
            mode => $capture->{mode},
        },
        module_graph => {
            modules => $capture->{capture}{loaded_files} // [],
        },
        package_state => {
            packages => $capture->{capture}{package_shapes} // {},
        },
        optree_units => {
            subs => $capture->{capture}{sub_optrees} // [],
        },
        lexical_pads => {
            subs => _sub_field_map($capture, 'pad_layout'),
        },
        closure_descriptors => {
            subs => _sub_field_map($capture, 'closure_descriptor'),
        },
        method_resolution => $capture->{capture}{method_resolution} // {},
        regex_metadata => $capture->{capture}{regex_metadata} // [],
        compile_phase_events => $capture->{capture}{compile_phase_events} // [],
        runtime_epochs => _initial_epochs($capture),
        source_features => $capture->{source_features} // {},
        compatibility => $compatibility,
        diagnostics => $capture->{diagnostics} // [],
    };
}

sub _sub_field_map {
    my ($capture, $field) = @_;
    my %map;
    for my $sub (@{ $capture->{capture}{sub_optrees} // [] }) {
        next if !defined $sub->{name};
        $map{ $sub->{name} } = $sub->{$field};
    }
    return \%map;
}

sub _abi_stamp {
    my ($runtime) = @_;
    my $config = $runtime->{config} // {};
    my $input = join "\n",
        map { $_ . '=' . (defined $config->{$_} ? $config->{$_} : '') }
        sort keys %$config;
    $input .= "\nversion=" . ($runtime->{config_version} // '');
    $input .= "\narchname=" . ($runtime->{archname} // '');
    return sha256_hex($input);
}

sub _initial_epochs {
    my ($capture) = @_;
    return {
        package_symbols => 0,
        method_resolution => 0,
        loaded_modules => scalar @{ $capture->{capture}{loaded_files} // [] },
        locale_mode => 0,
        unicode_mode => 0,
        regex_assumptions => 0,
        overload_tables => 0,
        eval_created_code => 0,
        interpreter_hooks => 0,
    };
}

1;

=pod

=head1 NAME

PAX::Manifest - capture manifest serializer

=head1 SYNOPSIS

  use PAX::Manifest;

  my $obj = PAX::Manifest->new(...);
  my $result = $obj->to_hash(...);

=head1 DESCRIPTION

Reads and writes the canonical manifest shape that PAX uses to move captured program structure between stages.

=head1 METHODS

=head2 new, to_hash

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the capture manifest serializer logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs capture manifest serializer. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects capture manifest serializer, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover capture manifest serializer.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Manifest -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
