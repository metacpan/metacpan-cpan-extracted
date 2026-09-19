#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/tests-covering.t - what the command passes on, and what it prints

=head1 DESCRIPTION

L<Perl::Tests::Covering> is mocked here: C<new> records its options, and
C<tests_covering> answers from a fixed list, so no test runs under coverage.

=cut

# Both import by being loaded, which ProhibitUnusedImports cannot see.
use Test2::V1 -i;                 ## no critic (ProhibitUnusedImports)
use Test2::Plugin::NoWarnings;    ## no critic (ProhibitUnusedImports)
use Test2::Tools::Exception qw{lives};
use Test2::Tools::Warnings  qw{warnings};
use Test::MockModule        qw{strict};
use Capture::Tiny           qw{capture};
use Cwd                     ();
use File::Temp              qw{tempdir};

use FindBin::libs;
use FindBin ();

ok( lives { require "$FindBin::Bin/../bin/tests-covering" }, "bin/tests-covering loads as a module" ) or bail_out("bin/tests-covering does not load: $@");

my $root = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
mkdir "$root/t" or die $!;

my ( @new_opts, @asked );
my $mock = Test::MockModule->new('Perl::Tests::Covering');
$mock->redefine(
    new => sub {
        my ( $class, %opts ) = @_;
        push @new_opts, \%opts;
        return $mock->original('new')->( $class, root => $root, cache_dir => "$root/.cache-bogus" );
    }
);
$mock->redefine(
    tests_covering => sub {
        my ( $self, @files ) = @_;
        push @asked, @files;
        return qw{t/a.t t/deeper/b.t};
    }
);

# What the other modes were asked, as [ method, arguments ].
my @calls;
$mock->redefine( tests_covering_diff => sub { shift; push @calls, [ diff => @_ ]; return 't/a.t' } );
$mock->redefine( tests_covering_sub  => sub { shift; push @calls, [ sub  => @_ ]; return 't/a.t' } );
$mock->redefine( files_covered_by    => sub { shift; push @calls, [ by   => @_ ]; return qw{lib/Foo.pm t/a.t} } );
$mock->redefine( refresh             => sub { push @calls, ['refresh']; return 't/a.t' } );

# main(@argv), with STDIN reading $stdin, run from $dir.  Returns the exit code,
# what it printed and what it warned.
sub run_main {
    my ( $dir, $stdin, @argv ) = @_;

    open my $in, '<', \$stdin or die $!;
    local *STDIN = $in;
    my $was = Cwd::getcwd();
    chdir $dir or die "Cannot chdir to $dir: $!";
    my $code;
    my ( $out, $err ) = capture { $code = Perl::Tests::Covering::Script::main(@argv) };
    chdir $was or die $!;
    return ( $code, $out, $err );
}

subtest main => sub {
    @new_opts = @asked = ();
    my ( $code, $out ) = run_main( $root, q{}, qw{lib/Foo.pm bin/foo} );
    is( $code,        0,                        'It exits 0 with an answer' );
    is( $out,         "t/a.t\nt/deeper/b.t\n",  'and prints each test, one per line' );
    is( \@asked,      [qw{lib/Foo.pm bin/foo}], 'The files on the command line are the ones asked about' );
    is( $new_opts[0], {},                       'With no options, the module picks every default' );

    @asked = ();
    ( $code, $out ) = run_main( "$root/t", "lib/Foo.pm\r\n\nbin/foo\n" );
    is( \@asked, [qw{lib/Foo.pm bin/foo}], 'With no files named, they are read from STDIN, without blank lines or line ends' );
    is( $out,    "a.t\ndeeper/b.t\n",      'The tests printed are relative to the current directory' );

    @new_opts = ();
    run_main( $root, q{}, qw{--root /bogus/root --test-dir t --test-dir xt --lib lib --lib t/lib --jobs 4 --cache-dir /bogus/cache x} );
    is(
        $new_opts[0],
        { root => '/bogus/root', tests => [qw{t xt}], lib => [qw{lib t/lib}], jobs => 4, cache_dir => '/bogus/cache' },
        'Each option reaches the module under its own name'
    );

    @new_opts = ();
    run_main( $root, q{}, qw{--map /bogus/map.pl --unexplained all x} );
    run_main( $root, q{}, qw{--no-map x} );
    is( \@new_opts, [ { map => '/bogus/map.pl', unexplained => 'all' }, { map => undef } ], '--map names the map, --no-map passes undef, and --unexplained passes through' );

    my ( $both, $both_out );
    my $warned = warnings { ( $both, $both_out ) = run_main( $root, q{}, qw{--map /bogus/map.pl --no-map x} ) };
    like( $warned, [qr/Give --map or --no-map, not both/], '--map with --no-map is refused, and says why' );
    is( [ $both, $both_out ], [ 2, q{} ], 'with exit 2' );

    my ( $bad, $bad_out, $bad_err );
    my $warnings = warnings { ( $bad, $bad_out, $bad_err ) = run_main( $root, q{}, qw{--bogus} ) };
    like( $warnings, [qr/Unknown option: bogus/], 'An option it does not know is named in a warning' );
    is( $bad,     2,   'and exits 2' );
    is( $bad_out, q{}, 'and prints nothing where the tests would go' );
    like( $bad_err, qr/tests-covering \[options\] FILE/, 'but prints the synopsis to STDERR' );

    my ( $help, $help_out ) = run_main( $root, q{}, qw{--help} );
    is( $help, 0, '--help exits 0' );
    like( $help_out, qr/--cache-dir DIR/, 'and prints the options to STDOUT' );
};

subtest 'main, in each mode' => sub {
    my $diff = "diff --git a/x b/x\n\n \n-old\n+new\n";

    @calls = ();
    my ( $code, $out ) = run_main( $root, $diff, '--diff' );
    is( \@calls, [ [ diff => $diff ] ], '--diff hands STDIN over whole, blank lines too' );
    is( $out,    "t/a.t\n",             'and prints the tests' );

    @calls = ();
    ( $code, $out ) = run_main( $root, q{}, qw{--sub up lib/Foo.pm} );
    is( \@calls, [ [ sub => 'lib/Foo.pm', 'up' ] ], '--sub asks about the sub in the one file' );

    @calls = ();
    ( $code, $out ) = run_main( $root, q{}, qw{--by t/a.t t/b.t} );
    is( \@calls, [ [ by => 't/a.t' ], [ by => 't/b.t' ] ], '--by asks about each test' );
    is( $out,    "lib/Foo.pm\nt/a.t\n",                    'and prints each file once' );

    @calls = ();
    ( $code, $out ) = run_main( $root, "not read\n", '--refresh' );
    is( \@calls, [ ['refresh'] ], '--refresh refreshes' );
    is( $out,    q{},             'and prints nothing, not even the tests it ran' );

    foreach my $case (
        [ [qw{--diff --refresh}],     qr/Give one of/,              'Two modes' ],
        [ [qw{--diff lib/Foo.pm}],    qr/--diff takes no files/,    '--diff with a file' ],
        [ [qw{--refresh lib/Foo.pm}], qr/--refresh takes no files/, '--refresh with a file' ],
        [ [qw{--sub up}],             qr/exactly one file/,         '--sub with no file' ],
        [ [qw{--sub up a.pm b.pm}],   qr/exactly one file/,         '--sub with two' ],
    ) {
        my ( $argv, $says, $what ) = @$case;
        @calls = ();
        my ( $exit, $printed );
        my $warned = warnings { ( $exit, $printed ) = run_main( $root, q{}, @$argv ) };
        like( $warned, [$says], "$what is refused, and says why" );
        is( [ $exit, $printed, \@calls ], [ 2, q{}, [] ], 'with exit 2, and without asking anything' );
    }
};

subtest read_names => sub {
    open my $fh, '<', \"a\nb\r\n\n\nc" or die $!;
    is( [ Perl::Tests::Covering::Script::read_names($fh) ], [qw{a b c}], 'One name a line, with the line end and the blank lines dropped' );
};

done_testing();
