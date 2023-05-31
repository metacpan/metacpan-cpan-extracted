use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Plack::App::Login::Password;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
eval {
	Plack::App::Login::Password->new(
		'css' => 'bad',
	)->to_app;
};
is($EVAL_ERROR, "Accessor 'css' must be a 'CSS::Struct::Output' object.\n",
	"Accessor 'css' must be a 'CSS::Struct::Output' object.");
clean();

# Test.
eval {
	Plack::App::Login::Password->new(
		'tags' => 'bad',
	)->to_app;
};
is($EVAL_ERROR, "Accessor 'tags' must be a 'Tags::Output' object.\n",
	"Accessor 'tags' must be a 'Tags::Output' object.");
clean();
