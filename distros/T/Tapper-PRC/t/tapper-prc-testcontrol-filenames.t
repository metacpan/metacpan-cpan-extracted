use strict;
use warnings;

use Test::More tests => 4;

use Tapper::PRC::Testcontrol;
use File::Temp qw/tempdir/;
use Log::Log4perl;

######################################################################
#                                                                    #
# For testprogram with the same name the output file names will be   #
# identical. To prevent this, we append a serial number. This test   #
# checks whether appending this serial number works as expected.     #
#                                                                    #
######################################################################


my $string = "log4perl.rootLogger = OFF, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


my $prc=Tapper::PRC::Testcontrol->new(cfg => {paths => {testprog_path => 't/files/exec/'}});
my $append=$prc->get_appendix('t/files/append/output');
is($append, '-002', 'Appendix for existing files with appendix');

$append=$prc->get_appendix('t/files/append/another');
is($append, '-001', 'Appendix for existing files without appendix');

$append=$prc->get_appendix('t/files/append/does_not_exist');
is($append, '', 'Appendix for non-existing files');

my $tempdir = tempdir(CLEANUP => 1);
$tempdir.="/";

$prc->testprogram_execute( {program => 'sleep.sh',
                            out_dir  => $tempdir,
                            argv => [ 0 ],
                           }
                         );

$prc->testprogram_execute( {program => 'sleep.sh',
                            out_dir  => $tempdir,
                            argv => [ 0 ],
                           }
                         );
ok(-e "$tempdir/sleep_sh-001.stdout", 'Output file with appendix exists');
