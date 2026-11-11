#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use File::Path ();
use Test::More;
use Punk::Command;

# punk api sync past the first run: a spec that grew an untagged operation
# whose first path segment names a controller that exists (the stub goes
# there), a new tagged group (a new file), a security scheme (the auth
# controller), all first as a dry run and then for real; a second sync with
# nothing to do; a method the spec no longer names; and the refusals: no
# application, no class, no spec, a spec with no operations.

plan skip_all => 'File::Raw::JSON required' unless eval { require File::Raw::JSON; 1 };
plan skip_all => 'Punk::Generate required' unless eval { require Punk::Generate; 1 };

my $base = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
sub slurp { my ($f) = @_; open my $fh, '<', $f or return ''; local $/; my $s = <$fh>; close $fh; return $s }
sub run_punk {
    my (@argv) = @_;
    my ($out, $err) = ('', '');
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    local $Punk::Command::OUT = $ofh;
    local $Punk::Command::ERR = $efh;
    my $code = Punk::Command->main(@argv);
    close $ofh; close $efh;
    return ($code, $out, $err);
}
sub op {
    my ($id, %o) = @_;
    return { operationId => $id, responses => { 200 => { description => 'ok' } }, %o };
}
sub spec_json {
    my (%paths) = @_;
    return File::Raw::JSON::file_json_encode({
        openapi => '3.1.0',
        info    => { title => 'Sync', version => '1' },
        paths   => \%paths,
        components => { securitySchemes => { key => { type => 'apiKey', in => 'header', name => 'X-Key' } } },
    });
}

my $dir = "$base/SyncApp";
my $v1 = "$base/v1.json";
spew($v1, spec_json(
    '/books'      => { get => op('allBooks', tags => [ 'Books' ]) },
    '/books/{id}' => { get => op('getBook',  tags => [ 'Books' ]) },
));
Punk::Generate->new(name => 'SyncApp', dir => $dir, api => $v1)->run;
my $ctrl = "$dir/lib/SyncApp/Controller/API";
ok(-f "$ctrl/Books.pm", 'the generated application has its Books controller');

# the spec grows
spew("$dir/openapi.json", spec_json(
    '/books'            => { get => op('allBooks', tags => [ 'Books' ]) },
    '/books/{id}'       => { get => op('getBook',  tags => [ 'Books' ]) },
    '/books/{id}/notes' => { get => op('bookNotes') },
    '/shelves'          => { get => op('allShelves', tags => [ 'Shelves' ]), post => op('addShelf', tags => [ 'Shelves' ], security => [ { key => [] } ]) },
));
{
    my ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir, '--dry-run');
    is($c, 0, 'a dry run exits 0') or diag $err;
    like($out, qr/^would add 3 stubs$/m, 'it would add the three new operations');
    like($out, qr/^\s+bookNotes\s+Books\.pm$/m, 'the untagged operation goes to the controller its path names');
    like($out, qr/^\s+allShelves\s+Shelves\.pm$/m, 'the new group to its own file');
    like($out, qr/^would create 2 files$/m, 'and would create that file and the auth controller');
    like($out, qr/^\s+Shelves\.pm \(2\)$/m, 'naming the group file');
    like($out, qr/^\s+Auth\.pm \(1\)$/m, 'and the auth class with its scheme count');
    ok(!-f "$ctrl/Shelves.pm", 'a dry run writes nothing');
    unlike(slurp("$ctrl/Books.pm"), qr/bookNotes/, 'not even a stub');
}
{
    my ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir);
    is($c, 0, 'the real sync exits 0') or diag $err;
    like($out, qr/^added 3 stubs$/m, 'it added the stubs');
    like($out, qr/^created 2 files$/m, 'and created the files');
    ok(-f "$ctrl/Shelves.pm", 'the group file exists');
    ok(-f "$ctrl/Auth.pm", 'and the auth controller');
    like(slurp("$ctrl/Books.pm"), qr/sub bookNotes/, 'the stub landed in Books.pm');
    like(slurp("$ctrl/Shelves.pm"), qr/sub allShelves.*sub addShelf/s, 'both shelf operations are in Shelves.pm');
}
{
    my ($c, $out) = run_punk('api', 'sync', '--dir', $dir);
    is($c, 0, 'a sync with nothing to do exits 0');
    like($out, qr/^every operation in the spec is implemented$/m, 'and says so');
}
{
    my $books = slurp("$ctrl/Books.pm");
    $books =~ s/^1;/sub retired { }\n1;/m or die "no 1; in Books.pm";
    spew("$ctrl/Books.pm", $books);
    my ($c, $out) = run_punk('api', 'sync', '--dir', $dir);
    is($c, 0, 'an orphan method is not an error');
    like($out, qr/^1 method with no operation in the spec \(left alone\)\n\s+retired$/m, 'but it is listed');
}

# ---- untagged operations whose homes differ ----------------------------------------
# Two untagged operations: one whose first segment names Books.pm, which
# exists, and one whose segment names nothing on disk. The first joins its
# siblings and the second gets the Default controller, created for it.
my %grown = (
    '/books'            => { get => op('allBooks', tags => [ 'Books' ]) },
    '/books/{id}'       => { get => op('getBook',  tags => [ 'Books' ]) },
    '/books/{id}/notes' => { get => op('bookNotes') },
    '/books/{id}/extra' => { get => op('bookExtra') },
    '/widgets'          => { get => op('allWidgets') },
    '/shelves'          => { get => op('allShelves', tags => [ 'Shelves' ]), post => op('addShelf', tags => [ 'Shelves' ], security => [ { key => [] } ]) },
);
{
    spew("$dir/openapi.json", spec_json(%grown));
    my ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir);
    is($c, 0, 'a sync with untagged operations of two homes exits 0') or diag $err;
    like($out, qr/^added 2 stubs$/m, 'both are added');
    like($out, qr/^created 1 file/m, 'one in a new file');
    like(slurp("$ctrl/Books.pm"), qr/sub bookExtra/, 'the one with siblings joins them');
    ok(-f "$ctrl/Default.pm", 'the other gets the Default controller');
    like(slurp("$ctrl/Default.pm"), qr/sub allWidgets/, 'with its stub');
}
# ---- a controller spelled without the closing 1; line -------------------------------
{
    my $books = slurp("$ctrl/Default.pm");
    $books =~ s/^1;[ \t]*$/1 ;/m or die "no 1; in Default.pm:\n$books";
    spew("$ctrl/Default.pm", $books);
    $grown{'/books/{id}/more'} = { get => op('bookMore') };
    spew("$dir/openapi.json", spec_json(%grown));
    my ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir);
    is($c, 0, 'a controller without the closing line still takes stubs') or diag $err;
    like(slurp("$ctrl/Default.pm"), qr/^1 ;\s.*sub bookMore/ms, 'appended after its last line');
}

# ---- refusals ------------------------------------------------------------------------
{
    my ($c, $out, $err) = run_punk('api', 'sync', '--dir', "$base/nowhere");
    is($c, 2, 'no application exits 2');
    like($err, qr/punk api: no application found/, 'and says so');
    ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir, '--spec', "$base/none.json");
    is($c, 2, 'a missing spec exits 2');
    like($err, qr/punk api: no such spec: .*none\.json/, 'naming it');
    spew("$base/empty.json", File::Raw::JSON::file_json_encode({ openapi => '3.1.0', info => { title => 'E', version => '1' }, paths => {} }));
    ($c, $out, $err) = run_punk('api', 'sync', '--dir', $dir, '--spec', "$base/empty.json");
    is($c, 1, 'a spec with no operations exits 1');
    like($err, qr/punk api: .*declares no operations/, 'saying why');
    my $noclass = "$base/noclass";
    File::Path::make_path($noclass);
    spew("$noclass/app.psgi", "sub { [ 200, [], [ 'x' ] ] };\n");
    spew("$noclass/openapi.json", slurp($v1));
    ($c, $out, $err) = run_punk('api', 'sync', '--dir', $noclass);
    is($c, 2, 'an application file naming no class exits 2');
    like($err, qr/cannot work out the application class/, 'and says so');
}

done_testing;
