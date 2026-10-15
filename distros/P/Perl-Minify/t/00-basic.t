#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Perl::Minify') }

# Default exports: none (check in main::)
ok(!defined(&minify),  'minify not exported by default');
ok(!defined(&minify_sub), 'minify_sub not exported by default');

# Explicit import
my $imported = eval q{
    package TestImport;
    use Perl::Minify qw(minify minify_sub);
    defined(&minify) && defined(&minify_sub) ? 1 : 0;
};
ok($imported, 'both functions imported via qw()');

# :all tag
my $all = eval q{
    package TestAll;
    use Perl::Minify ':all';
    defined(&minify) && defined(&minify_sub) ? 1 : 0;
};
ok($all, 'both functions imported via :all');

# _resolve_opts is NOT exported
my $private = eval q{
    package TestPrivate;
    use Perl::Minify ':all';
    !defined(&_resolve_opts);
};
ok($private, '_resolve_opts not exported');

done_testing;
