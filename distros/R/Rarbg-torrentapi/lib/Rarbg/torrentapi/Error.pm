package Rarbg::torrentapi::Error;

use strict;
use 5.008_005;
our $VERSION = 'v0.1.1';
use Moose;

has 'error' => (
    is  => 'ro',
    isa => 'Str'
);

has 'error_code' => (
    is  => 'ro',
    isa => 'Int'
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf-8

=head1 NAME

Rarbg::torrentapi::Error - Error response class for Rarbg::torrentapi

=head1 DESCRIPTION

This is not meant to be used directly, see Rarbg::torrentapi

=head1 AUTHOR

Paco Esteban E<lt>paco@onna.beE<gt>

=head1 COPYRIGHT

Copyright 2015- Paco Esteban

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
