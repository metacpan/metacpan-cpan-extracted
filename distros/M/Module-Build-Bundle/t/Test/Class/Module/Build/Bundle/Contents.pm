package Test::Class::Module::Build::Bundle::Contents;

use strict;
use warnings;
use Test::More;
use File::Copy qw(cp);
use Test::Exception;
use File::Tempdir;
use File::stat;
use File::Slurp;    #read_file
use Env qw($TEST_VERBOSE);

use base qw(Test::Class);

use FindBin;
use lib "$FindBin::Bin/../t";

sub setup : Test(setup => 2) {
    my $test = shift;

    use_ok('Module::Build::Bundle');

    ok( my $build = Module::Build::Bundle->new(
            module_name   => 'Dummy',
            dist_version  => '6.66',
            dist_author   => 'jonasbn',
            dist_abstract => 'this is a dummy',
            requires      => {
                'Module::Build' => '0',
                'Text::Soundex' => '2.00',
            },
        ),
        'calling constructor'
    );

    $test->{build} = $build;
    $test->{file}  = 'Dummy.pm';

    my $tmpdir = File::Tempdir->new();

    if ($TEST_VERBOSE) {
        diag "Created temporary directory: ", $tmpdir->name;

        my $mode = ( stat( $tmpdir->name ) )[2];

        diag sprintf "with permissions %04o\n", $mode & 07777;
    }

    $test->{tmpdir} = $tmpdir;

    #chmod '0400', $tmpdir->name
    #    or die "Unable to change permission for: ".$tmpdir->name;

    #this is induced in the code
    $build->notes( 'temp_wd' => $test->{tmpdir}->name );

    if ( -e $test->{tmpdir}->name and -w _ ) {
        $test->{unfriendly_fs} = 0;

        if ($TEST_VERBOSE) {
            diag("Classifying filesystem as friendly");
        }

    } else {
        $test->{unfriendly_fs} = 1;

        if ($TEST_VERBOSE) {
            diag("Classifying filesystem as unfriendly");
        }
    }
}

sub contents : Test(6) {
    my $test = shift;

    my $build = $test->{build};

SKIP: {
        skip "file system is not cooperative", 6 if $test->{unfriendly_fs};

        unless ( $test->{unfriendly_fs} ) {
            cp( 't/'.$test->{file}, $test->{tmpdir}->name.'/'.$test->{file} );

            my $mode = ( stat( $test->{tmpdir}->name.'/'.$test->{file} ) )[2];

            if ($TEST_VERBOSE) {
                diag sprintf "test file holds permissions %04o\n", $mode & 07777;
            }
        }

        ok( -e $test->{tmpdir}->name.'/'.$test->{file},  $test->{tmpdir}->name.'/'.$test->{file} . ' exists' );
        ok( -r $test->{tmpdir}->name.'/'.$test->{file},  $test->{tmpdir}->name.'/'.$test->{file} . ' is readable' );

        #HACK: we cheat and pretend to be 5.10.1
        $Module::Build::Bundle::myPERL_VERSION = 5.10.1;

        ok( $build->ACTION_contents, 'executing ACTION_contents' );

        ok( my $content = read_file($test->{tmpdir}->name.'/'.$test->{file}),
            'reading file contents' );

        like(
            $content,
            qr/=item \* L<Module::Build\|Module::Build>/s,
            'asserting Module::Build item'
        );
        like(
            $content,
            qr/=item \* L<Text::Soundex\|Text::Soundex>, 2\.00/,
            'asserting Text::Soundex item'
        );

        $test->{build} = $build;
    }
}

sub extended : Test(4) {
    my $test = shift;

    my $build = $test->{build};

SKIP: {
        skip "file system is not cooperative", 5 if $test->{unfriendly_fs};

        unless ( $test->{unfriendly_fs} ) {
            cp( 't/'.$test->{file}, $test->{tmpdir}->name.'/'.$test->{file} );

            my $mode = ( stat( $test->{tmpdir}->name.'/'.$test->{file} ) )[2];

            if ($TEST_VERBOSE) {
                diag sprintf "Dummy file holds permissions %04o\n", $mode & 07777;
            }
        }


        #HACK: we cheat and pretend to be 5.12.0
        $Module::Build::Bundle::myPERL_VERSION = 5.12.0;

        ok( $build->ACTION_contents, 'executing ACTION_contents' );

        ok( my $content = read_file($test->{tmpdir}->name.'/'.$test->{file}),
            'reading file contents' );

        like(
            $content,
            qr/=item \* L<Module::Build\|Module::Build>/s,
            'asserting Module::Build item'
        );
        like(
            $content,
            qr[=item \* L<Text::Soundex\|Text::Soundex>, L<2\.00\|http://search.cpan.org/dist/Text-Soundex-2\.00/lib/Text/Soundex.pm>],
            'asserting Text::Soundex item'
        );
    }
}

sub death_by_section_header : Test(2) {
    my $test = shift;

    my $build = $test->{build};

SKIP: {
        skip "file system is not cooperative", 2 if $test->{unfriendly_fs};

        ok( cp( 't/'.$test->{file}, $test->{tmpdir}.'/'.$test->{file} ),
            'Copying test file'
                or diag(
                'Unable to copy file: '.$test->{tmpdir}.'/'.$test->{file}." - $!")
        );

        $build->notes( 'section_header' => 'TO DEATH' );

        dies_ok { $build->ACTION_contents } 'Unable to replace section';
    }
}

sub section_header : Test(3) {
    my $test = shift;

    ok( my $build = Module::Build::Bundle->new(
            module_name   => 'Dummy2',
            dist_version  => '6.66',
            dist_author   => 'jonasbn',
            dist_abstract => 'this is another dummy',
            requires      => { 'Module::Build' => '0', },
        ),
        'calling constructor'
    );

    $build->notes( 'section_header' => 'DEPENDENCIES' );

    #overwriting default test file
    $test->{file} = 'Dummy2.pm';

SKIP: {
        skip "file system is not cooperative", 2 if $test->{unfriendly_fs};

        ok( cp( 't/'.$test->{file}, $test->{tmpdir}->name.'/'.$test->{file} ), 'Copying test file');

        ok( $build->ACTION_contents, 'executing ACTION_contents' );

        $test->{build} = $build;
    }
}

sub teardown : Test(teardown) {
    my $test = shift;

    my $file  = $test->{file};
    my $build = $test->{build};

    $build->notes( 'section_header' => '' );
}

1;
