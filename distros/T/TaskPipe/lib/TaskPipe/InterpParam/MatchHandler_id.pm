package TaskPipe::InterpParam::MatchHandler_id;

use Moose;
extends 'TaskPipe::InterpParam::MatchHandler';

has match_adjustment => (is => 'ro', isa => 'Int', default => -1 );

=head1 NAME

TaskPipe::InterpParam::MatchHandler_id - Match handler for the $id parameter variable

=head1 DESCRIPTION

MatchHandler for the $id parameter variable

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;       
