# parse() Taint_Clean argument test
# $Id: taint.t,v 1.2 2000/07/19 23:49:20 mfowler Exp $

# This script verifies the Taint_Clean argument to parse() prevents -T from
# complaining, and the lack of the option doesn't (indicating the option is
# no longer needed).



use Parse::PerlConfig;
use FindBin qw($Bin);
use IO::Handle;

use lib qw(t);
use parse::testconfig qw(ok);

use strict;
use vars qw($tconf $conf_file);


$tconf = parse::testconfig->new('test.conf');
$tconf->tests(2);
$tconf->ok_object;

$conf_file = $tconf->file_path();

my @includes = map { "-I$_" } (grep /blib/, @INC);
ok( run_cmd($^X, @includes, '-T', "$Bin/taint-test", $conf_file, 0) != 0 );
ok( run_cmd($^X, @includes, '-T', "$Bin/taint-test", $conf_file, 1) == 0 );


sub run_cmd {
    my @cmd = @_;

    STDOUT->flush;
    STDERR->flush;

    my $pid = fork();
    die("Unable to fork: \L$!.\n") unless defined($pid);

    if ($pid) {
        waitpid($pid, 0);
        return $?;
    } else {
        close(STDOUT);
        close(STDERR);
        exec(@cmd);
    }
}
