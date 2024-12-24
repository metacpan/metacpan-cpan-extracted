use 5.20.0;

use Test::Differences;
use Test::More;
use Test::Synopsis::Expectation;
use utf8;
use warnings  qw(FATAL utf8);    # fatalize encoding glitches
use Unicode::Normalize;
use open ':std', ':encoding(utf8)';

use Time::localtime;
my $current_year = (localtime->year() + 1900);

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

require_ok( 'Software::Copyright' );

synopsis_ok('lib/Software/Copyright.pm');

my @tests = (
    [
        '2002-06 Charles Kerr <charles@rebelbase.com>',
        '2002-2006, Charles Kerr <charles@rebelbase.com>'
    ],
    [
        # found in texlive-extra
        '2022 -20** by Romain NOEL <romainoel@free.fr>',
        "2022-$current_year, Romain NOEL <romainoel\@free.fr>",
    ],
    [
        # found in texlive-extra
        '2011-.. Maïeul Rouquette',
        "2011-$current_year, Maïeul Rouquette",
    ],
    [
        '2011 Heinrich Muller <henmull@src.gnome.org> / 2002-2006 Charles Kerr <charles@rebelbase.com>',
        "2011, Heinrich Muller <henmull\@src.gnome.org>\n2002-2006, Charles Kerr <charles\@rebelbase.com>"
    ],
    [
        '2002-6 Charles Kerr <charles@rebelbase.com> / 2002, 2003, 2004, 2005, 2007, 2008, 2010 Free Software / 2011 Heinrich Muller <henmull@src.gnome.org> / 2002 vjt (irssi project)',
        "2011, Heinrich Muller <henmull\@src.gnome.org>\n2002-2006, Charles Kerr <charles\@rebelbase.com>\n2002-2005, 2007, 2008, 2010, Free Software\n2002, vjt (irssi project)"
    ],
    [
        q!2004-2015, Oliva f00 Oberto / 2001-2010, Paul bar Stevenson !,
        "2004-2015, Oliva f00 Oberto\n2001-2010, Paul bar Stevenson"
    ],
    [
        '2005, Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us) / 2005, Michael Schuerig (http://www.schuerig.de/michael/) / 2005, Jon Tirsen (http://www.tirsen.com)',
        "2005, Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)\n2005, Michael Schuerig (http://www.schuerig.de/michael/)\n2005, Jon Tirsen (http://www.tirsen.com)"
    ],
    [
        '1998 Brian Bassett <brian@butterfly.ml.org>
2002 Noel Koethe <noel@debian.org>
2003-2010 Jonathan Oxer <jon@debian.org>
2006-2010 Jose Luis Tallon <jltallon@adv-solutions.net>
2010 Nick Leverton <nick@leverton.org>
2011-2014 Dominique Dumont <dod@debian.org>',
        '2011-2014, Dominique Dumont <dod@debian.org>
2010, Nick Leverton <nick@leverton.org>
2006-2010, Jose Luis Tallon <jltallon@adv-solutions.net>
2003-2010, Jonathan Oxer <jon@debian.org>
2002, Noel Koethe <noel@debian.org>
1998, Brian Bassett <brian@butterfly.ml.org>',
    ],
    [
        '2015, Jonathan Stowe
 Jonathan Stowe 2015-2021
 Jonathan Stowe <jns+git@gellyfish.co.uk>',
        '2015-2021, Jonathan Stowe <jns+git@gellyfish.co.uk>'
    ],
    [
        'Jonathan Stowe <jns+git@gellyfish.co.uk>
Jonathan Stowe 2015-2021',
        '2015-2021, Jonathan Stowe <jns+git@gellyfish.co.uk>'
    ],
    [
        '2015, Dominique Dumont <dod@debian.org>',
        '2015, Dominique Dumont <dod@debian.org>'
    ],
    [
        '2009 Steven G. Johnson <stevenj@alum.mit.edu> / 2009 Matteo Frigo
2008 Steven G. Johnson <stevenj@alum.mit.edu> / 2008 Matteo Frigo
2008 Steven G. Johnson <stevenj@alum.mit.edu> / 2008 Matteo Frigo',
        '2008, 2009, Steven G. Johnson <stevenj@alum.mit.edu>
2008, 2009, Matteo Frigo'
    ],
    [
        '2001, Andrei Alexandrescu / 2001',
        '2001, Andrei Alexandrescu'
    ],
    [
        # test merge of record using different normalizations.
        '2001, '.NFC("Éric Duchmol")."\n2002-2004 ".NFD("Éric Duchmol"),
        '2001-2004, Éric Duchmol'
    ],
    [
        '2015, 2018, Blaine Bublitz <blaine.bublitz@gmail.com> and Eric Schoffstall <yo@contra.io>',
    ],
    [
        '2014, 2015, Blaine Bublitz, Eric Schoffstall and other contributors',
    ],
    [
        'Isaac Z. Schlueter and Contributors',
    ],
    [
        q!Wenzel P. P. Peppmeyer
Tony O'Dell
Timo Paulssen
Elizabeth Mattijsen!,
    ],
    ["\@copyright{} 2001--2023 Free Software Foundation, Inc.", '2001-2023, Free Software Foundation, Inc.']
);

subtest "single statement" => sub {
    my $statement = Software::Copyright->new('2014,2015-2022 Marcel <marcel@example.com>');

    is("$statement", '2014-2022, Marcel <marcel@example.com>', "check simplified statement");
    ok($statement->is_valid, "check validity");
};

subtest "blank statement" => sub {
    my $statement = Software::Copyright->new('');

    is("$statement", '', "check simplified statement");
    eq_or_diff([$statement->owners],[], "check statement owners");
};

subtest "single invalid statement" => sub {
    my $statement = Software::Copyright->new('2014');

    is($statement->is_valid,0, "check validity");
};

subtest "two statement" => sub {
    my $statement = Software::Copyright->new(
        '2014,2015-2022 Marcel <marcel@example.com> / 2022 Thierry'
    );

    is("$statement", "2022, Thierry\n2014-2022, Marcel <marcel\@example.com>", "check simplified statement");
    ok($statement->is_valid, "check validity");
};

subtest "just a year" => sub {
    my $statement = Software::Copyright->new('2022');

    is("$statement", "2022", "check simplified statement");
    ok(! $statement->is_valid, "check validity");
};


subtest "lots of test cases" => sub {
    foreach my $t (@tests) {
        my ($in,$expect) = @$t;
        $expect //= $in;
        my $label = length $in > 50 ? substr($in,0,30).'...' : $in ;
        $label =~ s/\n.*/.../;
        my $statement = Software::Copyright->new($in);
        eq_or_diff($statement->stringify,$expect,"Normalised statement '$label'");
        ok($statement->is_valid, "check validity of $label");
    }
};

subtest "equal overload" => sub {
    my $in = '2015, Dominique Dumont <dod@debian.org>';
    my $left = Software::Copyright->new($in);
    my $right = Software::Copyright->new($in);
    my $other = Software::Copyright->new('2014,'.$in);

    cmp_ok($right => eq => $left, "test equal operator");
    cmp_ok($right => ne => $other, "test not equal operator");
};

subtest "merge record" => sub {
    my $original = '2014,2015-2020 Marcel / 2002 Dod / 2015 Marc';
    my @merge_tests = (
        [
            __LINE__,
            '2004-06 Marcel' ,
            '2015, Marc
2004-2006, 2014-2020, Marcel
2002, Dod'
        ],
        [
            __LINE__,
            '2004-06 Marcel / 2020 Billy' ,
            '2020, Billy
2015, Marc
2004-2006, 2014-2020, Marcel
2002, Dod'
        ],
    );

    foreach my $t (@merge_tests) {
        my $copyright = Software::Copyright->new($original);
        $copyright->merge(Software::Copyright->new($t->[1]));
        eq_or_diff("$copyright", $t->[2], "check merged copyright from line ".$t->[0]);
        is($copyright->is_valid, 1, "check validity of merged copyright");
    }

};

subtest "record contains another" => sub {
    my $original = '2014,2015-2020 Marcel / 2002 Dod / 2015 Marc';
    my $copyright = Software::Copyright->new($original);
    my @contains_tests = (
        [__LINE__, '2015, Marc / 2014-2020, Marcel / 2002, Dod', 1],
        [__LINE__, '2014-2020, Marcel / 2002, Dod', 1],
        [__LINE__, '2016, Marc / 2014-2020, Marcel / 2002, Dod', 0],
        [__LINE__, '2015, Yves / 2014-2020, Marcel / 2002, Dod', 0],
    );

    foreach my $t (@contains_tests) {
        my ($line, $other, $expect) = $t->@*;
        my $res = $copyright->contains(Software::Copyright->new($other));
        is($res, $expect, "check $other");
    }

};

done_testing;

