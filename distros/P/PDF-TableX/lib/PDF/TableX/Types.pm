package PDF::TableX::Types;

use MooseX::Types -declare => [qw/StyleDefinition/];
use MooseX::Types::Moose qw/ArrayRef Any/;

subtype StyleDefinition, as ArrayRef;
coerce StyleDefinition, from Any, via {
	[$_,$_,$_,$_];
};

1;

=head1 NAME

PDF::TableX::Types

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
