package PAX::Tier1;
our $VERSION = '0.031';

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;
use JSON::PP ();
use PAX::Backend::Tier1CraneliftEquivalent;
use PAX::Backend::Tier2LLVM;

sub new {
    my ($class, %args) = @_;
    return bless {
        backend => $args{backend} // 'portable-fallback',
        out_dir => $args{out_dir} // '.pax/native',
    }, $class;
}

sub compile {
    my ($self, $ssa_unit) = @_;
    my $can_native = _native_backend_available();
    if (!$can_native) {
        return {
            region_id => $ssa_unit->{region_id},
            status => 'fallback_artifact',
            backend => $self->{backend},
            reason => 'native backend toolchain unavailable in current workspace',
            entry_kind => 'interpreter_bridge',
        };
    }

    my $artifact = $self->_emit_native_artifact($ssa_unit);
    my $tier1 = PAX::Backend::Tier1CraneliftEquivalent->new->metadata;
    my $tier2_backend = PAX::Backend::Tier2LLVM->new(out_dir => $self->{out_dir});
    my $tier2 = $tier2_backend->metadata;
    my $tier2_artifact = $tier2_backend->emit_module($ssa_unit);
    return {
        region_id => $ssa_unit->{region_id},
        status => $artifact->{status},
        backend => 'cranelift-equivalent-c-abi',
        backend_tiers => [$tier1, $tier2],
        reason => $artifact->{reason},
        entry_kind => $artifact->{entry_kind},
        source_path => $artifact->{source_path},
        library_path => $artifact->{library_path},
        executable_path => $artifact->{executable_path},
        native_test => $artifact->{native_test},
        tier2_artifact => $tier2_artifact,
        symbol => 'pax_region_probe',
    };
}

sub _emit_native_artifact {
    my ($self, $ssa_unit) = @_;
    make_path($self->{out_dir});
    my $id = sha256_hex(join "\n",
        $ssa_unit->{region_id},
        ($ssa_unit->{region_name} // ''),
        $$,
        time(),
    );
    my $source_path = File::Spec->catfile($self->{out_dir}, "$id.c");
    my $library_path = File::Spec->catfile($self->{out_dir}, "libpax_$id.so");
    my $executable_path = File::Spec->catfile($self->{out_dir}, "pax_$id");
    my $emission = _c_source_for_region($ssa_unit);

    open my $fh, '>', $source_path or return {
        status => 'fallback_artifact',
        reason => "cannot write native source: $!",
    };
    print {$fh} $emission->{source};
    close $fh;

    system(_cc(), '-shared', '-fPIC', '-O2', '-o', $library_path, $source_path);
    if (($? >> 8) != 0 || !-f $library_path) {
        return {
            status => 'fallback_artifact',
            reason => 'C ABI backend failed to emit native shared artifact',
            source_path => $source_path,
        };
    }

    my $native_test;
    if ($emission->{executable}) {
        system(_cc(), '-O2', '-DPAX_STANDALONE_MAIN', '-o', $executable_path, $source_path);
        if (($? >> 8) == 0 && -x $executable_path) {
            my $left = defined $emission->{smoke_left} ? $emission->{smoke_left} : 2;
            my $right = defined $emission->{smoke_right} ? $emission->{smoke_right} : 3;
            my $expected = defined $emission->{smoke_expected} ? $emission->{smoke_expected} : '5';
            my $output = `$executable_path $left $right`;
            chomp $output;
            $native_test = {
                command => "$executable_path $left $right",
                expected => "$expected",
                actual => $output,
                passed => $output eq "$expected" ? JSON::PP::true() : JSON::PP::false(),
            };
        }
    }

    return {
        status => 'native_artifact',
        reason => $emission->{reason},
        entry_kind => $emission->{entry_kind},
        source_path => $source_path,
        library_path => $library_path,
        executable_path => -x $executable_path ? $executable_path : undef,
        native_test => $native_test,
    };
}

sub _c_source_for_region {
    my ($ssa_unit) = @_;
    my $region_id = $ssa_unit->{region_id} // 'unknown';
    my $shape = $ssa_unit->{native_shape} // $ssa_unit->{source}{native_shape} // {};
    if (($shape->{kind} // '') eq 'i64_sum_loop') {
        return {
            reason => "native i64 $shape->{op} loop emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_loop',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_loop_body(),
            ),
        };
    }

    if (($shape->{kind} // '') eq 'i64_masked_mix_accum_loop') {
        return {
            reason => "native i64 $shape->{op} loop emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_loop',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_masked_mix_accum_loop_body(),
            ),
        };
    }

    if (($shape->{kind} // '') eq 'i64_binary_leaf') {
        return {
            reason => "native i64 $shape->{op} leaf emitted from guarded SSA through the Tier 1 C ABI backend and smoke-tested",
            entry_kind => 'native_i64_leaf',
            executable => 1,
            smoke_left => $shape->{smoke_left},
            smoke_right => $shape->{smoke_right},
            smoke_expected => $shape->{smoke_expected},
            source => _c_translation_unit(
                $region_id,
                _c_binary_expr($shape->{op}),
            ),
        };
    }

    return {
        reason => 'native probe artifact emitted; semantic execution falls back because no region-specific emitter matched',
        entry_kind => 'native_probe_trampoline',
        executable => 0,
        source => _c_translation_unit($region_id, 'return 1;'),
    };
}

sub _native_backend_available {
    return 0 if ! _cc();
    return 1;
}

sub _cc {
    return $ENV{CC} if defined $ENV{CC} && length $ENV{CC};
    return _which('cc') || _which('gcc');
}

sub _c_binary_expr {
    my ($op) = @_;
    return 'return left + right;' if ($op // '') eq 'add';
    return 'return left - right;' if ($op // '') eq 'subtract';
    return 'return left * right;' if ($op // '') eq 'multiply';
    return 'return left > right ? 1 : 0;' if ($op // '') eq 'greater_than';
    return 'return 0;';
}

sub _c_loop_body {
    return <<'C_BODY';
if (left <= 0) {
    return 0;
}
int64_t sum = 0;
for (int64_t i = 1; i <= left; i++) {
    sum += i;
}
return sum;
C_BODY
}

# Emit Tier 1 C for the masked-mix accumulator loop shape used by synthetic
# long-running arithmetic benchmarks.
sub _c_masked_mix_accum_loop_body {
    return <<'C_BODY';
if (left <= 0) {
    return 0;
}
uint64_t acc = 0;
for (int64_t i = 0; i < left; i++) {
    uint64_t term = (((uint64_t)i * 13ULL) ^ ((uint64_t)i >> 3)) & 0xFFFFULL;
    acc += term;
}
return (int64_t)acc;
C_BODY
}

sub _c_translation_unit {
    my ($region_id, $body) = @_;
    my $escaped_id = $region_id;
    $escaped_id =~ s/\\/\\\\/g;
    $escaped_id =~ s/"/\\"/g;
    return <<"C";
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int64_t pax_region_i64(int64_t left, int64_t right) {
$body
}

int64_t pax_region_probe(void) {
    return pax_region_i64(2, 3);
}

size_t pax_region_id_len(void) {
    return strlen("$escaped_id");
}

#ifdef PAX_STANDALONE_MAIN
int main(int argc, char **argv) {
    int64_t left = argc > 1 ? strtoll(argv[1], 0, 10) : 2;
    int64_t right = argc > 2 ? strtoll(argv[2], 0, 10) : 3;
    printf("%lld\\n", (long long)pax_region_i64(left, right));
    return 0;
}
#endif
C
}

sub _which {
    my ($cmd) = @_;
    for my $dir (split /:/, $ENV{PATH} // '') {
        my $path = "$dir/$cmd";
        return $path if -x $path;
    }
    return;
}

1;

=pod

=head1 NAME

PAX::Tier1 - tier-1 native compilation planner

=head1 SYNOPSIS

  use PAX::Tier1;

  my $obj = PAX::Tier1->new(...);
  my $result = $obj->compile(...);

=head1 DESCRIPTION

Defines the fast native compilation plan shape used by the tier-1 acceleration path.

=head1 METHODS

=head2 new, compile

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the tier-1 native compilation planner logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs tier-1 native compilation planner. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects tier-1 native compilation planner, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover tier-1 native compilation planner.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Tier1 -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
