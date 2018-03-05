# -*- perl -*-
# t/008-get-distribution.t
use strict;
use warnings;
use 5.10.1;

use Perl::Download::FTP::Distribution;
use Test::More;
unless ($ENV{PERL_ALLOW_NETWORK_TESTING}) {
    plan 'skip_all' => "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests";
}
else {
    plan tests => 38;
}
use Test::RequiresInternet ('ftp.cpan.org' => 21);
use Capture::Tiny qw( capture_stdout );
use Carp;
use File::Temp qw( tempdir );


my $default_host = 'ftp.cpan.org';
my $default_dir  = 'pub/CPAN/modules/by-module';
my $sample = 'Test-Smoke';

{
    my ($self, $tb, $stdout, $tdir);
    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        host            => $default_host,
        dir             => $default_dir,
        Passive         => 1,
        verbose         => 1,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    # bad args #
    {
        local $@;
        eval { $self->get_latest_release([]); };
        like($@, qr/Argument to method must be hashref/,
            "Got expected error message for non-hashref argument");
    }

    note("Downloading tarball via FTP; this may take a while");
    $tdir = tempdir(CLEANUP => 1);
    $stdout = capture_stdout {
        $tb = $self->get_latest_release( {
            path        => $tdir,
            verbose     => 1,
        } );
    };

    ok(-f $tb, "Found downloaded release $tb");
    like($stdout,
        qr/Performing FTP 'get' call for/s,
        "get_latest_release(): Got expected verbose output re starting FTP get");
    like($stdout,
        qr/Elapsed time for FTP 'get' call:\s+\d+\s+seconds/s,
        "get_latest_release(): Got expected verbose output re elapsed time");
    like($stdout,
        qr/See:\s+\Q$tb\E/s,
        "get_latest_release(): Got expected verbose output re download location");
}

{
    note("Call ls() before get_latest_release()");
    my ($self, $tb, $stdout, $tdir);
    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        host            => $default_host,
        dir             => $default_dir,
        Passive         => 1,
        verbose         => 1,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    my @allreleases = $self->ls();
    ok(scalar(@allreleases), "ls(): returned >0 elements for $sample");

    note("Downloading tarball via FTP; this may take a while");
    $tdir = tempdir(CLEANUP => 1);
    $stdout = capture_stdout {
        $tb = $self->get_latest_release( {
            path        => $tdir,
            verbose     => 1,
        } );
    };

    ok(-f $tb, "Found downloaded release $tb");
    like($stdout,
        qr/Latest release.*?identified from cached ls\(\) call/s,
        "get_latest_release(): Got expected verbose output re cache");
    like($stdout,
        qr/Performing FTP 'get' call for/s,
        "get_latest_release(): Got expected verbose output re starting FTP get");
    like($stdout,
        qr/Elapsed time for FTP 'get' call:\s+\d+\s+seconds/s,
        "get_latest_release(): Got expected verbose output re elapsed time");
    like($stdout,
        qr/See:\s+\Q$tb\E/s,
        "get_latest_release(): Got expected verbose output re download location");
}

{
    note("Call ls() before get_latest_release(); download to current directory");
    my ($self, $tb, $stdout, $tdir);
    $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        host            => $default_host,
        dir             => $default_dir,
        Passive         => 1,
        verbose         => 1,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    my @allreleases = $self->ls();
    ok(scalar(@allreleases), "ls(): returned >0 elements for $sample");

    note("Downloading tarball via FTP; this may take a while");
    $tb = $self->get_latest_release( { } );

    ok(-f $tb, "Found downloaded release $tb");
    unlink $tb;
    ok(! -f $tb, "Removed downloaded release $tb");
}

#####

my $basic_args = {
    host            => $default_host,
    dir             => $default_dir,
};

$sample = 'Text-CSV_XS';
test_get_latest_release($basic_args, $sample);

$sample = 'List-Compare';
test_get_latest_release($basic_args, $sample);

$sample = 'Mojolicious-Plugin-MultiConfig';
test_get_latest_release($basic_args, $sample);

$sample = 'File-Rsync-Mirror-Recent';
test_get_latest_release($basic_args, $sample);

$sample = 'Lingua-LO-NLP';
test_get_latest_release($basic_args, $sample);

$sample = 'File-Download';
test_get_latest_release($basic_args, $sample);


sub test_get_latest_release {
    my ($basic_args, $sample) = @_;

    my $self = Perl::Download::FTP::Distribution->new( {
        distribution    => $sample,
        host        => $basic_args->{host},
        dir         => $basic_args->{dir},
        Passive     => 1,
    } );
    ok(defined $self, "Constructor returned defined object");
    isa_ok ($self, 'Perl::Download::FTP::Distribution');

    my $tdir = tempdir(CLEANUP => 1);
    my $tb = $self->get_latest_release( {
        path        => $tdir,
    } );
    ok(-f $tb, "Found downloaded release $tb");
}

