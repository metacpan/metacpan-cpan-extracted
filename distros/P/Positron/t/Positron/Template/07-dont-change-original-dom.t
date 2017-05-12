#!/usr/bin/perl

use strict;
use warnings;

use Data::Dump qw(pp);
use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests to prove that processing does not change the template DOM!

my $template = Positron::Template->new();
my $environment = {
    a => 'one',
    l => [],
};

my ($dom, $result);

subtest 'Voider in attribute' => sub {
    $dom = ['a', {href => '{~}'}, 'Link'];
    $result = $template->process($dom, $environment);
    is_deeply($result, ['a', { }, 'Link'], "Template processed");
    is_deeply($dom, ['a', {href => '{~}'}, 'Link'], "Original untouched" );
    isnt($result, $dom, "New root node");
};

subtest 'String in attribute' => sub {
    $dom = ['a', {href => '{$a}'}, 'Link'];
    $result = $template->process($dom, $environment);
    is_deeply($result, ['a', { href => 'one' }, 'Link'], "Template processed");
    is_deeply($dom, ['a', {href => '{$a}'}, 'Link'], "Original untouched" );
    isnt($result, $dom, "New root node");
};

subtest 'Loop' => sub {
    $dom = ['ul', {style => '{@+l}'}, ['li', {}]];
    $result = $template->process($dom, $environment);
    is_deeply($result, ['ul', {}], "Template processed");
    is_deeply($dom, ['ul', {style => '{@+l}'}, ['li', {}]], "Original untouched" );
    isnt($result, $dom, "New root node");
};

subtest 'Disappearing loop' => sub {
    $dom = ['ul', {style => '{@l}'}, ['li', {}]];
    $result = [ $template->process($dom, $environment) ];
    is_deeply($result, [], "Template processed");
    is_deeply($dom, ['ul', {style => '{@l}'}, ['li', {}]], "Original untouched" );
    isnt($result, $dom, "New root node");
};


subtest 'Condition' => sub {
    $dom = ['ul', {style => '{?+nothing}'}, ['li', {}]];
    $result = $template->process($dom, $environment);
    is_deeply($result, ['ul', {}], "Template processed");
    is_deeply($dom, ['ul', {style => '{?+nothing}'}, ['li', {}]], "Original untouched" );
    isnt($result, $dom, "New root node");
};

subtest 'Disappearing condition' => sub {
    $dom = ['ul', {style => '{?nothing}'}, ['li', {}]];
    $result = [ $template->process($dom, $environment) ];
    is_deeply($result, [], "Template processed");
    is_deeply($dom, ['ul', {style => '{?nothing}'}, ['li', {}]], "Original untouched" );
    isnt($result, $dom, "New root node");
};

subtest 'Loop and Condition' => sub {
    $dom = ['ul', {style => '{?+nothing}', id => '{@+l}'}, ['li', {}]];
    $result = $template->process($dom, $environment);
    is_deeply($result, ['ul', {}], "Template processed");
    is_deeply($dom, ['ul', {style => '{?+nothing}', id => '{@+l}'}, ['li', {}]], "Original untouched" );
    isnt($result, $dom, "New root node");
};

# More as bugs warrant.

done_testing();
