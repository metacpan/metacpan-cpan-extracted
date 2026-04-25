package NBI::Pipeline;
#ABSTRACT: Ordered list of NBI::Job objects with dependency wiring
#
# NBI::Pipeline - Minimal multi-job orchestration for nbilaunch.
#
# DESCRIPTION:
#   Holds an ordered list of NBI::Job objects.  When run() is called, jobs are
#   submitted in order.  If a job has _nbi_depends_on set to a previous job
#   object, the afterok dependency is injected into its NBI::Opts before
#   submission.
#
#   This is intentionally minimal in v1.  It does not resolve filenames between
#   jobs - complex launchers handle that via NBI::Manifest->load().
#
# USAGE IN A LAUNCHER:
#   sub build {
#       my ($self, %args) = @_;
#       my ($job1, $m1) = $self->_build_step1(%args);
#       my ($job2, $m2) = $self->_build_step2(%args);
#       $job2->{_nbi_depends_on} = $job1;
#       return (NBI::Pipeline->new(jobs => [$job1, $job2]), $m1);
#   }
#
# nbilaunch checks ref($result): NBI::Job → single submit, NBI::Pipeline → run().
#

use 5.012;
use strict;
use warnings;
use Carp qw(confess);

$NBI::Pipeline::VERSION = $NBI::Slurm::VERSION;

sub new {
    my ($class, %args) = @_;

    my $jobs = $args{jobs} // [];
    ref $jobs eq 'ARRAY'
        or confess "ERROR NBI::Pipeline: 'jobs' must be an arrayref\n";

    for my $j (@$jobs) {
        $j->isa('NBI::Job')
            or confess "ERROR NBI::Pipeline: each job must be an NBI::Job instance\n";
    }

    return bless { jobs => [@$jobs] }, $class;
}

# ── add_job($job) ─────────────────────────────────────────────────────────────
sub add_job {
    my ($self, $job) = @_;
    $job->isa('NBI::Job')
        or confess "ERROR NBI::Pipeline: job must be an NBI::Job instance\n";
    push @{ $self->{jobs} }, $job;
    return $self;
}

# ── run() ─────────────────────────────────────────────────────────────────────
# Submit all jobs in order.  Wires afterok dependencies automatically.
# Returns a list of Slurm job IDs (integers).
sub run {
    my ($self) = @_;

    my @job_ids;
    my %submitted;   # NBI::Job object → job_id (for dependency lookup)

    for my $job (@{ $self->{jobs} }) {
        # Inject afterok dependency if this job depends on a previous one
        if (my $dep_job = $job->{_nbi_depends_on}) {
            my $dep_id = $submitted{$dep_job}
                or confess "ERROR NBI::Pipeline: dependency job was not yet submitted\n";
            $job->opts->add_option("--dependency=afterok:$dep_id");
        }

        # Ensure the provenance directory exists before NBI::Job->run() writes there
        my $tmpdir = $job->opts->tmpdir;
        if ($tmpdir && !-d $tmpdir) {
            require File::Path;
            File::Path::make_path($tmpdir)
                or confess "ERROR NBI::Pipeline: cannot create tmpdir '$tmpdir': $!\n";
        }

        my $job_id = $job->run();
        $submitted{$job} = $job_id;
        push @job_ids, $job_id;
    }

    return @job_ids;
}

# ── print_summary() ───────────────────────────────────────────────────────────
# Human-readable dependency graph.
sub print_summary {
    my ($self) = @_;
    my @lines = ("Pipeline: " . scalar(@{ $self->{jobs} }) . " job(s)");
    for my $job (@{ $self->{jobs} }) {
        my $line = "  [" . $job->name . "]";
        if (my $dep = $job->{_nbi_depends_on}) {
            $line .= "  afterok:[" . $dep->name . "]";
        }
        push @lines, $line;
    }
    print join("\n", @lines) . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NBI::Pipeline - Ordered list of NBI::Job objects with dependency wiring

=head1 VERSION

version 0.21.0

=head1 SYNOPSIS

  use NBI::Pipeline;

  my $pipeline = NBI::Pipeline->new(jobs => [$job1, $job2]);

  # Wire job2 to run only after job1 succeeds
  $job2->{_nbi_depends_on} = $job1;

  my @ids = $pipeline->run();   # submits in order, injects afterok deps
  $pipeline->print_summary();

=head1 NAME

NBI::Pipeline - Ordered list of NBI::Job objects with dependency wiring

=head1 METHODS

=head2 new(jobs => \@jobs)

Construct a pipeline.  Each element must be an C<NBI::Job> instance.

=head2 add_job($job)

Append a job to the pipeline.

=head2 run()

Submit all jobs in order.  Returns a list of Slurm job IDs.
Jobs with C<_nbi_depends_on> set get an C<afterok> dependency injected.

=head2 print_summary()

Print a human-readable dependency graph to STDOUT.

=head1 AUTHOR

Andrea Telatin <proch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
