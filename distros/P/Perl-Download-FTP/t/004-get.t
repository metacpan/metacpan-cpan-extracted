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
    plan tests => 12;
}
use Test::RequiresInternet ('ftp.cpan.org' => 21);
use Capture::Tiny qw( capture_stdout );
use Carp;
use File::Path qw( make_path remove_tree );
use File::Spec;

my ($self);
my (@allarchives, $allcount, $stdout);
my ($classified, $classified_count, $tb);
my ($type, $compression, $tdir);
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

$stdout = capture_stdout { @allarchives = $self->ls(); };
$allcount = scalar(@allarchives);
ok($allcount, "ls(): returned >0 elements: $allcount");
like(
    $stdout,
    qr/Identified \d+ perl releases at ftp:\/\/\Q${default_host}${default_dir}\E/,
    "ls(): Got expected verbose output"
);

$classified = $self->classify_releases();
$classified_count =
    (scalar keys %{$classified->{dev}}) +
    (scalar keys %{$classified->{prod}}) +
    (scalar keys %{$classified->{rc}});
is($classified_count, $allcount,
    "Got expected number of classified entries: $allcount");

# bad args #
{
    local $@;
    eval { $self->get_latest_release([]); };
    like($@, qr/Argument to method must be hashref/,
        "Got expected error message for non-hashref argument");
}

$type = 'prod';
$compression = 'xz';
my $t = File::Spec->catdir(".", "tmp");
my $removed_count = remove_tree($t, { error  => \my $err_list, })
    if (-d $t);

($tdir) = make_path($t, +{ mode => 0711 })
    or croak "Unable to make_path for testing";

note("Downloading tarball via FTP; this may take a while");
$stdout = capture_stdout {
    $tb = $self->get_latest_release( {
        compression => $compression,
        type        => $type,
        path        => $tdir,
    } );
};

ok(-f $tb, "Found downloaded release $tb");

like($stdout,
    qr/Identifying latest $type release/s,
    "get_latest_release(): Got expected verbose output re latest releases");
like($stdout,
    qr/Preparing list of '$type' releases with '$compression' compression/s,
    "get_latest_release(): Got expected verbose output re list preparation");
like($stdout,
    qr/Performing FTP 'get' call for/s,
    "get_latest_release(): Got expected verbose output re starting FTP get");
like($stdout,
    qr/Elapsed time for FTP 'get' call:\s+\d+\s+seconds/s,
    "get_latest_release(): Got expected verbose output re elapsed time");
like($stdout,
    qr/See:\s+\Q$tb\E/s,
    "get_latest_release(): Got expected verbose output re download location");
