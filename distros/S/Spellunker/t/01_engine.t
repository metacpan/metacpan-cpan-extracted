use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;

use Spellunker;
use Data::Dumper;

BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }


my $engine = Spellunker->new();
ok $engine->{stopwords}->{"'s"} or die;
ok $engine->check_word("'s") or die;

# use Data::Dumper; die Dumper($engine->check_line('Spellunker->new'));

for (qw(good How darken lived studies How AUTHORS Dan's 19xx 2xx remove_header RFC IETF)) {
    ok($engine->check_word($_), $_);
}
ok(!$engine->check_word('gaaaaaa'));

is(0+$engine->check_line("It isn't"), 0);
is(0+$engine->check_line("<% \$module %>"), 0, 'in some case, Pod::Simple takes data from __DATA__ section.');
is(0+$engine->check_line("# What I think"), 0, 'Ignore Markdown-ish header');
is(0+$engine->check_line("You _know_ it"), 0, 'Plain text mark up');
is(0+$engine->check_line("You *know* it"), 0, 'Plain text mark up');
is(0+$engine->check_line("It isn't"), 0, 'short hand');
is(0+$engine->check_line('Use \%hashref'), 0, 'hashref');
is(0+$engine->check_line('Use \@val'), 0, 'array');
is(0+$engine->check_line("You can't"), 0, "can't");
is(0+$engine->check_line("O'Reilly"), 0, "O'Reilly");
is(0+$engine->check_line("'quoted'"), 0, "Quoted words");
is(0+$engine->check_line("'em"), 0, "'em");

while (<DATA>) {
    chomp;
    my @ret = $engine->check_line($_);
    is(0+@ret, 0, $_) or diag Dumper(\@ret);
}

done_testing;

__DATA__
cookies'
you've
You've
We're
mod_perl's
It doesn't
You'll
rename any non-standard executables so the names do not conflict with
Ingy döt Net
re-enabled
iterator
'xism' flag.
$frame->hasargs
$frame->hasargs()
$frame->hasargs($foo)
cpan
email
e-mail
my $spellunker = Spellunker->new();
pod-spell
machine-dependent
2xx is good code in HTTP
$spellunker->call
$spellunker->check_word($word);
You'd better quit smoking
%>>
:p
XD
--no-configure
Test::TCP->new(%args);
Test::TCP
Perl-ish
OO-ish
\1
\0
Copyright 2009-2011 Tatsuhiko Miyagawa
Masahiro Nagano <kazeburo {at} gmail.com>
IT'S ENTERTAINMENT!
If you want to use plugin under the 'Karas::Plugin::Name' namespace, you just write 'Name' part.
Show @args
$db->{connect_info}
:Str
#perl-qa
#amon
$JSON::SkipInvalid
You can pass a %args.
.7z file
.tar file
.jpeg file
pod-spell.t
why...
<p>hoge</p>
you can redistribute it and/or modify
5.8.x
5.10.x
+MyApp::Plugin::FooBar
\x2f
JSON::PP::
U+002F
\x00-\x1f\x22\x2f\x5c
~/lib/perl5
~/tmp/lib/perl5
PERL5LIB
APIs
/dev/tty
1st
2nd
3rd
4th
xt/01_spell.t
Stephen McCamant, and Gurusamy Sarathy.
delsp($x)
http://github.com/tokuhirom/Spellunker2
https://github.com/tokuhirom/Spellunker2
ua
正しいXHTMLで書けばこれらの問題は起こりません
&apos; bug.
e495aaaf0b9dcea6bc8bc97d9143a0d7a649fa06
