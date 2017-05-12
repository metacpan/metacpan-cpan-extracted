package t::odea::ExtendsBasicAttributes;

use Moo;
use MooX::LazierAttributes;

extends 't::odea::BasicAttributes';

attributes (    
    '+one'   => [ 20 ],
    '+two'   => [ [qw/four five six/]],
    '+three' => [ { three => 'four' }],
    '+four'  => [ 'a different value'],
    '+five'  => [ bless {}, 'Okays'],
    six      => [ ro, 1 ],
    '+seven' => [ nan, { lzy } ],
    [qw/+eleven +twelve +thirteen/] => ['ahhhhhhhhhhhhh']
);

sub _build_fourteen {
    return 40000;
}

1;
