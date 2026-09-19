#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/Perl-Tests-Covering.t - which tests it reports, and when it runs one again

=head1 DESCRIPTION

Every case is a small distribution written to a temporary directory, with a
cache directory of its own.

The coverage run itself is mocked: C<_run_tests> answers from C<%LOADS>, a list
of what each test loads, instead of running the test.  So these cases are
about the records and the cache.  F<t/integration-Perl-Tests-Covering.t> runs
the tests under Devel::Cover for real.

=cut

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use Test2::Tools::Exception qw{dies lives};
use Test::MockModule        qw{strict};
use Config                  ();
use Cwd                     ();
use File::Path              qw{make_path};
use File::Slurper           ();
use File::Spec              ();
use File::Temp              qw{tempdir};
use IO::Compress::Gzip      ();
use Readonly;

use FindBin::libs;

use FakeDiff  qw{change_lines git_blob};
use WriteFile qw{write_file};

use Perl::Tests::Covering ();

# What each test loads, besides itself, as the mocked coverage run reports it.
our %LOADS;

# The lines of each file that each test runs, and the lines of each file that
# Devel::Cover counts a statement on.  A file with no entry in %STATEMENTS has
# no lines in the record, as when Devel::Cover did not see it.
our ( %EXECUTED, %STATEMENTS );

# The tests the mocked coverage run was asked to run, in order.
our @RAN;

my $mock = Test::MockModule->new('Perl::Tests::Covering');
$mock->redefine(
    _run_tests => sub {
        my ( $self, @tests ) = @_;
        push @RAN, @tests;
        return { map { $_ => fake_record( $self->root(), $_ ) } @tests };
    }
);

# The record a run of $test would leave, from %LOADS, %EXECUTED and %STATEMENTS.
sub fake_record {
    my ( $root, $test ) = @_;

    my %record = ( loaded => {}, executed => {}, versions => {} );
    foreach my $rel ( grep { -e File::Spec->catfile( $root, $_ ) } $test, @{ $LOADS{$test} // [] } ) {
        my $content = File::Slurper::read_binary( File::Spec->catfile( $root, $rel ) );
        my $blob    = $record{loaded}{$rel} = git_blob($content);
        next if !$STATEMENTS{$rel};
        $record{executed}{$rel}  = $EXECUTED{$test}{$rel} // [];
        $record{versions}{$blob} = { %{ Perl::Tests::Covering::_layout($content) }, statements => $STATEMENTS{$rel} };
    }
    return \%record;
}

sub sha1_of {
    my ( $root, $rel ) = @_;
    return git_blob( File::Slurper::read_binary( File::Spec->catfile( $root, $rel ) ) );
}

# A distribution: two modules, a script, and three tests.
sub dist {
    my $root = tempdir( CLEANUP => 1 );
    write_file( $root, 'dist.ini',          "name = Bogus\n" );
    write_file( $root, 'lib/Foo.pm',        "package Foo; 1;\n" );
    write_file( $root, 'lib/Bar.pm',        "package Bar; 1;\n" );
    write_file( $root, 'bin/foo',           "use Foo;\n" );
    write_file( $root, 't/a.t',             "use Foo;\n" );
    write_file( $root, 't/b.t',             "system 'bin/foo';\n" );
    write_file( $root, 't/deeper/c.t',      "use Bar;\n" );
    write_file( $root, 't/lib/Helper.pm',   "package Helper; 1;\n" );
    write_file( $root, 't/data/not-a-test', "1\n" );
    return Cwd::abs_path($root);
}

sub covering {
    my ( $root, %opts ) = @_;
    return Perl::Tests::Covering->new( root => $root, cache_dir => File::Spec->catdir( $root, '.cache-bogus' ), %opts );
}

# Runs $code with the current directory at $dir, and returns what it returns.
sub in_dir {
    my ( $dir, $code ) = @_;
    my $was = Cwd::getcwd();
    chdir $dir or die "Cannot chdir to $dir: $!";
    my @got = eval { $code->() };
    my $err = $@;
    chdir $was or die "Cannot chdir back to $was: $!";
    die $err if $err;
    return @got;
}

local %LOADS = (
    't/a.t'        => ['lib/Foo.pm'],
    't/b.t'        => [ 'bin/foo', 'lib/Foo.pm' ],
    't/deeper/c.t' => ['lib/Bar.pm'],
);

subtest new => sub {
    my $root = dist();

    like( dies { Perl::Tests::Covering->new( root => $root, bogus => 1 ) },         qr/Unknown option\(s\).*bogus/, 'An option it does not know is an error, not ignored' );
    like( dies { Perl::Tests::Covering->new( root => "$root/nonexistent-bogus" ) }, qr/No root/,                    'A root that does not exist is an error' );

    foreach my $jobs ( 0, -1, 'x', '1.5', q{} ) {
        like( dies { covering( $root, jobs => $jobs ) }, qr/jobs must be/, "jobs => '$jobs' is refused" );
    }
    ok( lives { covering( $root, jobs => 1 ) }, 'jobs => 1, the smallest, is accepted' ) or note($@);

    like( dies { covering( $root, tests => 't' ) },        qr/tests must be a list/, 'tests as one string, not a list, is refused' );
    like( dies { covering( $root, lib   => { a => 1 } ) }, qr/lib must be a list/,   'lib as a hash is refused' );

    my ($found) = in_dir( "$root/lib", sub { Perl::Tests::Covering->new( cache_dir => "$root/.cache-bogus" )->root() } );
    is( $found, $root, 'With no root, the nearest directory above with a dist.ini is the root' );

    my $bare = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
  SKIP: {
        skip 'a directory above the temporary directory looks like a distribution', 1 if Perl::Tests::Covering::_find_root($bare);
        like(
            dies {
                in_dir( $bare, sub { Perl::Tests::Covering->new() } )
            },
            qr/No root: no distribution above/,
            'With no root and none above, it says so'
        );
    }
};

subtest root => sub {
    my $root = dist();
    my $link = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'link-bogus' );
    symlink $root, $link or skip_all("Cannot symlink here: $!");

    is( covering($link)->root(), $root, 'A root reached by a symbolic link is the directory itself, so it has one cache' );
};

subtest tests => sub {
    my $root = dist();

    is( [ covering($root)->tests() ], [qw{t/a.t t/b.t t/deeper/c.t}], 'Every .t under t/, in subdirectories too, and nothing else' );

    write_file( $root, 'xt/author.t', "1;\n" );
    is( [ covering( $root, tests => [qw{t xt nonexistent-bogus}] )->tests() ], [qw{t/a.t t/b.t t/deeper/c.t xt/author.t}], 'tests names the directories, and one that is not there adds nothing' );
};

subtest refresh => sub {
    my $root = dist();

    local @RAN;
    is( [ covering($root)->refresh() ], [qw{t/a.t t/b.t t/deeper/c.t}], 'With no cache, every test runs' );
    ok( -d "$root/.cache-bogus", 'and the cache is written' );

    @RAN = ();
    is( [ covering($root)->refresh() ], [], 'A new object with the same cache runs nothing' );
    is( \@RAN,                          [], 'and asks for no coverage run' );

    write_file( $root, 't/a.t', "use Foo; 1;\n" );
    is( [ covering($root)->refresh() ], ['t/a.t'], 'A changed test runs again, and only it' );

    write_file( $root, 'lib/Foo.pm', "package Foo; our \$x = 1; 1;\n" );
    is( [ covering($root)->refresh() ], [qw{t/a.t t/b.t}], 'A changed module runs again each test that loaded it' );

    write_file( $root, 't/lib/Helper.pm', "package Helper; 2;\n" );
    is( [ covering($root)->refresh() ], [], 'A change to a file no test loaded runs nothing' );

    write_file( $root, 't/d.t', "1;\n" );
    is( [ covering($root)->refresh() ], ['t/d.t'], 'A new test runs' );

    unlink "$root/lib/Bar.pm" or die $!;
    is( [ covering($root)->refresh() ], ['t/deeper/c.t'], 'A test that loaded a file which is gone runs again' );

    is( [ covering( $root, lib => [qw{lib t/lib}] )->refresh() ], [qw{t/a.t t/b.t t/d.t t/deeper/c.t}], 'Other lib directories make every record stale' );
    is( [ covering($root)->refresh() ],                           [qw{t/a.t t/b.t t/d.t t/deeper/c.t}], 'and so does going back, since the cache holds one configuration' );

    my ($cache) = glob "$root/.cache-bogus/*.json.gz";
    write_file( $root, File::Spec->abs2rel( $cache, $root ), 'not gzip' );
    is( [ covering($root)->refresh() ], [qw{t/a.t t/b.t t/d.t t/deeper/c.t}], 'A cache that does not decompress is an empty one, not an error' );

    my $blocked = write_file( $root, 'cache-bogus-is-a-file', q{} );
    ok( lives { covering( $root, cache_dir => "$blocked/sub" )->refresh() }, 'A cache that cannot be written is not an error' ) or note($@);
};

subtest tests_covering => sub {
    my $root = dist();

    my $covering = covering($root);
    is( [ $covering->tests_covering("$root/lib/Foo.pm") ],                       [qw{t/a.t t/b.t}],              'A module is covered by each test that loads it, directly or through a script' );
    is( [ $covering->tests_covering("$root/bin/foo") ],                          ['t/b.t'],                      'A script is covered by the test that runs it' );
    is( [ $covering->tests_covering("$root/t/a.t") ],                            ['t/a.t'],                      'A test covers itself' );
    is( [ $covering->tests_covering( "$root/lib/Foo.pm", "$root/lib/Bar.pm" ) ], [qw{t/a.t t/b.t t/deeper/c.t}], 'Several files are covered by the tests of each, once' );
    is( [ $covering->tests_covering("$root/t/lib/Helper.pm") ],                  [],                             'A file no test loads is covered by nothing' );
    is( [ $covering->tests_covering('/bogus/lib/Foo.pm') ],                      [],                             'A file outside the root is covered by nothing' );
    is( [ $covering->tests_covering() ],                                         [],                             'No files, no tests' );

    is( [ in_dir( "$root/lib", sub { $covering->tests_covering('Foo.pm') } ) ], [qw{t/a.t t/b.t}], 'A relative file is relative to the current directory' );

    # c.t now loads Foo as well; its old record says it does not.
    local $LOADS{'t/deeper/c.t'} = [qw{lib/Bar.pm lib/Foo.pm}];
    write_file( $root, 't/deeper/c.t', "use Bar; use Foo;\n" );
    is( [ $covering->tests_covering("$root/lib/Foo.pm") ], [qw{t/a.t t/b.t t/deeper/c.t}], 'A test that loads the file only since it changed is reported' );

    # c.t no longer loads Bar; its old record says it does.
    local $LOADS{'t/deeper/c.t'} = ['lib/Foo.pm'];
    write_file( $root, 't/deeper/c.t', "use Foo;\n" );
    is( [ $covering->tests_covering("$root/lib/Bar.pm") ], ['t/deeper/c.t'], 'A test that loaded the file until it changed is reported' );

    unlink "$root/lib/Bar.pm" or die $!;
    is( [ covering($root)->tests_covering("$root/lib/Bar.pm") ], [], 'A deleted file nothing loaded any more is covered by nothing' );

    unlink "$root/t/b.t" or die $!;
    is( [ covering($root)->tests_covering("$root/bin/foo") ], [], 'A test that is gone is not reported, although its old record covers the file' );
};

subtest 'tests_covering the deletion of a module' => sub {
    my $root = dist();
    covering($root)->refresh();

    unlink "$root/lib/Foo.pm" or die $!;
    local $LOADS{'t/a.t'} = [];
    local $LOADS{'t/b.t'} = ['bin/foo'];
    is( [ covering($root)->tests_covering("$root/lib/Foo.pm") ], [qw{t/a.t t/b.t}], 'A deleted module is covered by the tests that loaded it, which are the ones it breaks' );
};

# A module whose lines each test runs are known, and four tests of it: a.t
# runs sub a, b.t runs sub b, c.t only loads it and d.t does not.
Readonly::Scalar my $FOO => <<'END_FOO';
package Foo;
use strict;

our %S = (
    x => 1,
);

# Adds one.
sub a {
    my ($n) = @_;
    my %h = (
        k => 1,
    );
    if ( $n > 0 ) {
        return $n + 1;
    }
    return 0;
}

sub b {
    return 2;
}

=head1 NAME

Foo

=cut

1;
END_FOO

sub foo_dist {
    my $root = dist();
    write_file( $root, 'lib/Foo.pm', $FOO );
    write_file( $root, "t/$_.t",     "1;\n" ) for qw{a b c d};
    unlink "$root/t/deeper/c.t" or die $!;
    return $root;
}

# Runs $code with the loads and lines of the tests of foo_dist.
sub foo_records {
    my ($code) = @_;
    local %LOADS      = ( 't/a.t'      => ['lib/Foo.pm'], 't/b.t' => ['lib/Foo.pm'], 't/c.t' => ['lib/Foo.pm'], 't/d.t' => [] );
    local %STATEMENTS = ( 'lib/Foo.pm' => [ 2, 10, 11, 14, 15, 17, 21 ] );
    local %EXECUTED   = (
        't/a.t' => { 'lib/Foo.pm' => [ 2, 10, 11, 14, 15 ] },
        't/b.t' => { 'lib/Foo.pm' => [ 2, 21 ] },
        't/c.t' => { 'lib/Foo.pm' => [2] },
    );
    return $code->();
}

subtest _parse_diff => sub {
    my ($change) = Perl::Tests::Covering::_parse_diff(<<'DIFF');
diff --git a/lib/Foo.pm b/lib/Foo.pm
index 1234567..89abcde 100644
--- a/lib/Foo.pm
+++ b/lib/Foo.pm
@@ -3,2 +3,3 @@ sub a {
 context
-old four
+new four
+new five
@@ -10,0 +12,1 @@
+added before old eleven
@@ -20 +21,0 @@
--- a line that looks like a header, removed
\ No newline at end of file
DIFF
    is( [ @{$change}{qw{old new old_blob new_blob hunks}} ], [qw{lib/Foo.pm lib/Foo.pm 1234567 89abcde 3}], 'Paths without a/ and b/, the blobs, and the hunks' );
    is(
        $change->{blocks},
        [
            { at => 4,  deleted => [4],  added => [ 4, 5 ], deleted_text => ['old four'],                                    added_text => [ 'new four', 'new five' ] },
            { at => 11, deleted => [],   added => [12],     deleted_text => [],                                              added_text => ['added before old eleven'] },
            { at => 20, deleted => [20], added => [],       deleted_text => ['-- a line that looks like a header, removed'], added_text => [] },
        ],
        'A block replaced after context, code added where nothing was taken out, and a line taken out that reads like a header'
    );

    my @two = Perl::Tests::Covering::_parse_diff(<<'DIFF');
diff --git a/lib/Old.pm b/lib/New.pm
similarity index 100%
rename from lib/Old.pm
rename to lib/New.pm
diff --git a/lib/Gone.pm b/lib/Gone.pm
deleted file mode 100644
index 1234567..0000000
--- a/lib/Gone.pm
+++ /dev/null
@@ -1 +0,0 @@
-package Gone;
diff --git "a/lib/Tab\there.pm" "b/lib/Tab\there.pm"
--- "a/lib/Tab\there.pm"
+++ "b/lib/Tab\there.pm"
DIFF
    is(
        [ map { [ @{$_}{qw{old new}} ] } @two ],
        [ [qw{lib/Old.pm lib/New.pm}], [ 'lib/Gone.pm', undef ], [ ("lib/Tab\there.pm") x 2 ] ],
        'A rename, a deletion to /dev/null, and a quoted path'
    );
    ok( !$two[0]{hunks}, 'A rename with no changes has no hunks' );

    my ($plain) = Perl::Tests::Covering::_parse_diff("--- lib/Foo.pm\t2026-01-01 00:00:00\n+++ lib/Foo.pm\t2026-01-02 00:00:00\n\@\@ -1 +1 \@\@\n-a\n+b\n");
    is( [ @{$plain}{qw{old new}} ], [qw{lib/Foo.pm lib/Foo.pm}], 'A diff -u path keeps its directory and loses its date' );
    ok( !defined $plain->{old_blob}, 'and has no blob' );

    is( [ Perl::Tests::Covering::_parse_diff(q{}) ], [], 'An empty diff changes nothing' );
};

subtest _layout => sub {
    my $layout = Perl::Tests::Covering::_layout($FOO);
    ok( ( grep { $_->[0] == 9  && $_->[1] == 18 } @{ $layout->{spans} } ), 'sub a is one span, from its sub line to its brace' );
    ok( ( grep { $_->[0] == 11 && $_->[1] == 13 } @{ $layout->{spans} } ), 'A statement over three lines is one span' );
    ok( !( grep { $_->[0] == 12 } @{ $layout->{spans} } ), 'and what is inside its parentheses is not a statement of its own' );
    is( $layout->{inert}, [ 3, 7, 8, 19, 23 .. 29 ], 'The blank lines, the comment and the POD are inert, and no code is' );

    my $tricky = Perl::Tests::Covering::_layout( join "\n", 'my $x = <<EOT;', '# in a heredoc', q{}, 'EOT', 'my $y = "a', '# in a string', q{";}, q{} );
    is( $tricky->{inert}, [], 'A heredoc body or a string that looks like a comment or a blank line is not inert' );
    ok( ( grep { $_->[0] == 1 && $_->[1] == 4 } @{ $tricky->{spans} } ), 'A statement with a heredoc ends where the body does' );

    is( Perl::Tests::Covering::_layout(undef), undef, 'No content, no layout' );
};

subtest _touches => sub {
    my $version = { %{ Perl::Tests::Covering::_layout($FOO) }, statements => [ 2, 10, 11, 14, 15, 17, 21 ] };
    my $runs_a  = [ 2, 10, 11, 14, 15 ];
    my $touches = sub { Perl::Tests::Covering::_touches( $version, @_ ) };

    ok( $touches->( $runs_a,    [15], [] ),   'A statement the test ran' );
    ok( !$touches->( $runs_a,   [17], [] ),   'not a statement it did not run' );
    ok( !$touches->( [ 2, 21 ], [15], [] ),   'nor one of a sub it did not call' );
    ok( $touches->( $runs_a,    [12], [] ),   'The middle line of a statement it ran' );
    ok( $touches->( $runs_a,    [16], [] ),   'The brace that closes an if block it ran' );
    ok( $touches->( $runs_a,    [9],  [] ),   'The sub line of a sub it ran' );
    ok( !$touches->( [ 2, 21 ], [9],  [] ),   'but not of a sub it did not' );
    ok( $touches->( [2],        [5],  [] ),   'Code at the top of the file, which runs on loading, reaches a test that only loads it' );
    ok( $touches->( [2],        [1],  [] ),   'So does the package line' );
    ok( $touches->( [ 2, 21 ],  [],   [22] ), 'Code added inside sub b reaches a test that ran it' );
    ok( !$touches->( $runs_a,   [],   [22] ), 'and not a test that did not' );
    ok( $touches->( [2],        [],   [20] ), 'Code added between two subs reaches every test, as it runs on loading' );
    ok( $touches->( undef,      [],   [] ),   'A test with no lines recorded is reached' );
    ok( Perl::Tests::Covering::_touches( undef, $runs_a, [15], [] ), 'and so is one whose file has no layout' );
};

subtest tests_covering_diff => sub {
    my $diff_of = sub {
        my ( $root, @change ) = @_;
        foo_records( sub { covering($root)->refresh() } );
        return change_lines( $root, 'lib/Foo.pm', @change );
    };
    my $tests_for = sub {
        my ( $root, $diff ) = @_;
        local @RAN;
        my @tests = in_dir(
            $root,
            sub {
                foo_records( sub { covering($root)->tests_covering_diff($diff) } );
            }
        );
        is( \@RAN, [], 'and runs nothing to find out' );
        return \@tests;
    };

    my $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 15, 1, '        return $n + 2;' ) ), ['t/a.t'], 'A change to a line of sub a chooses the test that ran it' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 21, 1, '    return 3;' ) ), ['t/b.t'], 'A change to sub b chooses the test that ran that' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 17, 1, '    return -1;' ) ), [], 'A change to a line no test ran chooses none' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 8, 1, '# Adds one to n.' ) ), [], 'A change to a comment chooses none' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 26, 1, 'Foo, again' ) ), [], 'nor does one to POD' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 5, 1, '    x => 2,' ) ), [qw{t/a.t t/b.t t/c.t}], 'A change to code at the top of the file chooses every test that loads it' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 8, 1, 'foo();' ) ), [qw{t/a.t t/b.t t/c.t}], 'So does code put in place of a comment there' );

    $root = foo_dist();
    is( $tests_for->( $root, $diff_of->( $root, 20, 0, '# A comment.' ) ), [], 'A comment added between subs chooses none' );

    $root = foo_dist();
    my $diff = $diff_of->( $root, 20, 0, '# A comment.' );
    write_file( $root, 'lib/Foo.pm', "$FOO\n" );
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/b.t t/c.t}], 'but when the file is not what the diff made it, added lines count as code' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' );
    write_file( $root, 't/d.t', "2;\n" );
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/d.t}], 'A test that changed since its record, though not in the diff, is chosen as well' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' );
    write_file( $root, 't/e.t', "1;\n" );
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/e.t}], 'A test with no record is chosen' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' ) . change_lines( $root, 't/d.t', 1, 1, '2;' );
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/d.t}], 'A test in the diff is chosen' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' ) =~ s/index [0-9a-f]+/index 0123456/r;
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/b.t t/c.t}], 'When the old side is not the version recorded, every test that loaded the file is chosen' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' ) =~ s/^index .*\n//mr;
    is( $tests_for->( $root, $diff ), [qw{t/a.t t/b.t t/c.t}], 'and so when the diff does not say' );

    $root = foo_dist();
    foo_records( sub { covering($root)->refresh() } );
    rename "$root/lib/Foo.pm", "$root/lib/Moved.pm" or die $!;
    is(
        $tests_for->( $root, "diff --git a/lib/Foo.pm b/lib/Moved.pm\nsimilarity index 100%\nrename from lib/Foo.pm\nrename to lib/Moved.pm\n" ),
        [qw{t/a.t t/b.t t/c.t}],
        'Moving a file chooses every test that loaded it'
    );

    $root = foo_dist();
    $diff = $diff_of->( $root, 1, 30 );
    unlink "$root/lib/Foo.pm" or die $!;
    is( $tests_for->( $root, $diff =~ s{\+\+\+ b/lib/Foo.pm}{+++ /dev/null}r ), [qw{t/a.t t/b.t t/c.t}], 'and so does deleting it' );

    $root = foo_dist();
    $diff = $diff_of->( $root, 15, 1, '        return $n + 2;' );
    write_file( $root, 'lib/Foo.pm', $FOO );
    is( $tests_for->( $root, $diff =~ s{lib/Foo.pm}{../elsewhere/Foo.pm}gr ), [], 'A file outside the root chooses none' );
    is( $tests_for->( $root, q{} ),                                           [], 'nor does an empty diff' );
};

subtest tests_covering_sub => sub {
    my $root = foo_dist();
    my @for  = map {
        my $name = $_;
        [ foo_records( sub { covering($root)->tests_covering_sub( "$root/lib/Foo.pm", $name ) } ) ]
    } qw{a b Foo::a};
    is( \@for, [ ['t/a.t'], ['t/b.t'], ['t/a.t'] ], 'The tests that ran a sub, by its name with or without its package' );

    like(
        dies {
            foo_records( sub { covering($root)->tests_covering_sub( "$root/lib/Foo.pm", 'nonexistent_bogus' ) } )
        },
        qr/No sub nonexistent_bogus in/,
        'A sub that is not there is an error'
    );
    like( dies { covering($root)->tests_covering_sub( '/bogus/Foo.pm',    'a' ) }, qr/is not under/,                       'and so is a file outside the root' );
    like( dies { covering($root)->tests_covering_sub( "$root/lib/Foo.pm", q{} ) }, qr/needs a file and the name of a sub/, 'and so is an empty name' );
    like( dies { covering($root)->tests_covering_sub() }, qr/needs a file and the name of a sub/, 'and so is no arguments' );
};

subtest files_covered_by => sub {
    my $root = foo_dist();
    is( [ foo_records( sub { covering($root)->files_covered_by("$root/t/a.t") } ) ],  [qw{lib/Foo.pm t/a.t}], 'The files a test loaded, itself too' );
    is( [ foo_records( sub { covering($root)->files_covered_by('/bogus/t/a.t') } ) ], [],                     'A test outside the root loaded nothing' );
    like( dies { covering($root)->files_covered_by() }, qr/needs a test/, 'No test is an error' );
};

subtest 'new, with a map' => sub {
    my $root = foo_dist();
    my $code = sub { return };

    is( covering( $root, map => $code )->{map}, exact_ref($code), 'A code reference is the map' );
    is( covering($root)->{map},                 undef,            'With no map named and none at the root, there is none' );

    write_file( $root, '.tests-covering-map.pl', "use Foo; sub { \$Foo::LOADED_BY_MAP = 1; return 't/a.t' };\n" );
    write_file( $root, 'lib/Foo.pm',             "package Foo; our \$LOADED_BY_MAP; 1;\n" );
    my $found = covering($root)->{map};
    is( ref $found,                             'CODE', 'A map at the root is found without being named, and can load the modules of the distribution' );
    is( covering( $root, map => undef )->{map}, undef,  'map => undef means none, even when there is one at the root' );

    write_file( $root, 'maps/other.pl', "sub { return 't/b.t' };\n" );
    is( [ covering( $root, map => "$root/maps/other.pl" )->{map}->() ], ['t/b.t'], 'A map named by its file is loaded from it' );

    write_file( $root, 'maps/broken.pl', "sub {\n" );
    write_file( $root, 'maps/nocode.pl', "42;\n" );
    like( dies { covering( $root, map => "$root/maps/broken.pl" ) },            qr/Cannot compile the map/,            'A map that does not compile is an error' );
    like( dies { covering( $root, map => "$root/maps/nocode.pl" ) },            qr/returns something, not a code ref/, 'and so is one that returns no code reference' );
    like( dies { covering( $root, map => "$root/maps/nonexistent-bogus.pl" ) }, qr/Cannot read the map/,               'and so is one that is not there' );
    like( dies { covering( $root, map => [] ) },                                qr/map must be a code reference or/,   'and so is a map that is neither code nor a file' );

    like( dies { covering( $root, unexplained => 'some' ) }, qr/unexplained must be none or all, not 'some'/, 'unexplained is none or all' );
    ok( lives { covering( $root, unexplained => $_ ) }, "unexplained => '$_' is accepted" ) for qw{none all};
};

subtest 'tests_covering, with a map' => sub {
    my @asked;
    my $template = sub {
        my ( $root, %opts ) = @_;
        write_file( $root, 'templates/page.tt', "[% page %]\n" );
        return foo_records( sub { [ covering( $root, %opts )->tests_covering("$root/templates/page.tt") ] } );
    };
    my $map_saying = sub {
        my @answer = @_;
        return sub { push @asked, [@_]; return @answer };
    };

    is( $template->( foo_dist(), map => $map_saying->('t/d.t') ), ['t/d.t'],                          'A file no test loads is covered by the tests the map names' );
    is( \@asked,                                                  [ [ 'templates/page.tt', undef ] ], 'The map is asked about it once, relative to the root, with no change' );

    @asked = ();
    my $twice = foo_dist();
    write_file( $twice, 'templates/page.tt', "[% page %]\n" );
    foo_records( sub { covering( $twice, map => $map_saying->() )->tests_covering( ("$twice/templates/page.tt") x 2 ) } );
    is( scalar @asked, 1, 'even when it is named twice' );

    is( $template->( foo_dist(), map => $map_saying->('lib/Foo.pm') ),                                          [qw{t/a.t t/b.t t/c.t}],       'A file the map names stands in for it: its loaders cover it' );
    is( $template->( foo_dist(), map => $map_saying->( 't/d.t', 'lib/Foo.pm' ) ),                               [qw{t/a.t t/b.t t/c.t t/d.t}], 'Tests and files together' );
    is( $template->( foo_dist(), map => $map_saying->() ),                                                      [],                            'A map with nothing to say, and unexplained none, chooses nothing' );
    is( $template->( foo_dist(), map => $map_saying->(), unexplained => 'all' ),                                [qw{t/a.t t/b.t t/c.t t/d.t}], 'but with unexplained all, every test' );
    is( $template->( foo_dist(), map => undef, unexplained => 'all' ),                                          [qw{t/a.t t/b.t t/c.t t/d.t}], 'and so with no map at all' );
    is( $template->( foo_dist(), map => $map_saying->(Perl::Tests::Covering::NO_TESTS), unexplained => 'all' ), [],                            'A map says a file reaches no test with NO_TESTS' );

    my ( $got, $warned );
    $warned = warnings { $got = $template->( foo_dist(), map => $map_saying->( 't/nonexistent-bogus.t', '/bogus/abs' ), unexplained => 'all' ) };
    like( $warned, [ qr/the map said 't\/nonexistent-bogus.t' for templates\/page.tt, which is neither a test nor a file/, qr/'\/bogus\/abs'/ ], 'A path that is neither a test nor a file is dropped with a warning' );
    is( $got, [qw{t/a.t t/b.t t/c.t t/d.t}], 'and leaves the file unexplained, not explained away' );

    @asked = ();
    my $root = foo_dist();
    foo_records( sub { covering( $root, map => $map_saying->('t/d.t') )->tests_covering( "$root/lib/Foo.pm", "$root/t/d.t" ) } );
    is( \@asked, [], 'The map is not asked about a file a record names, nor about a test' );

    my $cwd = Cwd::getcwd();
    like(
        dies {
            $template->( foo_dist(), map => sub { die "no idea\n" } )
        },
        qr/no idea/,
        'A map that dies makes the question die'
    );
    is( Cwd::getcwd(), $cwd, 'with the working directory put back' );

    my $where;
    my $in = foo_dist();
    $template->( $in, map => sub { $where = Cwd::getcwd(); return } );
    is( $where, $in, 'The map runs in the root' );
};

subtest 'tests_covering_diff, with a map' => sub {
    my $root = foo_dist();
    write_file( $root, 'templates/page.tt', "[% page %]\n[%# a comment %]\n" );
    foo_records( sub { covering($root)->refresh() } );

    my @asked;
    my $map = sub { my ( $path, $change ) = @_; push @asked, [ $path, $change ]; return 't/d.t' };

    my $diff = change_lines( $root, 'templates/page.tt', 2, 1, '[%# a better comment %]' );
    is(
        [
            in_dir(
                $root,
                sub {
                    foo_records( sub { covering( $root, map => $map )->tests_covering_diff($diff) } );
                }
            )
        ],
        ['t/d.t'],
        'A file in a diff that no test loads is covered by what the map says'
    );
    is( scalar @asked,                         1,                           'The map is asked once' );
    is( $asked[0][0],                          'templates/page.tt',         'about the path relative to the root' );
    is( $asked[0][1]{blocks}[0]{deleted_text}, ['[%# a comment %]'],        'with the change, whose blocks have the removed text' );
    is( $asked[0][1]{blocks}[0]{added_text},   ['[%# a better comment %]'], 'and the added text' );

    $root = foo_dist();
    foo_records( sub { covering($root)->refresh() } );
    write_file( $root, 'templates/new.tt', "new\n" );
    write_file( $root, 'lib/New.pm',       "package New; 1;\n" );
    write_file( $root, 'bin/new',          "#!/usr/bin/perl\n1;\n" );
    $diff = join q{}, map { "diff --git a/$_ b/$_\nnew file mode 100644\nindex 0000000..1234567\n--- /dev/null\n+++ b/$_\n\@\@ -0,0 +1 \@\@\n+x\n" } qw{lib/New.pm bin/new};
    is(
        [
            in_dir(
                $root,
                sub {
                    foo_records( sub { covering( $root, unexplained => 'all' )->tests_covering_diff($diff) } );
                }
            )
        ],
        [],
        'A Perl file new in the diff is not unexplained, by its name or its #! line'
    );

    $diff = "diff --git a/templates/new.tt b/templates/new.tt\nnew file mode 100644\nindex 0000000..1234567\n--- /dev/null\n+++ b/templates/new.tt\n\@\@ -0,0 +1 \@\@\n+new\n";
    is(
        [
            in_dir(
                $root,
                sub {
                    foo_records( sub { covering( $root, unexplained => 'all' )->tests_covering_diff($diff) } );
                }
            )
        ],
        [qw{t/a.t t/b.t t/c.t t/d.t}],
        'but any other new file is'
    );

    # A new plugin, found by name at run time, and the template that comes
    # with it: nothing in the diff uses the plugin.
    my $plugin_diff = sub {
        my ( $dir, @files ) = @_;
        write_file( $dir, $_, "1;\n" ) for @files;
        return join q{}, map { "diff --git a/$_ b/$_\nnew file mode 100644\nindex 0000000..1234567\n--- /dev/null\n+++ b/$_\n\@\@ -0,0 +1 \@\@\n+1;\n" } @files;
    };
    my $chosen_with = sub {
        my ( $dir, $diff, %opts ) = @_;
        return [
            in_dir(
                $dir,
                sub {
                    foo_records( sub { covering( $dir, unexplained => 'all', %opts )->tests_covering_diff($diff) } );
                }
            )
        ];
    };
    my $plugins = sub {
        my ($path) = @_;
        return 'lib/Foo.pm'            if $path =~ m{\Alib/Foo/Plugin/.+[.]pm\z};
        return 'lib/Foo/Plugin/New.pm' if $path =~ m{\Atemplates/plugin/New[.]tt\z};
        return;
    };

    $root = foo_dist();
    foo_records( sub { covering($root)->refresh() } );
    $diff = $plugin_diff->( $root, 'lib/Foo/Plugin/New.pm' );
    is( $chosen_with->( $root, $diff, map => $plugins ),       [qw{t/a.t t/b.t t/c.t}], 'An added Perl file is asked about, and its stand-in chooses its loaders' );
    is( $chosen_with->( $root, $diff, map => sub { return } ), [],                      'An added Perl file the map says nothing about chooses nothing, even with unexplained all' );

    my $got;
    my $warned = warnings {
        $got = $chosen_with->( $root, $diff, map => sub { return 'nonexistent-bogus.pm' } )
    };
    like( $warned, [qr/the map said 'nonexistent-bogus.pm'/], 'An added Perl file the map says something wrong about is warned about' );
    is( $got, [qw{t/a.t t/b.t t/c.t t/d.t}], 'and is unexplained' );

    $root = foo_dist();
    foo_records( sub { covering($root)->refresh() } );
    $diff = $plugin_diff->( $root, 'lib/Foo/Plugin/New.pm', 'templates/plugin/New.tt' );
    is( $chosen_with->( $root, $diff, map => $plugins ), [qw{t/a.t t/b.t t/c.t t/d.t}], 'A stand-in that no test loads yet leaves its path unexplained, so every test runs' );
};

subtest 'NO_TESTS' => sub {
    my $root = foo_dist();
    write_file( $root, 'templates/page.tt', "[% page %]\n" );
    my $asking = sub {
        my (%opts) = @_;
        return [ foo_records( sub { covering( $root, unexplained => 'all', %opts )->tests_covering("$root/templates/page.tt") } ) ];
    };

    is( Perl::Tests::Covering::NO_TESTS(), q{}, 'NO_TESTS is the empty string, which no path is' );
    is( $asking->( map => sub { return Perl::Tests::Covering::NO_TESTS } ), [],                            'A path the map says reaches no test chooses none, even with unexplained all' );
    is( $asking->( map => sub { return q{} } ),                             [],                            'and so does the empty string' );
    is( $asking->( map => sub { return 'templates/page.tt' } ),             [qw{t/a.t t/b.t t/c.t t/d.t}], 'but the path itself is a stand-in that no test loads, and leaves it unexplained' );

    write_file( $root, '.tests-covering-map.pl', "use Perl::Tests::Covering qw{NO_TESTS};\nsub { return NO_TESTS, 't/d.t' };\n" );
    is( $asking->(), ['t/d.t'], 'A map file can import NO_TESTS, and return other paths after it' );
};

subtest _prune_cache => sub {
    my $root  = dist();
    my $cache = "$root/.cache-bogus";
    covering($root)->refresh();
    my ($ours) = glob "$cache/*.json.gz";

    my $gone = 'a' x 40;
    IO::Compress::Gzip::gzip( \'{}' => "$cache/$gone.json.gz", Comment => '/nonexistent-bogus' ) or die;
    write_file( $root, ".cache-bogus/${\( 'b' x 40 )}.json.gz", 'not gzip' );
    write_file( $root, '.cache-bogus/somebody-elses',           'keep' );

    Perl::Tests::Covering::_prune_cache($cache);
    ok( -e $ours,                              'The cache of a root that is there is kept' );
    ok( !-e "$cache/$gone.json.gz",            'The cache of a root that is gone is removed' );
    ok( !-e "$cache/${\( 'b' x 40 )}.json.gz", 'A cache whose header cannot be read is removed' );
    ok( -e "$cache/somebody-elses",            'A file that is not a cache is left alone' );
};

subtest _taint_switches => sub {
    my $root = dist();
    write_file( $root, 't/taint.t', "#!/usr/bin/perl -wT\n1;\n" );
    write_file( $root, 't/lower.t', "#! perl -t\n1;\n" );
    write_file( $root, 't/plain.t', "#!/usr/bin/perl -w\n# -T in a comment\n1;\n" );

    local $ENV{PERL5OPT} = q{-Mbogus::A -Mbogus::B='a b'};
    is(
        [ covering($root)->_taint_switches( 't/taint.t', [qw{/bogus/lib /bogus/own}], [qw{-MCover -MRecorder}] ) ],
        [ qw{-T -I/bogus/lib -I/bogus/own -MCover -MRecorder -Mbogus::A}, '-Mbogus::B=a b' ],
        'A -T test gets -T, then the libs as -I, then the modules, then PERL5OPT, which perl would otherwise ignore'
    );
    is( ( covering($root)->_taint_switches( 't/lower.t',             [],             [] ) )[0],       '-t', 'A -t test gets -t' );
    is( [ covering($root)->_taint_switches( 't/plain.t',             ['/bogus/lib'], ['-MCover'] ) ], [],   'A test without taint on its #! line gets nothing, and reads the environment' );
    is( [ covering($root)->_taint_switches( 't/nonexistent-bogus.t', [],             [] ) ],          [],   'A test that cannot be read gets nothing' );
};

subtest _split_path => sub {
    my $sep = $Config::Config{path_sep};
    is( [ Perl::Tests::Covering::_split_path("/bogus/a$sep$sep/bogus/b$sep") ], [qw{/bogus/a /bogus/b}], 'The directories of a list, without the empty ones' );
    is( [ Perl::Tests::Covering::_split_path(undef) ],                          [],                      'and none of a list that is not set' );
};

subtest _cover_switch => sub {
    my $root = tempdir( CLEANUP => 1 );
    my $odd  = "$root/a, b";
    make_path( "$odd/t", "$odd/lib" );
    write_file( $odd, 'dist.ini', q{} );

    my $switch = covering($odd)->_cover_switch('/bogus/db');
    unlike( $switch, qr/[\s]/, 'No whitespace in the switch, since perl splits PERL5OPT on it' );
    my ($opts) = $switch =~ m/\A-MDevel::Cover=(.*)\z/ or die "Not a Devel::Cover switch: $switch";
    my %opts   = split q{,}, $opts;
    is( $opts{-db}, '/bogus/db', 'Splitting on commas finds the database whole' );

    my $select = qr/$opts{-select}/;
    my $real   = Cwd::abs_path($odd);
    like( "$real/lib/Foo.pm", $select, 'The pattern selects a file under a root with a comma and a space in it' );
    like( 'lib/Foo.pm',       $select, 'and a relative one' );
    unlike( '/bogus/lib/Foo.pm', $select, 'but not one under some other root' );

    like( dies { covering($odd)->_cover_switch('/bogus/a,b') }, qr/comma or a space/, 'A database directory with a comma in it is refused, not mangled' );
};

done_testing();
