# Pod::WikiDoc - check module loading and create testing directory

use Test::More tests =>  5 ;

BEGIN { use_ok( 'Pod::WikiDoc' ); }

my $object = Pod::WikiDoc->new ();
isa_ok ($object, 'Pod::WikiDoc');
can_ok ($object, qw( format convert filter ) );


eval { $object->new() };
like( $@, qr{Error: Class method new\(\) can't be called on an object},
    "Catch new called as an object method"
);

eval { Pod::WikiDoc->new( comment_doc => 1 ) };
like( $@, qr{Error: Argument to new\(\) must be a hash reference},
    "Catch bad argument to new"
);
