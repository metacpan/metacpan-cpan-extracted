# ABSTRACT: request - role - has include
package PONAPI::Client::Request::Role::HasInclude;

use Moose::Role;

has include => (
    is        => 'ro',
    isa       => 'ArrayRef',
    predicate => 'has_include',
);

no Moose::Role; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request::Role::HasInclude - request - role - has include

=head1 VERSION

version 0.002012

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
