use 5.010;
use strict;
use warnings;

package String::Compile::Tr::Overload;

=encoding UTF-8

=head1 NAME

String::Compile::Tr::Overload - overload tr/// operands

=head1 VERSION

Version 0.06

=cut

our
$VERSION = '0.06';

=head1 SYNOPSIS

    use String::Compile::Tr::Overload;

=head1 DESCRIPTION

This module overloads the operands of a C<tr///> operator and replaces
the strings C<:search:> and C<:replace:> with the contents of the
variables C<$String::Compile::Tr::Overload::search> resp.
C<$String::Compile::Tr::Overload::replace>.

=head1 AUTHOR

Jörg Sommrey, C<< <git at sommrey.de> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Jörg Sommrey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<overload/Overloading Constants>

=cut

use overload;

sub _ovl_tr {
    our ($search, $replace);

    return $_[1] unless $_[2] eq 'tr';
    return "$search" if $_[1] eq ':search:';
    return "$replace" if $_[1] eq ':replace:';
    
    $_[1];
}

sub import {
    overload::constant q => \&_ovl_tr;
}

sub unimport {
    overload::remove_constant q => \&_ovl_tr;
}

1;
