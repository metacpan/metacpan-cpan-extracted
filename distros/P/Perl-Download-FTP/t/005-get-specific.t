# -*- perl -*-
# t/004-get.t
use strict;
use warnings;
use 5.10.1;

use Perl::Download::FTP;
use Test::More;
unless ($ENV{PERL_ALLOW_NETWORK_TESTING}) {
    plan 'skip_all' => "Set PERL_ALLOW_NETWORK_TESTING to conduct live tests";
}
else {
    plan tests => 10;
}
use Test::RequiresInternet ('ftp.cpan.org' => 21);
use Capture::Tiny qw( capture_stdout );
use Carp;
use File::Path qw( make_path remove_tree );
use File::Spec;

{
    my ($self);
    my $default_host = 'ftp.cpan.org';
    my $default_dir  = '/pub/CPAN/src/5.0';

    $self = Perl::Download::FTP->new( {
        host        => $default_host,
        dir         => $default_dir,
        Passive     => 1,
        verbose     => 1,
    } );
    ok(defined $self, "Constructor returned defined object when using default values");

    isa_ok ($self, 'Perl::Download::FTP');
    my $t = File::Spec->catdir(".", "tmp");
    my $removed_count = remove_tree($t, { error  => \my $err_list, })
        if (-d $t);

    my ($tb, $tdir, $stdout);
    ($tdir) = make_path($t, +{ mode => 0711 })
        or croak "Unable to make_path for testing";

    note("Downloading tarball via FTP; this may take a while");
    my $release = 'perl-5.25.6.tar.xz';
    $stdout = capture_stdout {
        $tb = $self->get_specific_release( {
            release     => $release,
            path        => $tdir,
        } );
    };

    ok(-f $tb, "Found downloaded release $tb");

    like(
        $stdout,
        qr/Identified \d+ perl releases at ftp:\/\/\Q${default_host}${default_dir}\E/,
        "ls(): Got expected verbose output"
    );
    like($stdout,
        qr/Performing FTP 'get' call for/s,
        "get_specific_release(): Got expected verbose output re starting FTP get");
    like($stdout,
        qr/Elapsed time for FTP 'get' call:\s+\d+\s+seconds/s,
        "get_specific_release(): Got expected verbose output re elapsed time");
    like($stdout,
        qr/See:\s+\Q$tb\E/s,
        "get_specific_release(): Got expected verbose output re download location");
}

{
    my ($self);
    my $default_host = 'ftp.cpan.org';
    my $default_dir  = '/pub/CPAN/src/5.0';

    $self = Perl::Download::FTP->new( {
        host        => $default_host,
        dir         => $default_dir,
        Passive     => 1,
    } );
    ok(defined $self, "Constructor returned defined object when using default values");

    isa_ok ($self, 'Perl::Download::FTP');

    my ($tb, $tdir);
    my $t = File::Spec->catdir(".", "tmp");
    my $removed_count = remove_tree($t, { error  => \my $err_list, })
        if (-d $t);

    ($tdir) = make_path($t, +{ mode => 0711 })
        or croak "Unable to make_path for testing";

    my $release = 'perl-5.25.99.tar.gz';
    local $@;
    eval {
        $tb = $self->get_specific_release( {
            release     => $release,
            path        => $tdir,
        } );
    };
    like($@,
        qr|$release not found among releases at ftp://$self->{host}$self->{dir}|,
        "Got expected error message for non-existent release");
}
