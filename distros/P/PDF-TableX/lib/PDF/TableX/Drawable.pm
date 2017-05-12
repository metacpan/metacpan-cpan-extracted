package PDF::TableX::Drawable;

use Moose::Role;

requires 'draw_content';
requires 'draw_borders';
requires 'draw_background';

1;

=head1 NAME

PDF::TableX::Drawable

=head1 VERSION

 TODO

=head1 AUTHOR

Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests at: L<https://github.com/grzegorzpapkala/PDF-TableX/issues>

=head1 SUPPORT

PDF::TableX is hosted on GitHub L<https://github.com/grzegorzpapkala/PDF-TableX>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2013 Grzegorz Papkala, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
