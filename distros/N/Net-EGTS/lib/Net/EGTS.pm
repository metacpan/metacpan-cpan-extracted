use utf8;

package Net::EGTS;
use namespace::autoclean;
use Mouse;

our $VERSION = 0.03;

=head1 NAME

Net::EGTS - Perl Interface to EGTS protocol. GOST R 56360-2015.

=head1 RESTRICTIONS

This initial release can only auth and send teledata.

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2018 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2018 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

__PACKAGE__->meta->make_immutable();
