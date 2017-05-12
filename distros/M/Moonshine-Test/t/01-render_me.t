use Test::Tester tests => 19;

use Moonshine::Test qw/:element :emo/;
use Test::MockObject;

(my $element = Test::MockObject->new)
    ->set_isa('Moonshine::Element');

$element->mock('render', sub { 
    my $args = $_[1]; 
    my $tag = delete $args->{tag};  
    my $text = delete $args->{data} // '';
    my $attributes = '';
    map {$attributes .= ' ';$attributes .= sprintf( '%s="%s"', $_, $args->{$_} );} keys %{ $args };
    return sprintf('<%s%s>%s</%s>', $tag, $attributes, $text, $tag);
}); 

(my $instance = Test::MockObject->new)->set_isa('Moonshine::Component');

$instance->mock('p', sub { my $args = $_[1]; 
    return (Test::MockObject->new)->mock('render', sub { $element->render({tag => 'p', %{$args} }) }) 
});

(my $div = Test::MockObject->new)->set_isa('Moonshine::Element');
$div->mock('render', sub { $element->render({tag => 'div', class => 'test', data => 'test' }) }); 

$instance->mock('broken', sub { my $args = $_[1]; 
    return (Test::MockObject->new)->mock('render', sub { $element->render({%{$args}}) }) 
});

check_test(
    sub {
        render_me(
            instance => $instance,
            func => 'p',
            args => {
                data => 'test',
            },
            expected => '<p>test</p>'
        );
    },
    {
        ok => 1,
        name => "render function: p: <p>test</p>",
        depth => 2,
        completed => 1,
    },
    'test render_me(p)'
);

check_test(
    sub {
        render_me(
            instance => $div,
            expected => '<div class="test">test</div>'
        );
    },
    {
        ok => 1,
        name => "render instance: <div class=\"test\">test</div>",
        depth => 2,
    },
    'test render_me(div)'
);

check_test(
    sub {
        render_me(
            instance => $instance,
            func => 'broken',
            args => {
                class => 'test',
                data  => 'test',
            },
            expected => '<div class="test">test</div>'
        );
    },
    {
        ok => 0,
        name => "render function: broken: <div class=\"test\">test</div>",
        depth => 2,
        diag => "         got: '< class=\"test\">test</>'\n    expected: '<div class=\"test\">test</div>'"
    },
    'test broken()'
);

sunrise(19, winning);

1;
