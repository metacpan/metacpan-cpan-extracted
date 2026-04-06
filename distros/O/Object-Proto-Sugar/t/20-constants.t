use strict;
use warnings;
use Test::More;
{
    package Test::Control;
    use Object::Proto::Sugar qw/ro dstr dhash darray lzy_str/;
    attributes( 
                foo => [ ro, {} ], 
                lzs => [ {lzy_str} ],
                ds => [ ro, {dstr} ],
                dh => [ ro, {dhash} ],
                da => [ ro, {darray} ]
        );
        1;
}
my $o1 = Test::Control->new( foo => { a => 'b' } );
use Data::Dumper;
is_deeply($o1->foo, { a => 'b' }, "foo is deeply { a => 'b' }");
is($o1->ds, '');
is($o1->lzs, '');
is_deeply($o1->dh, {});
is_deeply($o1->da, []);

done_testing;
