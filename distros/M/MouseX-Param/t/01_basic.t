use Test::Base;
use Test::Deep;

{
    package MyApp;
    use Mouse;
    with 'MouseX::Param';
}

plan tests => 3 * blocks;

filters { map { $_ => ['eval'] } qw(args params param) };

run {
    my $block = shift;
    my $app = MyApp->new(defined $block->args ? (params => $block->args) : ());

    cmp_deeply $app->params    => $block->params;
    cmp_deeply [ $app->param ] => $block->param;
    is $app->param('foo') => $block->foo;
};

__END__
=== undefined
--- params: {}
--- param: []

=== empty
--- args: {}
--- params: {}
--- param: []

=== init
--- args: { foo => 10 }
--- params: { foo => 10 }
--- param: ['foo']
--- foo: 10
