package Socialtext::WikiFixture::Null;
use strict;
use warnings;
use base 'Socialtext::WikiFixture';
use base 'Exporter';

our @EXPORT_OK = qw/get_num_calls/;

my $CALLS;

=head2 get_num_calls

Return the number of calls made to handle_command, and reset the counter.

=cut

sub get_num_calls {
    my $num = $CALLS;
    $CALLS = 0;
    return $num;
}

sub handle_command { 
    my $self = shift;
    my $command = shift;

    if ($self->can($command)) {
        $self->$command(@_);
    }
    else {
        print "Null: $command\n" unless $self->{silent};
    }
    $CALLS++;
    $self->{calls}{$command}++;
    push @{ $self->{args}{$command} }, \@_;
    die if $command eq 'die';
}

1;
