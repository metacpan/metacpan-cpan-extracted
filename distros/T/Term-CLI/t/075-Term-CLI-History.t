#!/usr/bin/perl -T
#
# Copyright (C) 2018, Steven Bakker.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

sub Main {
    Term_CLI_History_test->SKIP_CLASS(
        ($::ENV{SKIP_COMMAND})
            ? "disabled in environment"
            : 0
    );
    Term_CLI_History_test->runtests();
}

package Term_CLI_History_test {

use parent 0.225 qw( Test::Class );

use Test::More 1.001002;
use FindBin 1.50;
use Term::CLI;
use File::Temp 0.22 qw( tempfile );

# Untaint the PATH.
$::ENV{PATH} = '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

sub check_history : Test(12) {
    my $self = shift;
    my @commands;

    my $cli = Term::CLI->new(
        name => 'test_app',
        history_file => '/does/not/exist',
        history_lines => 100,
    );

    is($cli->history_lines, 100, 'history_lines is 100 after construction');

    $cli->history_lines(200);
    is($cli->history_lines, 200, 'history_lines is 200 after setting');

    ok(!$cli->read_history, 'read_history from non-existent file fails');
    like($cli->error,
        qr{/does/not/exist:}i,
        'error on failed read_history is set correctly'
    );

    ok(!$cli->write_history, 'write_history to non-existent file fails');
    ok(length($cli->error) > 0,
        'error on failed write_history is set'
    );

    my ($fh, $filename) = tempfile();

    $fh->seek(0,0);
    $fh->autoflush(1);
    my $history = "   \ncommand 1\ncommand 2\ncommand 3\n";
    say $fh $history;

    ok($cli->read_history($filename), 'read_history from new file works')
        or diag("history error: ".$cli->error);
    is($cli->history_file, $filename, 'history_file is set correctly after read');

    my $hist_read = join('', map { "$_\n" } $cli->term->GetHistory);

    is($hist_read, $history, 'history is read correctly');

    $fh->close;

    ($fh, $filename) = tempfile();
    $fh->close();
    $cli->term->AddHistory("command 4", "command 5");
    ok($cli->write_history($filename), 'write_history to new file works')
        or diag("history error: ".$cli->error);
    is($cli->history_file, $filename, 'history_file is set correctly after write');

    open $fh, '<', $filename;
    my $expected = $history."command 4\ncommand 5\n";
    my $new_history = join('', $fh->getlines());
    is($new_history, $expected, 'history is correctly saved');
}

}
Main();
