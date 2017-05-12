package MouseX::NonMoose;

use Mouse;
extends 'MouseX::Foreign';

our $VERSION = '1.000';

1;

__END__

=head1 NAME

MouseX::NonMoose - MouseX::Foreign plus drop-in compatibility with Any::Moose

=head1 VERSION

This document describes MouseX::Foreign version 1.000.

=head1 SYNOPSIS

    package MyInt;
    use Any::Moose;
    use Any::Moose 'X::NonMoose';
    extends 'Math::BigInt';

    has name => (
        is  => 'ro',
        isa => 'Str',
    );

=head1 DESCRIPTION

MouseX::NonMoose is a thin wrapper around L<MouseX::Foreign>, so as to be used
with L<Any::Moose> and L<MooseX::NonMoose>;

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
