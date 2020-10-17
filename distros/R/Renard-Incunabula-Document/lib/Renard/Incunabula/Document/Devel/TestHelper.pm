use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Devel::TestHelper;
# ABSTRACT: A helper library for document tests
$Renard::Incunabula::Document::Devel::TestHelper::VERSION = '0.005';
use Moo;

classmethod create_null_document( :$repeat = 1 ) {
	require Renard::Incunabula::Document::Null;
	require Renard::Incunabula::Page::Null;

	my $null_doc = Renard::Incunabula::Document::Null->new(
		pages => [
			map {
				Renard::Incunabula::Page::Null->new;
			} 0..$repeat*4-1
		],
	);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Devel::TestHelper - A helper library for document tests

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CLASS METHODS

=head2 create_null_document

  Renard::Incunabula::Document::Devel::TestHelper->create_null_document

Returns a L<Renard::Incunabula::Document::Null> which can be used for testing.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
