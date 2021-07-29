package SDL2::DollarGestureEvent {
    use SDL2::Utils;
    has
        type       => 'uint32',
        timestamp  => 'uint32',
        touchId    => 'opaque',    # SDL_TouchID
        gestureId  => 'opaque',    # SDL_GestureID
        numFingers => 'uint32',
        error      => 'float',
        x          => 'float',
        y          => 'float';

=encoding utf-8

=head1 NAME

SDL2::DollarGestureEvent - Dollar gesture event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_DOLLARGESTURE> or C<SDL_DOLLARRECORD>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<touchId> - The touch device id

=item C<gestureId>

=item C<numFingers>

=item C<error>

=item C<x> - Normalized center of gesture

=item C<y> - Normalized center of gesture

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
