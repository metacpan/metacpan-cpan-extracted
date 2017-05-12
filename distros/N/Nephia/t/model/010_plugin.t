use strict;
use warnings;
use Test::More;
use Test::Exception;
use Nephia::Plugin;
use Nephia::Core;

{
    package Nephia::Plugin::TestAlpha;
    use parent 'Nephia::Plugin';
    sub exports { qw/ one / };
    sub one     { sub () { 1 } };
}
{
    package Nephia::Plugin::TestBeta;
    use parent 'Nephia::Plugin';
    sub needs   { qw/ TestAlpha / };
    sub exports { qw/ incr / };
    sub incr    { 
        sub ($) { 
            my $num = $_[0];
            $num ? ++$num : one();
        }; 
    };
}
{
    package Nephia::Plugin::TestSeta;
    use parent 'Nephia::Plugin';
    sub requires { qw/one/ };
    sub two {
        sub ($) { one() + 1 };
    }
}
    
subtest basal => sub {
    my $x = Nephia::Plugin->new;
    isa_ok $x, 'Nephia::Plugin';
    is $x->exports, undef, 'not export anything';
};

subtest needs_failure => sub {
    throws_ok(
        sub{Nephia::Core->new(plugins => [qw/TestBeta/])}, 
        qr/Nephia::Plugin::TestBeta needs Nephia::Plugin::TestAlpha, you have to load Nephia::Plugin::TestAlpha first/
    );
};

subtest needs_ok => sub {
    my $v;
    lives_ok(sub{$v = Nephia::Core->new(plugins => [qw/TestAlpha TestBeta/])}, 'no error when loaded a plugin that needs other plugin');
    $v->export_dsl;
    is $v->dsl('one')->(), 1;
    is $v->dsl('incr')->(2), 3;
};

subtest requires_failure => sub {
    throws_ok(
        sub { Nephia::Core->new(plugins => [qw/TestSeta/]) },
        qr/Nephia::Plugin::TestSeta requires one DSL, you have to load some plugin that provides one DSL/
    );
};

done_testing;
