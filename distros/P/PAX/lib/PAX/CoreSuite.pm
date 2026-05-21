package PAX::CoreSuite;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP qw(decode_json);
use IPC::Open3;
use Symbol qw(gensym);

sub new {
    my ($class, %args) = @_;
    return bless {
        manifest_path => $args{manifest_path},
        perl => $args{perl} // $^X,
    }, $class;
}

sub run {
    my ($self) = @_;
    my $manifest = $self->_load_manifest;
    my @results;
    for my $case (@{ $manifest->{cases} // [] }) {
        push @results, $self->_run_case($case);
    }
    my $failed = grep { !$_->{passed} } @results;
    return {
        suite => 'perl_core_regression',
        manifest_path => $self->{manifest_path},
        perl => $self->{perl},
        total => scalar @results,
        failed => $failed,
        passed => $failed ? JSON::PP::false() : JSON::PP::true(),
        results => \@results,
    };
}

sub _run_case {
    my ($self, $case) = @_;
    my @cmd = ($self->{perl}, @{ $case->{argv} // [] });
    my ($stdout, $stderr, $exit) = _run(@cmd);
    return {
        id => $case->{id},
        description => $case->{description},
        command => \@cmd,
        exit => $exit,
        stdout => $stdout,
        stderr => $stderr,
        passed => $exit == 0 ? JSON::PP::true() : JSON::PP::false(),
    };
}

sub _load_manifest {
    my ($self) = @_;
    open my $fh, '<', $self->{manifest_path} or die "cannot read core suite manifest $self->{manifest_path}: $!";
    local $/;
    return decode_json(<$fh>);
}

sub _run {
    my (@cmd) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @cmd);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0);
    return ($stdout, $stderr, $? >> 8);
}

1;

=pod

=head1 NAME

PAX::CoreSuite - perl-core suite runner

=head1 SYNOPSIS

  use PAX::CoreSuite;

  my $obj = PAX::CoreSuite->new(...);
  my $result = $obj->run(...);

=head1 DESCRIPTION

Loads core-suite manifests and executes them through the PAX validation flow to measure language-surface compatibility.

=head1 METHODS

=head2 new, run

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the perl-core suite runner logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs perl-core suite runner. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects perl-core suite runner, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover perl-core suite runner.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::CoreSuite -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
