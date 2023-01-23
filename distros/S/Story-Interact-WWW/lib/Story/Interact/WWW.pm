use 5.024000;
use strict;
use warnings;

package Story::Interact::WWW;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

use constant DISTRIBUTION => 'Story-Interact-WWW';

use Mojo::ShareDir;
use Mojo::Base 'Mojolicious', -signatures;
use Story::Interact::State ();
use Text::Markdown::Hoedown;

sub startup ( $self ) {

	# Setup app config, paths, etc.
	$self->plugin( 'Config', { file => 'si_www.conf' } );
	unshift(
		$self->static->paths->@*,
		$self->home->rel_file( 'local/public' ),
		Mojo::ShareDir->new( DISTRIBUTION, 'public' ),
	);
	unshift(
		$self->renderer->paths->@*,
		$self->home->rel_file( 'local/templates' ),
		Mojo::ShareDir->new( DISTRIBUTION, 'templates' ),
	);

	# HTML + JavaScript story harness
	{
		$self->routes->get( '/story' )->to(
			cb => sub ($c) {
				$c->stash->{api}          = $c->url_for('/api');
				$c->stash->{title}        = $self->config( 'title' ) // 'Story';
				$c->stash->{storage_key}  = $self->config( 'storage_key' ) // 'story1';
				$c->render( template => 'story' );
			},
		)->name( 'story' );
	}

	# API endpoint to get a blank slate state
	{
		$self->routes->get( '/api/state/init' )->to(
			cb => sub ($c) {
				my $blank = Story::Interact::State->new;
				$c->render( json => { state => $blank->dump } );
			},
		)->name( 'api-state-init' );
	}

	# API endpoint to read a page
	{
		my $page_source = $self->config( 'page_source' );
		my $munge       = $self->config( 'data_munge' ) // sub {};
		my $render_html = sub ( $page ) {
			my $markdown = join "\n\n", @{ $page->text };
			return markdown( $markdown );
		};
		$self->routes->post( '/api/page/:page' )->to(
			cb => sub ($c) {
				my $state = Story::Interact::State->load( $c->req->json( '/state' ) );
				my $page = $page_source->get_page( $state, $c->stash( 'page' ) );
				my %data = (
					%$page,
					state => $state->dump,
					html  => $render_html->( $page ),
				);
				$munge->( \%data, $page, $state );
				$c->render( json => \%data );
			},
		)->name( 'api-page' );
	}

	# Done!
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Story::Interact::WWW - mojolicious app to read interactive stories

=head1 DESCRIPTION

This is a companiion to L<Story::Interact>, providing a browser-based
reader for interactive stories.

It is provided as-is with almost zero documentation or tests. Use at
your peril. :)

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-story-interact-www/issues>.

=head1 SEE ALSO

L<Story::Interact>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
