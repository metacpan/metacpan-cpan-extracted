use strict;
use warnings;
use Test::More;

BEGIN {
    eval {
	    require Moo;
        1;
    } or do {
        plan skip_all => "Moo is not available";
    };
}

{

    package Test::Control;
    use Moo;
    use MooX::LazierAttributes { limit => 10 }, qw/ro dstr dhash darray lzy_str/;
    attributes( 
		foo => [ ro, {} ], 
		lzs => [ {lzy_str} ],
		ds => [ ro, {dstr} ],
		dh => [ ro, {dhash} ],
		da => [ ro, {darray} ]
	);
}

my $o1 = Test::Control->new( foo => { a => 'b' } );
use Data::Dumper;

is_deeply($o1->foo, { a => 'b' }, "foo is deeply { a => 'b' }");
is($o1->ds, '');
is($o1->lzs, '');
is_deeply($o1->dh, {});
is_deeply($o1->da, []);

eval '
{
    package Test::Control::Death;
    use Moo;
    use MooX::LazierAttributes qw/ro/;
    attributes( foo => [ rw, {} ], );
}
';
my $error = $@;
like $error, qr/Bareword "rw" not allowed while "strict subs"/, "and we error - $error";

done_testing;
