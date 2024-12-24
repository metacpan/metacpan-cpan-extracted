use v5.10;
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Perl::Version::Bumper qw(
  version_fmt
  stable_version
  stable_version_inc
);

my %callback = (
    bump => sub {
        my ( $perv, $src, $expected, $name, $ctx ) = @_;
        my $version = $perv->version;
        my $this    = qq{"$name" [$version]};
        $expected =~ s/use VERSION;/use $version;/g;

        # bump_ppi
        my $doc = $ctx->{$src} //= do {    # cache the PPI document
            my $ppi = PPI::Document->new( \$src );
            is( $ppi, D, "'$name' parsed by PPI" );
            $ppi;
        };
        is( $perv->bump_ppi($doc)->serialize, $expected, "$this ->bump_ppi" );

        # bump
        is( $perv->bump($src), $expected, "$this ->bump" );

        # bump_file
        my $file = Path::Tiny->tempfile;
        $file->spew($src);
        my $ran = $perv->bump_file($file);
        if ( $src eq $expected ) { is( $ran, !!0, "$this ->bump_file (same)" ); }
        else                     { is( $ran, !!1, "$this ->bump_file (mod')" ); }
        is( $file->slurp, $expected, "$this ->bump_file (expected update)" );
    },
    bump_safely => sub {
        my ( $perv, $src, $expected, $name, $ctx ) = @_;
        my $version = $perv->version;
        my $this    = "$name [$version]";

        # perform the version expectations bump
        $expected =~ s/use VERSION;/use $version;/g;

        # make a PPI document
        my $doc = $ctx->{$src} //= do {         # cache the PPI document
            my $ppi = PPI::Document->new( \$src );
            is( $ppi, D, "'$name' parsed by PPI" );
            $ppi;
        };

        # and a file
        my $file = Path::Tiny->tempfile;
        $file->spew($src);

        my ( $ran, %got );
        {
            local $SIG{__WARN__} = sub { };

            # silence errors
            open( \*OLDERR, '>&', \*STDERR ) or die "Can't dup STDERR: $!";
            open( \*STDERR, '>',  '/dev/null' )
              or die "Can't re-open STDERR: $!";

            $ran = eval { $perv->bump_file_safely($file) }
              or my $error = $@;    # catch (syntax) errors in the eval'ed code

            # get STDERR back, and warn about errors while compiling
            open( \*STDERR, '>&', \*OLDERR ) or die "Can't restore STDERR: $!";

            # throw the errors in the eval, if any
            die $error if $error;

            # collect the results
            $got{bump_ppi_safely}  = $perv->bump_ppi_safely($doc)->serialize;
            $got{bump_safely}      = $perv->bump_safely( $doc->serialize );
            $got{bump_file_safely} = $file->slurp;
        }

        # test the other two subs
        if ( $name =~ /DIE(?: *< *(v5.[0-9]+))?/ ) {    # compilation might fail
            if ($1) {    # on an older perl binary
                if ( $] < version_fmt($1) ) {
                    is( $ran, U, "$this ->bump_file_safely did not compile on $^V" );
                    $expected = $src;    # no change expected
                }
                else {
                    is( $ran, D, "$this ->bump_file_safely compiled on $^V" );
                }
            }
            else {    # no minimum version, always expected to fail compilation
                is( $ran, U, "$this ->bump_file_safely did not compile on $^V" );
                $expected = $src;    # no change expected
            }
        }
        else {                       # not expected to fail compilatin
            is( $ran, D, "$this ->bump_file_safely compiled on $^V" );
        }

        # check the expected result
        is( $got{$_}, $expected, "$this ->$_" )
          for qw( bump_ppi_safely bump_safely bump_file_safely );
    },
);

sub test_dir {
    my %args = @_;
    my $dir  = path(__FILE__)->parent->parent->child( $args{dir} );
    test_file( %args, file => $_ ) for sort $dir->children(qr/\.data\z/);
}

sub test_file {
    my %args       = @_;
    my $file       = $args{file};
    my $callback   = $callback{ $args{callback} };
    my $start_from = stable_version( $args{start_from} // 5.010 );
    my $stop_at    = stable_version_inc( $args{stop_at}
          // Perl::Version::Bumper->feature_version );
    die "Unknown test callback '$args{callback}'" unless $callback;

    # blocks of test data are separated by ##########
    my @tests = split /^########## (.*)\n/m, path($file)->slurp;
    return diag("$file is empty") unless @tests;

    shift @tests;    # drop the test preamble

    subtest $file => sub {

        my $ctx = {};    # a context kept for the entire file

        while ( my ( $name, $data ) = splice @tests, 0, 2 ) {

            # sections starting at a given version number up to the next one
            # are separated by --- (the version is optional in the first one)
            my ( $src, @expected ) = split /^---(.*)\n/m, $data, -1;
            $expected[0] =~ s/\A *// if @expected;    # trim

            # assume no change up to the first version
            my $expected = $src //= '';

            # this is when we'll update our expectations
            my $next_version = defined $expected[0]
              ? $expected[0]
                  ? version_fmt( ( split / /, $expected[0] )[0] )
                  : 5.010    # bare --- (no version, default to v5.10)
              : $stop_at;    # no "expected" section (the empty case)

            my $todo;    # not a todo test by default
            my $version = $start_from;
            while ( $version < $stop_at ) {
                if ( $version >= $next_version ) {
                    ( my $version_todo, $expected ) = splice @expected, 0, 2;
                    ( undef, $todo ) = split / /, $version_todo, 2;
                    $expected[0] =~ s/\A *// if @expected;    # trim
                    $next_version = @expected
                      ? version_fmt( ( split / /, $expected[0] )[0] )
                      : $stop_at;
                }
                $todo &&= todo $todo;

                $callback->(
                    Perl::Version::Bumper->new( version => $version ),
                    $src, $expected, $name, $ctx
                );
            }

            # bump to  the next stable
            continue { $version = stable_version_inc( $version ) }

        }
    }
}

1;

__END__

This section describes the test data format.

Each test in a section marked with '##########', followed by a short
description of the test. It will be shown as part of the test message.

The individual test data is itself separated in multiple sub-sections,
marked by '---' followed by a Perl version number and an optional TODO
message. The first sub-section is the source code to bump, and each
following sub-section is the expected result for the given test.

The test is basically looping over stable Perl versions starting at v5.10
up to the latest version supported by Perl::Version::Bumper. (The module
can bump code to a version later than the perl running it.)

This is easier to describe with an example:

    ########## <test description>
    <input code>
    --- <version 1>
    <expected result 1>
    --- <version 2> <todo text>
    <expected result 2>
    --- <version 3>
    <expected result 3>

The <test description> will be used to produce the individual test
message, concatenated with the version the <input code> is being
bumped to.

From v5.10 up to <version 1>, the test expects the result to be equal
to <input code> (for example if the input code contains a `use v5.16;`
line, trying to update it to a lower version will not do anything).

From <version 1> up to <version 2> (not included), the test expects the
result to be equal to <expected result 1>.

From <version 2> up to <version 3> (not included), the test expects the
result to be equal to <expected result 1>. Since there's a <todo text>,
any failure will be marked as TODO.

From <version 3> up to the version of the running perl (included),
the test expects the result to be equal to <expected result 3>.

Tests stop as soon as the highest version supported by the module is
reached.

IMPORTANT: This implies the version numbers must be in increasing order.

To simplify writing the expected results, every "use VERSION" will have
the "VERSION" replaced with the Perl version being tested.

The first "---" line can be empty, in which case the version is assumed
to be v5.10.

Note that some tests (like `t/bump_file_safely.t`) pick some additional
test constraints from the <test description>.
