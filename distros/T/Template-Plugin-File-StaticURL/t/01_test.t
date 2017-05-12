#!/usr/bin/env perl

use Test::More;

use_ok("Template::Plugin::File::StaticURL");
use_ok("Template");
use_ok("File::stat");


my $t = Template->new;

my $stat = File::stat::stat('./t/var/hello_world.js');

my $mtime = $stat->mtime;
ok($mtime > 0, 'sane mtime of test subject');

my $size  = $stat->size;
ok($size > 0, 'sane size of test subject');


my $basic = template_process("[% USE File.StaticURL file_root='./t/var' -%][% File.StaticURL.url('/hello_world.js') %]");
is($basic, "/hello_world.js/$mtime/$size", 'basic test generating expected url');


my $postfix = template_process("[% USE File.StaticURL file_root='./t/var' postfix_filename=1 %][% File.StaticURL.url('/hello_world.js') %]");
is($postfix, "/hello_world\.js/$mtime/$size/hello_world.js", 'testing postfix');

my $qstring = template_process("[% USE File.StaticURL file_root='./t/var' prefix='?' %][% File.StaticURL.url('/hello_world.js') %]");
is($qstring, "/hello_world.js?$mtime/$size", 'testing query string form');


my $full_url = template_process("[% USE File.StaticURL file_root='./t/var' graceful=1 %][% File.StaticURL.url('http://www.google.com/hello_world.js') %]");
is($full_url, 'http://www.google.com/hello_world.js', 'lets full urls through if graceful is set');


eval {
   template_process("[% USE File.StaticURL file_root='./t/var' graceful=0 %][% File.StaticURL.url('/nonexistent.js') %]");
};
ok($@, 'fatals if file doesnt exist, and graceful is 0');

eval {
   template_process("[% USE File.StaticURL file_root='./t/var/nonexistent_dir' graceful=0 %][% File.StaticURL.url('/nonexistent.js') %]");
};
ok($@, 'fatals if file_root doesnt exist, and graceful is 0');





sub template_process {
    my $template = shift;

    my $out='';
    $t->process(\$template, {} ,\$out);
    die($t->error) if $t->error;
    return $out;
}



done_testing();
