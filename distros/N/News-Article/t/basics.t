#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 8 }

use News::Article;
ok(1);

my @data = (
'From: Ann Example <somebody@example.com>',
'Subject: example test post',
'Newsgroups: example.test',
'Organization: example.com',
' - for all your example needs',
'Message-ID: <0001@news.example.com>',
'',
'This is an example post.',
'',
'-- ',
'Ann Example <somebody@example.com> Sample Poster to the Stars'
);

my $art = News::Article->new();
ok(defined($art));
exit unless defined($art);

ok($art->read(\@data));
ok($art->lines == 4);

my %names;
my $n = 0;
++$names{lc $_}, ++$n for ($art->header_names);
ok($n == 5);
$n = 1;
$names{$_} == 1 or $n = 0 for qw(from subject newsgroups message-id organization);
ok($n);

ok($art->header("from") eq 'Ann Example <somebody@example.com>');
ok($art->header("organization") eq "example.com\n - for all your example needs");

exit;
__END__
