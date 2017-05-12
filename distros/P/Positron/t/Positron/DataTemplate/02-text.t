#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    use_ok('Positron::DataTemplate');
}

my $template = Positron::DataTemplate->new();

my $data = {
    this => 'that',
    again => 'too',
};

is($template->process('$this', $data), 'that', "Replace single text");
is($template->process('{$this}', $data), 'that', "Replace single text in braces");
is($template->process('one {$this} two', $data), 'one that two', "Replace longer text with braces");
is($template->process('one {$this} two {$again}', $data), 'one that two too', "Replace longer text with multiple braces");

is_deeply($template->process(['this', '$this', 'again', '$again'], $data), ['this', 'that', 'again', 'too'], "Replace nested in a list");
is_deeply($template->process(['this', ['$this', ['again', ['$again']]]], $data), ['this', ['that', ['again', ['too']]]], "Replace nested deeply in a list");

is_deeply($template->process({ '$this' => '$again', 'key' => [1, 2, 'this {$again}'] }, $data), { 'that' => 'too', 'key' => [ 1, 2, 'this too'] }, "Replace in hashes");

done_testing();
