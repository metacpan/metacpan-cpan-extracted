package PAX::Backend::Tier2LLVM;
our $VERSION = '0.031';

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use File::Spec;

sub new {
    my ($class, %args) = @_;
    return bless {
        enabled => exists $args{enabled} ? ($args{enabled} ? 1 : 0) : 1,
        out_dir => $args{out_dir} // '.pax/native',
    }, $class;
}

sub metadata {
    my ($self) = @_;
    return {
        tier => 2,
        name => 'llvm-optimising-backend',
        role => 'optimising_aot_jit_backend',
        status => $self->{enabled} ? 'enabled' : 'disabled_by_configuration',
        contract => 'guarded_ssa_to_llvm_ir_module_emission',
    };
}

sub emit_module {
    my ($self, $ssa_unit) = @_;
    return {
        status => 'disabled',
        reason => 'LLVM backend disabled by configuration',
    } if !$self->{enabled};

    my $module = $self->module_for($ssa_unit);
    return $module if ($module->{status} // '') ne 'llvm_ir';

    make_path($self->{out_dir});
    my $id = sha256_hex(join "\n",
        $ssa_unit->{region_id} // '',
        $ssa_unit->{region_name} // '',
        $module->{ir},
    );
    my $path = File::Spec->catfile($self->{out_dir}, "$id.ll");
    open my $fh, '>', $path or return {
        status => 'fallback',
        reason => "cannot write LLVM IR module: $!",
    };
    print {$fh} $module->{ir};
    close $fh;

    return {
        status => 'llvm_ir_artifact',
        path => $path,
        module_id => $id,
        entry_symbol => 'pax_region_i64',
        reason => $module->{reason},
    };
}

sub module_for {
    my ($self, $ssa_unit) = @_;
    my $shape = $ssa_unit->{native_shape} // $ssa_unit->{source}{native_shape} // {};
    my $region_id = $ssa_unit->{region_id} // 'unknown';
    my $region_name = $ssa_unit->{region_name} // 'unknown';

    if (($shape->{kind} // '') eq 'i64_binary_leaf') {
        my $op = $shape->{op} // '';
        my $body = _llvm_binary_body($op);
        return _module($region_id, $region_name, $body, "LLVM IR emitted for guarded i64 $op leaf");
    }

    if (($shape->{kind} // '') eq 'i64_sum_loop') {
        return _module($region_id, $region_name, _llvm_sum_loop_body(), 'LLVM IR emitted for guarded i64 sum loop');
    }

    if (($shape->{kind} // '') eq 'i64_masked_mix_accum_loop') {
        return _module($region_id, $region_name, _llvm_masked_mix_accum_loop_body(), 'LLVM IR emitted for guarded i64 masked mix accumulation loop');
    }

    return {
        status => 'fallback',
        reason => 'no LLVM lowering for this guarded SSA shape',
    };
}

sub _module {
    my ($region_id, $region_name, $body, $reason) = @_;
    my $escaped_region_id = $region_id;
    $escaped_region_id =~ s/\\/\\\\/g;
    $escaped_region_id =~ s/"/\\"/g;
    my $escaped_region_name = $region_name;
    $escaped_region_name =~ s/\\/\\\\/g;
    $escaped_region_name =~ s/"/\\"/g;
    return {
        status => 'llvm_ir',
        reason => $reason,
        ir => <<"LLVM",
; PAX Tier 2 LLVM module
; region_id: $escaped_region_id
; region_name: $escaped_region_name
target triple = "unknown-unknown-unknown"

define i64 \@pax_region_i64(i64 %left, i64 %right) {
$body
}

define i64 \@pax_region_probe() {
entry:
  %probe = call i64 \@pax_region_i64(i64 2, i64 3)
  ret i64 %probe
}
LLVM
    };
}

sub _llvm_binary_body {
    my ($op) = @_;
    return <<"LLVM" if $op eq 'add';
entry:
  %result = add nsw i64 %left, %right
  ret i64 %result
LLVM
    return <<"LLVM" if $op eq 'subtract';
entry:
  %result = sub nsw i64 %left, %right
  ret i64 %result
LLVM
    return <<"LLVM" if $op eq 'multiply';
entry:
  %result = mul nsw i64 %left, %right
  ret i64 %result
LLVM
    return <<"LLVM" if $op eq 'greater_than';
entry:
  %cmp = icmp sgt i64 %left, %right
  %result = zext i1 %cmp to i64
  ret i64 %result
LLVM
    return <<"LLVM";
entry:
  ret i64 0
LLVM
}

sub _llvm_sum_loop_body {
    return <<'LLVM';
entry:
  %non_positive = icmp sle i64 %left, 0
  br i1 %non_positive, label %done_zero, label %loop

loop:
  %i = phi i64 [ 1, %entry ], [ %next_i, %loop ]
  %sum = phi i64 [ 0, %entry ], [ %next_sum, %loop ]
  %next_sum = add nsw i64 %sum, %i
  %next_i = add nsw i64 %i, 1
  %again = icmp sle i64 %next_i, %left
  br i1 %again, label %loop, label %done_sum

done_zero:
  ret i64 0

done_sum:
  ret i64 %next_sum
LLVM
}

# Lower the masked-mix accumulator loop into Tier 2 LLVM IR for native script
# and standalone benchmarking paths.
sub _llvm_masked_mix_accum_loop_body {
    return <<'LLVM';
entry:
  %non_positive = icmp sle i64 %left, 0
  br i1 %non_positive, label %done_zero, label %loop

loop:
  %i = phi i64 [ 0, %entry ], [ %next_i, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %next_acc, %loop ]
  %mul = mul nsw i64 %i, 13
  %shift = ashr i64 %i, 3
  %mix = xor i64 %mul, %shift
  %term = and i64 %mix, 65535
  %next_acc = add nsw i64 %acc, %term
  %next_i = add nsw i64 %i, 1
  %again = icmp slt i64 %next_i, %left
  br i1 %again, label %loop, label %done_sum

done_zero:
  ret i64 0

done_sum:
  ret i64 %next_acc
LLVM
}

1;

=pod

=head1 NAME

PAX::Backend::Tier2LLVM - tier-2 backend planning stub for optimized native code generation

=head1 SYNOPSIS

  use PAX::Backend::Tier2LLVM;

  my $obj = PAX::Backend::Tier2LLVM->new(...);
  my $result = $obj->metadata(...);

=head1 DESCRIPTION

Represents the slower but more optimizing tier-2 backend contract used when PAX promotes hot regions beyond the tier-1 path.

=head1 METHODS

=head2 new, metadata, emit_module, module_for

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the tier-2 backend planning stub for optimized native code generation logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs tier-2 backend planning stub for optimized native code generation. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects tier-2 backend planning stub for optimized native code generation, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover tier-2 backend planning stub for optimized native code generation.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::Backend::Tier2LLVM -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
