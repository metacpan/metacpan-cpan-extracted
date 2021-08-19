use Test2::V0;

plan 30;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is copyright("© Foo"),   ':Foo', 'copyright sign as identifier';
is copyright("©Foo"),    ':Foo', 'copyright sign and no space as identifier';
is copyright("Ⓒ Foo"),  ':Foo', 'capital C-in-circle symbol as identifier';
is copyright("ⓒ Foo"),  ':Foo', 'c-in-circle symbol as identifier';
is copyright("⒞ Foo"),  ':Foo', 'c-in-parens symbol as identifier';
is copyright("🄒 Foo"), ':Foo', 'capital c-in-parens symbol as identifier';
is copyright("🄫 Foo"), ':Foo', 'cursive c-in-circle symbol as identifier';
is copyright("🅒 Foo"), ':Foo', 'inverse c-in-circle symbol as identifier';
is copyright("(c) Foo"),  ':Foo', '(c) as identifier';
is copyright("(C) Foo"),  ':Foo', '(C) as identifier';
is copyright("{c} Foo"),  ':Foo', '{c} as identifier';
is copyright("{C} Foo"),  ':Foo', '{C} as identifier';
is copyright("Copyright: Foo"), ':Foo', '"Copyright:" as identifier';
is copyright("Copyright-holder: Foo"), ':Foo',
	'"Copyright-holder:" as identifier';
is copyright("Copyright-holders: Foo"), ':Foo',
	'"Copyright-holders:" as identifier';
is copyright("Copr. Foo"), ':Foo', '"Copr." as identifier';

is copyright('Copyright: (C) 2001 Foo'), '2001:Foo',
	'"Copyright: (C)" as identifier';
is copyright('Copyright(C) 2001 Foo'), '2001:Foo',
	'"Copyright(C)" as identifier';

is copyright('others have copyright or other rights in the material'),
	'', 'bogus identifier followed by " or"';
is copyright('Copyright Oracle'),
	':Oracle', 'make sure excluding " or" still includes e.g. " Oracle"';

is copyright('The following copyright applies to code from'),
	'', 'bogus identifier followed by " applies"';
is copyright('See original copyright at the end of this file'),
	'', 'bogus identifier followed by " at"';
is copyright(
	'THIS SOFTWARE IS PROVIDED BY <<var;name=copyrightHolderAsIs;original=COPYRIGHT HOLDER;match=.+>> "AS IS" AND '
	),
	'', 'bogus identifier followed by latin character';
is copyright('Copyright transferred 2000/09/15 to Artifex'),
	'', 'bogus identifier followed by " transferred"';
is copyright('copyright tag white point and grayTRC'),
	'', 'bogus identifier followed by " tag"';
is copyright('change the copyright block at the bottom'),
	'', 'bogus identifier followed by " block"';
is copyright('These have no copyright, and are of unknown quality.'),
	'', 'bogus identifier preceded by "no "';
is copyright('#define FONT_INFO_COPYRIGHT 0x0040'),
	'', 'bogus identifier preceded by underscore';

is copyright('copyright-at-end-flag: t'),
	'', 'bogus identifier followed by dash';

my $todo = todo 'not implemented yet';
is copyright(
	'Copyright 1995 - 2013 by Andreas Koenig, Copyright 2013 by Kenichi Ishigaki'
	),
	'1995-2013:Andreas Koenig', 'dual entries on one line';

done_testing;
