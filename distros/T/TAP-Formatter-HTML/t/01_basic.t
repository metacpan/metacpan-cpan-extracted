use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;
use File::Basename qw( basename );

use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

my $stdout_fh      = FileTempTFH->new;
my $stdout_orig_fh = IO::File->new_from_fd( fileno(STDOUT), 'w' )
  or die "Error opening STDOUT for writing: $!";

STDOUT->fdopen( fileno($stdout_fh), 'w' )
  or die "Error redirecting STDOUT: $!";

# Only run 1 test on Windows or tests will hang (RT #81922)
my @tests = ($^O =~ /win/i ? 't/data/01_pass.pl' : glob( 't/data/*.pl' ));
my $h = TAP::Harness->new({ merge => 1, formatter_class => 'TAP::Formatter::HTML' });
$h->runtests(@tests);

STDOUT->fdopen( fileno($stdout_orig_fh), 'w' )
  or die "Error resetting STDOUT: $!";

my $stdout = $stdout_fh->get_all_output || '';
isnt( $stdout, '', 'captured test output to stdout' );

foreach my $file (@tests) {
    my $test = basename( $file );
    $test    =~ s/\.pl$//;
    ok( $stdout =~ qr|$test|, "output contains test '$test'" );
}

