package Moose::Declarations::MethodModifiers::Vanilla;

use Moose;

has 'moo_att' => ( is => 'rw', );

has [qw/ label progress butWarn butTime start_stop /] => ( isa => 'Ref', is => 'rw' );

has qw(account) => ( is => 'rw', );

has non_quoted_attr => ( is => 'rw' );

sub pub_sub {
	return;
}

sub _pri_sub {
	return;
}

before 'mm_before' => sub {
	return;
};

after 'mm_after' => sub {
	return;
};

around 'mm_around' => sub {
	return;
};

override 'mm_override' => sub {
	return;
};

augment 'mm_augment' => sub {
	return;
};

1;

__END__
