#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/integration-Perl-Tests-Covering.t - what Devel::Cover says each test loads

=head1 DESCRIPTION

The tests of a small distribution really run under Devel::Cover here, in child
perls, so this is where a change in what Devel::Cover records shows up.  That
is slow next to the rest, so it runs only with C<RELEASE_TESTING=1>.

=cut

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use Capture::Tiny       qw{capture};
use Cwd                 ();
use File::Slurper       ();
use File::Slurper::Temp ();
use File::Spec          ();
use File::Temp          qw{tempdir};

use FindBin::libs;

use FakeDiff  qw{change_lines};
use WriteFile qw{write_file};

skip_all('Set RELEASE_TESTING=1 to run the tests of a distribution under Devel::Cover') if !$ENV{RELEASE_TESTING};

use Perl::Tests::Covering ();

# Tests that load a module, one that runs a script in a child perl, one that
# finds its lib by FindBin, one under taint, and one that fails loudly.
my $root = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
write_file( $root, 'dist.ini',               "name = Bogus\n" );
write_file( $root, 'lib/Foo.pm',             "package Foo;\nsub a { 1 }\nsub b { 2 }\n1;\n" );
write_file( $root, 'lib/Foo/NeverCalled.pm', "package Foo::NeverCalled;\nsub x { 1 }\n1;\n" );
write_file( $root, 'lib/Bar.pm',             "package Bar;\nsub c { 3 }\n1;\n" );
write_file( $root, 'lib/Unloaded.pm',        "package Unloaded;\n1;\n" );
write_file( $root, 'bin/foo',                "use Foo;\nprint Foo::b(), qq{\\n};\n" );
write_file( $root, 't/lib/Helper.pm',        "package Helper;\nsub h { 1 }\n1;\n" );
write_file( $root, 't/a.t',                  "use Test::More;\nuse Foo;\nuse Foo::NeverCalled;\nok( Foo::a() );\ndone_testing;\n" );
write_file( $root, 't/b.t',                  "use Test::More;\nmy \$out = `\$^X bin/foo`;\nis( \$out, qq{2\\n} );\ndone_testing;\n" );
write_file( $root, 't/c.t',                  "use Test::More;\nuse FindBin;\nuse lib qq{\$FindBin::Bin/../lib}, qq{\$FindBin::Bin/lib};\nuse Bar;\nuse Helper;\nok( Bar::c() && Helper::h() );\ndone_testing;\n" );
write_file( $root, 't/taint.t',              "#!perl -T\nuse Test::More;\nuse Bar;\nok( Bar::c() );\ndone_testing;\n" );
write_file( $root, 't/loud.t',               "print qq{not ok 1 - leaked\\n};\nprint STDERR qq{leaked\\n};\ndie qq{on purpose\\n};\n" );

my %cover = ( root => $root, cache_dir => File::Spec->catdir( $root, '.cache-bogus' ) );

subtest 'tests_covering, from real coverage runs' => sub {
    my $covering = Perl::Tests::Covering->new( %cover, jobs => 2 );

    my ( $out, $err, @ran ) = capture { $covering->refresh() };
    is( \@ran, [qw{t/a.t t/b.t t/c.t t/loud.t t/taint.t}], 'Every test runs the first time, two at once' );
    is( $out,  q{},                                        'Nothing a test prints reaches STDOUT' );
    is( $err,  q{},                                        'or STDERR' );

    is( [ $covering->tests_covering("$root/lib/Foo.pm") ],             [qw{t/a.t t/b.t}],     'A module is covered by the test that calls it and by the test whose child perl does' );
    is( [ $covering->tests_covering("$root/lib/Foo/NeverCalled.pm") ], ['t/a.t'],             'A module that is loaded but never called is covered' );
    is( [ $covering->tests_covering("$root/bin/foo") ],                ['t/b.t'],             'A script is covered by the test that runs it in a child perl' );
    is( [ $covering->tests_covering("$root/lib/Bar.pm") ],             [qw{t/c.t t/taint.t}], 'A module is covered by a test found through FindBin, and by a test under -T' );
    is( [ $covering->tests_covering("$root/t/lib/Helper.pm") ],        ['t/c.t'],             'A test helper is covered' );
    is( [ $covering->tests_covering("$root/t/loud.t") ],               ['t/loud.t'],          'A test that dies still covers itself' );
    is( [ $covering->tests_covering("$root/lib/Unloaded.pm") ],        [],                    'A module no test loads is covered by nothing' );

    ok( !-e "$root/cover_db", 'Nothing is written to the cover_db of the distribution' );
};

subtest 'refresh, from real coverage runs' => sub {
    is( [ Perl::Tests::Covering->new(%cover)->refresh() ], [], 'A second object runs nothing' );

    write_file( $root, 'lib/Bar.pm', "package Bar;\nuse Unloaded;\nsub c { 3 }\n1;\n" );
    my $covering = Perl::Tests::Covering->new(%cover);
    is( [ $covering->tests_covering("$root/lib/Unloaded.pm") ], [qw{t/c.t t/taint.t}], 'A module that a changed module starts to load is covered after the tests of that module run again' );
};

# A module with a sub on many lines, and tests that each run a different part
# of it: the lines Devel::Cover counts are what the choice by hunk rests on.
my $hunks = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
write_file( $hunks, 'dist.ini',     q{} );
write_file( $hunks, 'lib/Steps.pm', join "\n", 'package Steps;', 'our %LIMIT = (', '    top => 10,', ');', 'sub up {', '    my ($n) = @_;', '    if ( $n < $LIMIT{top} ) {', '        return $n + 1;', '    }', '    return $n;', '}', 'sub down {', '    my ($n) = @_;', '    return $n - 1;', '}', '1;', q{} );
write_file( $hunks, 't/up.t',       "use Test::More;\nuse Steps;\nis( Steps::up(1), 2 );\ndone_testing;\n" );
write_file( $hunks, 't/top.t',      "use Test::More;\nuse Steps;\nis( Steps::up(10), 10 );\ndone_testing;\n" );
write_file( $hunks, 't/down.t',     "#!perl -T\nuse Test::More;\nuse Steps;\nis( Steps::down(1), 0 );\ndone_testing;\n" );
write_file( $hunks, 't/none.t',     "use Test::More;\nok(1);\ndone_testing;\n" );

# A test that reads a template and loads no module for it, and the map that
# says so, where the module finds it without being told.
write_file( $hunks, 'templates/greeting.tt',  "Hello [% name %]\n" );
write_file( $hunks, 't/greet.t',              q{use Test::More; open my $fh, '<', 'templates/greeting.tt' or die; like( scalar <$fh>, qr/Hello/ ); done_testing;} . "\n" );
write_file( $hunks, '.tests-covering-map.pl', q{sub { my ($path) = @_; return $path =~ m{\Atemplates/} ? 't/greet.t' : () };} . "\n" );

my %hunk_cover = ( root => $hunks, cache_dir => File::Spec->catdir( $hunks, '.cache-bogus' ) );
my $steps      = File::Slurper::read_binary("$hunks/lib/Steps.pm");

# The tests the change that change_lines(@change) makes could break.
sub chosen_for {
    my (@change) = @_;

    Perl::Tests::Covering->new(%hunk_cover)->refresh();
    my $diff = change_lines( $hunks, 'lib/Steps.pm', @change );
    my $was  = Cwd::getcwd();
    chdir $hunks or die $!;
    my @tests = Perl::Tests::Covering->new(%hunk_cover)->tests_covering_diff($diff);
    chdir $was or die $!;
    File::Slurper::Temp::write_binary( "$hunks/lib/Steps.pm", $steps );
    return \@tests;
}

subtest 'tests_covering_diff, from real coverage runs' => sub {
    is( chosen_for( 8,  1, '        return $n + 2;' ),         ['t/up.t'],                    'A line only one test ran chooses that test' );
    is( chosen_for( 10, 1, '    return $n * 1;' ),             ['t/top.t'],                   'The other branch chooses the other test' );
    is( chosen_for( 7,  1, '    if ( $n <= $LIMIT{top} ) {' ), [qw{t/top.t t/up.t}],          'The condition both ran chooses both' );
    is( chosen_for( 14, 1, '    return $n - 2;' ),             ['t/down.t'],                  'A line of a sub run only under -T chooses that test' );
    is( chosen_for( 3,  1, '    top => 11,' ),                 [qw{t/down.t t/top.t t/up.t}], 'Code at the top of the file chooses every test that loads it' );
};

subtest 'tests_covering_sub and files_covered_by, from real coverage runs' => sub {
    my $covering = Perl::Tests::Covering->new(%hunk_cover);
    is( [ $covering->tests_covering_sub( "$hunks/lib/Steps.pm", 'up' ) ],   [qw{t/top.t t/up.t}],      'The tests that ran sub up' );
    is( [ $covering->tests_covering_sub( "$hunks/lib/Steps.pm", 'down' ) ], ['t/down.t'],              'The test that ran sub down' );
    is( [ $covering->files_covered_by("$hunks/t/up.t") ],                   [qw{lib/Steps.pm t/up.t}], 'The files a test loaded' );
    is( [ $covering->files_covered_by("$hunks/t/none.t") ],                 ['t/none.t'],              'A test that loads nothing of the distribution loaded itself' );
};

subtest 'the map, from real coverage runs' => sub {
    my $covering = Perl::Tests::Covering->new(%hunk_cover);
    is( [ $covering->files_covered_by("$hunks/t/greet.t") ],           ['t/greet.t'], 'A test that reads a template does not load it' );
    is( [ $covering->tests_covering("$hunks/templates/greeting.tt") ], ['t/greet.t'], 'so the map at the root says which test it reaches' );

    my $diff = change_lines( $hunks, 'templates/greeting.tt', 1, 1, 'Hi [% name %]' );
    my $was  = Cwd::getcwd();
    chdir $hunks or die $!;
    my @tests = Perl::Tests::Covering->new(%hunk_cover)->tests_covering_diff($diff);
    chdir $was or die $!;
    is( \@tests, ['t/greet.t'], 'and the same in a diff' );
};

done_testing();
