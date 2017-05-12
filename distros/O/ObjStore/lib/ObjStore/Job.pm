use strict;
package ObjStore::Job;
use ObjStore;
use base 'ObjStore::HV';  #use fields? XXX
use vars qw($VERSION);
$VERSION = '0.02';

sub new {
    use attrs 'method';
    # a unique $id could be constructed with join('.', `hostname`, $$, $id++);

    my ($class, $near, $id, $priority) = @_;
    # uses real pointers so must be per-database...
    my $t = $near->database_of->hash->{'ObjStore::Job::Table'};
    die "No ObjStore::Job::Table found" if !$t;
    my $o = shift->SUPER::new($t->segment_of);
    # $id is a string!
    if ($id) { $$o{id} = "$id"; }
    else {     $$o{id} = "$$t{nextid}"; ++$$t{nextid}; }
    $$o{priority} = int(defined $priority? $priority : 10);
    $$o{job_table} = $$t{SELF};
    $$o{cpu} = 0;
    $$o{state} = 'R';
    $$o{why} = '';   #why killed
    $t->add($o);
    $o;
}

sub runnable {
    use attrs 'method';
    my $state = shift->{state};
    $state ne 'D' and $state ne 'K';
}
sub running {
    use attrs 'method';
    my $state = shift->{state};
    $state eq 'R' or $state eq 'S';
}

use ObjStore::notify qw(work set_priority signal acknowledge);
sub do_work {
    my ($o, $slices) = @_;
    # override this method!
    my $used = int rand 8;
    warn "$o->work(): consuming $used slices";
    $$o{state} = 'S' if $used == 0;  #avoid 'L' state
    $slices - $used;  # how many left
}
sub do_set_priority {
    my ($o, $pri) = @_;
    my $t = $$o{job_table}->focus;
    $o->HOLD;
    $t->remove($o);
    $$o{priority} = $pri;
    $t->add($o);
    ()
}
sub do_signal {
    my ($o, $sig) = @_;
    return if !$o->runnable;
    if    ($sig eq 'kill')      { $$o{state} = 'K'; $$o{why} = 'signal'; }
    elsif ($sig eq 'suspend')   { $$o{state} = 'T'; }
    elsif ($sig eq 'resume')    { $$o{state} = 'R'; }
    else { warn "$o->signal($sig): unknown signal"; }
    ()
}
sub do_acknowledge {  #like wait(2)
    my ($o) = @_;
    return if $o->runnable;
    $o->cancel();
    ()
}

sub cancel {
    use attrs 'method';
    my ($o) = @_;
    $$o{job_table}->focus->remove($o);
}

1;

=head1 NAME

ObjStore::Job - Jobs for a Non-Preemptive Idle-Time Job Scheduler

=head1 SYNOPSIS

=over 4

=item 1

Add an C<ObjStore::Job::Table> to your database.

=item 2

Sub-class C<ObjStore::Job> and override the C<do_work> method.

=item 3

  package ObjStore::Job
  use ObjStore::Mortician;

Maybe all jobs should have delayed destruction by default.

=back

=head1 DESCRIPTION

=head1 JOB STATES

 R running
 L infinite loop detected
 S sleeping                - will retry every second
 T suspended
 D done
 K killed

=head1 SCHEDULING PRIORITIES

=over 4

=item * HIGH PRIORITY <= 0

Allowed to consume all available pizza slices.

=item * TIME-SLICED 1-20

Given pizza slices proportional to the priority until either all the
pizza slices are consumed or all the jobs are asleep (feasts induce
slumber :-).

=item * IDLE > 20

Given all remaining pizza slices.

=back

=head1 TRANSACTION STRATEGY

The whole scheduling operation occurs within a single transaction.
While this means that any job can kill the entire transaction, this
seems a better choice than wrapping every job in its own
mini-transaction.  Since transactions are relatively expensive, it is
hoped that most of the time all jobs will complete without error.

=head1 BUGS

Too bad you can't store CODEREFs in the database.

Time does not necessarily transmute into pizza.

=cut
