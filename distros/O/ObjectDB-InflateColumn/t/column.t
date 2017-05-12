use Test::More;

use lib 't/lib';

SKIP: {
    eval {require JSON};
    skip "JSON not installed", 'no_plan' if $@;
    
    use Author;

    my $author = Author->new;
    
    ok($author);
    
    ok(not defined $author->column(undef));
    ok(not defined $author->column('id'));
    
    $author->column(id => 'boo');
    is($author->column('id'), 'boo');
    
    $author->column(id => undef);
    ok(not defined $author->column('id'));
    
    $author->column(id => 'bar');
    $author->column('id');
    is($author->column('id'), 'bar');
    
    $author = Author->new(id => 'foo');
    is($author->column('id'), 'foo');
    
    pass("Inflate test\n".'*' x 10);
    $author = Author->new(name => 'foo');
    $author->inflate_column('data',[1,2,3]);
    is($author->column('data'), '[1,2,3]');
    is(ref $author->inflate_column('data'), 'ARRAY');
    is($author->inflate_column('data')->[1], 2);
    
    pass("end\n".'*' x 10);    
}

done_testing();

