package Storage::Abstract::Role::Driver::Basic;
$Storage::Abstract::Role::Driver::Basic::VERSION = '0.007';
use v5.14;
use warnings;

use Mooish::AttributeBuilder -standard;
use Types::Common -types;
use Moo::Role;

use Storage::Abstract::Handle;

sub _build_readonly
{
	return !!0;
}

before 'store_impl' => sub {
	$_[2] = Storage::Abstract::Handle->adapt($_[2]);
};

before ['retrieve_impl', 'dispose_impl'] => sub {
	Storage::Abstract::X::NotFound->raise("file was not found")
		unless $_[0]->is_stored_impl($_[1]);
};

1;

