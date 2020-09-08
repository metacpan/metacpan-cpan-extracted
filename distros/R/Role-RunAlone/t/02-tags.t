#!perl

use strict;
use warnings;

use Test::More tests => 4;

use FindBin;
use IPC::Run;
use File::Temp ();
use Time::HiRes qw( sleep );

my $script_txt = <<'_EOS_';
$| = 1;

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Moo;
with 'Role::RunAlone';

my $tag_info = Role::RunAlone->_runalone_tag_pkg;
print "tag namespace: $tag_info->{package}\n";

sleep 5;

exit;
_EOS_

my $stdout_str = qr/tag namespace: /;

subtest DATA_tag_with_main_namespace => sub {
    plan tests => 7;

    my $txt = $script_txt . '__DATA__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $p1_stdout = '';
    my $p1_stderr = '';
    my $p1        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    sleep .25;

    my $p2_stdout = '';
    my $p2_stderr = '';
    my $p2        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p2_stdout .= $_[0] },
        '2>', sub { $p2_stderr .= $_[0] }
    );
    $p2->finish;

    is( $p2->result, '1', 'p2: __DATA__ tag blocked exit code is 1' );
    like( $p2_stderr, qr/FATAL/, 'p2: fatal error message is on STDERR' );
    is( $p2_stdout, '', 'p2: script did not produce output' );

    my $p1_k = $p1->signal('USR1');
    $p1->finish;
    is( $p1->result, '', 'p1: __DATA__ tag exit code is 0' );
    is( $p1_stderr,  '', 'p1: no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'p1: script executes' );

    $p1_stdout =~ /tag namespace: (.+)$/;
    is( $1, 'main', '__DATA__ tag found in script namespace' );
};

subtest END_tag_with_main_namespace => sub {
    plan tests => 7;

    my $txt = $script_txt . '__END__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $p1_stdout = '';
    my $p1_stderr = '';
    my $p1        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    sleep .25;

    my $p2_stdout = '';
    my $p2_stderr = '';
    my $p2        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p2_stdout .= $_[0] },
        '2>', sub { $p2_stderr .= $_[0] }
    );
    $p2->finish;

    is( $p2->result, '1', 'p2: __END__ tag blocked exit code is 1' );
    like( $p2_stderr, qr/FATAL/, 'p2: fatal error message is on STDERR' );
    is( $p2_stdout, '', 'p2: script did not produce output' );

    my $p1_k = $p1->signal('USR1');
    $p1->finish;
    is( $p1->result, '', 'p1: __END__ tag exit code is 0' );
    is( $p1_stderr,  '', 'p1: no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'p1: script executes' );

    $p1_stdout =~ /tag namespace: (.+)$/;
    is( $1, 'main', '__END__ tag found in main namespace' );
};

subtest DATA_tag_with_script_namespace => sub {
    plan tests => 7;

    my $txt = "package My::TestScript;\n";
    $txt .= $script_txt . '__DATA__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $p1_stdout = '';
    my $p1_stderr = '';
    my $p1        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    sleep .25;

    my $p2_stdout = '';
    my $p2_stderr = '';
    my $p2        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p2_stdout .= $_[0] },
        '2>', sub { $p2_stderr .= $_[0] }
    );
    $p2->finish;

    is( $p2->result, '1', 'p2: __DATA__ tag blocked exit code is 1' );
    like( $p2_stderr, qr/FATAL/, 'p2: fatal error message is on STDERR' );
    is( $p2_stdout, '', 'p2: script did not produce output' );

    my $p1_k = $p1->signal('USR1');
    $p1->finish;
    is( $p1->result, '', 'p1: __DATA__ tag exit code is 0' );
    is( $p1_stderr,  '', 'p1: no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'p1: script executes' );

    $p1_stdout =~ /tag namespace: (.+)$/;
    is( $1, 'My::TestScript', '__DATA__ tag found in script namespace' );
};

subtest END_tag_with_script_namespace => sub {
    plan tests => 7;

    my $txt = "package My::TestScript;\n";
    $txt .= $script_txt . '__END__';

    my $fh = File::Temp->new;
    print $fh $txt;
    close $fh;

    my $p1_stdout = '';
    my $p1_stderr = '';
    my $p1        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p1_stdout .= $_[0] },
        '2>', sub { $p1_stderr .= $_[0] }
    );
    sleep .25;

    my $p2_stdout = '';
    my $p2_stderr = '';
    my $p2        = IPC::Run::start(
        [ $^X, $fh->filename ],
        '>', sub  { $p2_stdout .= $_[0] },
        '2>', sub { $p2_stderr .= $_[0] }
    );
    $p2->finish;

    is( $p2->result, '1', 'p2: __END__ tag blocked exit code is 1' );
    like( $p2_stderr, qr/FATAL/, 'p2: fatal error message is on STDERR' );
    is( $p2_stdout, '', 'p2: script did not produce output' );

    my $p1_k = $p1->signal('USR1');
    $p1->finish;
    is( $p1->result, '', 'p1: __END__ tag exit code is 0' );
    is( $p1_stderr,  '', 'p1: no error message on STDERR' );
    like( $p1_stdout, $stdout_str, 'p1: script executes' );

    $p1_stdout =~ /tag namespace: (.+)$/;
    is( $1, 'main', '__END__ tag found in main namespace' );
};

done_testing();
exit;

__END__
