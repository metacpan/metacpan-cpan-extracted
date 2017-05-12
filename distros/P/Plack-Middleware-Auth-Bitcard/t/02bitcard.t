=pod

=encoding utf-8

=head1 PURPOSE

Given that bitcard.org is a third-party, it's hard to thoroughly test that
this module works. This it the best automated workout I've been able to
manage.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Authen::Bitcard;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Request;
use Plack::Test;
use URI;
use URI::QueryParam;

my $app = sub {
	my $env = shift;
	[ 200, [ Content_Type => "text/plain" ], ["OK"] ];
};

my $bc = "Authen::Bitcard"->new;
$bc->token( 1234 );
$bc->api_secret( 12345678 );

test_psgi
	app => builder {
		enable "Auth::Bitcard",
			bitcard => $bc,
			skip_if => sub { my $r = "Plack::Request"->new(@_); $r->path =~ m{^/?public/} };
		$app;
	},
	client => sub {
		my $cb  = shift;
		
		subtest "Protected URL" => sub
		{
			plan tests => 3;
			my $res = $cb->(GET "/private/");
			is($res->code, 302, "Response status is HTTP 302 Found");
			my $uri = URI->new(scalar $res->header("Location"));
			like($uri->host, qr{bitcard.org$}, "Response redirects to bitcard.org");
			like(scalar($uri->query_param("bc_r")), qr{/_bitcard_boomerang}, "Looks like bitcard.org will redirect back OK");
		};
		
		subtest "Public URL" => sub
		{
			plan tests => 2;
			my $res = $cb->(GET "/public/");
			is($res->code, 200, "Response status is HTTP 200 OK");
			is($res->content, "OK", "Reponse body OK");
		};
	};

done_testing;
