package Regru::API::Role::Serializer;

# ABSTRACT: something that can (de)serialize

use strict;
use warnings;
use Moo::Role;
use JSON;
use Carp;
use namespace::autoclean;

our $VERSION = '0.049'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

has serializer => (
    is      => 'rw',
    isa     => sub {
        croak "$_[0] is not a JSON instance"    unless ref($_[0]) =~ m/JSON/;
        croak "$_[0] can not decode"            unless $_[0]->can('decode');
        croak "$_[0] can not encode"            unless $_[0]->can('encode');
    },
    lazy    => 1,
    default => sub { JSON->new->utf8 },
);

1;  # End of Regru::API::Role::Serializer

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Role::Serializer - something that can (de)serialize

=head1 VERSION

version 0.049

=head1 SYNOPSIS

    package Regru::API::Client;
    ...
    with 'Regru::API::Role::Serializer';

    $str = $self->serializer->encode({ answer => 42, foo => [qw(bar baz quux)] });

=head1 DESCRIPTION

Any class or role that consumes this one will able to (de)serialize JSON.

=head1 ATTRIBUTES

=head2 serializer

Returns an L<JSON> instance with B<utf8> option enabled.

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

L<JSON>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/regru/regru-api-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Polina Shubina <shubina@reg.ru>

=item *

Anton Gerasimov <a.gerasimov@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by REG.RU LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
