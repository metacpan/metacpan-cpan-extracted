package Peta::NN::Parallel;
# ABSTRACT: independent pieces of work on several cores

# Independent pieces of work on several cores: each task runs in a process
# of its own (Parallel::ForkManager) and hands its result back as plain data.
#
# This is coarse on purpose. Training runs of different models, of different
# widths of one model, or of one width on different seeds have nothing to do
# with each other, and each takes seconds to minutes; a process per run costs
# nothing beside that. A child starts as a copy of its parent, so what the
# parent has loaded (word lists, training pairs) is there without being sent.

use v5.36;

use Exporter qw(import);

our $VERSION = '0.2610090';
our @EXPORT_OK = qw(in_parallel workers);

# How many processes to use when the caller leaves it open: PETA_NN_WORKERS,
# or 1, which is no parallelism at all.
sub workers () {
    my $asked = $ENV{PETA_NN_WORKERS} // 1;
    die "PETA_NN_WORKERS is a whole number of 1 or more, not '$asked'\n" if $asked !~ /\A[1-9][0-9]*\z/;
    return $asked;
}

# Run the tasks, at most $workers at a time, and return what they returned,
# in the order of the tasks. A task is a sub; what it returns must be plain
# data (no objects, no code), since it crosses from one process to another.
# With one worker, or one task, everything runs here, in order.
# A task that dies takes the whole call with it, after the others are done.
sub in_parallel ($workers, @tasks) {
    return map { scalar $_->() } @tasks if $workers <= 1 || @tasks <= 1;

    require Parallel::ForkManager;
    my $manager = Parallel::ForkManager->new($workers < @tasks ? $workers : scalar @tasks);
    my (@result, @failed);
    $manager->run_on_finish(sub ($pid, $code, $n, $signal, $core, $data) {
        if    ($signal || $code || !$data) { push @failed, "task $n ended with " . ($signal ? "signal $signal" : "status $code") }
        elsif (defined $data->{error})     { push @failed, "task $n: $data->{error}" }
        else                               { $result[$n] = $data->{value} }
    });
    for my $n (0 .. $#tasks) {
        $manager->start($n) and next;
        my $value = eval { scalar $tasks[$n]->() };
        $manager->finish(0, defined $value || !$@ ? { value => $value } : { error => $@ =~ s/\s+\z//r });
    }
    $manager->wait_all_children;
    die join("\n", @failed) . "\n" if @failed;
    return @result;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::Parallel - independent pieces of work on several cores

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    use Peta::NN::Parallel qw(in_parallel);

    my @rows = in_parallel(4, map { my $rule = $_; sub { train_and_export($rule) } } @rules);

=head1 DESCRIPTION

C<in_parallel> runs each task in a process of its own and returns their
results in the tasks' order. A result is plain data. C<workers> is the number
C<PETA_NN_WORKERS> names, or 1.

The examples run their jobs with it, one model's job per process.

=head1 FUNCTIONS

Both are exported on request.

=head2 in_parallel

C<in_parallel($workers, @tasks)>: runs the tasks, at most C<$workers> at a
time, and returns what they returned, in the tasks' order. With one worker,
or one task, everything runs in this process. A task that dies fails the
call.

=head2 workers

The number C<PETA_NN_WORKERS> names, or 1.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
