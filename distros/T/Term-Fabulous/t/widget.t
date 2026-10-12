use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Widget::Box;

subtest 'classes' => sub {
	my @names = qw(sidebar dim);
	my $box   = Term::Fabulous::Widget::Box->new( classes => \@names );
	push @names, 'later';
	is [ $box->get_classes ], [qw(sidebar dim)], 'the names are kept as given at construction';

	like dies { Term::Fabulous::Widget::Box->new( classes => 'sidebar' ) },      qr/classes must be an array reference of names, got 'sidebar'/,        'a plain string dies';
	like dies { Term::Fabulous::Widget::Box->new( classes => { a => 1 } ) },     qr/classes must be an array reference of names, got a HASH reference/, 'a hash dies';
	like dies { Term::Fabulous::Widget::Box->new( classes => [ 'a', undef ] ) }, qr/every class name must be a string, got undef/,                      'an undefined name dies';
	like dies { Term::Fabulous::Widget::Box->new( classes => [ [] ] ) },         qr/every class name must be a string, got an ARRAY reference/,         'a reference dies';
};

done_testing;
