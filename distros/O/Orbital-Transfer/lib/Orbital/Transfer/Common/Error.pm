use Modern::Perl;
package Orbital::Transfer::Common::Error;
# ABSTRACT: Common exceptions/errors for Orbital
$Orbital::Transfer::Common::Error::VERSION = '0.001';
use custom::failures qw/
	IO::FileNotFound
	Authorization
	Service::NotAvailable
	Retrieval::NotFound
	/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Orbital::Transfer::Common::Error - Common exceptions/errors for Orbital

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
