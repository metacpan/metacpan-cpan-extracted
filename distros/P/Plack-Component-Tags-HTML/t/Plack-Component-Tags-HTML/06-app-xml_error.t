use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;

package App;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

sub _tags_middle {
	my $self = shift;

	$self->{'tags'}->put(
		['b', 'error'],
		['d', 'Error message.'],
		['e', 'error'],
	);

	return;
}

package main;

use HTTP::Request::Common;
use Plack::Test;

my $app = App->new(
	'content_type' => 'application/xml',
	'encoding' => 'UTF-8',
	'flag_begin' => 0,
	'flag_end' => 0,
	'status_code' => 400,
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 400, 'HTTP code (400).');
	is($res->header('Content-Type'), 'application/xml', 'Content type (XML).');
	is($res->content, '<error>Error message.</error>', 'Content (XML error).');
});
