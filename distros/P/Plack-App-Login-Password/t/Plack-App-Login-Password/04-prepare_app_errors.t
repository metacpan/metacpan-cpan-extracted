use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Plack::App::Login::Password;
use Test::More 'tests' => 6;
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
		'lang' => 'xxx',
	)->to_app;
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-2 code (xxx).");
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

# Test.
eval {
	Plack::App::Login::Password->new(
		'text' => 'bad',
	)->to_app;
};
is($EVAL_ERROR, "Parameter 'text' must be a hash with language texts.\n",
	"Parameter 'text' must be a hash with language texts.");
clean();

# Test.
eval {
	Plack::App::Login::Password->new(
		'text' => {},
	)->to_app;
};
is($EVAL_ERROR, "Texts for language 'eng' doesn't exist.\n",
	"Texts for language 'eng' doesn't exist.");
clean();
