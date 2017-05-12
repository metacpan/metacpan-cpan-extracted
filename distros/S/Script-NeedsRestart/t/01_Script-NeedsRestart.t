#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

use FindBin qw($Bin);
use lib "$Bin/lib";

my @files_to_unlink;

BEGIN {
    use_ok('Script::NeedsRestart') or exit;
    unshift(@Script::NeedsRestart::exec_self_cmd,
        'making-something-up-for-exec-to-fail');
}

subtest 'check_mtimes' => sub {
    ok(!Script::NeedsRestart->check_mtimes, 'no need for restart yet');

    require_dummy_file();
    ok(Script::NeedsRestart->check_mtimes, 'restart needed');
};

subtest 'restart_if_needed' => sub {
    throws_ok {Script::NeedsRestart->restart_if_needed} qr/exec of .+ failed/,
        'tried to exec';

    Script::NeedsRestart->set_logger(dummy_testing::logger->new());
    throws_ok {Script::NeedsRestart->restart_if_needed} qr/exec of .+ failed/,
        'tried to exec with logger set';
    is(scalar(@dummy_testing::logger::logs), 2, 'two log lines');
};

done_testing();

sub require_dummy_file {
    sleep(1);    # needs for -M to have non-zero value
    my ($fh, $tmp_required_filename) = tempfile();
    print $fh '1;';
    close($fh);
    require($tmp_required_filename);
    push(@files_to_unlink, $tmp_required_filename);
    return $tmp_required_filename;
}

END {
    foreach my $filename (@files_to_unlink) {
        unlink($filename);
    }
}

package dummy_testing::logger;

use strict;
use warnings;

our @logs;

sub new {return bless {}, __PACKAGE__;}
sub info  {shift; push(@logs, @_);}
sub debug {shift; push(@logs, @_);}

1;
