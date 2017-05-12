package Template::Parser::LocalizeNewlines;

=pod

=head1 NAME

Template::Parser::LocalizeNewlines - Drop-in replacement Template::Parser that
fixes bad newlines

=head1 DESCRIPTION

L<Template::Parser> has a problem with PRE_CHOMP and related options. They
only work on local newlines. If a Template Toolkit instance on a Unix host
encounters DOS newlines in a Template, it will fail to chomp the newline
correctly, with potentially disasterous results.

B<Template::Parser::LocalizeNewlines> is a drop-in replacement that behaves
EXACTLY the same (and is a subclass of) as a normal parser, except that
before it goes to parse the template content, it applies the newline
localisation regex describes in L<http://ali.as/devel/newlines.html>.

=head2 Using this Module

When creating your Template instance, simple pass an instance of this object
along to the constructor.

=cut

use 5.005;
use strict;
use base 'Template::Parser';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.04';
}

# The only method we need to change
sub parse {
	my $self = shift;
	my $text = shift;

	# Localise the newlines
	$text =~ s/(?:\015{1,2}\012|\015|\012)/\n/gs;

	# Pass off to the normal parser
	$self->SUPER::parse( $text, @_ );
}

1;

=pod

=head1 METHODS

This module is identical to L<Template::Parser>.

=head1 SUPPORT

Bugs should be reported via the following link.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Parser-LocalizeNewlines>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
