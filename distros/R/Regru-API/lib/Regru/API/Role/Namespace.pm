package Regru::API::Role::Namespace;

# ABSTRACT: something that can treat as a namespace

use strict;
use warnings;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '0.053'; # VERSION
our $AUTHORITY = 'cpan:OLEG'; # AUTHORITY

requires 'available_methods';

1;  # End of Regru::API::Role::Namespace

__END__

=pod

=encoding UTF-8

=head1 NAME

Regru::API::Role::Namespace - something that can treat as a namespace

=head1 VERSION

version 0.053

=head1 SYNOPSIS

    package Regru::API::Dummy;
    ...
    with 'Regru::API::Role::Namespace';

    sub available_methods { [qw(foo bar baz)] }

=head1 DESCRIPTION

Any class or role that consumes this one will considered as a namespace (or category) in REG.API v2.

=head1 REQUIREMENTS

=head2 available_methods

A list of methods (as array reference) provides by namespace. An empty array reference should be used in
case of namespace does not provide any methods. But this so odd...

=head1 SEE ALSO

L<Regru::API>

L<Regru::API::Role::Client>

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
