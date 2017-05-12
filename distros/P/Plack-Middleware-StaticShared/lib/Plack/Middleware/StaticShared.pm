package Plack::Middleware::StaticShared;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Request;
use LWP::Simple qw($ua);
use Digest::SHA1 qw(sha1_hex);
use DateTime::Format::HTTP;
use DateTime;
use Path::Class;

our $VERSION = '0.06';

__PACKAGE__->mk_accessors(qw(cache base binds verifier));

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
}

sub call {
	my ($self, $env) = @_;
	for my $static (@{ $self->binds }) {
		my $prefix = $static->{prefix};
		# Some browsers (eg. Firefox) always access if the url has query string,
		# so use `:' for parameters
		my ($version, $files) = ($env->{PATH_INFO} =~ /^$prefix:([^:\s]{1,32}):(.+)$/) or next;
		my $req = Plack::Request->new($env);
		my $res = $req->new_response;

		if ($self->verifier && !$self->verifier->(local $_ = $version, $prefix)) {
			$res->code(400);
			return $res->finalize;
		}

		my $key = join(':', $version, $files);
		my $etag = sha1_hex($key);

		if ($req->header('If-None-Match') || '' eq $etag) {
			# Browser cache is avaialable but force reloaded by user.
			$res->code(304);
		} else {
			my $content = eval {
				my $ret = $self->cache->get($etag);
				if (not defined $ret) {
					$ret = $self->concat(split /,/, $files);
					$ret = $static->{filter}->(local $_ = $ret) if $static->{filter};
					$self->cache->set($etag => $ret);
				}
				$ret;
			};

			if ($@) {
				$res->code(503);
				$res->header('Retry-After' => 10);
				$res->content($@);
			} else {
				# Cache control:
				# IE requires both Last-Modified and Etag to ignore checking updates.
				$res->code(200);
				$res->header("Cache-Control" => "public; max-age=315360000; s-maxage=315360000");
				$res->header("Expires" => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years => 10)));
				$res->header("Last-Modified" => DateTime::Format::HTTP->format_datetime(DateTime->from_epoch(epoch => 0)));
				$res->header("ETag" => $etag);
				$res->content_type($static->{content_type});
				$res->content($content);
			}
		}

		return $res->finalize;
	}

	$self->app->($env);
}

sub concat {
	my ($self, @files) = @_;
	my $base = dir($self->base);

	my $concat = '';
	for my $f (@files) {
		my $file = $base->file($f);
		next unless -e $file;

		$file->resolve;
		next unless $base->contains($file);

		$concat .= $file->slurp;
	}

	return $concat;
}

1;
__END__

1;
__END__

=head1 NAME

Plack::Middleware::StaticShared - concat some static files to one resource

=head1 SYNOPSIS

  use Plack::Builder;
  use WebService::Google::Closure;

  builder {
      enable "StaticShared",
          cache => Cache::Memcached::Fast->new(servers => [qw/192.168.0.11:11211/]),
          base  => './static/',
          binds => [
              {
                  prefix       => '/.shared.js',
                  content_type => 'text/javascript; charset=utf8',
                  filter       => sub {
                      WebService::Google::Closure->new(js_code => $_)->compile->code;
                  }
              },
              {
                  prefix       => '/.shared.css',
                  content_type => 'text/css; charset=utf8',
              }
          ];
          verifier => sub {
              my ($version, $prefix) = @_;
              $version =~ /v\d/
          },

      $app;
  };

And concatnated resources are provided as like following:

  /.shared.js:v1:/js/foolib.js,/js/barlib.js,/js/app.js
      => concat following: ./static/js/foolib.js, ./static/js/barlib.js, ./static/js/app.js

=head1 DESCRIPTION

Plack::Middleware::StaticShared provides resource end point which concat some static files to one resource for reducing http requests.

=head1 CONFIGURATIONS

=over 4

=item cache (required)

A cache object for caching concatnated resource content.

=item base (required)

Base directory which concatnating resource located in.

=item binds (required)

Definition of concatnated resources.

=item verifier (optional)

A subroutine for verifying version string to avoid attacking of cache flooding.

=back

=head1 AUTHOR

cho45

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Builder>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

