package SDL2::version 0.01 {
    use SDL2::Utils;
    use experimental 'signatures';
    #
    use SDL2::stdinc;
    #
    package SDL2::Version {
        use SDL2::Utils;
        our $TYPE = has major => 'uint8', minor => 'uint8', patch => 'uint8';
    };

    sub _ver() {
        CORE::state $version;
        if ( !defined $version ) {
            $version = SDL2::Version->new();
            SDL2::FFI::SDL_VERSION($version);
        }
        $version;
    }
    define version => [
        [ SDL_MAJOR_VERSION => sub () { SDL2::version::_ver()->major } ],
        [ SDL_MINOR_VERSION => sub () { SDL2::version::_ver()->minor } ],
        [ SDL_PATCHLEVEL    => sub () { SDL2::version::_ver()->patch } ],
        [ SDL_VERSION       => sub ($version) { SDL2::FFI::SDL_GetVersion($version); } ],
        [ SDL_VERSIONNUM    => sub ( $X, $Y, $Z ) { ( ($X) * 1000 + ($Y) * 100 + ($Z) ) } ],
        [   SDL_COMPILEDVERSION => sub () {
                SDL2::FFI::SDL_VERSIONNUM(
                    SDL2::FFI::SDL_MAJOR_VERSION(),
                    SDL2::FFI::SDL_MINOR_VERSION(),
                    SDL2::FFI::SDL_PATCHLEVEL()
                );
            }
        ],
        [   SDL_VERSION_ATLEAST => sub ( $X, $Y, $Z ) {
                ( SDL2::FFI::SDL_COMPILEDVERSION() >= SDL2::FFI::SDL_VERSIONNUM( $X, $Y, $Z ) )
            }
        ]
    ];
    attach version =>
        { SDL_GetVersion => [ ['SDL_Version'] ], SDL_GetRevision => [ [], 'string' ], };

=encoding utf-8

=head1 NAME

SDL2::version - Information About the Version of SDL in Use

=head1 SYNOPSIS

    use SDL2 qw[:version];
    SDL_GetVersion( my $ver = SDL2::version->new );
    CORE::say sprintf 'SDL version %d.%d.%d', $ver->major, $ver->minor, $ver->patch;

=head1 DESCRIPTION

SDL2::version represents the library's version as three levels: major, minor,
and patch level.

=head1 Functions

These may be imported with the <:version> tag.

=head2 C<SDL_VERSION( ... )>

Macro to determine SDL version program was compiled against.

This macro fills in a SDL_version structure with the version of the library you
compiled against. This is determined by what header the compiler uses. Note
that if you dynamically linked the library, you might have a slightly newer or
older version at runtime. That version can be determined with SDL_GetVersion(),
which, unlike SDL_VERSION(), is not a macro.

Expected parameters include:

=over

=item C<x> - a pointer to a L<SDL2::Version> struct to initialize

=back

=head2 C<SDL_VERSIONNUM( ... )>

This macro turns the version numbers into a numeric value:

    (1,2,3) -> (1203)

This assumes that there will never be more than 100 patchlevels.

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

Returns an integer.

=head2 C<SDL_VERSION_ATLEAST( ... )>

Evaluates to true if compiled with SDL at least C<major.minor.patch>.

	if ( SDL_VERSION_ATLEAST( 2, 0, 15 ) ) {
		# Some feature that requires 2.0.15+
	}

Expected parameters include:

=over

=item C<major>

=item C<minor>

=item C<patch>

=back

Returns a boolean value.

=head2 C<GetVersion( ... )>

Get the version of SDL that is linked against your program.

	SDL_GetVersion( my $version_ = SDL2::Version->new() );

If you are linking to SDL dynamically, then it is possible that the current
version will be different than the version you compiled against. This function
returns the current version, while L<< C<SDL_VERSION( ... )>|/C<SDL_VERSION(
... )> >> is a macro that tells you what version you compiled with.

This function may be called safely at any time, even before C<SDL_Init( ... )>.

Expected parameters include:

=over

=item C<ver> - the L<SDL2::Version> structure that contains the version information

=back

=head2 C<SDL_GetRevision( )>

Get the code revision of SDL that is linked against your program.

This value is the revision of the code you are linked with and may be different
from the code you are compiling with, which is found in the upstream constant
C<SDL_REVISION>.

The revision is arbitrary string (a hash value) uniquely identifying the exact
revision of the SDL library in use, and is only useful in comparing against
other revisions. It is NOT an incrementing number.

If SDL wasn't built from a git repository with the appropriate tools, this will
return an empty string.

Prior to SDL 2.0.16, before development moved to GitHub, this returned a hash
for a Mercurial repository.

You shouldn't use this function for anything but logging it for debugging
purposes. The string is not intended to be reliable in any way.

Returns an arbitrary string, uniquely identifying the exact revision of the SDL
library in use.

=head1 Defined Values

These may be imported with the <:version> tag.

=over

=item C<SDL_MAJOR_VERSION>

=item C<SDL_MINOR_VERSION>

=item C<SDL_PATCHLEVEL>

=item C<SDL_COMPILEDVERSION> - Version number for the current SDL version

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

patchlevels

=end stopwords

=cut

};
1;
