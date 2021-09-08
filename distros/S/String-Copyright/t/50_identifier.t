use Test2::V0;

plan 63;

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
is copyright("Copyright: Foo"),  ':Foo', '"Copyright:" as identifier';
is copyright('Copyright : Foo'), ':Foo', '"Copyright :" as identifier';
is copyright("Copyright-holder: Foo"), ':Foo',
	'"Copyright-holder:" as identifier';
is copyright("Copyright-holders: Foo"), ':Foo',
	'"Copyright-holders:" as identifier';
is copyright("Copr. Foo"),         ':Foo', '"Copr." as identifier';
is copyright('Copyright -C- Foo'), ':Foo', '"Copyright -C- " as identifier';

is copyright('Copyright - Foo'),  ':Foo', '"Copyright - " as identifier';
is copyright('Copyright -- Foo'), ':Foo', '"Copyright -- " as identifier';

is copyright('\(co Foo'), ':Foo', '"\(co" (© in roff markup) as identifier';

is copyright('Copyright: (C) 2001 Foo'), '2001:Foo',
	'"Copyright: (C)" as identifier';
is copyright('Copyright(C) 2001 Foo'), '2001:Foo',
	'"Copyright(C)" as identifier';
is copyright('Copyright:: Copyright (c) Foo'), ':Foo',
	'"Copyright:: Copyright (c)" as identifier';

is copyright('Copyright 1999 (c) Foo'), '1999:Foo',
	'"pseudo-sign after years';

is copyright("-C- Foo"), '', 'bogus lone non-pseudosign -C-';

is copyright('(c) You must '),
	'', 'bogus pseudo-sign chatter "(c) You must"';
is copyright('((b), (c), 0)'),
	'', 'bogus pseudo-sign chatter "(c), 0)"';
is copyright('memset ((d), (c), (l))'),
	'', 'bogus pseudo-sign chatter "(c), cl)"';

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
is copyright('if the compilation and its resulting copyright are '),
	'', 'bogus identifier followed by " are"';
is copyright('according to the copyright dates in '),
	'', 'bogus identifier followed by " dates"';
is copyright('to sign a "copyright disclaimer" for the program '),
	'', 'bogus identifier followed by " disclaimer"';
is copyright('See COPYRIGHT for more information'),
	'', 'bogus identifier followed by " for "';
is copyright('infringe copyright if you do '),
	'', 'bogus identifier followed by " if"';
is copyright('disclaims all copyright interest in '),
	'', 'bogus identifier followed by " interest"';
is copyright('fall under the copyright of this Package'),
	'', 'bogus identifier followed by " of "';
is copyright('requiring copyright permission '),
	'', 'bogus identifier followed by " permission"';
is copyright('contain a copyright sign '),
	'', 'bogus identifier followed by " sign"';
is copyright('contain a copyright symbol '),
	'', 'bogus identifier followed by " symbol"';
is copyright('contain a copyright text '),
	'', 'bogus identifier followed by " text"';
is copyright('the WIPO copyright treaty '),
	'', 'bogus identifier followed by " treaty"';
is copyright('Copyright transferred 2000/09/15 to Artifex'),
	'', 'bogus identifier followed by " transferred"';
is copyright('copyright tag white point and grayTRC'),
	'', 'bogus identifier followed by " tag"';
is copyright('change the copyright block at the bottom'),
	'', 'bogus identifier followed by " block"';
is copyright('These have no copyright, and are of unknown quality.'),
	'', 'bogus identifier preceded by "no "';
is copyright('we copyright the '),
	'', 'bogus identifier preceded by "we "';
is copyright('Check for copyright lines'),
	'', 'bogus identifier preceded by "for "';
is copyright('#define FONT_INFO_COPYRIGHT 0x0040'),
	'', 'bogus identifier preceded by underscore';

is copyright('the United States Copyright Act of 1976'),
	'', 'bogus identifier "Copyright Act"';
is copyright('the U.S. Copyright Act'),
	'', 'bogus identifier "Copyright Act"';
is copyright('the US Copyright Act'),
	'', 'bogus identifier "Copyright Act"';
is copyright('the repressive Digital Millennium Copyright Act'),
	'', 'bogus identifier "Copyright Act"';

is copyright('copyright the library, '),
	'', 'bogus identifier followed by " the library,"';
is copyright('copyright the software, '),
	'', 'bogus identifier followed by " the software,"';
is copyright('COPYRIGHT 1999 The Software Studio <eric@civicknowledge.com>'),
	'1999:The Software Studio <eric@civicknowledge.com>',
	'identifier followed by non-bogus "The Software Studio"';

is copyright('copyright-at-end-flag: t'),
	'', 'bogus identifier followed by dash';

is copyright('COPYRIGHT This software is copyright (c) 2004 by Foo'),
	'2004:Foo', 'bogus identifier followed by " This ", then real identifier';

my $todo = todo 'not implemented yet';
is copyright(
	'Copyright 1995 - 2013 by Andreas Koenig, Copyright 2013 by Kenichi Ishigaki'
	),
	'1995-2013:Andreas Koenig', 'dual entries on one line';

done_testing;
