#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Module::ScanDeps qw/scan_chunk/;

my @tests = (
    {
        chunk    => 'use strict;',
        expected => 'strict.pm',
    },
    {
        chunk    => 'use base qw(strict);',
        expected => 'base.pm strict.pm',
    },
    {
        chunk    => 'use parent qw(strict);',
        expected => 'parent.pm strict.pm',
    },
    {
        chunk    => 'use parent "Foo::Bar"',
        expected => 'parent.pm Foo/Bar.pm',
    },
    {
        chunk    => 'use parent qw(Fred Wilma);',
        expected => 'parent.pm Fred.pm Wilma.pm',
    },
    {
        chunk    => 'use parent "Foo::Bar", qw(Fred Wilma);',
        expected => 'parent.pm Foo/Bar.pm Fred.pm Wilma.pm',
    },
    {
        chunk    => 'use parent::doesnotexist qw(strict);',
        expected => 'parent/doesnotexist.pm',
    },
    {
        chunk    => 'use Mojo::Base "strict";',
        expected => 'Mojo/Base.pm strict.pm',
        comment  => 'Mojo::Base',
    },
    {
        chunk    => 'use Catalyst qw/-Debug ConfigLoader Session::State::Cookie/',
        expected => 'Catalyst.pm Catalyst/Plugin/ConfigLoader.pm 
                     Catalyst/Plugin/Session/State/Cookie.pm',
        comment  => '-Debug should be skipped',
    },
    {
        chunk    => 'use Catalyst qw/URI +My::Catalyst::Stuff/',
        expected => 'Catalyst.pm Catalyst/Plugin/URI.pm My/Catalyst/Stuff.pm',
    },
    {
        chunk    => 'with "Some::Role1", "Some::Role2"',
        expected => 'Some/Role1.pm Some/Role2.pm',
    },
    {
        chunk    => 'with qw(Some::Role1 Some::Role2)',
        expected => 'Some/Role1.pm Some/Role2.pm',
    },
    {
        chunk    => 'use I18N::LangTags 0.30 ();',
        expected => 'I18N/LangTags.pm',
    },
);

plan tests => 0+@tests;

foreach my $t (@tests)
{
    my @got = scan_chunk($t->{chunk});
    my @exp = split(' ', $t->{expected});
    is_deeply([sort @got], [sort @exp], $t->{comment});
}
