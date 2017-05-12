package SVG::Convert::BaseDriver;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/parser/);

use Carp::Clan;

=head1 NAME

SVG::Convert::BaseDriver - Base class for SVG::Convert drivers

=head1 VERSION

version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

=head1 METHODS

=head2 convert_string

=cut

sub convert_string {
    croak('Not implements this method');
}

=head2 convert_file

=cut

sub convert_file {
    croak('Not implements this method');
}

=head2 convert_doc

=cut

sub convert_doc {
    croak('Not implements this method');
}

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svg-convert-basedriver@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SVG::Convert::BaseDriver
