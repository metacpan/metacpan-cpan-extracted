package PAX::NativeRunner;

our $VERSION = '0.031';

use strict;
use warnings;
use IPC::Open3;
use Symbol qw(gensym);

sub new {
    my ($class, %args) = @_;
    return bless {}, $class;
}

sub run_i64_binary {
    my ($self, %args) = @_;
    my $path = $args{path};
    my $left = defined $args{left} ? $args{left} : 0;
    my $right = defined $args{right} ? $args{right} : 0;

    if (!defined $path || !-x $path) {
        return {
            status => 'error',
            reason => 'native executable missing or not executable',
        };
    }

    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, $path, $left, $right);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0);
    chomp $stdout;

    return {
        status => ($? >> 8) == 0 ? 'ok' : 'error',
        exit => $? >> 8,
        stdout => $stdout,
        stderr => $stderr,
        value => $stdout =~ /^-?\d+$/ ? 0 + $stdout : undef,
    };
}

1;

=pod

=head1 NAME

PAX::NativeRunner - native artifact launcher and fallback bridge

=head1 SYNOPSIS

  use PAX::NativeRunner;

  my $obj = PAX::NativeRunner->new(...);
  my $result = $obj->run_i64_binary(...);

=head1 DESCRIPTION

Selects an available native artifact for a region and falls back to the non-native runtime path when the native path is missing or invalidated.

=head1 METHODS

=head2 new, run_i64_binary

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the native artifact launcher and fallback bridge logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs native artifact launcher and fallback bridge. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects native artifact launcher and fallback bridge, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover native artifact launcher and fallback bridge.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::NativeRunner -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
