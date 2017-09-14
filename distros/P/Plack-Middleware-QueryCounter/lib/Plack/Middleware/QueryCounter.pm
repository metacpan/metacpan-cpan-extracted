package Plack::Middleware::QueryCounter;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";



1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::QueryCounter - query counter per request middleware

=head1 DESCRIPTION

Plack::Middleware::QueryCounter is query counter middleware.

Currently available counter is for DBI. see L<Plack::Middleware::QueryCounter::DBI>.

=head1 LICENSE

Copyright (C) Masatoshi Kawazoe (acidlemon).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masatoshi Kawazoe (acidlemon) E<lt>acidlemon@beatsync.netE<gt>

=cut

