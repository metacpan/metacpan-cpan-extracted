use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	has name => (
	  is  => 'rw',
	);

	has log => (
	  is      => 'rw',
	  default => '',
	);

	sub greet { 'hello' }

	before 'greet' => sub {
		my ($self) = @_;
		$self->log($self->log . 'before,');
	};

	after 'greet' => sub {
		my ($self) = @_;
		$self->log($self->log . 'after');
	};

	around 'greet' => sub {
		my ($orig, $self) = @_;
		return 'around(' . $self->$orig() . ')';
	};

	1;
}

package main;

my $test = new Test;

my $result = $test->greet;

is($result, 'around(hello)', 'around wraps the return value');
is($test->log, 'before,after', 'before and after both ran');

done_testing();
