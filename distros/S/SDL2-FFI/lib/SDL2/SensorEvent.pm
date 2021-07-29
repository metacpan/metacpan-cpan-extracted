package SDL2::SensorEvent {
    use SDL2::Utils;
    has
        type      => 'uint32',
        timestamp => 'uint32',
        which     => 'sint32',
        data      => 'float[6]';

=encoding utf-8

=head1 NAME

SDL2::SensorEvent - Sensor event structure

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION
 


=head1 Fields

=over

=item C<type> - C<SDL_SENSORUPDATE>

=item C<timestamp> - In milliseconds, populated using L<< C<SDL_GetTicks( )>|SDL2::FFI/C<SDL_GetTicks( )> >>

=item C<which> - The instance ID of the sensor

=item C<data> - Up to 6 values from the sensor - additional values can be queried using L<< C<SDL_SensorGetData( )>|SDL2::FFI/C<SDL_SensorGetData( )> >>.

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
