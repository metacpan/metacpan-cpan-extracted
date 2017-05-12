#!/usr/bin/perl -w
use Test::More tests => 69;
use strict;
use SVK::Test;
use SVK::Util qw( time2str );
our $output;

my ($xd, $svk) = build_test('bob');

is_output_like ($svk, 'ls', ["there/is/no/spoon"], qr|not a checkout path|, 'bad path');

foreach my $depot ('','bob') {
    my ($copath) = get_copath ("list$depot");
    $svk->checkout ("/$depot/", $copath);
    chdir ("$copath");
    mkdir ('A');
    overwrite_file ("A/foo", "foobar\n");
    my $size = -s "A/foo";
    $svk->add ('A');
    $svk->commit ('-m', 'init');
    mkdir('A/B');
    overwrite_file('A/B/foo',"foobar\n");
    $svk->add ('A/B');
    $svk->commit ('-m', 'dir B');

    is_output ($svk, 'ls', [], ['A/']);
    is_output ($svk, 'ls', ['-r1', 'A'], ['foo']);
    is_output ($svk, 'ls', ['A/foo'], ['foo']);
    is_output ($svk, 'ls', ['-R', 'A'], ['B/', ' foo', 'foo']);
    is_output ($svk, 'ls', ['-R', '-d1'], ['A/', ' B/', ' foo']);
    is_output ($svk, 'ls', ['-f','A/foo'], ["/$depot/A/foo"]);
    is_output ($svk, 'ls', ["/$depot/"], ['A/']);
    is_output ($svk, 'ls', ['-f',"/$depot/"], ["/$depot/A/"]);
    is_output ($svk, 'ls', ['-f',"/$depot/A"],  ["/$depot/A/B/", "/$depot/A/foo"]);
    is_output ($svk, 'ls', ['-f',"/$depot/A/"],
	       ["/$depot/A/B/","/$depot/A/foo"]);
    is_output ($svk, 'ls', ['-f','-R',"/$depot/A/"], ["/$depot/A/B/","/$depot/A/B/foo", "/$depot/A/foo"]);
    is_output ($svk, 'ls', ['-f',"/$depot/crap/"], ['Path /crap is not versioned.']);
    ok ($svk->ls ('-f', "/$depot/crap/") == 1, "ls -f /$depot/crap/ [exit status]");
    is_output ($svk, 'ls', ['-f',"/$depot/", "/$depot/A"],
               ["/$depot/A/", '', "/$depot/A/B/","/$depot/A/foo", '']);
    ok ($svk->ls ('-f', "/$depot/", "/$depot/A") == 0, "ls -f /$depot/ /$depot/A [exit status]");
    is_output ($svk, 'ls', ['-f',"/$depot/A", "/$depot/crap/"],
               ["/$depot/A/B/","/$depot/A/foo", '', 'Path /crap is not versioned.', '']);
    ok ($svk->ls ('-f', "/$depot/A", "/$depot/crap/") == 1, "ls -f /$depot/A /$depot/crap/ [exit status]");

    use POSIX qw( mktime );
    my $re_date = join '|', map { 
	quotemeta time2str( "%b", mktime(0, 0, 0, 1, $_, 96) ) 
    } 0 .. 11;
    $re_date = " ?(?:$re_date) \\d{2} \\d{2}:\\d{2}";
    my $re_user = "(?:\\S*\\s+)";
    is_output ($svk, 'ls', ['-v'],
               [qr"      2 $re_user          $re_date A/"]);
    is_output ($svk, 'ls', ['-v', '-r1'],
               [qr"      1 $re_user          $re_date A/"]);
    is_output ($svk, 'ls', ['-v', 'A/foo'],
               [qr"      1 $re_user        $size $re_date foo"]);
    is_output ($svk, 'ls', ['-v', '-r1', '-R'],
               [qr"      1 $re_user          $re_date A/",
                qr"      1 $re_user        $size $re_date  foo"]);
    is_output ($svk, 'ls', ['-v', '-R'],
               [qr"      2 $re_user          $re_date A/",
                qr"      2 $re_user          $re_date  B/",
                qr"      2 $re_user        $size $re_date   foo",
                qr"      1 $re_user        $size $re_date  foo"]);
    is_output ($svk, 'ls', ['-v', '-R', '-d1'],
               [qr"      2 $re_user          $re_date A/",
                qr"      2 $re_user          $re_date  B/",
                qr"      1 $re_user        $size $re_date  foo"]);
    is_output ($svk, 'ls', ['-v', '-f'],
               [qr"      2 $re_user          $re_date /$depot/A/"]);
    is_output ($svk, 'ls', ['-v', '-f', 'A/foo'],
               [qr"      1 $re_user        $size $re_date /$depot/A/foo"]);
    is_output ($svk, 'ls', ['-v', '-f', "/$depot/"],
               [qr"      2 $re_user          $re_date /$depot/A/"]);
    is_output ($svk, 'ls', ['-v', '-f', "/$depot/A/"],
               [qr"      2 $re_user          $re_date /$depot/A/B/",
                qr"      1 $re_user        $size $re_date /$depot/A/foo"]);
    is_output ($svk, 'ls', ['-v', '-f', '-R', "/$depot/A/"],
               [qr"      2 $re_user          $re_date /$depot/A/B/",
                qr"      2 $re_user        $size $re_date /$depot/A/B/foo",
                qr"      1 $re_user        $size $re_date /$depot/A/foo"]);
    is_output ($svk, 'ls', ['-v', '-f',"/$depot/crap/"],
               ['Path /crap is not versioned.']);
    ok ($svk->ls ('-v', '-f', "/$depot/crap/") == 1, "ls -v -f /$depot/crap/ [exit status]");
    is_output ($svk, 'ls', ['-v', '-f', "/$depot/", "/$depot/A/"],
               [qr"      2 $re_user          $re_date /$depot/A/",
                  '',
                qr"      2 $re_user          $re_date /$depot/A/B/",
                qr"      1 $re_user        $size $re_date /$depot/A/foo", '']);
    ok ($svk->ls ('-v', '-f', "/$depot/", "/$depot/A") == 0, "ls -v -f /$depot/ /$depot/A [exit status]");
    is_output ($svk, 'ls', ['-v', '-f', "/$depot/A/", "/$depot/crap/"],
               [qr"      2 $re_user          $re_date /$depot/A/B/",
                qr"      1 $re_user        $size $re_date /$depot/A/foo",
                  '',
                  'Path /crap is not versioned.', '']);
    ok ($svk->ls ('-v', '-f', "/$depot/A", "/$depot/crap/") == 1, "ls -f /$depot/A /$depot/crap/ [exit status]");

    chdir("..");
}

