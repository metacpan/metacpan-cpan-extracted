use Test::Tester;

use Moonshine::Test qw/:all/;
use Test::MockObject;

(my $element = Test::MockObject->new)
    ->set_isa('Moonshine::Element');

(my $div = Test::MockObject->new)->set_isa('Moonshine::Element');
$div->mock('tag', sub { return 'div'; }); 
$div->mock('class', sub { return 'testing'; }); 

$element->mock('div', sub { return $div; }); 

moon_test(
    name         => 'sub test',
    instance     => $element,
    instructions => [
        {
            test => 'obj',
            func => 'div',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'scalar',
                    func => 'tag',
                    expected => 'div', 
                },
                {
                    test => 'scalar',
                    func => 'class',
                    expected => 'testing',
                }
            ],
        },
    ],
);

sunrise(5, flexing);

1;
