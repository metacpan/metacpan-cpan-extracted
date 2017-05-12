#!/usr/bin/perl
use warnings;
use strict;
use FindBin '$Bin';
use lib "$Bin/lib";
use My::Setup ':all';
use Test::More;

# those are ok both under valid() and valid_relaxed()
my @basic_ok = (
    'Post Road 123',
    'Post Rd 123',
    'Post Street 123',
    'Post St 123',
    'Post Avenue 123',
    'Post Av 123',
    'Post Alley 123',
    'Post Drive 123',
    'Post Grove 123',
    'Post Walk 123',
    'Post Parkway 123',
    'Post Row 123',
    'Post Lane 123',
    'Post Bridge 123',
    'Post Boulevard 123',
    'Post Square 123',
    'Post Garden 123',
    'Post Strasse 123',
    'Post Allee 123',
    'Post Gasse 123',
    'Post Platz 123',
    'Postsparkassenplatz 1',
    'Postelweg 5',
    'Boxgasse 32',
    'Postfachplatz 11',
    'PFalznerweg 91',
    'aPOSTelweg 12',
    '',
    undef,
    WHITELIST,
);

# those are not ok both under valid() and valid_relaxed()
my @basic_not_ok = (
    'Box 123',       'Pob',    'Postbox',                'Post',
    'Postschachtel', 'PF 123', 'Postfach 41, 1023 Wien', BLACKLIST,
);

# These are not ok under valid(), but are ok under valid_relaxed().
my @relaxed = (
    'PO 37, Postgasse 5',
    'P.F. 37, Post Drive 9',
    'P.O. BOX 37, Post Drive 9',
    'Post Street, P.O.B.',
    'Post Gasse, Postlagernd',
);
plan tests => 2 * (@basic_ok + @basic_not_ok + @relaxed);
my $matcher = get_matcher();
$matcher->set_is_literal_text;
$matcher->update;
is_valid($matcher, @basic_ok);
is_invalid($matcher, @basic_not_ok, @relaxed);
is_valid_relaxed($matcher, @basic_ok, @relaxed);
is_invalid_relaxed($matcher, @basic_not_ok);
