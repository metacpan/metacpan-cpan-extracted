# ABSTRACT: request - create
package PONAPI::Client::Request::Create;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsPOST',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasData',
     'PONAPI::Client::Request::Role::HasUriAll';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request::Create - request - create

=head1 VERSION

version 0.002009

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

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
