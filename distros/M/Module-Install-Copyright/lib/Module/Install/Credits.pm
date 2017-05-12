package Module::Install::Credits;

use 5.006;
use base qw(Module::Install::Base);
use strict;

our $AUTHOR_ONLY = 1;
our $AUTHORITY   = 'cpan:TOBYINK';
our $VERSION     = '0.009';

sub write_credits_file
{
	my $self = shift;
	$self->admin->write_credits_file(@_) if $self->is_admin;
}

1;

__END__

=head1 NAME

Module::Install::Credits - package a CREDITS file with a distribution

=head1 SYNOPSIS

In Makefile.PL:

	write_credits_file;

=head1 DESCRIPTION

Extracts copyright and licensing information from RDF metadata included in
the distribution, and outputs it as a text file called "CREDITS".

This module provides one function for use in L<Module::Install>-based
Makefile.PL scripts:

=over

=item C<< write_credits_file >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Module-Install-Copyright>.

=head1 SEE ALSO

This is a plugin for L<Module::Install>.

It relies on metadata from L<Module::Install::RDF>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

