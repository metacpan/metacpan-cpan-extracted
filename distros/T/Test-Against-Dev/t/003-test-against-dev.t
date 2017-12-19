# -*- perl -*-
# t/003-test-against-dev.t - download and install a perl, a cpanm
use strict;
use warnings;
use feature 'say';

use Test::More;
use Carp;
use File::Temp ( qw| tempdir |);
use Data::Dump ( qw| dd pp | );
use Capture::Tiny ( qw| capture_stdout capture_stderr | );
use Test::RequiresInternet ('ftp.funet.fi' => 21);
use Test::Against::Dev;

my $tdir = tempdir(CLEANUP => 1);
my $self;

$self = Test::Against::Dev->new( {
    application_dir         => $tdir,
} );
isa_ok ($self, 'Test::Against::Dev');

my $host = 'ftp.funet.fi';
my $hostdir = '/pub/languages/perl/CPAN/src/5.0';

SKIP: {
    skip 'Live FTP download', 20
        unless $ENV{PERL_ALLOW_NETWORK_TESTING} and $ENV{PERL_AUTHOR_TESTING};

    my ($stdout, $stderr);
    my ($tarball_path, $work_dir, $release_dir);
    note("Performing live FTP download of Perl tarball;\n  this may take a while.");
    $stdout = capture_stdout {
        ($tarball_path, $work_dir) = $self->perform_tarball_download( {
            host                => $host,
            hostdir             => $hostdir,
            perl_version        => 'perl-5.27.6',
            compression         => 'gz',
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

    my $alt = "sh ./Configure -des -Dusedevel -Dprefix=$release_dir -Uversiononly -Dman1dir=none -Dman3dir=none";
    my $this_perl = $self->configure_build_install_perl({
        configure_command => $alt,
        verbose => 1,
    });
    ok(-f $this_perl, "Installed $this_perl");

    my $this_cpanm = $self->fetch_cpanm( { verbose => 1 } );
    ok(-f $this_cpanm, "Installed $this_cpanm");
    ok(-e $this_cpanm, "'$this_cpanm' is executable");

    my $bin_dir = $self->get_bin_dir();
    ok(-d $bin_dir, "Located '$bin_dir/'");
    my $lib_dir = $self->get_lib_dir();
    ok(-d $lib_dir, "Located '$lib_dir/'");
    my $cpanm_dir = $self->get_cpanm_dir();
    ok(-d $cpanm_dir, "Located '$cpanm_dir/'");

    system(qq|$this_perl -I$self->{lib_dir} $this_cpanm List::Compare|)
        and croak "Unable to use 'cpanm' to install module List::Compare";
    my $hw = `$this_perl -I$self->{lib_dir} -MList::Compare -e 'print q|hello world|;'`;
    is($hw, 'hello world', "Got 'hello world' when -MList::Compare");
    my $lcv = qx|$this_perl -I$lib_dir -MList::Compare -E 'say \$List::Compare::VERSION;'|;
    chomp($lcv);
    like($lcv, qr/^\d\.\d\d$/, "Got \$List::Compare::VERSION $lcv");

    {
        local $@;
        eval { $self->run_cpanm( [ module_file => 'foo', title => 'not-cpan-river' ] ); };
        like($@, qr/run_cpanm: Must supply hash ref as argument/,
            "Got expected error message: absence of hashref");
    }

    {
        local $@;
        my $bad_element = 'foo';
        eval { $self->run_cpanm( { $bad_element => 'bar', title => 'not-cpan-river' } ); };
        like($@, qr/run_cpanm: '$bad_element' is not a valid element/,
            "Got expected error message: bad argument");
    }

    {
        local $@;
        eval { $self->run_cpanm( {
            module_file => 'foo',
            module_list => [ 'Foo::Bar', 'Alpha::Beta' ],
            title => 'not-cpan-river',
        } ); };
        like($@, qr/run_cpanm: Supply either a file for 'module_file' or an array ref for 'module_list' but not both/,
            "Got expected error message: bad mixture of arguments");
    }

    {
        local $@;
        my $bad_module_file = 'foo';
        eval { $self->run_cpanm( { module_file => $bad_module_file, title => 'not-cpan-river' } ); };
        like($@, qr/run_cpanm: Could not locate '$bad_module_file'/,
            "Got expected error message: module_file not found");
    }

    {
        local $@;
        eval { $self->run_cpanm( { module_list => "Foo::Bar", title => 'not-cpan-river' } ); };
        like($@, qr/run_cpanm: Must supply array ref for 'module_list'/,
            "Got expected error message: value for module_list not an array ref");
    }

    pp({ %{$self} });
    note("Status");
}

done_testing();
