#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# $Net::SFTP::Foreign::debug = 17 + 64;

use lib "./t";
use common;

use File::Spec;
use Cwd qw(getcwd);

plan skip_all => "tests not supported on inferior OS"
    if (is_windows and eval "no warnings; getlogin ne 'salva'");

my @new_args = new_args;

plan tests => 223;

use_ok('Net::SFTP::Foreign');
use Net::SFTP::Foreign::Constants qw(:flags);

$SIG{ALRM} = sub {
    print STDERR "# timeout expired: your computer is too slow or some test is not finishing\n";
    exit 1;
};

# don't set the alarm if we are being debugged!
alarm 300 unless exists ${DB::}{sub};

chdir 't';
my $lcwd = File::Spec->rel2abs('.');

for my $bs (7, 8, 9, 20, 1024, 4096) {

    my $sftp = eval { Net::SFTP::Foreign->new(@new_args, block_size => $bs) };
    diag($@) if $@;

    ok (defined $sftp, "creating object");
    unless (defined $sftp) {
        diag "unable to create Net::SFTP::Foreign object, aborting tests";
        exit 1;
    }

    ok (!$sftp->error, "sftp object created ok - $bs");
    diag ($sftp->error) if $sftp->error;

    my $rcwd = $sftp->realpath($lcwd);

    ok ($sftp->setcwd($rcwd), "setcwd");
    diag ($sftp->error) if $sftp->error;

    ok($sftp->get('data.txu', 'copied.txd', conversion => 'unix2dos'), "get unix2dos - $bs");
    diag ($sftp->error) if $sftp->error;

    ok(!filediff('data.txd', 'copied.txd'), "get conversion unix2dos ok - $bs");
    unlink 'copied.txd';

    ok($sftp->get('data.txd', 'copied.txd', conversion => 'unix2dos'), "get unix2dos when already in dos format - $bs");
    diag ($sftp->error) if $sftp->error;

    ok(!filediff('data.txd', 'copied.txd'), "get conversion unix2dos when already is dos format ok - $bs");
    unlink 'copied.txd';

    ok($sftp->get('data.txd', 'copied.txu', conversion => 'dos2unix'), "get dos2unix - $bs");
    diag ($sftp->error) if $sftp->error;

    ok(!filediff('data.txu', 'copied.txu'), "get conversion dos2unix ok - $bs");
    unlink 'copied.txu';

    ok($sftp->put('data.txu', 'copied.txd', conversion => 'unix2dos'), "put unix2dos - $bs");
    diag ($sftp->error) if $sftp->error;

    ok(!filediff('data.txd', 'copied.txd'), "put conversion unix2dos ok - $bs");
    # unlink 'copied.txd';

    ok($sftp->put('data.txd', 'copied.txu', conversion => 'dos2unix'), "put dos2unix - $bs");
    diag ($sftp->error) if $sftp->error;

    ok(!filediff('data.txu', 'copied.txu'), "put conversion dos2unix ok - $bs");
    # unlink 'copied.txu';

    for my $r (1..3) {
        my $trunc = int (2500 * rand);

        truncate 'copied.txd', $trunc;
        ok($sftp->put('data.txu', 'copied.txd', conversion => 'unix2dos', resume => 1),
           "put unix2dos with resume - $bs, $r")
            or diag $sftp->error;
        ok(!filediff('data.txd', 'copied.txd'), "put conversion unix2dos with resume ok - $bs, $r")
            or diag "truncation position: $trunc";

        truncate 'copied.txu', $trunc;
        ok($sftp->put('data.txd', 'copied.txu', conversion => 'dos2unix', resume => 1),
           "put dos2unix with resume - $bs, $r")
            or diag $sftp->error;
        ok(!filediff('data.txu', 'copied.txu'), "put conversion dos2unix with resume ok - $bs, $r")
            or diag "truncation position: $trunc";

        truncate 'copied.txd', $trunc;
        ok($sftp->put('data.txd', 'copied.txd', resume => 1),
           "put with resume - $bs, $r")
            or diag $sftp->error;
        ok(!filediff('data.txd', 'copied.txd'), "put with resume ok - $bs, $r")
            or diag "truncation position: $trunc";

        truncate 'copied.txd', $trunc;
        ok($sftp->get('data.txd', 'copied.txd', resume => 1),
           "get with resume - $bs, $r")
            or diag $sftp->error;
        ok(!filediff('data.txd', 'copied.txd'), "get with resume ok - $bs, $r, $trunc")
            # or exit 1;
	    or diag "truncation position: $trunc";
    }

    unlink 'copied.txu';
    unlink 'copied.txd';
}
