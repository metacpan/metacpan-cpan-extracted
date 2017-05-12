package PerlLocks;
use strict;

# Containing a record for each lock, that will be:
#   { owned => 1/0,
#     waiting => [list of request numbers],
#     waiting_signal => [list of request numbers],
#   }
my %variables;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub AcceptRequest {
    my ($self, $params) = @_;
    my ($operation, $lock_name) = split(' ', $params->{request}, 2);
    my $requestNumber = $params->{requestNumber};
    my $record;
    if (exists $variables{$lock_name}) {
        $record = $variables{$lock_name};
    } else {
        $record = { owned => 0, waiting => [], waiting_signal => [] };
        $variables{$lock_name} = $record;
    }
    
    if ($operation eq 'lock') {
        if ($record->{owned}) {
            push @{ $record->{waiting} }, $requestNumber;
            return $STAF::DelayedAnswer;
        } else {
            $record->{owned} = 1;
            return (0, "OK");
        }
    }
    
    if ($operation eq 'release') {
        $self->Release($record);
        return (0, "OK");
    }

    if ($operation eq 'cond_wait') {
        push @{ $record->{waiting_signal} }, $requestNumber;
        $self->Release($record);
        return $STAF::DelayedAnswer;
    }

    if ($operation eq 'cond_signal') {
        my $other_requestNumber = shift @{ $record->{waiting_signal} };
        push @{ $record->{waiting} }, $other_requestNumber;
        return (0, "OK");
    }

    if ($operation eq 'cond_broadcast') {
        push @{ $record->{waiting} }, @{ $record->{waiting_signal} };
        @{ $record->{waiting_signal} } = ();
        return (0, "OK");
    }
    
    return (1, "Unknown command");
}

sub Release {
    my ($self, $record) = @_;
    if (@{ $record->{waiting} }) {
        my $other_requestNumber = shift @{ $record->{waiting} };
        STAF::DelayedAnswer($other_requestNumber, 0, "OK");
    } else {
        $record->{owned} = 0;
    }
}

1;