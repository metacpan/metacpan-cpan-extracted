use Modern::Perl;
package Renard::Incunabula::Common::Error;
# ABSTRACT: Exceptions
$Renard::Incunabula::Common::Error::VERSION = '0.004';
use custom::failures qw/
	Programmer::Logic
	IO::FileNotFound
	/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Common::Error - Exceptions

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

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
