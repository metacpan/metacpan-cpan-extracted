#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;


$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $data_dir = 't/data';
my $file     = 'children.xml';

my $child1   = {
   dir        => 'ltr',
   lang       => 'en',
   'xml:lang' => 'en',
   uri        => 'foo/',
   direction  => 'ltr',
   title      => 'Foo'
};
my $child2   = {
   dir        => 'ltr',
   lang       => 'en',
   'xml:lang' => 'en',
   uri        => 'bar/',
   direction  => 'ltr',
   title      => 'Bar'
};
my $child3   = {
   dir        => 'ltr',
   lang       => 'en',
   'xml:lang' => 'en',
   uri        => 'baz/',
   direction  => 'ltr',
   title      => 'Baz'
};

my @args     = (
    self => {
      children => [ $child1, $child2, $child3 ]
    }
);

my $template = new Petal (base_dir => $data_dir, file => $file);
my $result = $template->process (@args);

like ($result, qr/foo/  =>  'contains foo');
like ($result, qr/bar/  =>  'contains bar');
like ($result, qr/baz/  =>  'contains baz');
like ($result, qr/Foo/  =>  'contains Foo');
like ($result, qr/Bar/  =>  'contains Bar');
like ($result, qr/Baz/  =>  'contains Baz');

