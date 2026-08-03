use strict;
use warnings;
use Test::More;
use Object::Proto;

{
	package PrivTest;
	use Object::Proto::Sugar qw(is_rw prv Str);

	has name   => (is_rw, isa => Str);       # public
	has secret => (is => 'rw', private => 1); # private via option
	has token  => (is_rw, prv);               # private via the prv shortcut

	# In-package access is allowed (getter and setter).
	sub reveal       { $_[0]->secret }
	sub reveal_token { $_[0]->token }
	sub stash        { my ($self, $v) = @_; $self->secret($v) }

	1;
}

package main;

my $obj = new PrivTest name => 'Rex', secret => 'sshh', token => 'abc';
isa_ok($obj, 'PrivTest', 'constructor builds object');

# public accessor is unaffected
is($obj->name, 'Rex', 'public accessor works from main');

# private accessor works from within the owning package
is($obj->reveal, 'sshh', 'private getter (option) works from inside the class');
is($obj->reveal_token, 'abc', 'private getter (prv shortcut) works from inside the class');

# ... and a private setter from inside the class
$obj->stash('new-secret');
is($obj->reveal, 'new-secret', 'private setter works from inside the class');

# getting a private attribute from another package dies
eval { $obj->secret };
like($@, qr/cannot call private attribute secret on PrivTest from main/,
	'private getter (option) dies from main');

eval { $obj->token };
like($@, qr/cannot call private attribute token on PrivTest from main/,
	'private getter (prv shortcut) dies from main');

# setting a private attribute from another package dies too
eval { $obj->secret('nope') };
like($@, qr/cannot call private attribute secret on PrivTest from main/,
	'private setter dies from main');
is($obj->reveal, 'new-secret', 'value unchanged after denied set from main');

# the prv shortcut expands to (private => 1)
is_deeply({ Object::Proto::Sugar::prv() }, { private => 1 }, 'prv => (private => 1)');

done_testing();
