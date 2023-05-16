use 5.024000;
use strict;
use warnings;

package Story::Interact::WWW;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001006';

use constant DISTRIBUTION => 'Story-Interact-WWW';

use Digest::SHA qw( sha256_hex );
use Mojo::ShareDir;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Util qw( xml_escape );
use Nanoid ();
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
	
	my $get_session = sub ( $self, $c ) {
		my $db  = $self->config( 'database' ) or return undef;
		my $sth = $db->prepare( 'SELECT u.id, u.username, u.email, u.created, s.id AS session_id, s.token AS session FROM user u INNER JOIN session s ON u.id=s.user_id WHERE s.token=?' );
		$sth->execute( ref($c) ? ( $c->req->param('session') // $c->req->json->{session} ) : $c );
		if ( my $row = $sth->fetchrow_hashref ) {
			my $sth2 = $db->prepare( 'UPDATE session SET last_access=? WHERE id=?' );
			$sth2->execute( $row->{session_id}, scalar(time) );
			return $row;
		}
		return undef;
	};
	
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
				$c->stash->{api}            = $c->url_for('/api');
				$c->stash->{story_id}       = $story_id;
				$c->stash->{title}          = $story_config->{title}       // 'Story';
				$c->stash->{storage_key}    = $story_config->{storage_key} // $story_id;
				$c->stash->{server_storage} = !!$self->config( 'database' );
				$c->stash->{server_signups} = !!$self->config( 'open_signups' );
				$c->render( template => $story_config->{template} // 'story' );
			},
		)->name( 'story' );
	}
	
	# API endpoint to get a blank slate state
	{
		$self->routes->get( '/api/state/init' )->to(
			cb => sub ( $c ) {
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
			cb => sub ( $c ) {
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
				
				local $Story::Interact::SESSION;
				local $Story::Interact::DATABASE;
				
				if ( $c->req->json->{session} ) {
					$Story::Interact::SESSION  = $self->$get_session( $c );
					$Story::Interact::DATABASE = $self->config( 'database' );
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

	# API endpoint for user creation
	{
		$self->routes->post( '/api/user/init' )->to(
			cb => sub ( $c ) {
				$self->config( 'open_signups' ) or die;
				
				my $db = $self->config( 'database' ) or die;
				my $u  = $c->req->json->{username};
				my $p  = $c->req->json->{password} or die;
				my $e  = $c->req->json->{email};
				
				my $hash = sha256_hex( sprintf( '%s:%s', $u, $p ) );
				my $sth = $db->prepare( 'INSERT INTO user ( username, password, email, created ) VALUES ( ?, ?, ?, ? )' );
				if ( $sth->execute( $u, $hash, $e, scalar(time) ) ) {
					my $id = $db->last_insert_id;
					my $session_id = Nanoid::generate();
					my $sth = $db->prepare( 'INSERT INTO session ( user_id, token, last_access ) VALUES ( ?, ?, ? )' );
					$sth->execute( $id, $session_id, scalar(time) );
					$c->render( json => { session => $session_id, username => $u } );
				}
				else {
					$c->render( json => { error => 'User creation error' } );
				}
			},
		)->name( 'api-user-init' );
	}

	# API endpoint for logins
	{
		$self->routes->post( '/api/session/init' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $u  = $c->req->json->{username};
				my $p  = $c->req->json->{password};
				
				my $hash = sha256_hex( sprintf( '%s:%s', $u, $p ) );
				my $sth = $db->prepare( 'SELECT id, username FROM user WHERE username=? AND password=?' );
				$sth->execute( $u, $hash );
				if ( my $row = $sth->fetchrow_hashref ) {
					my $session_id = Nanoid::generate();
					my $sth = $db->prepare( 'INSERT INTO session ( user_id, token, last_access ) VALUES ( ?, ?, ? )' );
					$sth->execute( $row->{id}, $session_id, scalar(time) );
					$c->render( json => { session => $session_id, username => $u } );
				}
				else {
					$c->render( json => { error => 'Authentication error' } );
				}
			},
		)->name( 'api-session-init' );
	}

	# API endpoint for logout
	{
		$self->routes->post( '/api/session/destroy' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $session = $self->$get_session( $c );
				my $sth = $db->prepare( 'DELETE FROM session WHERE id=? AND token=? AND user_id=?' );
				$sth->execute( $session->{session_id}, $session->{session}, $session->{id} );
				$c->render( json => { session => \0 } );
			},
		)->name( 'api-session-destroy' );
	}

	# API endpoints for bookmarks
	{
		$self->routes->get( '/api/story/:story/bookmark' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $story_id = $c->stash( 'story' );
				my $session = $self->$get_session( $c );
				my $sth = $db->prepare( 'SELECT slug, label, created, modified FROM bookmark WHERE user_id=? AND story=?' );
				$sth->execute( $session->{id}, $story_id );
				my @results;
				while ( my $row = $sth->fetchrow_hashref ) {
					push @results, $row;
				}
				$c->render( json => { bookmarks => \@results } );
			},
		)->name( 'api-story-bookmark' );
		
		$self->routes->post( '/api/story/:story/bookmark' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $story_id = $c->stash( 'story' );
				my $session = $self->$get_session( $c );
				my $slug = Nanoid::generate( size => 14 );
				my $label = $c->req->json->{label} // 'Unlabelled';
				my $data = $c->req->json->{stored_data} or die;
				my $now = time;
				my $sth = $db->prepare( 'INSERT INTO bookmark ( user_id, story, slug, label, created, modified, stored_data ) VALUES ( ?, ?, ?, ?, ?, ?, ? )' );
				if ( $sth->execute( $session->{id}, $story_id, $slug, $label, $now, $now, $data ) ) {
					$c->render( json => { slug => $slug, label => $label, created => $now, modified => $now } );
				}
				else {
					$c->render( json => { error => 'Error storing bookmark data' } );
				}
			},
		)->name( 'api-story-bookmark-post' );
		
		$self->routes->get( '/api/story/:story/bookmark/:slug' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $story_id = $c->stash( 'story' );
				my $slug = $c->stash( 'slug' );
				my $session = $self->$get_session( $c );
				my $sth = $db->prepare( 'SELECT slug, label, created, modified, stored_data FROM bookmark WHERE story=? AND slug=?' );
				$sth->execute( $story_id, $slug );
				if ( my $row = $sth->fetchrow_hashref ) {
					$c->render( json => $row );
				}
				else {
					$c->render( json => { error => 'Bookmark not found' } );
				}
			},
		)->name( 'api-story-bookmark-slug' );
		
		$self->routes->post( '/api/story/:story/bookmark/:slug' )->to(
			cb => sub ( $c ) {
				my $db = $self->config( 'database' ) or die;
				my $story_id = $c->stash( 'story' );
				my $slug = $c->stash( 'slug' );
				my $session = $self->$get_session( $c );
				if ( $c->req->json->{stored_data} ) {
					my $sth = $db->prepare( 'UPDATE bookmark SET modified=?, stored_data=? WHERE user_id=? AND story=? AND slug=?' );
					if ( $sth->execute( scalar(time), $c->req->json->{stored_data}, $session->{id}, $story_id, $slug ) ) {
						$c->render( json => {} );
					}
					else {
						$c->render( json => { error => 'Error storing bookmark data' } );
					}
				}
				else {
					my $sth = $db->prepare( 'DELETE FROM bookmark WHERE user_id=? AND story=? AND slug=?' );
					if ( $sth->execute( $session->{id}, $story_id, $slug ) ) {
						$c->render( json => {} );
					}
					else {
						$c->render( json => { error => 'Error removing bookmark data' } );
					}
				}
			},
		)->name( 'api-story-bookmark-slug-post' );
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
