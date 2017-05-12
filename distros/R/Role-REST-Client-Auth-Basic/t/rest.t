use Test::More tests => 12;

{
	package RESTExample;

	use Moo;
	with 'Role::REST::Client';
	with 'Role::REST::Client::Auth::Basic';

	sub bar {
		my ($self) = @_;
		my $res = $self->post('foo/bar/baz', {foo => 'bar'});
		my $code = $res->code;
		my $data = $res->data;
		return $data if $code == 200;
   }
}

my %testdata = (
	server =>      'http://localhost:3000',
	type   =>      'application/json',
	user   =>      'mee',
	passwd =>      'sekrit',
);
ok(my $obj = RESTExample->new(%testdata), 'New object');
isa_ok($obj, 'RESTExample');

for my $item (qw/post get put delete _call httpheaders/) {
    ok($obj->can($item), "Role method $item exists");
}

for my $item (qw/server type user passwd/) {
    is($obj->$item, $testdata{$item}, "Role attribute $item is set");
}
