use 5.024000;
use strict;
use warnings;

package Story::Interact::WWW;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001004';

use constant DISTRIBUTION => 'Story-Interact-WWW';

use Mojo::ShareDir;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Util qw( xml_escape );
use Story::Interact::State ();
use Text::Markdown::Hoedown;

sub startup ( $self ) {

	$self->log->info( 'Story::Interact::State->VERSION = ' . Story::Interact::State->VERSION );

	$self->secrets( [ __PACKAGE__ . '/' . $VERSION ] );

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

	# Story list
	{
		$self->routes->get( '/' )->to(
			cb => sub ($c) {
				my $stories = $self->config( 'story' );
				my @keys = sort {
					( $stories->{$a}{title} // 'Story' ) cmp ( $stories->{$b}{title} // 'Story' )
				} keys %$stories;
				my $html = '<ul class="list-group">';
				for my $k ( @keys ) {
					$html .= sprintf(
						'<li class="list-group-item"><a href="%s">%s</a></li>',
						xml_escape( $c->url_for( "/story/$k" ) ),
						xml_escape( $stories->{$k}{title} ),
					);
				}
				$html .= '</ul>';
				$c->stash->{title} = 'Stories';
				$c->stash->{story_list} = $html;
				$c->render( template => 'index' );
			},
		)->name( 'index' );
	}

	# HTML + JavaScript story harness
	{
		$self->routes->get( '/story/:story' )->to(
			cb => sub ($c) {
				my $story_id     = $c->stash( 'story' );
				my $story_config = $self->config( 'story' )->{$story_id};
				$c->stash->{api}          = $c->url_for('/api');
				$c->stash->{story_id}     = $story_id;
				$c->stash->{title}        = $story_config->{title}       // 'Story';
				$c->stash->{storage_key}  = $story_config->{storage_key} // $story_id;
				$c->render( template => $story_config->{template} // 'story' );
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
		my $render_html = sub ( $page ) {
			my $markdown = join "\n\n", @{ $page->text };
			return markdown( $markdown );
		};
		$self->routes->post( '/api/story/:story/page/:page' )->to(
			cb => sub ($c) {
				my $story_id     = $c->stash( 'story' );
				my $page_id      = $c->stash( 'page' );
				$c->log->info("Request for page `$page_id` from story `$story_id`");
				my $story_config = $self->config( 'story' )->{$story_id};
				my $page_source  = $story_config->{page_source};
				my $munge_state  = $story_config->{state_munge} // sub {};
				my $munge        = $story_config->{data_munge}  // sub {};
				my $state = Story::Interact::State->load( $c->req->json( '/state' ) );
				$munge_state->( $c, $state );
				
				if ( $page_id =~ /\A(.+)\?(.+)\z/ms ) {
					$page_id = $1;
					require URI::Query;
					my $params = URI::Query->new( $2 )->hash;
					$state->params( $params );
				}
				else {
					$state->params( {} );
				}
				
				my $page = $page_source->get_page( $state, $page_id );
				my %data = (
					%$page,
					state => $state->dump,
					html  => $render_html->( $page ),
				);
				$munge->( \%data, $page, $state );
				$c->render( json => \%data );
			},
		)->name( 'api-story-page' );
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

This is a companion to L<Story::Interact>, providing a browser-based
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
