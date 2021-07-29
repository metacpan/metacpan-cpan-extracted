package SDL2::WindowEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        display   => 'uint32',
        event     => 'uint8',
        padding1  => 'uint8',
        padding2  => 'uint8',
        padding3  => 'uint8',
        data1     => 'sint32',
        data2     => 'sint32';

=encoding utf-8

=head1 NAME

SDL2::WindowEvent - Window state change event data

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 

=head1 Fields

=over

=item C<type> - C<SDL_WINDOWEVENT>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<display> - The associated display index

=item C<event>

=item C<padding1>

=item C<padding2>

=item C<padding3>

=item C<data1> - Event dependant data

=item C<data2> - Event dependant data

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
