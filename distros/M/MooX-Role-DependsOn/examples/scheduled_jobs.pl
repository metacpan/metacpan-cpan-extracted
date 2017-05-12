package Task;
use Moo;
with 'MooX::Role::DependsOn';
use feature 'say';

sub execute {
  my ($self) = @_;
  say "Running job ".$self->dependency_tag;
}

package main;
# Create some objects that consume MooX::Role::DependsOn:
my $job = {};
for my $jobname (qw/ A B C D E /) {
  $job->{$jobname} = Task->new(dependency_tag => $jobname)
}

# Add some dependencies:
# A depends on B, D:
$job->{A}->depends_on( $job->{B}, $job->{D} );
# B depends on C, E:
$job->{B}->depends_on( $job->{C}, $job->{E} );
# C depends on D, E:
$job->{C}->depends_on( $job->{D}, $job->{E} );

# Resolve dependencies (recursively) for an object:
my @ordered = $job->{A}->dependency_schedule;
# -> scheduled as ( D, E, C, B, A ):
for my $obj (@ordered) {
  $obj->execute;
}

