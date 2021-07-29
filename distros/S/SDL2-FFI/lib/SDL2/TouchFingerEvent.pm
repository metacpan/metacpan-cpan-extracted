package SDL2::TouchFingerEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        touchId   => 'opaque',    # SDL_TouchID
        fingerId  => 'opaque',    # SDL_FingerID
        x         => 'float',
        y         => 'float',
        dx        => 'float',
        dy        => 'float',
        pressure  => 'float',
        windowID  => 'uint32';

=encoding utf-8

=head1 NAME

SDL2::TouchFingerEvent - Touch finger event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_FINGERMOTION> or C<SDL_FINGERDOWN> or C<SDL_FINGERUP>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<touchId> - The touch device id

=item C<fingerId> - 

=item C<x> - Normalized in the range C<0..1>

=item C<y> - Normalized in the range C<0..1>

=item C<dx> - Normalized in the range C<-1..1>

=item C<dy> - Normalized in the range C<-1..1>

=item C<pressure> - Normalized in the range C<0..1>

=item C<windowID> - The window underneath the finger, if any

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
