# -*- cperl -*-

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

my $io_available = 1;

if (not can_svn()) {
    plan skip_all => 'Cannot find or use svn commands.';
}
else {
    plan tests => 10;
}

my $t    = reset_repo();
my $wc   = catdir($t, 'wc');

set_hook(<<'EOS');
use SVN::Hooks::Mailer;
EOS

sub work {
    my $file = catfile($wc, $_[0]);
    <<"EOS";
echo txt >$file
svn add -q --no-auto-props $file
svn ci -mmessage $wc
EOS
}

set_conf(<<'EOS');
EMAIL_CONFIG();
EOS

work_nok('config sans args', 'DEPRECATED', work('f'));

set_conf(<<'EOS');
EMAIL_CONFIG(WHAT => 1);
EOS

work_nok('config invalid', 'DEPRECATED', work('f'));

set_conf(<<'EOS');
EMAIL_COMMIT(1);
EOS

work_nok('commit odd args', 'DEPRECATED', work('f'));

set_conf(<<'EOS');
EMAIL_COMMIT(what => 1);
EOS

work_nok('commit invalid opt', 'DEPRECATED', work('f'));

set_conf(<<'EOS');
EMAIL_COMMIT(match => 1);
EOS

work_nok('commit invalid match', "DEPRECATED", work('f'));

set_conf(<<'EOS');
EMAIL_COMMIT(match => qr/./);
EOS

work_nok('commit missing from', "DEPRECATED", work('f'));

set_conf(<<'EOS');
EMAIL_COMMIT(match => qr/./, from => 's@a.b');
EOS

work_nok('commit missing to', "DEPRECATED", work('f'));

exit 0 unless $io_available;

my $log = '02-mailer.log';

set_conf(<<'EOS');
EMAIL_CONFIG(IO => '02-mailer.log');
EMAIL_COMMIT(
    match => qr/^a/,
    tag   => 'A',
    from  => 'from@example.net',
    to    => 'to@example.net',
    diff  => undef,
);
EMAIL_COMMIT(
    match => qr/^b/,
    tag   => 'B',
    from  => 'from@example.net',
    to    => 'to@example.net',
    diff  => ['--no-diff-deleted'],
);
EOS

work_nok('commit none', 'DEPRECATED', work('none'));

work_nok('commit A', 'DEPRECATED', work('a'));

work_nok('commit B', 'DEPRECATED', work('b'));
