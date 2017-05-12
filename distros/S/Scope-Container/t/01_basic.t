use strict;
use Test::More;
use Scope::Container;

{
    my $sc = start_scope_container();
    scope_container('foo', 'foo1');
    is( scope_container('foo'), 'foo1' );
}

{
    my $sc = start_scope_container();

    scope_container('bar', 'bar1');
    is( scope_container('bar'), 'bar1' );

    my $sc2 = start_scope_container();
    is( scope_container('bar'), 'bar1' );
    scope_container('bar', 'bar2');
    is( scope_container('bar'), 'bar2' );

    undef $sc2;
    is( scope_container('bar'), 'bar1' );
}

{
    local *STDERR;
    open my $fh, '>', \my $content;
    *STDERR = $fh;
    ok( !scope_container('bar') );
    like $content, qr/not initilized/;
}


{
    my $sc = start_scope_container();

    scope_container('bar', 'bar1');
    is( scope_container('bar'), 'bar1' );

    my $sc2 = start_scope_container(-clear=>1);
    ok( !scope_container('bar') );
    scope_container('bar', 'bar2');
    is( scope_container('bar'), 'bar2' );

    undef $sc2;
    {
        local *STDERR;
        open my $fh, '>', \my $content;
        *STDERR = $fh;
        ok( !scope_container('bar') );
        like $content, qr/not initilized/;
    }
    
}

{
    my $sc = start_scope_container();
    scope_container('bar', 'bar3');
    my $sc2 = start_scope_container();
    scope_container('bar', 'bar3-1');
    {
        local *STDERR;
        open my $fh, '>', \my $content;
        *STDERR = $fh;
        undef $sc;
        like $content, qr/nested scope_container/;
    }
    {
        local *STDERR;
        open my $fh, '>', \my $content;
        *STDERR = $fh;
        ok( !scope_container('bar') );
        undef $sc2;
        like $content, qr/not initilized/;
        like $content, qr/nested scope_container/;
    }
}


sub bar {
    my ($key, $val) = @_;
    is(scope_container($key), $val);
}

{
    my $sc = start_scope_container();
    scope_container('foo', 'foo2');
    bar('foo','foo2');
    {
        bar('foo','foo2');
        my $sc = start_scope_container();
        ok( scope_container('foo') );
        scope_container('foo', 'foo3');
        bar('foo','foo3');
        {
            my $sc = start_scope_container();
            scope_container('foo', 'foo4');
        }
        is(scope_container('foo'), 'foo3');
        bar('foo','foo3');
    }
    is(scope_container('foo'), 'foo2');
}
{
    ok( !in_scope_container() );
}

{
    my $sc = start_scope_container();
    ok( in_scope_container() );
}



done_testing;
