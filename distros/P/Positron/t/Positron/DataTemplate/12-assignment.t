#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::DataTemplate');
}

my $template = Positron::DataTemplate->new();
$template->add_include_paths('t/Positron/DataTemplate/');

our $test_scalar = '';

my $data = {
    title => 'The title',
    subtitle => 'The subtitle',
    list => [20, 21],
    compound => {
        one => 1,
        two => 2,
        list => [30, 31],
    },
    test_func => sub {
        $test_scalar = shift;
    },
};

is_deeply($template->process(
    [1, '= title subtitle', '$title', 2], $data),
    [1, 'The subtitle', 2],
    "Assignment in list"
);

is_deeply($template->process(
    [1, ['= title subtitle', '$title'], '$title'], $data),
    [1, ['The subtitle'], 'The title'],
    "Assignment is local"
);

is_deeply($template->process(
    [1, ['=- title subtitle', '$title'], '$title'], $data),
    [1, 'The subtitle', 'The title'],
    "Assignment is local, interpolates"
);

is_deeply($template->process(
    [1, '= a compound.one', '= list compound.list', ['@- list', '&_' ], 'a'], $data),
    [1, 30, 31, 'a'],
    "Assign a list"
);

is_deeply($template->process(
    [1, ['= _ compound', '$two', '&-list'], '&list', 2], $data),
    [1, [2, 30, 31], [20, 21], 2],
    "Assignment to underscore"
);

is_deeply($template->process(
    [1, ['= env _', '&env.title'], '&env', 2], $data),
    [1, ['The title'], undef, 2],
    "Assignment from underscore"
);

is_deeply($template->process(
    [1, ['@list', ['=- num _', '&num']], 2], $data),
    [1, [20, 21], 2],
    "Assignment from underscore of loop"
);


# Hashes
is_deeply($template->process(
    { '= title subtitle' => { name => '$title' }, title => '$title'}, $data),
    { name => 'The subtitle', title => 'The title'},
    "Hash auto-interpolates"
);

# Text
is_deeply($template->process(
    { 'key' => '= value test_func(title)'}, $data),
    { key => '' },
    "Assignment in text is empty (like comments)"
);
is($test_scalar, 'The title', "Assignment in text has still been executed");

done_testing();
