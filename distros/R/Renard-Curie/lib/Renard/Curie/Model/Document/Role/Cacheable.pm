use Renard::Curie::Setup;
package Renard::Curie::Model::Document::Role::Cacheable;
# ABSTRACT: Role that caches rendered pages
$Renard::Curie::Model::Document::Role::Cacheable::VERSION = '0.001';
use Moo::Role;
use Renard::Curie::Types qw(InstanceOf);

use CHI;

has render_cache => (
	is => 'lazy', # _build_render_cache
	isa => InstanceOf['CHI::Driver'],
);

sub _build_render_cache {
	CHI->new( driver => 'RawMemory', global => 0 );
}

requires 'get_rendered_page';
around get_rendered_page => sub {
	my $orig = shift;
	my ($self, %rest) = @_;
	my @args = @_;
	return $self->render_cache->compute(
		\%rest,
		'never',
		sub { $orig->(@args); }
	);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Document::Role::Cacheable - Role that caches rendered pages

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 render_cache

Holds an in-memory cache of the rendered pages.

See L<CHI> and L<CHI::Driver::RawMemory> for more information.

=head1 METHODS

=head2 get_rendered_page

  around get_rendered_page

A method modifier that caches the results of C<get_rendered_page>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
