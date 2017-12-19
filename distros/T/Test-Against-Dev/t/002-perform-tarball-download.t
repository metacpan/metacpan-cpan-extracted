# -*- perl -*-
# t/002-perform-tarball-download.t - check module loading and create testing directory
use strict;
use warnings;

use Test::More;
use File::Temp ( qw| tempdir |);
use Data::Dump ( qw| dd pp | );
use Capture::Tiny ( qw| capture_stdout capture_stderr | );
use Test::RequiresInternet ('ftp.funet.fi' => 21);
BEGIN { use_ok( 'Test::Against::Dev' ); }

my $tdir = tempdir(CLEANUP => 1);
my $self;

$self = Test::Against::Dev->new( {
    application_dir         => $tdir,
} );
isa_ok ($self, 'Test::Against::Dev');

my $host = 'ftp.funet.fi';
my $hostdir = '/pub/languages/perl/CPAN/src/5.0';

{
    local $@;
    my $count;
    eval { $count = $self->setup_results_directories(); };
    like($@, qr/Perl release not yet defined/,
        "Got expected error message: premature attempt to set up results directory tree");
}

{
    local $@;
    eval {
        my ($tarball_path, $work_dir) = $self->perform_tarball_download( [
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.1',
            compression         => 'gz',
            verbose             => 0,
            mock                => 1,
      ] );
    };
    like($@, qr/perform_tarball_download: Must supply hash ref as argument/,
        "perform_tarball_download: Got expected error message for lack of hashref as argument");
}

{
    local $@;
    my $bad_key = 'foo';
    eval {
        my ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.1',
            compression         => 'gz',
            verbose             => 0,
            mock                => 1,
            $bad_key            => 'bar',
      } );
    };
    like($@, qr/perform_tarball_download: '$bad_key' is not a valid element/,
        "perform_tarball_download: Got expected error message for invalid element");
}

{
    local $@;
    my $bad_perl_version = '5.27.1';
    eval {
        my ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => $bad_perl_version,
            compression         => 'gz',
            verbose             => 0,
            mock                => 1,
      } );
    };
    like($@, qr/perform_tarball_download: '$bad_perl_version' does not conform to pattern/,
        "perform_tarball_download: Got expected error message for invalid perl_version");
}

{
    local $@;
    my $bad_compression = 'foo';
    eval {
        my ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.1',
            compression         => $bad_compression,
            verbose             => 0,
            mock                => 1,
      } );
    };
    like($@, qr/perform_tarball_download: '$bad_compression' is not a valid compression format/,
        "perform_tarball_download: Got expected error message for invalid compression format");
}

{
    local $@;
    my $bad_work_dir = '/foo/bar/baz';
    eval {
        my ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.1',
            compression         => 'gz',
            work_dir            => $bad_work_dir,
            mock                => 1,
      } );
    };
    like($@, qr/Could not locate '$bad_work_dir' for purpose of downloading tarball and building perl/,
        "perform_tarball_download: Got expected error message for work_dir not located");
}


SKIP: {
    skip "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests", 24
        unless $ENV{PERL_ALLOW_NETWORK_TESTING};
    my ($tarball_path, $work_dir, $stdout, $release_dir, $configure_command, $alt, $make_install_command);

    {
        local $@;
        eval { $release_dir = $self->get_release_dir(); };
        like($@, qr/release directory has not yet been defined; run perform_tarball_download\(\)/,
            "get_release_dir: Got expected error message for premature call");
    };
    ($tarball_path, $work_dir) = $self->perform_tarball_download( {
        host                => $host,
        hostdir             => $hostdir,
        perl_version        => 'perl-5.27.1',
        compression         => 'gz',
        verbose             => 0,
        mock                => 1,
    } );
    ok($tarball_path, 'perform_tarball_download: returned true value when mocking');
    $release_dir = $self->get_release_dir();
    ok(-d $release_dir, "Located release dir: $release_dir");

    my $count = $self->setup_results_directories();
    is($count, 4, "Created version-specific results directory and 3 subdirectories");

    $configure_command = $self->access_configure_command();
    is($configure_command,
       "sh ./Configure -des -Dusedevel -Uversiononly -Dprefix=$release_dir -Dman1dir=none -Dman3dir=none",
        "Got default configure command"
    );
    $alt = "sh ./Configure -des -Dusedevel -Dprefix=$release_dir -Uversiononly -Dman1dir=none -Dman3dir=none";
    $configure_command = $self->access_configure_command($alt);
    is($configure_command, $alt, "Got user-specified configure command");

    $make_install_command = $self->access_make_install_command();
    is($make_install_command, 'make install', "Got default make install command");
    $alt = 'make -j4 install';
    $make_install_command = $self->access_make_install_command($alt);
    is($make_install_command, $alt, "Got user specified make install command");

    $stdout = capture_stdout {
        ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.2',
            compression         => 'xz',
            verbose             => 1,
            mock                => 1,
        } );
    };
    ok($tarball_path, 'perform_tarball_download: returned true value when mocking and requesting verbose output');
    like($stdout, qr/Mocking/, "Got expected verbose output");
    $release_dir = $self->get_release_dir();
    ok(-d $release_dir, "Located release dir: $release_dir");

    SKIP: {
        skip 'Live FTP download', 13 unless $ENV{PERL_AUTHOR_TESTING};
        note("Performing live FTP download of Perl tarball;\n  this may take a while.");
        $stdout = capture_stdout {
            ($tarball_path, $work_dir) = $self->perform_tarball_download( {
                host                => $host,
                hostdir             => $hostdir,
                perl_version        => 'perl-5.27.2',
                compression         => 'xz',
                verbose             => 1,
                mock                => 0,
            } );
        };
        ok($tarball_path, 'perform_tarball_download: returned true value');
        $release_dir = $self->get_release_dir();
        ok(-d $release_dir, "Located release dir: $release_dir");
        ok(-f $tarball_path, "Downloaded tarball: $tarball_path");
        ok(-d $work_dir, "Located work directory: $work_dir");
        like($stdout, qr/Beginning FTP download/s,
            "Got expected verbose output: starting download");
        like($stdout, qr/Perl configure-build-install cycle will be performed in $work_dir/s,
            "Got expected verbose output: cycle location");
        like($stdout, qr/Path to tarball is $tarball_path/s,
            "Got expected verbose output: tarball path");

        ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.3',
            compression         => 'xz',
        } );
        ok($tarball_path, 'perform_tarball_download: returned true value');
        $release_dir = $self->get_release_dir();
        ok(-d $release_dir, "Located release dir: $release_dir");
        ok(-f $tarball_path, "Downloaded tarball: $tarball_path");
        ok(-d $work_dir, "Located work directory: $work_dir");
    }

    {
        local $@;
        my $bin_dir;
        eval { $bin_dir = $self->get_bin_dir(); };
        like($@, qr/bin directory has not yet been defined; run configure_build_install_perl\(\)/,
            "get_bin_dir: Got expected error message for premature call");
    };

    {
        local $@;
        my $lib_dir;
        eval { $lib_dir = $self->get_lib_dir(); };
        like($@, qr/lib directory has not yet been defined; run configure_build_install_perl\(\)/,
            "get_lib_dir: Got expected error message for premature call");
    };

    {
        local $@;
        my $cpanm_dir;
        eval { $cpanm_dir = $self->get_cpanm_dir(); };
        like($@, qr/cpanm directory has not yet been defined; run fetch_cpanm\(\)/,
            "get_cpanm_dir: Got expected error message for premature call");
    };
}

done_testing();
