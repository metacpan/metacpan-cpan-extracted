use Modern::Perl;
package Renard::Curie::Error;
# ABSTRACT: Exceptions for Curie
$Renard::Curie::Error::VERSION = '0.004';
use custom::failures qw/
	User::InvalidPageNumber
	ViewOptions::InvalidGridOptions
	/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Error - Exceptions for Curie

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<failure>

=item * L<failure>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
