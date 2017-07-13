use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::Cacheable;
# ABSTRACT: Role that caches rendered pages
$Renard::Incunabula::Document::Role::Cacheable::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(InstanceOf);

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

	# make sure to call in a scalar context
	my $return = $self->render_cache->compute(
		\%rest,
		'never',
		sub { $orig->(@args); }
	);

	$return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::Cacheable - Role that caches rendered pages

=head1 VERSION

version 0.003

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

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
