package PSGI::Hector::Middleware;

=pod

=head1 NAME

PSGI::Hector::Middleware - Application middleware

=head1 SYNOPSIS

	PSGI::Hector::Middleware->wrap($app);

=head1 DESCRIPTION

Wraps the application in additional middleware.

=head1 METHODS

=cut

use strict;
use warnings;
use Plack::Builder;
#########################################################

=pod

=head2 wrap()

	PSGI::Hector::Middleware->wrap($app)

Adds the following middleware to the application:

Serving static files from "images", "js", "style" which are located in the "htdocs" directory. These
will be minified, cached and compressed in a production environment.

Non static files will only be compressed.

=cut

##################################

sub wrap{
	my($class, $app) = @_;
	
	builder{

		# ReverseProxy fixes scheme/host/port
		enable "ReverseProxy";

		# ReverseProxyPath uses new headers
		# fixes SCRIPT_NAME and PATH_INFO
		enable "ReverseProxyPath";

		#minify assets on production
		enable_if{$ENV{'ENV'} && $ENV{'ENV'} eq "production"} "Plack::Middleware::MCCS",
			path => qr{^/(images|js|style)/},
			root => './htdocs'
		;
		enable_if{!$ENV{'ENV'} || $ENV{'ENV'} ne "production"} "Static",
			path => qr{^/(images|js|style)/},
			root => './htdocs';
		;
		enable sub {
			my $app = shift;
			sub {
				my $env = shift;
				my $ua = $env->{HTTP_USER_AGENT} || '';
				# Netscape has some problem
				$env->{"psgix.compress-only-text/html"} = 1 if $ua =~ m!^Mozilla/4!;
				# Netscape 4.06-4.08 have some more problems
				$env->{"psgix.no-compress"} = 1 if $ua =~ m!^Mozilla/4\.0[678]!;
				# MSIE (7|8) masquerades as Netscape, but it is fine
				if ( $ua =~ m!\bMSIE (?:7|8)! ) {
					$env->{"psgix.no-compress"} = 0;
					$env->{"psgix.compress-only-text/html"} = 0;
				}
				$app->($env);
			}
		};
		
		enable "Deflater",
			content_type => ['text/css','text/html','text/javascript','application/javascript', 'application/json'],
			vary_user_agent => 1;
		$app;
	};
}
###########################################################

=pod

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 See Also

L<Plack::Middleware::Static::Minifier> L<Plack::Middleware::Static> L<Plack::Middleware::Deflater>

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
##################################
return 1;