
package Schedule::Pluggable::Plugin::DefaultEventHandler;
use Moose::Role;
use FileHandle;
use POSIX qw/ strftime /;

has EventsToReport => ( is => 'rw',
                        isa => 'Str',
                        required => 1,
                        default => qq/JobStarted,JobFailed,JobSucceeded,JobStderr/,
                        );
has ShowTimeStamp => ( is => 'rw',
                       isa => 'Bool',
                       required => 1,
                       default => 1 );
has MessagesTo => ( is => 'rw',
                    isa => 'Any',
                    required => 1,
                    default => sub { FileHandle->new('>&1') },
                    );
has ErrorsTo => ( is => 'rw',
                  isa => 'Any',
                  required => 1,
                  default => sub { FileHandle->new('>&1') },
                    );
                           

after event_handler => sub {
    my $self = shift;
	my %params = @_;
	return if exists $params{JobName} and  $params{JobName} =~ m/^MonitorJobs$/i;
	return if $self->EventsToReport =~ m/^none$/i;
	my $event = $params{Event};
	return if $self->EventsToReport !~ m!^all$!i and
              $self->EventsToReport !~ m!\b$event\b!;
    my %whattoreport = (
                   JobQueued      => [qw/ Event JobName Command /],
                   JobStarted     => [qw/ Event JobName Command /],
                   JobDone        => [qw/ Event JobName Command /],
                   JobStderr      => [qw/ Event JobName Stderr /],
                   JobStdout      => [qw/ Event JobName Stdout /],
                   JobFailed      => [qw/ Event JobName Command ReturnValue Stderr /],
                   JobSucceeded   => [qw/ Event JobName Command /],
                   MaxJobsReached => [qw/ Event /],
                   ManagerStart   => [qw/ Event /],
                   ManagerStart   => [qw/ Event /],
                       );
	return unless exists $whattoreport{ $params{Event} };
    my @mess = ();
    push(@mess, strftime('%d/%m/%Y %H:%M:%S', localtime(time()))) if $self->ShowTimeStamp;
    foreach my $field (@{ $whattoreport{$params{Event}} }) {
        push(@mess, ref($params{$field}) eq 'ARRAY' ? @{ $params{$field} } : $params{$field});
    }
    my $handle = $params{Event} =~ m/(JobStderr|JobFailed)/ ? $self->ErrorsTo
                                                              : $self->MessagesTo;
        
    if (ref($handle) eq 'FileHandle') {
        $handle->print(join(' ',@mess)."\n"); 
    }
    else {
        $handle->(join(' ',@mess)."\n"); 
    }
};
no Moose;
1;
__END__

=head1 NAME

Schedule::Pluggable::Plugin::DefaultEventHandler - Plugin Role for Schedule::Pluggable to handle events

=head1 DESCRIPTION

Plugin to provide default handling of events in a schedule.
Basically, it just prints out the details of the events specified in the array EventsToReport with an optional preceding date/time stamp

=head1 METHODS

=over

=item event_handler

The method required by all event handler plugins - gets called but the methods in Schedule::Pluggable::Monitor when they are called 
when events occur
Is supplied a handle to the Schedule::Pluggable object and a hash specifying what has happened 
the following table shows what gets passed depending on the event :-
B<Event>            B<Parameters passed>
JobQueued      => Event JobName Command
JobStarted     => Event JobName Command 
JobDone        => Event JobName Command 
JobStderr      => Event JobName Stderr
JobStdout      => Event JobName Stdout
JobFailed      => Event JobName Command ReturnValue Stderr
JobSucceeded   => Event JobName Command
MaxJobsReached => Event
ManagerStart   => Event
ManagerStart   => Event

=back
 
e.g. 
C<$self->event_handler(Event    => 'JobStderr', 
                     JobName => $job->{name},
                     Command => $job->{command},
                     Stderr  => $stderr,
                    );>


=cut
