# ABSTRACT: request - retrieve
package PONAPI::Client::Request::Retrieve;

use Moose;

with 'PONAPI::Client::Request',
     'PONAPI::Client::Request::Role::IsGET',
     'PONAPI::Client::Request::Role::HasType',
     'PONAPI::Client::Request::Role::HasId',
     'PONAPI::Client::Request::Role::HasFields',
     'PONAPI::Client::Request::Role::HasFilter',
     'PONAPI::Client::Request::Role::HasInclude',
     'PONAPI::Client::Request::Role::HasPage',
     'PONAPI::Client::Request::Role::HasUriSingle';

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Client::Request::Retrieve - request - retrieve

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
