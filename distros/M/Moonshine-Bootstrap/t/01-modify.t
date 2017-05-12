use strict;
use warnings;
use Moonshine::Test;

use Moonshine::Bootstrap::Component;
my $instance = Moonshine::Bootstrap::Component->new;

moon_test_one(
    test => 'list_index_ref',
    instance => $instance,
    func => 'modify',
    args => [
        {},
        {},
        {
            switch => 'switch',
            switch_base => 'component-',
        }
    ],
    args_list => 1,
    index => 0,
    expected => {
        class => 'component-switch',
    },
);

moon_test_one(
    test => 'list_index_ref',
    instance => $instance,
    func => 'modify',
    args => [
        { class => 'base' },
        {},
        {
            class => 1,
            class_base => 'component',
        }
    ],
    args_list => 1,
    index => 0,
    expected => {
        class => 'base component',
    },
);

moon_test_one(
    test => 'list_index_ref',
    instance => $instance,
    func => 'modify',
    args => [
        { class => 'base' },
        {},
        {
            sizing => 'lg',
            sizing_base => 'size-',
            alignment => 'right',
            alignment_base => 'align-',
            txt_base => 'text-',
            txt => 'base',
        }
    ],
    args_list => 1,
    index => 0,
    expected => {
        class => 'base size-lg align-right text-base',
    },
);

moon_test_one(
    test => 'list_index_ref',
    instance => $instance,
    func => 'modify',
    args => [
        { class => 'base' },
        {},
        {
            sizing => 'lg',
            sizing_base => 'size-',
            alignment => 'right',
            alignment_base => 'align-',
            txt_base => 'text-',
            txt => 'base',
        }
    ],
    args_list => 1,
    index => 0,
    expected => {
        class => 'base size-lg align-right text-base',
    },
);

sunrise(4);
