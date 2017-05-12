use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

my $stdout_fh      = FileTempTFH->new;
my $stdout_orig_fh = IO::File->new_from_fd( fileno(STDOUT), 'w' )
  or die "Error opening STDOUT for writing: $!";

STDOUT->fdopen( fileno($stdout_fh), 'w' )
  or die "Error re-directing STDOUT: $!";

my @tests = ( 't/data/01_pass.pl', 't/data/02_fail.pl' );
my $f = TAP::Formatter::HTML->new({ escape_output => 1, quiet => 1, force_inline_css => 0 });
my $h = TAP::Harness->new({ merge => 1, formatter => $f });

$h->runtests(@tests);

STDOUT->fdopen( fileno($stdout_orig_fh), 'w' )
  or die "Error resetting STDOUT: $!";

my $stdout = $stdout_fh->get_all_output || '';
like( $stdout, qr|\A(?!<html)|ms, 'expect other content before HTML report' );
like( $stdout, qr|^<html.+/html>\s*\Z|ms, 'HTML report should be output last' );

