#!/usr/bin/perl -w

use strict;
use Test::More tests => 32;
#use Test::More 'no_plan';
use File::Spec::Functions qw(tmpdir catdir);
use File::Path qw(remove_tree);

my $CLASS;
BEGIN {
    $CLASS = 'Pod::Site';
    use_ok $CLASS or die;
}

my $mod_root = catdir qw(t lib);
my $tmpdir   = catdir tmpdir, "$$-pod-site-test";
my $doc_root = catdir $tmpdir, 'doc_root';
my $base_uri = '/docs/';

END { remove_tree if -d $tmpdir }

can_ok $CLASS, qw(
    doc_root
    base_uri
    module_roots
    index_file
    css_path
    js_path
    verbose
    name
    versioned_title
    label
    title
    nav_header
    replace_css
    replace_js
    mod_files
    bin_files

    go
    new
    build
    sort_files
    start_nav
    start_toc
    output
    output_bin
    finish_nav
    finish_toc
    batch_html
    copy_etc
    get_desc
    sample_module
    main_module
    sample_module
    version
);

isa_ok 'Pod::Site::Search', 'Pod::Simple::Search';
can_ok 'Pod::Site::Search', qw(
    instance
    new
);

isa_ok 'Pod::Site::XHTML', 'Pod::Simple::XHTML';
can_ok 'Pod::Site::XHTML', qw(
    new
    start_L
    html_header
    batch_mode_page_object_init
);

eval { $CLASS->new };
ok my $err = $@, 'Should catch exception';
like $err, qr{Missing required parameters doc_root, base_uri, and module_roots},
    'Should have the proper error message';

isa_ok my $ps = $CLASS->new({
    doc_root     => $doc_root,
    base_uri     => $base_uri,
    module_roots => $mod_root,
}), $CLASS, 'new object';

ok $ps->build, 'Build it and they will come';
is $ps->index_file, 'index.html', 'Should have defautl index file';
is $ps->verbose, 0, 'Should have default verbosity';
is $ps->js_path, '', 'Should have default js_path';
is $ps->css_path, '', 'Should have default css_path';
is $ps->name, 'Foo::Bar', 'Should have name';
is $ps->title, $ps->name, 'Should have main title';
is $ps->nav_header, $ps->name, 'Should have nav header';
is $ps->main_module, 'Foo::Bar', 'Should have main module';
is $ps->sample_module, 'Foo::Bar', 'Should have sample module';
is $ps->label, undef, 'Should have no label';

is_deeply $ps->module_roots, [$mod_root],
    'module_roots should be converted to an array';
is_deeply $ps->base_uri, [$base_uri],
    'base_uri should be converted to an array';

isa_ok $ps = $CLASS->new({
    doc_root        => $doc_root,
    base_uri        => $base_uri,
    module_roots    => [$mod_root],
    base_uri        => [$base_uri],
    versioned_title => 1,
    label           => 'API Browser',
}), $CLASS, 'another object';

ok $ps->build, 'Build it again';
is_deeply $ps->module_roots, [$mod_root],
    'module_roots array should be retained';
is_deeply $ps->base_uri, [$base_uri],
    'base_uri array should be retained';
is $ps->name, 'Foo::Bar', 'Should have name';
is $ps->label, 'API Browser', 'Should have label';
is $ps->nav_header, $ps->name . ' ' . $ps->version,
    'Nav header should have version';
is $ps->title, $ps->name . ' ' . $ps->version . ' ' . $ps->label,
    'Should have main title with label';

my $path = "$$-" . __FILE__ . time;
eval { $CLASS->new({
    doc_root     => $doc_root,
    base_uri     => $base_uri,
    module_roots => $path,
}) };

ok $err = $@, 'Should catch exception';
like $err, qr{The module root \Q$path\E does not exist},
    'Should be non exist error';
