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
    'one' => 1,
    'list' => [1],
    'empty_list' => [],
    'hash' => { 1 => 2 },
    'empty_hash' => {},
};

is_deeply($template->process( [1, '# a comment', 2], $data ), [1, 2], "Collapsing text comment in list");
is_deeply($template->process( [1, '#+ a comment', 2], $data ), [1, '', 2], "Non-collapsing text comment in list");
is_deeply($template->process( {1 => '# a comment'}, $data ), {1 => ''}, "Collapsing text comment in hash value");
is_deeply($template->process( {'# a comment' => 1 }, $data ), {'' => 1 }, "Collapsing text comment in hash key");

is_deeply($template->process( {'one{# could be anything} two' => 1}, $data ), {'one two' => 1}, "Embedded text comment in hash key");
is_deeply($template->process( {'one {# could be anything} two' => 1}, $data ), {'one  two' => 1}, "Embedded text comment (with whitespace)");
is_deeply($template->process( {'one {#- could be anything} two' => 1}, $data ), {'onetwo' => 1}, "Embedded text comment (with whitespace trimming)");

# structural comments

is_deeply($template->process( [1, '/not the next', 2, 3], $data), [1, 3], "Structural comments remove next");
is_deeply($template->process( [1, '//not the next two', 2, 3], $data), [1 ], "Double structural comments remove all next");
is_deeply($template->process( ['//not the nexts', 1, 2, 3], $data), [], "Double structural comments can clear array");

is_deeply($template->process( [1, ['/-not the next', 2, 3], 4], $data), [1, 3, 4], "Structural comments with -");
is_deeply($template->process( [1, ['//-not the next two', 2, 3], 4], $data), [1, 4], "Double structural comments with -");
is_deeply($template->process( [1, '<', ['/not the next', 2, 3], 4], $data), [1, 3, 4], "Structural comments with <");
is_deeply($template->process( [1, '<', ['//not the next two', 2, 3], 4], $data), [1, 4], "Double structural comments with <");

is_deeply($template->process({ '/not this' => [], 'this' => {}}, $data), {'this' => {}}, "Comment hash keys remove key and value");
# do we need this yet?
dies_ok { $template->process({ one => '/not this' },$data); } "Can't comment out a value";

done_testing();
