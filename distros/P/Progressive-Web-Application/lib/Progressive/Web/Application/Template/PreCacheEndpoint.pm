package Progressive::Web::Application::Template::PreCacheEndpoint;

use parent 'Progressive::Web::Application::Template::Base';

sub required_params { qw/cache_name offline_path precache_endpoint/ }

1;

__DATA__

@@ pwa.js

if ('serviceWorker' in navigator) {
	navigator.serviceWorker.getRegistrations().then(function (registrations) {
		navigator.serviceWorker.register('/service-worker.js').then(function (worker) {
			console.log('Service Worker Registered');
		});
	});
}

@@ service-worker.js

var cacheName = {cache_name};
var offlineFile = {offline_path};
var precache_endpoint = {precache_endpoint};

self.addEventListener('install', function (e) {
	e.waitUntil(
		caches.open(cacheName).then(function(cache) {i
			fetch(precache_endpoint).then(function(response) {
				// expects a JSON encode ARRAY of resource/endpoint urls
				return response.json();
			}).then(function(urls) {
				cache.add(offlineFile);
				return cache.addAll(urls);
			});
	     	})
	);
});

self.addEventListener('activate', function (e) {
	e.waitUntil(
		caches.keys().then(function(keyList) {
			return Promise.all(
				keyList.filter(function(cacheName) {}).map(function(key) {
					return caches.delete(key);
				})
			);
		})
	);
	return self.clients.claim();
});

self.addEventListener('fetch', function (e) {
	e.waitUntil(
		caches.open(cacheName).then(function(cache) {
			return cache.match(e.request).then(function (response) {
				return response || fetch(e.request).catch(function () {
					return caches.match(offlineFile);
				});
			});
		});
	);
});

__END__

=head1 NAME

Progressive::Web::Application::Template::PreCacheEndpoint - A Progressive::Web::Application Template, cache from endpoint then network and offline.

=cut

=head1 SYNOPSIS

	my $pwa = Progressive::Web::Application->new(
		template => 'PreCacheEndpoint',
		params => {
			offline_path => '/offline',
			cache_name => 'my-cache-name-v1',
			files_to_cache => [qw/.../],
		}
	);

=cut

=head1 Description

This template implements a cache from endpoint strategy.

An API request is made (precache_endpoint), this is expected to return an JSON ARRAY of resources/request uri's that would 
then be fetched and cached for use in later requests.

Foreach application request the service worker will first check in the cache whether a response is available to return, 
if one does not exists then the resource will be fetched from the network.

This template 'only' overwrites the default downasuar page a browser displays when a client loses network connectivity.

=cut

=head1 Methods

=head2 required_params

=over

=item offline_path

The offline endpoint that should be cached and retrieved when the client losses connectivity and the request is not retrievable from the cache.

=item cache_name

A cache name that is checked per 'active' state to ensure the client has the latest resources cached. If the cache name changes then the client will
clear the existing cache and re-fetch resources from the server.

=item precache_endpoint

An API endpoint which returns an array of files/resouDrces to pre-cache on install.

=back

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-progressive-web-application at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Progressive-Web-Application>.  I will be notifie
d, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

        perldoc Progressive::Web::Application

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Progressive-Web-Application>

=item * Search CPAN

L<http://search.cpan.org/dist/Progressive-Web-Application/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019->2025 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
