package GroupedSections;

use strict;
use warnings;

use Mojo::Base 'Mojolicious';

sub startup {
	my $self = shift;

	$self->plugin('Buffer');

	my $r = $self->routes;

	$r->get('/' => sub { shift->redirect_to('/docs/intro') });

	# A static section: every page below this route is written by hand and
	# never changes between requests, so the white space and the comments can
	# go.  One declaration covers the whole namespace.
	my $docs = $r->under('/docs')->to(optimise_content => 1);
	$docs->get('/intro' => sub {
		shift->render(template => 'docs/page', title => 'Introduction');
	})->name('docs_intro');
	$docs->get('/install' => sub {
		shift->render(template => 'docs/page', title => 'Installation');
	})->name('docs_install');

	# These assets are built by the application rather than streamed from
	# disk, so the plugin sees them.  They are already minified and the
	# reverse proxy in front of the app compresses them, so the application
	# leaves the bytes alone: one cacheable copy per URL, not one per content
	# coding.  The declaration is in the controller, for the whole namespace.
	$r->get('/assets/app.css')->to('assets#css');
	$r->get('/assets/app.js')->to('assets#js');

	return;
}

package GroupedSections::Controller::Assets;

use Mojo::Base 'Mojolicious::Controller';

# Declared once for every action in this controller
has buffer_compress_content => 0;

my $CSS = '.card{background:#fff;border:1px solid #ddd;padding:1rem}'
	. '.card h2{font-size:1rem;margin:0 0 .5rem}'
	. '@media (prefers-color-scheme:dark){.card{background:#111;border-color:#333;color:#eee}}';

my $JS = 'document.addEventListener("DOMContentLoaded",function(){'
	. 'document.querySelectorAll("[data-toggle]").forEach(function(el){'
	. 'el.addEventListener("click",function(){'
	. 'var target=document.getElementById(el.dataset.toggle);'
	. 'if(target){target.hidden=!target.hidden}'
	. '})})});';

sub css {
	my $c = shift;

	$c->res->headers->cache_control('public, max-age=86400');

	return $c->render(data => $CSS, format => 'css');
}

sub js {
	my $c = shift;

	$c->res->headers->cache_control('public, max-age=86400');

	return $c->render(data => $JS, format => 'js');
}

1;
