#!perl

# Punk::Model::Markdown: the pages of a `markdown` mount as model rows. The
# application is handed to every backend Punk::Model builds, which is how
# this one finds the mount.

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Encode ();

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
}

sub spew {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} Encode::encode('UTF-8', $text);
    close $fh;
}

my $tree = File::Temp->newdir;
spew("$tree/older.md", "---\ndate: 2026-10-01\ntags: [a, b]\n---\n# Older\n\nOld words.\n");
spew("$tree/newer.md", "---\ndate: 2026-10-19\ndescription: The newer one.\n---\n# Newer\n");
spew("$tree/note.md",  "# A Note\n\nUndated.\n");
spew("$tree/draft.md", "---\ndraft: 1\ndate: 2026-12-01\n---\n# Draft\n");
spew("$tree/naïve.md", "---\ndate: 2026-10-05\n---\n# Naïve Café\n");

my $esc = "$tree"; $esc =~ s/'/\\'/g;
eval <<"PERL" or die $@;
package MMApp;
use Punk;
markdown '/blog' => '$esc', sort => 'date', search => 0;
database blog => { backend => 'Punk::Model::Markdown', prefix => '/blog/' };
1;
PERL
{
    package MMApp::Model::Post;
    use Punk::Model;
    database 'blog';
    table 'posts';
    field path    => { type => 'string', primary => 1 };
    field url     => { type => 'string' };
    field title   => { type => 'string' };
    field date    => { type => 'integer' };
    field updated => { type => 'integer' };
    field summary => { type => 'string' };
    field meta    => { type => 'object' };
}
MMApp->to_app;
my $M = MMApp->punk_app->model_instance('Post');

isa_ok $M->backend, 'Punk::Model::Markdown';
is $M->count({}), 4, 'one row per page, the draft not among them';
is_deeply [ map $_->{path}, @{ $M->search({ date => { '!=' => undef } },
                                          { order_by => [ date => 'desc' ] })->{rows} } ],
    [ '/newer', '/naïve', '/older' ], 'dated pages, newest first';
is_deeply [ map $_->{path}, @{ $M->search({ date => undef })->{rows} } ], ['/note'],
    'undated pages';

my $p = $M->get(path => '/older');
is $p->{url}, '/blog/older', 'get: url';
is $p->{title}, 'Older', '...title';
is $p->{meta}{tags}, '[a, b]', '...front matter';
is $p->{summary}, 'Old words.', '...summary';
is $p->{updated}, $p->{date}, '...updated defaults to the date';
is $M->get(path => '/naïve')->{title}, 'Naïve Café', 'characters';
is $M->get(path => '/draft'), undef, 'a draft is no row';

is $M->get(path => '/newer')->{summary}, 'The newer one.', 'summary from the description';
is $M->count({ title => { starts_with => 'N' } }), 2, 'filters work as on any model';
my $pg = $M->search({}, { limit => 2 });
ok $pg->{has_more_data} && $pg->{next}, 'paging';
is scalar @{ $M->search({}, { limit => 2, after => $pg->{next} })->{rows} }, 2, '...continues';

{
    my $r = $M->get(path => '/older');
    $r->{meta}{tags} = 'CHANGED';
    is $M->get(path => '/older')->{meta}{tags}, '[a, b]', 'rows are copies';
}

for my $w (qw(create update delete)) {
    my $err = do { local $@; eval { $w eq 'delete' ? $M->delete(path => '/older') : $M->$w({ path => '/x' }) }; $@ };
    like $err, qr/Punk::Model::Markdown: $w - the pages at \/blog\/ are the markdown files/,
        "$w croaks";
}

# ---- what it needs -------------------------------------------------------------------

{
    my $err = do { local $@; eval { Punk::Model::Markdown->new(database => { prefix => '/blog' }, table => 't', primary => 'path') }; $@ };
    like $err, qr/needs the application/, 'built by hand, without the app, it croaks';
    $err = do { local $@; eval { Punk::Model::Markdown->new(database => {}, table => 't', primary => 'path', app => MMApp->punk_app) }; $@ };
    like $err, qr/needs a `prefix`/, 'a database without a prefix croaks';
}
{
    eval <<'PERL' or die $@;
package MMNone;
use Punk;
database blog => { backend => 'Punk::Model::Markdown', prefix => '/nope' };
package MMNone::Model::P;
use Punk::Model;
database 'blog';
table 'p';
field path => { type => 'string', primary => 1 };
1;
PERL
    MMNone->to_app;
    my $err = do { local $@; eval { MMNone->punk_app->model_instance('P')->all }; $@ };
    like $err, qr/Punk::Model::Markdown: no markdown mount at '\/nope' \(there are none\)/,
        'an unknown prefix croaks as markdown_pages does';
}

# ---- the other backends ignore the app -------------------------------------------------

{
    my $d = File::Temp->newdir;
    eval <<"PERL" or die $@;
package MMJ;
use Punk;
database j => { backend => 'Punk::Model::JSONFile', file => '$d/j.json' };
package MMJ::Model::R;
use Punk::Model;
database 'j';
table 'r';
field id => { type => 'integer', primary => 1 };
1;
PERL
    MMJ->to_app;
    is MMJ->punk_app->model_instance('R')->count({}), 0, 'a backend that does not want the app is unaffected';
}

done_testing;
