package SDL2::AudioSpec {
    use SDL2::Utils;
    has
        freq     => 'int',
        format   => 'uint16',
        channels => 'uint8',
        silence  => 'uint8',
        samples  => 'uint16',
        padding  => 'uint16',
        size     => 'uint32',
        callback => 'opaque',    # SDL_AudioCallback
        userdata => 'opaque'     # void *
        ;

=encoding utf-8

=head1 NAME

SDL2::AudioSpec - The Structure that Defines a Point with Integers

=head1 SYNOPSIS

    use SDL2 qw[:all];
    # TODO: I need to whip up a quick example

=head1 DESCRIPTION

SDL2::AudioSpec

The calculated values in this structure are calculated by SDL_OpenAudio().

For multi-channel audio, the default SDL channel mapping is:

    *  2:  FL FR                       (stereo)
    *  3:  FL FR LFE                   (2.1 surround)
    *  4:  FL FR BL BR                 (quad)
    *  5:  FL FR FC BL BR              (quad + center)
    *  6:  FL FR FC LFE SL SR          (5.1 surround - last two can also be BL BR)
    *  7:  FL FR FC LFE BC SL SR       (6.1 surround)
    *  8:  FL FR FC LFE BL BR SL SR    (7.1 surround)

=head1 Fields

=over

=item C<freq> - DSP frequency -- samples per second

=item C<format> - Audio data format

=item C<channels> - Number of channels: 1 mondo, 2 stereo

=item C<silence> - Audio buffer silence value (calculated)

=item C<samples> - Audio buffer size in sample FRAMES (total samples divided by channel count)

=item C<padding> - Necessary for some compile environments

=item C<size> - Audio buffer size in bytes (calculated)

=item C<callback> - Callback that feeds the audio device (undef to use C<SDL_QueueAudio( ... )>)

=item C<userdata> - Userdata passed to callback (ignored for undef callbacks)

=back

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords


=end stopwords

=cut

};
1;
