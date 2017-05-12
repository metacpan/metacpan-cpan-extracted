use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More 'no_plan';
use FileTempTFH;

use TAP::Harness;
use_ok( 'TAP::Formatter::HTML' );

my $output_fh      = FileTempTFH->new;
my $stdout_fh      = FileTempTFH->new;
my $stdout_orig_fh = IO::File->new_from_fd( fileno(STDOUT), 'w' )
  or die "Error opening STDOUT for writing: $!";

STDOUT->fdopen( fileno($stdout_fh), 'w' )
  or die "Error re-directing STDOUT: $!";

# Note: strangely this doesn't fail on Windows, even though we're
# running 2 tests... worth pointing out it may be due to lack of
# output...
my @tests = ( 't/data/01_pass.pl', 't/data/02_fail.pl' );
{
    my $f = TAP::Formatter::HTML->new({ escape_output => 1, silent => 1 });
    my $h = TAP::Harness->new({ merge => 1, formatter => $f });
    $h->runtests(@tests);

    my $stdout = $stdout_fh->get_all_output || '';
    is( $stdout, '', 'should be no output to stdout' );

    my $html_ref = $f->html;
    ok( $$html_ref, 'formatter->html exists' );
}

{
    my $f = TAP::Formatter::HTML->new({ silent => 1, output_fh => $output_fh });
    my $h = TAP::Harness->new({ merge => 1, formatter => $f });
    $h->runtests(@tests);

    my $stdout = $stdout_fh->get_all_output || '';
    is( $stdout, '', 'should be no output to stdout' );

    my $html = $output_fh->get_all_output || '';
    ok( $html, 'html still output to non-stdout fh when silent is set' );
    like( $html, qr|01_pass|, 'html contains file 1' );

    my $html_ref = $f->html;
    ok( $$html_ref, 'formatter->html exists' );
}

