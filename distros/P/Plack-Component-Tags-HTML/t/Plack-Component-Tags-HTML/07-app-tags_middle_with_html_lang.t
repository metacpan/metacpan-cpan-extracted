use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;

package App;

use base qw(Plack::Component::Tags::HTML);
use strict;
use warnings;

use Unicode::UTF8 qw(decode_utf8);

sub _tags_middle {
	my $self = shift;

	$self->{'tags'}->put(
		['d', decode_utf8('Ahoj světe')],
	);

	return;
}

package main;

use HTTP::Request::Common;
use Plack::Test;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $app = App->new(
	'css_init' => [],
	'html_lang' => 'cs',
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $expected_content = '<!DOCTYPE html>'."\n".'<html lang="cs"><head><meta http-equiv="Content-Type" '.
		'content="text/html; charset=utf-8" />'.
		'<meta name="viewport" content="width=device-width, initial-scale=1.0" />'.
		'</head><body>Ahoj světe</body></html>';
	is($res->content, $expected_content, 'Content (real HTML content).');
});
