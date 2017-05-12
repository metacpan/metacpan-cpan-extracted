use Test::Tester;

use Moonshine::Test qw/:all/;
use Test::MockObject;

(my $instance = Test::MockObject->new)->set_isa('Moonshine::Component');

my $element = bless {}, 'Moonshine::Element'; 
$instance->mock('p', sub {  
    return $element; 
});

$instance->mock('broken', sub { my $args = $_[1]; 
    return (Test::MockObject->new)->mock('render', sub { $element->render({%{$args}}) }) 
});

moon_test_one(
    test => 'array',
    meth => \&Moonshine::Test::_run_the_code,
    args => {
        instance => $element,
        data => 'test',
    },
    expected => ['instance', $element],
);

moon_test_one(
    test => 'array',
    meth => \&Moonshine::Test::_run_the_code,
    args => {
        instance => $instance,
        func => 'p',
        data => 'test',
    },
    expected => ['function: p', $element],
);

moon_test_one(
    catch => 1,
    meth => \&Moonshine::Test::_run_the_code,
    args => {
        data => 'test',
    },
    expected => qr/instruction passed to _run_the_code must have a func, meth or instance/,
);

sunrise(3, strut);

1;
