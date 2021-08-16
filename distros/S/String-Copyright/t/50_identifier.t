use strict;
use warnings;
use utf8;

use Test::More tests => 16;

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
