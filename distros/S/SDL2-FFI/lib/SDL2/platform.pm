package SDL2::platform 0.01 {
    use SDL2::Utils;
    #
    attach platform => { SDL_GetPlatform => [ [], 'string' ] };

=encoding utf-8

=head1 NAME

SDL2::platform - Platform Defined Values

=head1 SYNOPSIS

    use SDL2 qw[:platform];
	warn SDL_GetPlatform( );

=head1 DESCRIPTION

SDL2::platform contains functions for dealing with the current platform.

=head1 Functions

These may be imported by name or with the C<:platform> tag.

=head2 C<SDL_GetPlatform( )>

Get the name of the platform.

	if ( SDL_GetPlatform( ) eq 'Linux' ) {
		# ...
	}

Here are the names returned for some (but not all) supported platforms:

=over

=item * "Windows"

=item * "Mac OS X"

=item * "Linux"

=item * "iOS"

=item * "Android"

=back

Returns the name of the platform. If the correct platform name is not
available, returns a string beginning with the text "Unknown".

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
