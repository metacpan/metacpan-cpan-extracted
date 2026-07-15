use Test::Most;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Template::EmbeddedPerl;

{
    package Local::TemplateLookup::Explicit;

    sub new { bless {}, shift }
    sub template { 'objects/explicit' }
}

{
    package Local::TemplateLookup::Outside;

    sub new { bless {}, shift }
}

{
    package MyApp::View::HTML::ContactList;

    sub new { bless {}, shift }
}

{
    package MyApp::View::Empty;

    sub new { bless {}, shift }
    sub template { '' }
}

my $root = tempdir(CLEANUP => 1);
my $app = File::Spec->catdir($root, 'app');
my $shared = File::Spec->catdir($root, 'shared');
make_path(File::Spec->catdir($app, 'html'));
make_path(File::Spec->catdir($shared, 'html'));

my $app_template = File::Spec->catfile($app, 'html', 'contact_list.epl');
my $shared_template = File::Spec->catfile($shared, 'html', 'contact_list.epl');
open my $app_fh, '>', $app_template or die "Failed to create $app_template: $!";
print {$app_fh} 'app';
close $app_fh or die "Failed to close $app_template: $!";
open my $shared_fh, '>', $shared_template or die "Failed to create $shared_template: $!";
print {$shared_fh} 'shared';
close $shared_fh or die "Failed to close $shared_template: $!";

my $engine = Template::EmbeddedPerl->new(
    directories => [[$root, 'app'], [$root, 'shared']],
    view_namespace => 'MyApp::View',
);

is_deeply(
    [$engine->_template_candidates('html/contact_list')],
    [$app_template, $shared_template],
    'candidate paths preserve nested directory and declared order',
);
is(
    $engine->_class_to_template('MyApp::View::HTML::ContactList'),
    'html/contact_list',
    'package suffix becomes a snake-case template identifier',
);
is($engine->_class_to_template('MyApp::View::HTML'), 'html', 'acronym segment stays together');
is($engine->_class_to_template('MyApp::View::HTMLPage'), 'html_page', 'acronym run stays together');
is($engine->_class_to_template('MyApp::View::ContactList'), 'contact_list', 'camel-case segment becomes snake case');

my $uncached = $engine->from_file('html/contact_list');
is($uncached->render, 'app', 'first matching directory wins');
is($uncached->{identifier}, 'html/contact_list', 'uncached compiled template retains identifier metadata');
is($uncached->{source}, $app_template, 'uncached compiled template retains source metadata');

is(
    $engine->_resolve_view_template(Local::TemplateLookup::Explicit->new),
    'objects/explicit',
    'a nonempty object template is authoritative',
);
is(
    $engine->_resolve_view_template(MyApp::View::Empty->new),
    'empty',
    'an empty object template falls back to the namespace convention',
);
is(
    $engine->_resolve_view_template(MyApp::View::HTML::ContactList->new),
    'html/contact_list',
    'the namespace convention resolves an object without a template override',
);

my $error;
eval { $engine->_class_to_template('OtherApp::View::HTML'); 1 } or $error = $@;
like($error, qr/Cannot resolve template for view class 'OtherApp::View::HTML'/, 'classes outside view namespace fail');

undef $error;
eval { $engine->_resolve_view_template(Local::TemplateLookup::Outside->new); 1 } or $error = $@;
like($error, qr/Cannot resolve template for view class 'Local::TemplateLookup::Outside'/, 'unresolvable view names its class');

unlink $app_template or die "Failed to remove $app_template: $!";
is($engine->from_file('html/contact_list')->render, 'shared', 'lookup falls back in order');

my $cached_engine = Template::EmbeddedPerl->new(
    directories => [[$root, 'app'], [$root, 'shared']],
    use_cache => 1,
);
my $cached_first = $cached_engine->from_file('html/contact_list');
my $cached_second = $cached_engine->from_file('html/contact_list');
is($cached_first->{identifier}, 'html/contact_list', 'cached compiled template retains identifier metadata');
is($cached_first->{source}, $shared_template, 'cached compiled template retains source metadata');
is($cached_second->{identifier}, 'html/contact_list', 'cache hit retains identifier metadata');
is($cached_second->{source}, $shared_template, 'cache hit retains source metadata');

undef $error;
eval { $engine->from_file('missing/template'); 1 } or $error = $@;
like(
    $error,
    qr/Template 'missing\/template' not found; searched: \Q@{[ File::Spec->catfile($app, 'missing', 'template.epl') ]}\E, \Q@{[ File::Spec->catfile($shared, 'missing', 'template.epl') ]}\E/,
    'missing template reports every candidate in declared order',
);

done_testing;
