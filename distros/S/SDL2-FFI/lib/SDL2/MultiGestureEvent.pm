package SDL2::MultiGestureEvent {
    use SDL2::Utils;
    has
        type       => 'uint32',
        timestamp  => 'uint32',
        touchId    => 'opaque',    # SDL_TouchID
        dTheta     => 'float',
        dDist      => 'float',
        x          => 'float',
        y          => 'float',
        numFingers => 'uint16',
        padding    => 'uint16';

=encoding utf-8

=head1 NAME

SDL2::MultiGestureEvent - Multiple finger gesture event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_MULTIGESTURE>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<touchId> - The touch device id

=item C<dTheta>

=item C<dDist>

=item C<x>

=item C<y>

=item C<numFingers>

=item C<padding>

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
