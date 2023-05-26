use 5.20.0;

use Test::More;
use Test::Synopsis::Expectation;
use Time::localtime;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

require_ok('Software::Copyright::Statement');

synopsis_ok('lib/Software/Copyright/Statement.pm');

sub new_st($str) {
    return Software::Copyright::Statement->new($str);
}

subtest "blank statement" => sub {
    my $statement = new_st('');

    is("$statement", '', "check simplified statement");
    is($statement->name, undef, "check simplified statement name");
    is($statement->email, undef, "check simplified statement email");
};

subtest "just a name" => sub {
    my $statement = new_st('Marcel <marcel@example.com>');

    is("$statement", 'Marcel <marcel@example.com>', "check simplified statement");
    is($statement->name, 'Marcel', "check simplified statement name");
    is($statement->email, 'marcel@example.com', "check simplified statement email");
};

subtest "O'name" => sub {
    my $statement = new_st(q!Tony O'Dell!);

    is($statement->name, "Tony O'Dell", "check simplified statement name");
};

subtest "single statement" => sub {
    my $statement = new_st('2014,2015-2022 Marcel <marcel@example.com>');

    is("$statement", '2014-2022, Marcel <marcel@example.com>', "check simplified statement");
};

subtest "just a number" => sub {
    my $statement = new_st('2021');

    is($statement->name, undef, "check statement without name");
    is("$statement", '2021', "check statement string without name");
};

subtest "combined owners" => sub {
    my $owner_str = "Blaine Bublitz, Eric Schoffstall and other contributors";
    my $str = "2014, 2015, $owner_str";
    my $owner = new_st($str);

    is("$owner", $str, "check statement string");
    is($owner->name, undef, "check owner name");
    is($owner->record, "Blaine Bublitz, Eric Schoffstall and other contributors", "check owner record");
};

subtest "combined owners and email" => sub {
    my $owner_str = 'Blaine Bublitz <blaine.bublitz@gmail.com>,'
        . ' Eric Schoffstall <yo@contra.io> and other contributors';
    my $str = '2013-2018, '.$owner_str;
    my $owner = new_st($str);

    is("$owner", $str, "check statement string");
    is($owner->name, undef, "check owner name");
    is($owner->record, $owner_str, "check owner record");
    is($owner->email, undef, "check owner email");
};

subtest "compare statements" => sub {
    my $one   = new_st('2022 Thierry');
    my $other = new_st('2014,2015-2022 Marcel <marcel@example.com>');

    is($one cmp $one, 0, "check cmp equal");
    is($one cmp $other, 1, "check cmp equal");
    is($other cmp $one, -1, "check cmp equal");
};

subtest "merge record" => sub {
    my $statement = new_st('2014,2015-2020 Marcel');

    $statement->merge(new_st('2004-06 Marcel'));
    is("$statement", '2004-2006, 2014-2020, Marcel', "check simplified statement");

    $statement->merge(new_st('2007-08 Marcel'));
    is("$statement", '2004-2008, 2014-2020, Marcel', "check statement after year merge");

    $statement->merge(new_st('2021, Marcel'));
    is("$statement", '2004-2008, 2014-2021, Marcel', "check statement after 2021 year merge");

    # add email
    $statement->merge(new_st('Marcel <marcel@bad.com>'));
    is("$statement", '2004-2008, 2014-2021, Marcel <marcel@bad.com>', "merge bad email address");

    # fix email
    $statement->merge(new_st('2022, Marcel <marcel@example.com>'));
    is("$statement", '2004-2008, 2014-2022, Marcel <marcel@example.com>', "fix email");

};

subtest "add years" => sub {
    my $statement = new_st('2022, Marcel <marcel@example.com>');
    $statement->add_years(2010);
    is("$statement", '2010, 2022, Marcel <marcel@example.com>', "added year");
};

subtest "handle garbage" => sub {
    my $statement = new_st('**b <= a and (c+1)**b > a');
    is($statement.'',"","handle C code with (c)");
};

subtest "handle No Copyright given by licensecheck" => sub {
    my $statement = new_st('*No copyright*');
    is($statement.'',"","handle No Copyright given by licensecheck");
};

subtest "contains record" => sub {
    my $statement = new_st('2015-2020 Marcel');

    my @tests = (
        ['2014, Marcel', 0 ],
        ['2015, Marcel', 1 ],
        ['2015-2019, Marcel', 1 ],
        ['2015-2019, Yves', 0 ],
    );

    foreach my $t (@tests) {
        my ($str, $expect) = $t->@*;
        is($statement->contains(new_st($str)), $expect, "check $str");
    }
};

subtest "clean copyright" => sub {
    my $current_year =  localtime->year() + 1900;

    my @tests = (
        [
            '(c) 2006-present Philipp Lehman,',
            "2006-$current_year, Philipp Lehman"
        ],
        [
            # see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1033406
            '2022 -01-17:16:26:37 -- Version 1.3 André Hilbig, mail@andrehilbig.de',
            '2022, Version 1.3 André Hilbig, mail@andrehilbig.de',
        ],
        [
            'Uwe Lueck 2012-11-06',
            '2012, Uwe Lueck'
        ],
        [
            '2003  - 2004 - 2006 Alphonse',
            '2003-2006, Alphonse'
        ],
        [
            '(C) Werenfried Spit    04-10-90',
            '1990, Werenfried Spit'
        ],
        [
            '(c) 2003--2005 Alexej Kryukov <basileia@yandex.ru>.',
            '2003-2005, Alexej Kryukov <basileia@yandex.ru>.',
        ]
    );
    foreach my $t (@tests) {
        my ($str, $expect) = $t->@*;
        is(new_st($str), $expect, "check «$str»");
    }
};

done_testing;

