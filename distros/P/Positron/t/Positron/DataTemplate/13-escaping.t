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
    'list' => [1, 2, 3],
    'empty_list' => [],
    'hash' => { 1 => 2 },
    'empty_hash' => {},
};

is_deeply($template->process( '~$one', $data ), '$one', "Escaping ~ before \$");
is_deeply($template->process( 'the {{~}$one} ring', $data ), 'the {$one} ring', "Escaping {~} before {\$}");
is_deeply($template->process( ['~$one', 2], $data ), ['$one', 2], "Escaping ~ at the beginning of lists");
is_deeply($template->process( {'~$one' => 2}, $data ), {'$one'=> 2}, "Escaping ~ in key of hashes");
is_deeply($template->process( {2 => '~$one'}, $data ), {2 => '$one'}, "Escaping ~ in value of hashes");

is_deeply($template->process( '~&one', $data ), '&one', "Escaping ~ before &");
is_deeply($template->process( ['~@list', 'q'], $data ), ['@list', 'q'], "Escaping ~ before \@");
is_deeply($template->process( { '~%hash' => {'$key' => '$value'} }, $data ), { '%hash' => { '' => '' }}, "Escaping ~ before \%");

is_deeply($template->process( ['~?one', 1, 0], $data ), ['?one', 1, 0], "Escaping ~ before \?");
is_deeply($template->process( {'~?one' => { 1 => 'a', 2 => 'b' }}, $data ), {'?one' => { 1 => 'a', 2 => 'b' }}, "Escaping ~ before switch \?");

done_testing();
