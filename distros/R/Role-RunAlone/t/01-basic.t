#!perl

use strict;
use warnings;

use Test::More tests => 3;

use FindBin;
use IPC::Run;

# force OO API
use File::Temp ();

my $script_txt = <<'_EOS_';
package My::TestScript;

$| = 1;

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Role::Tiny::With;
with 'Role::RunAlone';

print "checkpoint charlie\n";

exit;
_EOS_

subtest missing_DATA_or_END_tag => sub {
    plan tests => 3;

    my $fh = File::Temp->new;
    print $fh $script_txt;
    close $fh;

    my $stdout_str = qr/No __DATA__ or __END__/;
    my $p1_stdout  = '';
    my $p1_stderr  = '';
    my $p1         = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    $p1->finish;
    is( $p1->result, 2, 'missing __DATA__ or __END__ tag exit code is 2' );
    like( $p1_stderr, $stdout_str, 'correct error message on STDERR' );
    is( $p1_stdout, '', 'nothing sent to STDOUT' );
};

subtest DATA_tag_present => sub {
    plan tests => 3;

    my $txt = $script_txt . '__DATA__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $stdout_str = qr/checkpoint charlie/;
    my $p1_stdout  = '';
    my $p1_stderr  = '';
    my $p1         = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    $p1->finish;
    is( $p1->result, '', '__DATA__ tag exit code is 0' );
    is( $p1_stderr,  '', 'no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'script executes and printed to STDOUT' );
};

subtest END_tag_present => sub {
    plan tests => 3;

    my $txt = $script_txt . '__END__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $stdout_str = qr/checkpoint charlie/;
    my $p1_stdout  = '';
    my $p1_stderr  = '';
    my $p1         = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    $p1->finish;
    is( $p1->result, '', '__END__ tag exit code is 0' );
    is( $p1_stderr,  '', 'no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'script executes and printed to STDOUT' );
};

done_testing();
exit;

__END__
