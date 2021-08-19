use Test2::V0;

plan 23;

use String::Copyright {
	format => sub { join ':', $_->[0] || '', $_->[1] || '' }
};

is copyright('This software is copyright (c) 2016 by Foo'), '2016:Foo',
	'sign pseudosign intro';
is copyright('This software is (c) copyright 2016 by Foo'), '2016:Foo',
	'pseudosign sign intro';

is copyright("Copyright:\n2000 Foo"), '2000:Foo', 'sign then newline';
is copyright("Copyright:\n!not Foo"), '', 'sign then newline then non-owner';

is copyright("#define foo(c) 1999 Foo"), '', 'bogus sign';

is copyright("(c) 1999 Foo\n#define foo(c) 1999 Bar"),
	'1999:Foo',
	'sign, then bogus sign';

is copyright("#define foo(c) 1999 Foo\n(c) 1999 Bar"),
	'1999:Bar',
	'bogus sign, then sign';

is copyright("(c) 1999 Foo #define foo(c) 1999 Bar"),
	'1999:Foo #define foo(c) 1999 Bar',
	'sign, then bogus sign on same line';

is copyright("#define foo(c) 1997 Foo (c) 1999 Bar"),
	'1999:Bar',
	'bogus sign, then sign on same line';

is copyright("(c) 1999 Foo (c) 2000 Foo © 2002 Foo"),
	'1999:Foo (c) 2000 Foo © 2002 Foo',
	'sign x 3 on same line';

my $todo = todo 'not yet handled';
is copyright("© 2000 Foo\n    2005 Bar\n2008 Baz"),
	":2000:Foo\n2005:Bar\n2008:Baz",
	'multi-line multi-statement';

is copyright("Copyright:\n2000 Foo\n2000 Bar"),
	"2000:Foo\n2000:Bar",
	'multi-line multi-statement after single sign';

is copyright("Copyright:\nFoo\nBar\n\nBaz"),
	":Foo\n:Bar",
	'multi-line owner-only multi-statement after single sign';

is copyright("Copyright:\n2000\n2001\nFoo\n\n2002"),
	"2000-2000:\n:Foo",
	'multi-line year-only multi-statement after single sign';
$todo = undef;

is copyright(
	"Copyright (C) 2004 - 2005\n\nSee http://foo.bar for more information"),
	'2004-2005:',
	'years-only, with unrelated text after double-newline';

is copyright("* Note, the copyright information is at end of file."), '',
	'non-sign and space';

is copyright("* For copyright information, see copyright.h."), '',
	'non-sign and punctuation';

is copyright('covered under the following copyright and permission notice:'),
	'',
	'chatter involving "and"';

is copyright(" if (ref \$copyright eq 'ARRAY') {"), '',
	'chatter involving "eq"';

is copyright('the above copyright  notice, this list'), '',
	'chatter with double whitespace';
is copyright(
	"=head1 COPYRIGHT AND LICENSE\n\nThis software is (c) copyright 2016 by Foo"
	), '2016:Foo',
	'chatter then copyright';

is copyright("Copyright ?1991-2012 Unicode, Inc."),
	'1991-2012:Unicode, Inc.',
	'broken copyright sign';

is copyright(
	"Copyright 1991-2012 Unicode, Inc. All rights reserved. Distributed under the Terms of Use in http://www.unicode.org/copyright.html."
	), '1991-2012:Unicode, Inc.',
	'boilerplate then chatter';

done_testing;
