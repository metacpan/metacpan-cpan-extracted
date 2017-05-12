# -*- perl -*-
#	utf8_text.t --- Term::ReadLine::Gnu UTF-8 text string test script
#
#	$Id: utf8_text.t 551 2016-06-12 14:30:54Z hayashi $
#
#	Copyright (c) 2016 Hiroo Hayashi.  All rights reserved.
#
#	This program is free software; you can redistribute it and/or
#	modify it under the same terms as Perl itself.

# The GNU Readline Library start supporting multibyte characters since
# version 4.3, and is still improving the support.  You should use the
# latest GNU Readline Library for UTF-8 support.

use strict;
use warnings;

# convert into UTF-8 text strings
# use ':encoding(UTF-8)', not ':utf8' nor ':encoding(utf8)'
#   http://perldoc.perl.org/PerlIO.html
#   http://perldoc.perl.org/Encode.html, 'UTF-8 vs. utf8 vs. UTF8'
use utf8;
use open ':std', ':encoding(UTF-8)';

# This must follow UTF-8 setting.
# See 'CAVEATS and NOTES' in http://perldoc.perl.org/Test/More.html for details.
use constant NTEST => 13;
use Test::More tests => NTEST;
use Data::Dumper;

# redefine Test::Mode::note due to it requires Perl 5.10.1.
{
    no warnings 'redefine';
    sub note {
	my $msg = join('', @_);
	$msg =~ s{\n(?!\z)}{\n# }sg;
	print "# $msg" . ($msg =~ /\n$/ ? '' : "\n");
    }
}

BEGIN {
#    $ENV{PERL_RL} = 'Gnu';	# force to use Term::ReadLine::Gnu
    $ENV{LC_ALL} = 'en_US.UTF-8';
}

use Term::ReadLine;
ok(1, 'load done');
note "I'm testing Term::ReadLine::Gnu version $Term::ReadLine::Gnu::VERSION";

my $verbose = scalar @ARGV && ($ARGV[0] eq 'verbose');

# check locale setting because the following tests depend on locale feature.
use Config;
if (!$Config{d_setlocale}) {
    diag "d_setlocale is not defined. Skipped...";
    ok(1, 'skip') for 1..(NTEST-1);
    exit 0;
}
ok(1, '$Config{d_setlocale}');

# http://perldoc.perl.org/perllocale.html
use POSIX qw(locale_h);
use locale;
my $old_locale = setlocale(LC_ALL, 'en_US.UTF-8');
if (!defined $old_locale) {
    diag "The locale 'en_US.UTF-8' is not supported. Skipped...";
    ok(1, 'skip') for 1..(NTEST-2);
    exit 0;
}
ok(1, 'setlocale');

my ($in, $line, @layers);
open ($in, "<", "t/utf8.txt") or die "cannot open utf8.txt: $!";

if (0) {	# This may cause a fail.
    $line = <$in>; chomp($line);
    note $line;
    note Dumper($line, "🐪");
    ok($line eq "🐪", 'pre-read');
}

my $expected = $] >= 5.010 ? ['unix', 'perlio', 'encoding(utf-8-strict)', 'utf8']
    : ['stdio', 'encoding(utf-8-strict)', 'utf8'];
my $expected_x;
if (${^UNICODE} == 0) {
    $expected_x = $expected;
} else {
    $expected_x = $] >= 5.010 ? ['unix', 'perlio', 'utf8', 'encoding(utf-8-strict)', 'utf8']
    : ['stdio', 'utf8', 'encoding(utf-8-strict)', 'utf8'];
}
@layers = PerlIO::get_layers($in);
note 'i: ', join(':', @layers);
is_deeply(\@layers, $expected, "input layers before 'new'");
@layers = PerlIO::get_layers(\*STDOUT);
note 'o: ', join(':', @layers);
is_deeply(\@layers, $expected_x, "output layers before 'new'");

my $t;
if ($verbose) {
    #$t = new Term::ReadLine 'ReadLineTest', \*STDIN, \*STDOUT;
    #$Term::ReadLine::Gnu::utf8_mode = 1;
    $t = new Term::ReadLine 'ReadLineTest';
    $t->enableUTF8;
} else {
    $t = new Term::ReadLine 'ReadLineTest', $in, \*STDOUT;
}
print "\n";	# rl_initialize() outputs some escape characters in Term-ReadLine-Gnu less than 6.3, 
isa_ok($t, 'Term::ReadLine');

@layers = PerlIO::get_layers($t->IN);
note 'i: ', join(':', @layers);
is_deeply(\@layers, $expected, "input layers after 'new'");
@layers = PerlIO::get_layers($t->OUT);
note 'o: ', join(':', @layers);
is_deeply(\@layers, $expected_x, "output layers after 'new'");

# force the GNU Readline 8 bit through
if ($t->ReadLine eq 'Term::ReadLine::Gnu') {
    $t->parse_and_bind('set input-meta on');
    $t->parse_and_bind('set convert-meta off');
    $t->parse_and_bind('set output-meta on');
}

my $a = $t->Attribs;
# verbose mode
if ($verbose) {
    $a->{do_expand} = 1;
    while ($line = $t->readline("🐪🐪> ")) {
	print {$t->OUT} $line, "\n";
	print {$t->OUT} Dumper($line), "\n";
    }
    exit 0;
}

# UTF8 string input
$line = $t->readline("🐪🐪> ");
note $line;
note Dumper($line, "🐪");
ok($line eq "🐪", 'UTF-8 text string read');
ok(utf8::is_utf8($line), 'UTF-8 text string: function');

# output stream
print {$t->OUT} "# output stream test: 🐪 🐪🐪 🐪🐪🐪\n";

# UTF8 string variable access
$a->{readline_name} = '🐪 🐪🐪 🐪🐪🐪';
$line = $a->{readline_name};
note $line;
note Dumper($line);
ok($line eq '🐪 🐪🐪 🐪🐪🐪', 'UTF-8 binary string variable');
ok(utf8::is_utf8($line), 'UTF-8 text string: variable');

# UTF-8 text string works well.
ok(reverse $line eq '🐪🐪🐪 🐪🐪 🐪', 'This does work.');

if (0) {	# This may cause a fail.
    $line = <$in>; chomp($line);
    note $line;
    note Dumper($line, "🐪🐪");
    ok($line eq "🐪🐪");

    $line = $t->readline("🐪🐪🐪> ");
    note $line;
    note Dumper($line, "🐪🐪🐪");
    ok($line eq "🐪🐪🐪");

    @layers = PerlIO::get_layers($in);      note 'i: ', join(':', @layers);
    @layers = PerlIO::get_layers(\*STDOUT); note 'o: ', join(':', @layers);
}

exit 0;
