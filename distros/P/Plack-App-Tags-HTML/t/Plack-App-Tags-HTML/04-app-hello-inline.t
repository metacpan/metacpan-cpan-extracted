use strict;
use warnings;

package Hello;

use base qw(Tags::HTML);
use strict;
use warnings;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# No CSS support.
	push @params, 'no_css', 1;

	my $self = $class->SUPER::new(@params);

	# Object.
	return $self;
}
	
sub _process {
	my $self = shift;

	$self->{'tags'}->put(
		['d', 'Hello world'],
	);

	return;
}

package main;

use HTTP::Request::Common;
use Plack::App::Tags::HTML;
use Plack::Test;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $app = Plack::App::Tags::HTML->new(
	'component' => 'Hello',
);
test_psgi($app, sub {
	my $cb = shift;

	my $res = $cb->(GET "/");
	is($res->code, 200, 'HTTP code (200).');
	is($res->header('Content-Type'), 'text/html; charset=utf-8', 'Content type (HTML).');
	my $right_content = <<'END';
<!DOCTYPE html>
<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /></head><body>Hello world</body></html>
END
	chomp $right_content;
	is($res->content, $right_content, 'Content (hello world html page).');
});
