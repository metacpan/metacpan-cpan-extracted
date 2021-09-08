use Test2::V0;

plan 46;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is copyright("© 1999 12345 Steps"),
	'1999:12345 Steps',
	'year-like owner';

is copyright("© 1999 1234 Steps"),
	'1234, 1999:Steps',
	'too-year-like owner';

is copyright("© Foo"), ':Foo', 'year-less owner';

is copyright("© , Foo"), ':Foo', 'messy owner starting with comma';
is copyright("Copyright,, Foo"),  '', 'messy owner starting with dual comma';
is copyright("Copyright, , Foo"), '', 'messy owner starting with dual comma';

is copyright("© -Foo"),  '', 'bogus owner starting with dash';
is copyright("© --Foo"), '', 'bogus owner starting with double dash';

is copyright("© (Foo)"), ':(Foo)', 'owner starting with paranthesis';

is copyright('© Foo (Bar) Baz'), ':Foo (Bar) Baz',
	'owner with non-first word in parenthesis';

is copyright('© Foo (Bar Baz)'), ':Foo (Bar Baz)',
	'owner with non-first words in parenthesis';

is copyright('© (Foo) Bar Baz'), ':(Foo) Bar Baz',
	'owner with first word in parenthesis';

# TODO: either exclude these or reduce owner initial regexp
is copyright('© ?Foo'), ':Foo',  'messy owner starting with question mark';
is copyright('© *Foo'), ':*Foo', 'messy owner starting with asterisk';
is copyright('© ,Foo'), ':Foo',  'messy owner starting with comma';
is copyright('© <Foo'), ':<Foo', 'messy owner starting with chevron';
is copyright('© @Foo'), ':@Foo', 'messy owner starting with at sign';
is copyright('© [Foo'), ':[Foo', 'messy owner starting with bracket';
is copyright('© {Foo'), ':{Foo', 'messy owner starting with brace';

is copyright('and (c) all begin '), '', 'bogus owner starting with all begin';

is copyright('© !Foo'),   '',     'bogus owner starting with bang';
is copyright('© \'Foo'),  '',     'bogus owner starting with singlequote';
is copyright('© "Foo'),   '',     'bogus owner starting with doublequote';
is copyright('© #Foo'),   '',     'bogus owner starting with hash';
is copyright('© $Foo'),   '',     'bogus owner starting with dollar';
is copyright('© %Foo'),   '',     'bogus owner starting with percent';
is copyright('© &Foo'),   '',     'bogus owner starting with ampersand';
is copyright("© ( Foo)"), '',     'bogus owner starting with lone paren';
is copyright('© )Foo'),   '',     'bogus owner starting with end-bracket';
is copyright('© +Foo'),   '',     'bogus owner starting with plus';
is copyright('© . Foo'),  '',     'bogus owner starting with dot';
is copyright('© :Foo'),   ':Foo', 'owner starting with colon';
is copyright('© ;Foo'),   '',     'bogus owner starting with semicolon';
is copyright('© >Foo'),   '',     'bogus owner starting with end chevron';
is copyright('© =Foo'),   '',     'bogus owner starting with equals';
is copyright('© ]Foo'),   '',     'bogus owner starting with end bracket';
is copyright('© \Foo'),   '',     'bogus owner starting with backslash';
is copyright('© ^Foo'),   '',     'bogus owner starting with caret';
is copyright('© _Foo'),   '',     'bogus owner starting with underscore';
is copyright('© `Foo'),   '',     'bogus owner starting with backtick';
is copyright('© }Foo'),   '',     'bogus owner starting with end brace';
is copyright('© |Foo'),   '',     'bogus owner starting with pipe';
is copyright('© ~Foo'),   '',     'bogus owner starting with tilde';

is copyright('© Foo, all rights reserved.'), ':Foo', 'boilerplate';

is copyright('© Foo, all rights reserved. Bar'), ':Foo',
	'boilerplate, then noise';

my $todo = todo 'not yet handled';

is copyright('© Foo, all rights reserved. © Bar'), ":Foo\n:Bar",
	'boilerplate, then another copyright';

done_testing;
