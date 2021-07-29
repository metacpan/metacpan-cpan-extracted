package SDL2::version 0.01 {
    use SDL2::Utils;
    has major => 'uint8', minor => 'uint8', patch => 'uint8';

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

=head1 Fields

=head2 C<major( )>

Returns value which increments with massive changes, additions, and
enhancements.

=head2 C<minor( )>

Returns value which increments with backwards-compatible changes to the major
revision.

=head2 C<patch( )>

Returns value which increments with fixes to the minor revision.

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
