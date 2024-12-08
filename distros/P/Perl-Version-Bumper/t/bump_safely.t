use v5.10;
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use List::Util qw( min );
use Perl::Version::Bumper qw( stable_version );

# t/lib
use lib path(__FILE__)->parent->child('lib')->stringify;
use TestFunctions;

test_dir(
    dir     => 'bump_safely',
    stop_at => min(             # stop at the earliest stable between those:
        stable_version,                         # - supported by the perl binary
        Perl::Version::Bumper->feature_version, # - supported by the module
    ),
    callback => sub {
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

done_testing;
