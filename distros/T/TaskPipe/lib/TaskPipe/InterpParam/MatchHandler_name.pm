package TaskPipe::InterpParam::MatchHandler_name;

use Moose;
extends 'TaskPipe::InterpParam::MatchHandler';


has match_adjustment => (is => 'ro', isa => 'Int', default => -1 );

sub match_condition{
    my ($self,$param) = @_;

    $param->{_name} eq $self->parts->label_val?1:0;
}


=head1 NAME

TaskPipe::InterpParam::MatchHandler_name - match handler for the $name parameter variable

=head1 DESCRIPTION

TaskPipe Match handler for the $name parameter variable

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
