package Mojolicious::Plugin::TagHelpers::NoCaching;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::URL;
use File::Spec;
use Cwd;

our $VERSION = '0.05';

sub register {
	my ($plugin, $app, $cfg) = @_;
	
	$cfg->{key} = 'nc' unless defined $cfg->{key};
	
	$plugin->{url2path} = {};
	$plugin->{path2key} = {};
	$plugin->{cfg}      = $cfg;
	
	$app->helper(stylesheet_nc => sub {
		my $self = shift;
		
		if (@_ % 2) {
			# this is css url
			my $href = $plugin->_nc_href($self, shift);
			unshift @_, $href;
		}
		
		$self->stylesheet(@_);
	});
	
	$app->helper(javascript_nc => sub {
		my $self = shift;
		
		if (@_ % 2) {
			# this is script url
			my $href = $plugin->_nc_href($self, shift);
			unshift @_, $href;
		}
		
		$self->javascript(@_);
	});
	
	$app->helper(image_nc => sub {
		my $self = shift;
		
		my $href = $plugin->_nc_href($self, shift);
		unshift @_, $href;
		
		$self->image(@_);
	});
}

sub _href2absolute {
	my ($controller, $href) = @_;
	
	$href =~ s/\?.+//; # query params
	if ($href =~ m!^(?:/|[a-z]+://)!i) {
		# absolute
		return $href;
	}
	
	my $path = $controller->req->url->path;
	$path =~ s![^/]+$!!;
	$path = '/' if $path eq '';
	$href = $path . $href;
	
	return $href;
}

sub _href2filepath {
	my ($controller, $href) = @_;
	
	if ($href =~ m!^[a-z]+://!i) {
		my $url   = Mojo::URL->new($href);
		my $c_url = $controller->req->url->to_abs;
		
		if ($url->host ne $c_url->host) {
			# external url
			return;
		}
		
		$href = $url->path;
	}
	
	my $static =$controller->app->static;
	my $asset = $static->file($href)
		or return;
	
	$asset->is_file
		or return;
	
	my $path = File::Spec->canonpath(Cwd::realpath($asset->path)||return);
	my $ok;
	for my $p (@{$static->paths}) {
		$ok = index($path, $p) == 0
			and last;
	}
	# check is found file is inside public directory
	$ok or return;
	
	return $path;
}

sub _nc_key {
	my ($self, $path) = @_;
	return (stat($path))[9];
}

sub _nc_href {
	my ($self, $controller, $href) = @_;
	
	my $abs_href = _href2absolute($controller, $href);
	
	unless (exists $self->{url2path}{$abs_href}) {
		$self->{url2path}{$abs_href} = _href2filepath($controller, $abs_href);
	}
	
	my $path = $self->{url2path}{$abs_href}
		or return $href;
	
	unless (exists $self->{path2key}{$path}) {
		$self->{path2key}{$path} = $self->_nc_key($path);
	}
	
	my $key = $self->{path2key}{$path}
		or return $href;
	
	$href .= index($href, '?') == -1 ?  '?' : '&';
	$href .= $self->{cfg}{key} . '=' . $key;
	
	# fix for https://github.com/kraih/mojo/issues/565
	return Mojo::URL->new($href);
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::TagHelpers::NoCaching - Force images, styles, js reloading by the browser if they were modified on filesystem

=head1 SYNOPSIS

    use Mojolicious::Lite;
    
    plugin 'TagHelpers::NoCaching', {key => 'v'};
    
    get '/' => 'index';
    
    __DATA__
    
    @@index.html.ep
    <html>
        <head>
            %= javascript_nc "/js/app.js"
            %= stylesheet_nc "/css/app.css"
        </head>
        <body>
            My greate photo:<br>
            %= image_nc "/img/avatar.jpg"
        </body>
    </html>

=head1 DESCRIPTION

When you updating your project on production server with new version, new version often contains changed styles, javascript, images.
You fetched all new files from the repository, restarted application, but browsers still shows you old images, your html looks like
a shit (because of the old styles on new html), javascript events doesn't work (because of the old js in use). All of this because your
browser cached old version of included files and don't want to reload it.

If you ever come across this, this module will help you.

=head1 HOW IT WORKS

This plugin contains several helpers described below. All this helpers are alternatives for helpers with same name (but without _nc suffix)
from L<Mojolicious::Plugin::TagHelpers>. "_nc" suffix in helpers names means "no caching". Behaviour of this helpers are identical except
that helpers from this module adds query parameter with file version for each file included with help of them. For now query 
parameter is modification time of the file. So we can guarantee that when file will be modified query parameter will be changed and file will be reloaded by
the browser on next request. This works only for server local files included with absolute url ("http://host/file.css"), absolute path ("/file.css") or relative path ("file.css").
And they will become something like "http://host/file.css?nc=1384766621", "/file.css?nc=1384766621", "file.css"?nc=1384766621" respectively.

One important thing is that query parameter for modified file will be changed only after application reload, because modification time for included files
will be cached to be more efficient. This shouldn't be big problem, because when you updating your app with new version you also changed your
perl files and should reload application. Or if you are on development morbo server it will reload application for you.

=head1 CONFIGURATION

Config for plugin accepts this options

=head2 key

Which query key should be used. Default is "nc".

=head1 HELPERS

Mojolicious::Plugin::TagHelpers::NoCaching implements the following helpers

=head2 javascript_nc "url_or_path"

Same as L<javascript|Mojolicious::Plugin::TagHelpers/javascript>, but will add query key and value to prevent caching

=head2 stylesheet_nc "url_or_path"

Same as L<stylesheet|Mojolicious::Plugin::TagHelpers/stylesheet>, but will add query key and value to prevent caching

=head2 image_nc "url_or_path"

Same as L<image|Mojolicious::Plugin::TagHelpers/image>, but will add query key and value to prevent caching

=head1 SEE ALSO

L<Mojolicious::Plugin::TagHelpers>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
