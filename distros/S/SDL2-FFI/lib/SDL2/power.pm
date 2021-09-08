package SDL2::power 0.01 {
    use SDL2::Utils;
    #
    use SDL2::stdinc;
    #
    enum SDL_PowerState => [
        qw[SDL_POWERSTATE_UNKNOWN
            SDL_POWERSTATE_ON_BATTERY
            SDL_POWERSTATE_NO_BATTERY
            SDL_POWERSTATE_CHARGING
            SDL_POWERSTATE_CHARGED
        ]
    ];
    attach power => { SDL_GetPowerInfo => [ [ 'int*', 'int*' ], 'SDL_PowerState' ] };

=encoding utf-8

=head1 NAME

SDL2::power - SDL Power Management Routines

=head1 SYNOPSIS

    use SDL2 qw[:power :powerState];
	if ( SDL_GetPowerInfo( \my $secs, \my $pct ) == SDL_POWERSTATE_ON_BATTERY ) {
        printf("Battery is draining: ");
        if ( $secs == -1 ) {
            printf("(unknown time left)\n");
        }
        else {
            printf( "(%d seconds left)\n", $secs );
        }
        if ( $pct == -1 ) {
            printf("(unknown percentage left)\n");
        }
        else {
            printf( "(%d percent left)\n", $pct );
        }
    }

=head1 DESCRIPTION

SDL2::power exposes a supported system's power state.

=head1 Functions

These may be imported by name or with the C<:power> tag.

=head2 C<SDL_GetPowerInfo( ... )>

Get the current power supply details.

    my $state = SDL_GetPowerInfo( \my $secs, \my $pct );

You should never take a battery status as absolute truth. Batteries (especially
failing batteries) are delicate hardware, and the values reported here are best
estimates based on what that hardware reports. It's not uncommon for older
batteries to lose stored power much faster than it reports, or completely drain
when reporting it has 20 percent left, etc.

Battery status can change at any time; if you are concerned with power state,
you should call this function frequently, and perhaps ignore changes until they
seem to be stable for a few seconds.

It's possible a platform can only report battery percentage or time left but
not both.

Expected parameters include:

=over

=item C<secs> - seconds of battery life left, you can pass a C<undef> here if you don't care, will return C<-1> if we can't determine a value, or we're not running on a battery

=item C<pct> - percentage of battery life left, between C<0> and C<100>, you can pass a C<undef> here if you don't care, will return C<-1> if we can't determine a value, or we're not running on a battery

=back

Returns an C<SDL_PowerState> enum representing the current battery state.

=head1 Enumerations

These may be imported with the given tag.

=head2 C<SDL_PowerState>

The basic state for the system's power supply. These may be imported with the
C<:powerState> tag.

=over

=item C<SDL_POWERSTATE_UNKNOWN> - cannot determine power status

=item C<SDL_POWERSTATE_ON_BATTERY> - Not plugged in, running on the battery

=item C<SDL_POWERSTATE_NO_BATTERY> - Plugged in, no battery available

=item C<SDL_POWERSTATE_CHARGING> - Plugged in, charging battery

=item C<SDL_POWERSTATE_CHARGED> - Plugged in, battery charged

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

=end stopwords

=cut

};
1;
