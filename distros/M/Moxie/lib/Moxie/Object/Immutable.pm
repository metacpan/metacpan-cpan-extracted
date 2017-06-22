package Moxie::Object::Immutable;
# ABSTRACT: Yet Another (Immutable) Base Class

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use UNIVERSAL::Object::Immutable;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

our @ISA; BEGIN {
    @ISA = (
        'UNIVERSAL::Object::Immutable',
        'Moxie::Object',
    );
}

1;

__END__

=pod

=head1 NAME

Moxie::Object::Immutable - Yet Another (Immutable) Base Class

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is an extension of L<UNIVERSAL::Object::Immutable> and
L<Moxie::Object>.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
