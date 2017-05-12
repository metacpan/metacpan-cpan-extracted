#!perl -w
use strict;
use warnings;
use Test::More tests => 30;
use Term::Emit;

# _oid(): output identifier function
is(Term::Emit::_oid(),         0,      "_oid(): null");
is(Term::Emit::_oid(q{}),      0,      "_oid(): empty string");
is(Term::Emit::_oid("xy"),     0,      "_oid(): string");
my $str = q{};
is(Term::Emit::_oid(\$str),    "str",  "_oid(): string ref");
is(Term::Emit::_oid(*STDIN),   0,      "_oid(): *STDIN");
is(Term::Emit::_oid(*STDOUT),  1,      "_oid(): *STDOUT");
is(Term::Emit::_oid(*STDERR),  2,      "_oid(): *STDOUT");

# _colorize(): apply ANSI escapes to color a string
my %colors = (EMERG => '[1;31;40m',
              ALERT => '[1;35m',
              CRIT  => '[1;31m',
              FAIL  => '[1;31m',
              FATAL => '[1;31m',
              ERROR => '[31m',
              WARN  => '[33m',
              NOTE  => '[36m',
              INFO  => '[32m',
              OK    => '[1;32m',
              DEBUG => '[37;43m',
              NOTRY => '[30;47m',
              UNK   => '[1;37;47m',
              YES   => '[32m',
              NO    => '[31m',
             );
foreach my $sev (keys %colors) {
    my $code = $colors{$sev};
    is(Term::Emit::_colorize("abc", $sev), chr(27).$code.'abc'.chr(27).'[0m', "_colorize(): severity $sev");
}
is(Term::Emit::_colorize("abc", "DONE"),           'abc', "_colorize(): severity DONE");
is(Term::Emit::_colorize("abc", "AnyThingElse"),   'abc', "_colorize(): anything else");

# _wrap(): word wrap a string
my $wstr = "Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
my @got = ();
@got = Term::Emit::_wrap(undef, 10, 20);
is_deeply(\@got, [undef], "_wrap(): undefined message");
@got = Term::Emit::_wrap($wstr, 1, 2);
is_deeply(\@got, [$wstr], "_wrap(): max too small (<3)");
@got = Term::Emit::_wrap($wstr, 9, 7);
is_deeply(\@got, [$wstr], "_wrap(): min > max");
@got = Term::Emit::_wrap($wstr, 10, 90);
is_deeply(\@got, [$wstr], "_wrap(): 10..90");
@got = Term::Emit::_wrap($wstr, 25, 30);
is_deeply(\@got, ["Lorem ipsum dolor sit amet,",
                  "consectetur adipiscing elit."], "_wrap(): 25..30");
@got = Term::Emit::_wrap($wstr, 17, 20);
is_deeply(\@got, ["Lorem ipsum dolor",
                  "sit amet, consectetu",
                  "r adipiscing elit."], "_wrap(): 17..20 forcing word to split");
