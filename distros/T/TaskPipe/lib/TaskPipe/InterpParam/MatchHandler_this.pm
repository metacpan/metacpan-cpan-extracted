package TaskPipe::InterpParam::MatchHandler_this;

use Moose;
extends 'TaskPipe::InterpParam::MatchHandler';



sub format_valid{
    my $self = shift;

    my $valid = 1;
    $valid = 0 if $self->parts->label_val || $self->parts->match_count;

    return $valid;
}



sub match_index{
    return 0;
}


=head1 NAME

TaskPipe::InterpParam::MatchHandler_this - match handler for the $this parameter variable

=head1 DESCRIPTION

MatchHandler for the $this parameter variable

=cut

__PACKAGE__->meta->make_immutable;
1;

        












    
